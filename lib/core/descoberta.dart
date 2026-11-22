import '../game/onboarding.dart';
import '../l10n/idioma.dart';
import '../services/progress_store.dart';
import 'ofertas.dart';
import 'passe.dart';

/// Somewhere the end-of-level card can take the player.
enum Atalho {
  infinito('Infinito', Onboarding.endlessAt),
  obras('Obras', Onboarding.obrasAt),
  desafioDiario('Desafio diário', Onboarding.dailyAt),
  blitz('Blitz 60s', Onboarding.blitzAt),
  duelo('Duelo', Onboarding.duelAt),
  torre('Torre do Capi', Onboarding.towerAt),
  passe('Passe do Capi', null),
  loja('Loja', null);

  const Atalho(this._nome, this.liberaNaFase);

  /// The name in Portuguese, as on the menu (translated by [nome]).
  final String _nome;
  String get nome => tr(_nome);

  /// For a game mode: the level it opens at.
  final int? liberaNaFase;
}

/// Where the player stands on the Passe do Capi, for one line on the card.
class LinhaPasse {
  const LinhaPasse({this.prontas = 0, this.faltam = 0, this.premio = ''});

  /// Rewards waiting to be claimed (then the line is about them).
  final int prontas;

  /// Points to the next level, and what it gives on the free track.
  final int faltam;
  final String premio;

  String get texto => prontas > 0
      ? trN(prontas, 'Passe: {n} prêmio pronto!', 'Passe: {n} prêmios prontos!')
      : trN(
          faltam,
          'Passe: falta {n} ponto para {premio}',
          'Passe: faltam {n} pontos para {premio}',
          {'premio': premio},
        );
}

/// What the end-of-level card shows besides the result, so that a player
/// who goes from level to level (and seldom sees the menu) still finds out
/// what the game has: a mode that just opened, the Passe, the piggy bank.
abstract final class Descoberta {
  /// The modes that open when level [concluida] is won for the first time
  /// (the player moves on to the next one).
  static List<Atalho> liberadosAoVencer(int concluida) => [
    for (final a in Atalho.values)
      if (a.liberaNaFase == concluida + 1) a,
  ];

  /// The Passe's line, or null once the season's track is done and
  /// everything was claimed.
  static LinhaPasse? passe(ProgressStore store, DateTime agora) {
    final prontas = PasseDoCapi.prontas(store, agora);
    if (prontas > 0) return LinhaPasse(prontas: prontas);
    final nivel = PasseDoCapi.nivel(store, agora);
    if (nivel >= PasseDoCapi.niveis) return null;
    final pontos = PasseDoCapi.pontos(store, agora);
    return LinhaPasse(
      faltam: PasseDoCapi.pontosPorNivel - pontos % PasseDoCapi.pontosPorNivel,
      premio: PasseDoCapi.trilha(agora)[nivel].gratis.texto,
    );
  }

  /// The piggy bank's line once it is worth breaking, or null.
  static String? cofrinho(ProgressStore store) {
    if (!Cofrinho.podeQuebrar(store)) return null;
    return Cofrinho.cheio(store)
        ? tr('Cofrinho cheio: {n} estrelas!', {'n': store.cofrinho})
        : tr('Cofrinho: {n} estrelas guardadas', {'n': store.cofrinho});
  }
}
