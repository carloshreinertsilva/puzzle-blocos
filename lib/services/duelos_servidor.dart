import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/duelos.dart';
import '../l10n/idioma.dart';
import 'duelo_link.dart';
import 'firebase_app.dart';
import 'progress_store.dart';

/// A challenge on the server: whose it is and the score to beat.
class DueloNoServidor {
  const DueloNoServidor({
    required this.id,
    required this.dono,
    required this.nome,
    required this.pontos,
  });
  final String id;
  final String dono;
  final String nome;
  final int pontos;
}

/// A friend's answer to a challenge: their best score on that board.
class RespostaDuelo {
  const RespostaDuelo({
    required this.duelo,
    required this.dono,
    required this.uid,
    required this.nome,
    required this.pontos,
    required this.meta,
    this.em,
  });
  final String duelo;
  final String dono;
  final String uid;
  final String nome;
  final int pontos;

  /// The challenge's score (the owner's), copied so the owner's phone
  /// needs no second read.
  final int meta;
  final DateTime? em;

  String get id => '${duelo}_$uid';

  Map<String, Object> toMap() => {
    'duelo': duelo,
    'dono': dono,
    'uid': uid,
    'nome': nome,
    'pontos': pontos,
    'meta': meta,
  };

  static RespostaDuelo? ler(Map<String, dynamic> d) {
    final duelo = d['duelo'], dono = d['dono'], uid = d['uid'];
    final nome = d['nome'], pontos = d['pontos'], meta = d['meta'];
    if (duelo is! String || dono is! String || uid is! String) return null;
    if (nome is! String || pontos is! num || meta is! num) return null;
    final em = d['em'];
    return RespostaDuelo(
      duelo: duelo,
      dono: dono,
      uid: uid,
      nome: nome,
      pontos: pontos.toInt(),
      meta: meta.toInt(),
      em: em is Timestamp ? em.toDate() : null,
    );
  }
}

/// Where duels and their answers live.
abstract class DuelosServidor {
  /// Null where there is no server (tests, desktop): duels then work as
  /// plain links, with no result coming back.
  static DuelosServidor? atual;

  /// This phone's id on the server, or null without a connection.
  Future<String?> entrar();

  /// A new challenge id, made on the phone (no wait).
  String novoId();

  /// Registers the challenge [id].
  Future<void> criar({
    required String id,
    required String dono,
    required String nome,
    required int pontos,
    required int semente,
    required bool blitz,
  });

  Future<DueloNoServidor?> ler(String id);

  /// Sends [r], unless the friend already sent a score at least as good.
  Future<void> responder(RespostaDuelo r);

  /// Every answer to [dono]'s challenges.
  Future<List<RespostaDuelo>> paraMim(String dono);
}

/// Firestore (rules in firestore.rules), with the same anonymous sign-in as
/// the ranking:
/// - `duelos/{id}`: `{dono, nome, pontos, semente, blitz, criadoEm}`;
/// - `respostas/{duelo}_{uid}`: `{duelo, dono, uid, nome, pontos, meta, em}`,
///   a friend's best score on that challenge. Only the challenge's owner
///   lists the answers that are theirs.
class DuelosFirebase implements DuelosServidor {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<String?> entrar() async {
    if (!await firebasePronto()) return null;
    try {
      final auth = FirebaseAuth.instance;
      return (auth.currentUser ?? (await auth.signInAnonymously()).user)?.uid;
    } catch (e) {
      debugPrint('Duelos: login: $e');
      return null;
    }
  }

  @override
  String novoId() => _db.collection('duelos').doc().id;

  @override
  Future<void> criar({
    required String id,
    required String dono,
    required String nome,
    required int pontos,
    required int semente,
    required bool blitz,
  }) => _db.collection('duelos').doc(id).set({
    'dono': dono,
    'nome': nome,
    'pontos': pontos,
    'semente': semente,
    'blitz': blitz,
    'criadoEm': FieldValue.serverTimestamp(),
  });

  @override
  Future<DueloNoServidor?> ler(String id) async {
    final d = (await _db.collection('duelos').doc(id).get()).data();
    if (d == null) return null;
    final dono = d['dono'], nome = d['nome'], pontos = d['pontos'];
    if (dono is! String || nome is! String || pontos is! num) return null;
    return DueloNoServidor(
      id: id,
      dono: dono,
      nome: nome,
      pontos: pontos.toInt(),
    );
  }

  @override
  Future<void> responder(RespostaDuelo r) async {
    final doc = _db.collection('respostas').doc(r.id);
    await _db.runTransaction((t) async {
      final atual = await t.get(doc);
      final antes = (atual.data()?['pontos'] as num?)?.toInt();
      if (antes != null && antes >= r.pontos) return;
      t.set(doc, {...r.toMap(), 'em': FieldValue.serverTimestamp()});
    });
  }

  @override
  Future<List<RespostaDuelo>> paraMim(String dono) async {
    final r = await _db
        .collection('respostas')
        .where('dono', isEqualTo: dono)
        .limit(Duelos.maximo)
        .get();
    return [for (final d in r.docs) ?RespostaDuelo.ler(d.data())];
  }
}

