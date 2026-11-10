import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/nome_filtro.dart';
import '../core/ranking.dart';
import 'convites_servidor.dart';
import 'firebase_app.dart';
import 'progress_store.dart';

/// Where the boards are kept. The game talks to this; on the phones it is
/// Firebase ([RankingFirebase]), in tests an in-memory one.
abstract class RankingServidor {
  /// The one in use; null where there is no ranking (the web).
  static RankingServidor? atual;

  /// This player's id on the boards, or null when there is no connection.
  Future<String?> entrar();

  /// The best [limite] lines of board [id], best first.
  Future<List<EntradaRanking>> topo(String id, int limite);

  /// How many lines of board [id] have more than [pontos].
  Future<int> acima(String id, int pontos);

  Future<void> enviar(String id, EntradaRanking entrada);

  /// A player reports [denunciado]'s name on board [id].
  Future<void> denunciar(String id, EntradaRanking denunciado, String por);

  /// Players hidden by the moderation, and more words for the name filter.
  Future<({Set<String> ocultos, Set<String> palavras})> moderacao();
}

/// The ranking's server part, on Firebase (project `capiblocks`), with the
/// same anonymous sign-in as the invites.
///
/// Firestore (rules in firestore.rules):
/// - `rankings/{quadro}/jogadores/{uid}`: `{nome, pontos, chapeu, pelagem,
///   embaixador, em}`; `quadro` is Ranking.id (`torre_geral`, `torre_s2965`);
/// - `denuncias/{id}`: a reported name, for whoever moderates to look at;
/// - `config/ranking`: `{ocultos: [uid], palavras: [..]}`, edited by hand
///   in the Firebase console: players hidden from every list and more
///   words for the name filter, without a new version of the game.
class RankingFirebase implements RankingServidor {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _jogadores(String id) =>
      _db.collection('rankings').doc(id).collection('jogadores');

  @override
  Future<String?> entrar() async {
    if (!ConvitesServidor.ativo || !await firebasePronto()) return null;
    try {
      final auth = FirebaseAuth.instance;
      return (auth.currentUser ?? (await auth.signInAnonymously()).user)?.uid;
    } catch (e) {
      debugPrint('Ranking: login: $e');
      return null;
    }
  }

  @override
  Future<List<EntradaRanking>> topo(String id, int limite) async {
    final r = await _jogadores(id)
        .orderBy('pontos', descending: true)
        .limit(limite)
        .get();
    return [for (final d in r.docs) ?EntradaRanking.ler(d.id, d.data())];
  }

  @override
  Future<int> acima(String id, int pontos) async {
    final r = await _jogadores(id)
        .where('pontos', isGreaterThan: pontos)
        .count()
        .get();
    return r.count ?? 0;
  }

  @override
  Future<void> enviar(String id, EntradaRanking entrada) =>
      _jogadores(id)
          .doc(entrada.uid)
          .set({...entrada.toMap(), 'em': FieldValue.serverTimestamp()});

  @override
  Future<void> denunciar(String id, EntradaRanking denunciado, String por) =>
      _db.collection('denuncias').add({
        'quadro': id,
        'uid': denunciado.uid,
        'nome': denunciado.nome,
        'por': por,
        'em': FieldValue.serverTimestamp(),
      });

  @override
  Future<({Set<String> ocultos, Set<String> palavras})> moderacao() async {
    final d = (await _db.collection('config').doc('ranking').get()).data();
    Set<String> lista(String campo) => {
      for (final v in (d?[campo] as List?) ?? const [])
        if (v is String) v,
    };
    return (ocultos: lista('ocultos'), palavras: lista('palavras'));
  }
}

/// Keeps the server up to date with what is on the phone.
abstract final class RankingSync {
  static Set<String> ocultos = {};
  static bool _moderacaoLida = false;

  /// Reads the moderation's lists, once per session.
  static Future<void> moderacao(RankingServidor s) async {
    if (_moderacaoLida) return;
    try {
      final m = await s.moderacao();
      ocultos = m.ocultos;
      NomeFiltro.extras = m.palavras.map(NomeFiltro.normalizar).toSet();
      _moderacaoLida = true;
    } catch (e) {
      debugPrint('Ranking: moderação: $e');
    }
  }

  /// Sends the player's lines that changed (new record, new name, another
  /// hat). Nothing happens without a name or a connection.
  static Future<void> enviar(ProgressStore store, [DateTime? quando]) async {
    final s = RankingServidor.atual;
    if (s == null || store.rankingNome == null) return;
    try {
      final uid = await s.entrar();
      if (uid == null) return;
      final agora = quando ?? DateTime.now();
      for (final q in Quadro.values) {
        for (final p in Periodo.values) {
          final e = Ranking.minha(store, uid, q, p, agora);
          if (e == null) continue;
          final id = Ranking.id(q, p, agora);
          final assinatura = Ranking.assinatura(id, e);
          if (store.rankingEnviado(q.id, p.name) == assinatura) continue;
          await s.enviar(id, e);
          await store.setRankingEnviado(q.id, p.name, assinatura);
        }
      }
    } catch (e) {
      debugPrint('Ranking: enviar: $e');
    }
  }
}

/// A server in memory, for tests and to try the screen without Firebase.
class RankingDeTeste implements RankingServidor {
  RankingDeTeste({this.uid = 'eu'});
  final String uid;
  final Map<String, Map<String, EntradaRanking>> quadros = {};
  final List<(String, String)> denuncias = [];
  Set<String> ocultos = {};

  @override
  Future<String?> entrar() async => uid;

  @override
  Future<List<EntradaRanking>> topo(String id, int limite) async =>
      ((quadros[id]?.values.toList() ?? [])
            ..sort((a, b) => b.pontos.compareTo(a.pontos)))
          .take(limite)
          .toList();

  @override
  Future<int> acima(String id, int pontos) async =>
      quadros[id]?.values.where((e) => e.pontos > pontos).length ?? 0;

  @override
  Future<void> enviar(String id, EntradaRanking entrada) async {
    (quadros[id] ??= {})[entrada.uid] = entrada;
  }

  @override
  Future<void> denunciar(String id, EntradaRanking d, String por) async {
    denuncias.add((id, d.uid));
  }

  @override
  Future<({Set<String> ocultos, Set<String> palavras})> moderacao() async =>
      (ocultos: ocultos, palavras: <String>{});
}
