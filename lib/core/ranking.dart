import 'dart:math';

import '../services/progress_store.dart';
import 'convites.dart';
import 'wardrobe.dart';

/// The game's own boards (services/ranking_servidor.dart keeps them).
enum Quadro {
  torre('torre', 'Torre do Capi', 'andares', 500),
  infinito('infinito', 'Infinito', 'pontos', 5000000),
  blitz('blitz', 'Blitz 60s', 'pontos', 1000000),
  fases('fases', 'Fases', 'fases', 100000);

  const Quadro(this.id, this.nome, this.unidade, this.maximo);
  final String id;

  /// In Portuguese (shown through `tr`).
  final String nome;
  final String unidade;

  /// No honest score is above this (the server refuses more).
  final int maximo;
}

/// Each board has two lists: this week's (it starts over every Monday,
/// 00:00 UTC) and the all-time one.
enum Periodo { semana, geral }

/// One line of a board.
class EntradaRanking {
  const EntradaRanking({
    required this.uid,
    required this.nome,
    required this.pontos,
    this.chapeu = 'helmet',
    this.pelagem = Wardrobe.pelagemPadrao,
    this.embaixador = false,
  });
  final String uid;
  final String nome;
  final int pontos;

  /// What the player's Capi wears on the list.
  final String chapeu;
  final String pelagem;

  /// Brought enough friends (see Convites.embaixador).
  final bool embaixador;

  Map<String, Object?> toMap() => {
    'nome': nome,
    'pontos': pontos,
    'chapeu': chapeu,
    'pelagem': pelagem,
    'embaixador': embaixador,
  };

  static EntradaRanking? ler(String uid, Map<String, Object?> d) {
    final nome = d['nome'], pontos = d['pontos'];
    if (nome is! String || pontos is! num) return null;
    return EntradaRanking(
      uid: uid,
      nome: nome,
      pontos: pontos.toInt(),
      chapeu: d['chapeu'] is String ? d['chapeu']! as String : 'helmet',
      pelagem: d['pelagem'] is String
          ? d['pelagem']! as String
          : Wardrobe.pelagemPadrao,
      embaixador: d['embaixador'] == true,
    );
  }
}

/// What the phone decides by itself about the ranking: which week it is,
/// each board's score and what still has to be sent.
abstract final class Ranking {
  /// How many lines of a board are shown.
  static const topo = 20;

  static const _dia = 86400000;

  /// Weeks since 1970, starting on Mondays (UTC): the same number the
  /// server's rules compute, so nobody writes on another week's board.
  static int semana(DateTime t) =>
      (t.toUtc().millisecondsSinceEpoch ~/ _dia + 3) ~/ 7;

  /// When this week's boards start over.
  static DateTime fimDaSemana(DateTime t) =>
      DateTime.fromMillisecondsSinceEpoch(
        ((semana(t) + 1) * 7 - 3) * _dia,
        isUtc: true,
      );

  /// The board's document on the server.
  static String id(Quadro q, Periodo p, DateTime agora) =>
      p == Periodo.geral ? '${q.id}_geral' : '${q.id}_s${semana(agora)}';

  /// The player's score on a board.
  static int pontos(ProgressStore store, Quadro q, Periodo p, DateTime agora) {
    if (p == Periodo.semana) return store.rankingDaSemana(q.id, semana(agora));
    return switch (q) {
      Quadro.torre => store.towerBestHeight,
      Quadro.infinito => store.bestScore,
      Quadro.blitz => store.blitzBestScore,
      Quadro.fases => max(0, store.level - 1),
    };
  }

  /// A match just ended with [pontos] on [q]: this week's best. On
  /// [Quadro.fases] each level won counts one more for the week.
  static Future<void> marcar(
    ProgressStore store,
    Quadro q,
    int pontos,
    DateTime agora,
  ) async {
    final s = semana(agora);
    final atual = store.rankingDaSemana(q.id, s);
    final novo = q == Quadro.fases ? atual + 1 : max(atual, pontos);
    if (novo != atual) await store.setRankingDaSemana(q.id, s, novo);
  }

  /// The player's line on a board, as it should be on the server.
  static EntradaRanking? minha(
    ProgressStore store,
    String uid,
    Quadro q,
    Periodo p,
    DateTime agora,
  ) {
    final nome = store.rankingNome;
    final pts = min(pontos(store, q, p, agora), q.maximo);
    if (nome == null || pts <= 0) return null;
    return EntradaRanking(
      uid: uid,
      nome: nome,
      pontos: pts,
      chapeu: store.equippedHat,
      pelagem: store.equippedIn(Slot.pelagem) ?? Wardrobe.pelagemPadrao,
      embaixador: Convites.embaixador(store),
    );
  }

  /// What identifies a line already sent: nothing is sent twice.
  static String assinatura(String id, EntradaRanking e) =>
      '$id|${e.pontos}|${e.nome}|${e.chapeu}|${e.pelagem}|${e.embaixador}';
}