/// A server in memory, for tests and the browser tests.
class DuelosDeTeste implements DuelosServidor {
  DuelosDeTeste({this.uid = 'eu'});
  String uid;
  final duelos = <String, DueloNoServidor>{};
  final respostas = <String, RespostaDuelo>{};
  var _proximo = 0;

  @override
  Future<String?> entrar() async => uid;

  @override
  String novoId() => 'duelo${++_proximo}';

  @override
  Future<void> criar({
    required String id,
    required String dono,
    required String nome,
    required int pontos,
    required int semente,
    required bool blitz,
  }) async {
    duelos[id] = DueloNoServidor(
      id: id,
      dono: dono,
      nome: nome,
      pontos: pontos,
    );
  }

  @override
  Future<DueloNoServidor?> ler(String id) async => duelos[id];

  @override
  Future<void> responder(RespostaDuelo r) async {
    final antes = respostas[r.id];
    if (antes != null && antes.pontos >= r.pontos) return;
    respostas[r.id] = RespostaDuelo(
      duelo: r.duelo,
      dono: r.dono,
      uid: r.uid,
      nome: r.nome,
      pontos: r.pontos,
      meta: r.meta,
      em: DateTime.now(),
    );
  }

  @override
  Future<List<RespostaDuelo>> paraMim(String dono) async => [
    for (final r in respostas.values)
      if (r.dono == dono) r,
  ];
}

/// What the game does with the server: register a challenge when it is
/// sent, answer one when it is played, and fetch the friends' answers.
/// Without a server or a connection each step quietly does nothing.
abstract final class DuelosSync {
  /// This phone's id on the server, once signed in.
  static String? _uid;

  /// Signs in ahead of time, so a challenge can be sent at once.
  static Future<String?> preparar() async {
    final s = DuelosServidor.atual;
    if (s == null) return null;
    try {
      return _uid ??= await s.entrar();
    } catch (e) {
      debugPrint('Duelos: entrar: $e');
      return null;
    }
  }

  /// Forgets the sign-in (tests).
  static void limpar() => _uid = null;

  /// [convite] with a new id on the server and the player's name, or null
  /// (no server, no name, not signed in yet). Answers at once: the share
  /// sheet (and the browser's copy, which must follow the tap) can't wait
  /// for the network; the challenge is saved on the server meanwhile.
  static DueloConvite? criar(ProgressStore store, DueloConvite convite) {
    final s = DuelosServidor.atual;
    final nome = store.rankingNome;
    final uid = _uid;
    if (s == null || nome == null) return null;
    if (uid == null) {
      preparar();
      return null;
    }
    try {
      final id = s.novoId();
      s
          .criar(
            id: id,
            dono: uid,
            nome: nome,
            pontos: convite.meta,
            semente: convite.semente,
            blitz: convite.blitz,
          )
          .catchError((Object e) => debugPrint('Duelos: criar: $e'));
      return convite.com(id: id, nome: nome);
    } catch (e) {
      debugPrint('Duelos: criar: $e');
      return null;
    }
  }

  /// Sends the player's [pontos] on the friend's challenge [id] and keeps
  /// the result on the phone. Returns the result, or null when nothing
  /// could be sent (or it is the player's own challenge).
  static Future<ResultadoDuelo?> responder(
    ProgressStore store,
    String id,
    int pontos,
  ) async {
    final s = DuelosServidor.atual;
    if (s == null) return null;
    try {
      final uid = await preparar();
      if (uid == null) return null;
      final duelo = await s.ler(id);
      if (duelo == null || duelo.dono == uid) return null;
      final anterior = Duelos.todos(store)
          .where((r) => r.duelo == id && r.rival == duelo.dono)
          .firstOrNull;
      if (anterior != null && anterior.eu >= pontos) return anterior;
      await s.responder(
        RespostaDuelo(
          duelo: id,
          dono: duelo.dono,
          uid: uid,
          nome: store.rankingNome ?? tr('Amigo'),
          pontos: pontos,
          meta: duelo.pontos,
        ),
      );
      final r = ResultadoDuelo(
        duelo: id,
        rival: duelo.dono,
        nome: duelo.nome,
        eu: pontos,
        ele: duelo.pontos,
        meu: false,
        em: DateTime.now().millisecondsSinceEpoch,
      );
      await Duelos.registrar(store, r);
      return r;
    } catch (e) {
      debugPrint('Duelos: responder: $e');
      return null;
    }
  }

  /// Fetches the friends' answers to the player's challenges. Returns the
  /// ones not told yet.
  static Future<List<ResultadoDuelo>> buscar(ProgressStore store) async {
    final s = DuelosServidor.atual;
    if (s == null) return const [];
    try {
      final uid = await preparar();
      if (uid == null) return const [];
      for (final r in await s.paraMim(uid)) {
        await Duelos.registrar(
          store,
          ResultadoDuelo(
            duelo: r.duelo,
            rival: r.uid,
            nome: r.nome,
            eu: r.meta,
            ele: r.pontos,
            meu: true,
            em: (r.em ?? DateTime.now()).millisecondsSinceEpoch,
          ),
        );
      }
    } catch (e) {
      debugPrint('Duelos: buscar: $e');
    }
    return Duelos.novos(store);
  }
}
