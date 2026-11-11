import 'package:flutter/foundation.dart';

import '../core/ranking.dart';
import 'progress_store.dart';
import 'ranking_servidor.dart';

/// Where the player stands on one of this week's boards.
class PosicaoRanking {
  const PosicaoRanking(this.quadro, this.posicao, this.faltam, this.anterior);
  final Quadro quadro;
  final int posicao;

  /// How much more it takes to reach the next place up; null at the top.
  final int? faltam;

  /// The place the player had the last time the ranking was opened this
  /// week, or null.
  final int? anterior;

  bool get caiu => anterior != null && posicao > anterior!;
  bool get subiu => anterior != null && posicao < anterior!;
}

/// The player's place on the week's boards, for the menu and the end of a
/// match. Each answer costs two reads on the server and is kept for a few
/// minutes, so playing match after match does not spend the free quota.
abstract final class RankingResumo {
  static const validade = Duration(minutes: 4);

  /// By board id: when it was read, with how many points, the place and
  /// what is missing for the next one.
  static final _lidas = <String, (DateTime, int, int, int?)>{};

  @visibleForTesting
  static void limpar() => _lidas.clear();

  /// The player's place on [q] this week. Null without a ranking (the web),
  /// a name, points this week or a connection.
  static Future<PosicaoRanking?> ler(
    ProgressStore store,
    Quadro q, {
    DateTime? quando,
  }) async {
    final s = RankingServidor.atual;
    if (s == null || store.rankingNome == null) return null;
    final agora = quando ?? DateTime.now();
    final pontos = Ranking.pontos(store, q, Periodo.semana, agora);
    if (pontos <= 0) return null;
    final id = Ranking.id(q, Periodo.semana, agora);
    var lida = _lidas[id];
    if (lida == null ||
        lida.$2 != pontos ||
        agora.difference(lida.$1) >= validade) {
      try {
        // The boards can only be read by a signed-in player.
        if (await s.entrar() == null) return null;
        final acima = await s.acima(id, pontos);
        final proximo = acima == 0 ? null : await s.proximo(id, pontos);
        lida = _lidas[id] = (
          agora,
          pontos,
          acima + 1,
          proximo == null ? null : proximo - pontos,
        );
      } catch (e) {
        debugPrint('Ranking: posição: $e');
        return null;
      }
    }
    return PosicaoRanking(
      q,
      lida.$3,
      lida.$4,
      store.rankingVisto(q.id, Ranking.semana(agora)),
    );
  }

  /// The board where the player is best placed this week (for the menu).
  static Future<PosicaoRanking?> melhor(
    ProgressStore store, {
    DateTime? quando,
  }) async {
    PosicaoRanking? melhor;
    for (final q in Quadro.values) {
      final p = await ler(store, q, quando: quando);
      if (p != null && (melhor == null || p.posicao < melhor.posicao)) {
        melhor = p;
      }
    }
    return melhor;
  }

  /// The player opened the ranking: the "went up / went down" arrows
  /// start over from the places seen now.
  static Future<void> visto(ProgressStore store, {DateTime? quando}) async {
    final agora = quando ?? DateTime.now();
    for (final q in Quadro.values) {
      final p = await ler(store, q, quando: agora);
      if (p == null) continue;
      await store.setRankingVisto(q.id, Ranking.semana(agora), p.posicao);
    }
  }
}
