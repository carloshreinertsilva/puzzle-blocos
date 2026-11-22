import '../game/onboarding.dart';
import '../l10n/idioma.dart';
import '../services/progress_store.dart';
import 'passe.dart';
import 'wardrobe.dart';

/// Something the game has that Capi can point at on the menu.
enum TemaDica {
  guardaRoupa('opened_wardrobe'),
  loja('opened_loja'),
  passe('opened_passe'),
  blitz('opened_blitz'),
  ranking('opened_ranking'),
  duelo('opened_duel'),
  missoes('opened_missions'),
  torre('opened_tower'),
  infinito('opened_endless'),
  vila('opened_village'),
  obras('opened_obras'),
  desafioDiario('opened_daily');

  const TemaDica(this.aberto);

  /// The [ProgressStore.markSeen] topic set when the player opens it.
  final String aberto;

  /// What Capi says about it.
  String get texto => switch (this) {
    TemaDica.guardaRoupa => tr(
      'Sabia que dá para me vestir? Tem chapéus, óculos e muito mais no '
      'Guarda-Roupa!',
    ),
    TemaDica.loja => tr(
      'A Loja troca as ofertas todo dia. Vem dar uma espiada!',
    ),
    TemaDica.passe => tr(
      'No Passe do Capi as estrelas que você ganha jogando viram prêmios!',
    ),
    TemaDica.blitz => tr(
      'Topa a Blitz? São 60 segundos para fazer o máximo de pontos!',
    ),
    TemaDica.ranking => tr(
      'Veja no Ranking como você está contra os outros jogadores!',
    ),
    TemaDica.duelo => tr(
      'Desafie um amigo no Duelo: as mesmas peças, quem fizer mais vence!',
    ),
    TemaDica.missoes => tr(
      'Todo dia tem missões novas, com um baú de prêmio no fim!',
    ),
    TemaDica.torre => tr(
      'Já subiu a Torre do Capi? Empilhe os blocos o mais alto que puder!',
    ),
    TemaDica.infinito => tr(
      'Já jogou o Infinito? Sem metas, só você e o seu recorde.',
    ),
    TemaDica.vila => tr(
      'Com as suas estrelas você constrói a minha vila. Vem ver!',
    ),
    TemaDica.obras => tr(
      'Experimente as Obras: um quebra-cabeça que vale até 3 estrelas!',
    ),
    TemaDica.desafioDiario => tr(
      'O Desafio diário de hoje está esperando por você!',
    ),
  };
}

/// Capi's tip of the day on the menu: at most one a day, about something
/// already open to the player that they never used, a different one each
/// time.
abstract final class DicaDoDia {
  /// The tip for [hoje] (a [ProgressStore.dayKey]), or null: one was given
  /// today already, or there is nothing left to show. [disponiveis] are the
  /// open and never used ones; they take turns after [ultimo], in the
  /// order of [TemaDica].
  static TemaDica? escolher({
    required Set<TemaDica> disponiveis,
    required int hoje,
    int ultimoDia = 0,
    TemaDica? ultimo,
  }) {
    if (ultimoDia == hoje || disponiveis.isEmpty) return null;
    const todos = TemaDica.values;
    final inicio = ultimo == null ? 0 : ultimo.index + 1;
    for (var i = 0; i < todos.length; i++) {
      final t = todos[(inicio + i) % todos.length];
      if (disponiveis.contains(t)) return t;
    }
    return null;
  }

  /// Whether the player can get to [t] now.
  static bool liberado(
    ProgressStore store,
    TemaDica t,
    DateTime agora, {
    required bool lojaExiste,
  }) => switch (t) {
    TemaDica.loja => lojaExiste,
    TemaDica.infinito => Onboarding.endlessUnlocked(store),
    TemaDica.obras => Onboarding.obrasUnlocked(store),
    // Done today: nothing to go to until tomorrow.
    TemaDica.desafioDiario =>
      Onboarding.dailyUnlocked(store) && !store.dailyDone(agora),
    TemaDica.blitz => Onboarding.blitzUnlocked(store),
    TemaDica.duelo => Onboarding.duelUnlocked(store),
    TemaDica.torre => Onboarding.towerUnlocked(store),
    TemaDica.guardaRoupa ||
    TemaDica.passe ||
    TemaDica.ranking ||
    TemaDica.missoes ||
    TemaDica.vila => true,
  };

  /// Whether the player already uses [t]. Besides the screen's own mark
  /// (new in 1.16), what a player from before left behind counts too.
  static bool usado(ProgressStore store, TemaDica t, DateTime agora) {
    if (store.hasSeen(t.aberto)) return true;
    return switch (t) {
      TemaDica.guardaRoupa =>
        store.unlockedHats.length > 1 ||
            store.equippedHat != 'helmet' ||
            Slot.values.any((s) => store.equippedIn(s) != null),
      TemaDica.loja => store.jaComprou || store.lojaVistaDia != 0,
      TemaDica.passe => store.passPremium(PasseDoCapi.temporada(agora)),
      TemaDica.ranking => store.rankingNome != null,
      TemaDica.missoes => store.missionsStreak(agora) > 0,
      TemaDica.vila => store.villageBuilt > 0,
      TemaDica.infinito => false,
      TemaDica.obras => store.obraLevel > 1,
      TemaDica.desafioDiario =>
        store.dailyDone(agora) || store.dailyStreak(agora) > 0,
      TemaDica.blitz => store.blitzBestScore > 0,
      TemaDica.duelo => store.duelsWon > 0,
      TemaDica.torre => store.towerBestHeight > 0,
    };
  }

  /// Today's tip for this player, or null.
  static TemaDica? paraHoje(
    ProgressStore store,
    DateTime agora, {
    required bool lojaExiste,
  }) {
    final ultimo = store.dicaTema;
    return escolher(
      disponiveis: {
        for (final t in TemaDica.values)
          if (liberado(store, t, agora, lojaExiste: lojaExiste) &&
              !usado(store, t, agora))
            t,
      },
      hoje: ProgressStore.dayKey(agora),
      ultimoDia: store.dicaDia,
      ultimo: TemaDica.values.where((t) => t.name == ultimo).firstOrNull,
    );
  }

  /// [t] was shown today: no other tip until tomorrow.
  static Future<void> mostrada(
    ProgressStore store,
    TemaDica t,
    DateTime agora,
  ) => store.setDica(ProgressStore.dayKey(agora), t.name);
}
