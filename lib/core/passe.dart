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

/// One month's season: its theme, the item that comes the moment the
/// premium track is bought, and the theme's items on the track (by level,
/// replacing that level's base reward).
class TemaTemporada {
  const TemaTemporada(
    this._nome, {
    this.naCompra,
    this.premium = const {},
    this.gratis = const {},
  });

  final String _nome;
  String get nome => tr(_nome);

  /// A wardrobe item id, given with the premium track.
  final String? naCompra;
  final Map<int, String> premium;
  final Map<int, String> gratis;

  /// Every item of the season.
  List<String> get itens => [?naCompra, ...premium.values, ...gratis.values];
}

/// The Passe do Capi: one season per calendar month. Stars earned by
/// playing (not bought) are the pass points; every [pontosPorNivel] points
/// open a level. The free track is for everyone; the premium track
/// ([Produto.passeCapi], once per season) adds more stars, tools, the
/// month's themed items and, at once, its exclusive one. Nothing in it is
/// random: every reward is shown from the start. A season's items are only
/// on offer in its month (they come back a year later); whoever has them
/// keeps them.
abstract final class PasseDoCapi {
  /// Season 1 is November 2026; each calendar month is a season.
  static final inicio = DateTime(2026, 11, 1);
  static const pontosPorNivel = 30;

  /// The themes, by month (1 to 12). A month without one has a track of
  /// stars and tools only. New ones are added a couple of months ahead.
  static const temas = <int, TemaTemporada>{
    1: TemaTemporada(
      'Verão',
      naCompra: 'chapeu_melancia',
      premium: {10: 'mascara_mergulho', 20: 'prancha_surfe'},
      gratis: {25: 'colar_conchas'},
    ),
    11: TemaTemporada(
      'Estrelas',
      premium: {10: 'oculos_estrelados', 20: 'medalha', 30: 'coroa_estrelas'},
    ),
    12: TemaTemporada(
      'Natal',
      naCompra: 'gorro_natal',
      premium: {10: 'cachecol_natal', 20: 'chifres_rena'},
      gratis: {25: 'sininho'},
    ),
  };

  static TemaTemporada? tema(DateTime agora) => temas[agora.month];

  /// The track of the season running at [agora].
  static List<NivelPasse> trilha(DateTime agora) {
    final t = tema(agora);
    if (t == null) return _base;
    return [
      for (var n = 1; n <= _base.length; n++)
        NivelPasse(
          t.gratis[n] != null
              ? Recompensa.item(t.gratis[n]!)
              : _base[n - 1].gratis,
          t.premium[n] != null
              ? Recompensa.item(t.premium[n]!)
              : _base[n - 1].premium,
        ),
    ];
  }

  static const _base = <NivelPasse>[
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
      Recompensa.estrelas(15),
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
      Recompensa.estrelas(15),
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
    NivelPasse(Recompensa.estrelas(15), Recompensa.estrelas(40)),
  ];

  static int get niveis => _base.length;

  /// Season 1 sells the premium track at a launch price (set in the Play
  /// Console; later seasons cost more).
  static bool precoLancamento(DateTime agora) => temporada(agora) == 1;

  static int temporada(DateTime agora) =>
      max(1, (agora.year - inicio.year) * 12 + agora.month - inicio.month + 1);

  /// When season [temporada] ends: the first day of the next month.
  static DateTime fim(int temporada) =>
      DateTime(inicio.year, inicio.month + temporada);

  static int diasRestantes(DateTime agora) =>
      max(1, (fim(temporada(agora)).difference(agora).inHours + 23) ~/ 24);

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
    final nivel = trilha(agora)[n - 1];
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
