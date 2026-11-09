import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

import '../core/convites.dart';
import 'firebase_app.dart';
import 'progress_store.dart';

/// The invites' server part, on Firebase (project `capiblocks`), with no
/// e-mail or login: each phone signs in anonymously.
///
/// Firestore (rules in firestore.rules):
/// - `codigos/{codigo}`: `{uid}`, whose code it is (created once);
/// - `convites/{uid}`: `{codigo, dono, fase5}`, the code this player came in
///   with, whose code it is, and whether they reached
///   [Convites.faseQueConta].
/// Whoever invited counts the `convites` that are theirs (`dono`) with
/// `fase5`; nobody can list anyone else's.
///
/// Off on the web and in tests: there, codes still work on the phone but
/// nothing is counted.
abstract final class ConvitesServidor {
  static bool get ativo => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<User?> _entrar() async {
    if (!ativo || !await firebasePronto()) return null;
    try {
      final auth = FirebaseAuth.instance;
      return auth.currentUser ?? (await auth.signInAnonymously()).user;
    } catch (e) {
      debugPrint('Convites: login: $e');
      return null;
    }
  }

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Brings the server up to date (called when the menu opens): registers
  /// this phone's code, the friend's code it came in with and whether it
  /// reached the level that counts, then counts this player's friends and
  /// gives the reward steps reached. Returns the new steps.
  static Future<List<MetaConvite>> sincronizar(ProgressStore store) async {
    final user = await _entrar();
    if (user == null) return const [];
    try {
      await _registrarCodigo(store, user.uid);
      await _enviarConvite(store, user.uid);
      final amigos = await _contarAmigos(store, user.uid);
      if (amigos == null) return const [];
      return await Convites.receberMetas(store, amigos);
    } catch (e) {
      debugPrint('Convites: $e');
      return const [];
    }
  }

  static Future<void> _registrarCodigo(ProgressStore store, String uid) async {
    if (store.conviteCodigoNoServidor) return;
    // A code taken by someone else (very rare): a new one.
    for (var tentativa = 0; tentativa < 4; tentativa++) {
      final codigo = await Convites.meuCodigo(store);
      final doc = _db.collection('codigos').doc(codigo);
      final criado = await _db.runTransaction((t) async {
        final atual = await t.get(doc);
        if (atual.exists) return atual.data()?['uid'] == uid;
        t.set(doc, {'uid': uid, 'criadoEm': FieldValue.serverTimestamp()});
        return true;
      });
      if (criado) {
        await store.setConviteCodigoNoServidor();
        return;
      }
      await store.setConviteCodigo(Convites.gerarCodigo());
    }
  }

  static Future<void> _enviarConvite(ProgressStore store, String uid) async {
    final codigo = store.conviteUsado;
    if (codigo == null || store.conviteEnviado == _semDono) return;
    final doc = _db.collection('convites').doc(uid);
    if (store.conviteEnviado < 1) {
      // Whose code it is: the invite is saved under them, so each player
      // can only count their own friends.
      final dono = await _db.collection('codigos').doc(codigo).get();
      final donoUid = dono.data()?['uid'];
      if (donoUid is! String || donoUid == uid) {
        // A code nobody has (typed wrong): the gift stays, nothing counts.
        await store.setConviteEnviado(_semDono);
        return;
      }
      await doc.set({
        'codigo': codigo,
        'dono': donoUid,
        'fase5': false,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      await store.setConviteEnviado(1);
    }
    if (store.conviteEnviado < 2 && store.level >= Convites.faseQueConta) {
      await doc.update({'fase5': true});
      await store.setConviteEnviado(2);
    }
  }

  /// [ProgressStore.conviteEnviado] for a code with no owner on the server.
  static const _semDono = 9;

  static Future<int?> _contarAmigos(ProgressStore store, String uid) async {
    if (!store.conviteCodigoNoServidor) return null;
    final total = await _db
        .collection('convites')
        .where('dono', isEqualTo: uid)
        .where('fase5', isEqualTo: true)
        .count()
        .get();
    return total.count;
  }

  /// On Android, the first time: the code in the Play Store's install
  /// referrer (the invite link's store button carries it). Null when there
  /// is none.
  static Future<String?> codigoDaInstalacao(ProgressStore store) async {
    if (!ativo || !Platform.isAndroid || store.conviteReferrerLido) {
      return null;
    }
    await store.setConviteReferrerLido();
    try {
      final dados = await PlayInstallReferrer.installReferrer;
      return Convites.lerReferrer(dados.installReferrer);
    } catch (e) {
      debugPrint('Convites: referrer: $e');
      return null;
    }
  }
}
