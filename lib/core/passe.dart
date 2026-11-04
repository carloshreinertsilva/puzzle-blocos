import 'dart:math';

import '../l10n/idioma.dart';
import '../services/progress_store.dart';
import 'wardrobe.dart';

/// One reward on the Passe do Capi's track: stars, tools or an item.
class Recompensa {
  const Recompensa.estrelas(this.quantidade) : ferramenta = null, item = null;
  const Recompensa.ferramenta(CapiTool this.ferramenta, this.quantidade)
    : item = null;
  const Recompensa.item(String this.item) : ferramenta = null, quantidade = 1;

  final int quantidade;
  final CapiTool? ferramenta;

  /// A wardrobe item id (see wardrobe.dart).
  final String? item;

  String get texto {
    if (item != null) return Wardrobe.byId(item!)!.label;
    final n = quantidade;
    return switch (ferramenta) {
      CapiTool.hammer => trN(n, '{n} martelo', '{n} martelos'),
      CapiTool.shovel => trN(n, '{n} pá', '{n} pás'),
      CapiTool.reroll => trN(n, '{n} troca de peças', '{n} trocas de peças'),
      CapiTool.rotate => trN(n, '{n} giro', '{n} giros'),
      null => trN(n, '{n} estrela', '{n} estrelas'),
    };
  }
}

/// One level of the track: a free reward for everyone and a premium one.
class NivelPasse {
  const NivelPasse(this.gratis, this.premium);
  final Recompensa gratis;
  final Recompensa premium;
}

/// The Passe do Capi: a 30-day season. Stars earned by playing (not bought)
/// are the pass points; every [pontosPorNivel] points open a level. The free
/// track is for everyone; the premium track ([Produto.passeCapi], once per
/// season) adds more stars, tools, 2 exclusive rare items and the season's
/// legendary one. Nothing in it
/// is random: every reward is shown from the start.
abstract final class PasseDoCapi {
  /// Season 1 starts here; each season lasts [diasPorTemporada] days.
  static final inicio = DateTime(2026, 11, 1);
  static const diasPorTemporada = 30;
  static const pontosPorNivel = 30;

  static const trilha = <NivelPasse>[
    NivelPasse(Recompensa.estrelas(3), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.shovel, 1),
      Recompensa.ferramenta(CapiTool.shovel, 2),
    ),
    NivelPasse(Recompensa.estrelas(3), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.reroll, 1),
      Recompensa.ferramenta(CapiTool.reroll, 2),
    ),
    NivelPasse(Recompensa.estrelas(3), Recompensa.estrelas(15)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.hammer, 1),
      Recompensa.ferramenta(CapiTool.hammer, 2),
    ),
    NivelPasse(Recompensa.estrelas(3), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.shovel, 1),
      Recompensa.ferramenta(CapiTool.shovel, 2),
    ),
    NivelPasse(Recompensa.estrelas(3), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.reroll, 1),
      Recompensa.item('oculos_estrelados'),
    ),
    NivelPasse(Recompensa.estrelas(4), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.hammer, 1),
      Recompensa.ferramenta(CapiTool.hammer, 2),
    ),
    NivelPasse(Recompensa.estrelas(4), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.shovel, 1),
      Recompensa.ferramenta(CapiTool.shovel, 2),
    ),
    NivelPasse(Recompensa.estrelas(10), Recompensa.estrelas(15)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.reroll, 1),
      Recompensa.ferramenta(CapiTool.reroll, 2),
    ),
    NivelPasse(Recompensa.estrelas(4), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.hammer, 1),
      Recompensa.ferramenta(CapiTool.hammer, 2),
    ),
    NivelPasse(Recompensa.estrelas(4), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.shovel, 1),
      Recompensa.item('medalha'),
    ),
    NivelPasse(Recompensa.estrelas(5), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.reroll, 1),
      Recompensa.ferramenta(CapiTool.reroll, 2),
    ),
    NivelPasse(Recompensa.estrelas(5), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.hammer, 1),
      Recompensa.ferramenta(CapiTool.hammer, 2),
    ),
    NivelPasse(Recompensa.estrelas(5), Recompensa.estrelas(15)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.shovel, 1),
      Recompensa.ferramenta(CapiTool.shovel, 2),
    ),
    NivelPasse(Recompensa.estrelas(5), Recompensa.estrelas(8)),
    NivelPasse(
      Recompensa.ferramenta(CapiTool.reroll, 1),
      Recompensa.ferramenta(CapiTool.reroll, 2),
    ),
    NivelPasse(Recompensa.estrelas(5), Recompensa.estrelas(8)),
    NivelPasse(Recompensa.estrelas(15), Recompensa.item('coroa_estrelas')),
  ];

  static int get niveis => trilha.length;

  /// Season 1 sells the premium track at a launch price (set in the Play
  /// Console; later seasons cost more).
  static bool precoLancamento(DateTime agora) => temporada(agora) == 1;

  static int temporada(DateTime agora) =>
      max(0, agora.difference(inicio).inDays) ~/ diasPorTemporada + 1;

  static DateTime fim(int temporada) =>
      inicio.add(Duration(days: temporada * diasPorTemporada));

  static int diasRestantes(DateTime agora) =>
      max(1, fim(temporada(agora)).difference(agora).inHours ~/ 24 + 1);

  static int pontos(ProgressStore store, DateTime agora) =>
      store.passPoints(temporada(agora));

  /// Levels reached (0 to [niveis]).
  static int nivel(ProgressStore store, DateTime agora) =>
      min(niveis, pontos(store, agora) ~/ pontosPorNivel);

  static bool premium(ProgressStore store, DateTime agora) =>
      store.passPremium(temporada(agora));

  /// Whether level [n] (from 1) on that track can be claimed now.
  static bool podePegar(
    ProgressStore store,
    DateTime agora,
    int n, {
    required bool trilhaPremium,
  }) {
    final t = temporada(agora);
    if (n > nivel(store, agora)) return false;
    if (trilhaPremium && !store.passPremium(t)) return false;
    return !store.passClaimed(t, n, premium: trilhaPremium);
  }

  /// Rewards ready to claim, for the badge.
  static int prontas(ProgressStore store, DateTime agora) {
    var n = 0;
    for (var i = 1; i <= nivel(store, agora); i++) {
      if (podePegar(store, agora, i, trilhaPremium: false)) n++;
      if (podePegar(store, agora, i, trilhaPremium: true)) n++;
    }
    return n;
  }

  /// Gives level [n]'s reward on that track, once.
  static Future<bool> pegar(
    ProgressStore store,
    DateTime agora,
    int n, {
    required bool trilhaPremium,
  }) async {
    if (!podePegar(store, agora, n, trilhaPremium: trilhaPremium)) {
      return false;
    }
    final t = temporada(agora);
    await store.markPassClaimed(t, n, premium: trilhaPremium);
    final nivel = trilha[n - 1];
    final r = trilhaPremium ? nivel.premium : nivel.gratis;
    if (r.item case final id?) {
      await store.unlockHat(id);
      await Wardrobe.awardCollections(store);
    } else if (r.ferramenta case final f?) {
      await store.addTool(f, r.quantidade);
    } else {
      // Reward stars don't count as pass points (no loop).
      await store.addBoughtStars(r.quantidade);
    }
    return true;
  }
}
