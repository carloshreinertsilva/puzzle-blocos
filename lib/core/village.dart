import 'dart:ui';

/// One thing Capi can build in his village: its price in stars and its
/// footprint on the island's ground, in tiles (x runs to the lower right of
/// the screen, y to the lower left; see `lib/village/iso.dart`).
class VillageItem {
  const VillageItem(this.id, this.name, this.cost, this.spot);
  final String id;
  final String name;
  final int cost;
  final Rect spot;
}

/// The first village (Capi's lagoon, on a floating island). The player picks
/// what to build from the village market, in any order. Drawn in code by
/// `lib/village/`.
abstract final class Village {
  /// The island is a square of this many tiles a side.
  static const island = 10.0;

  static const items = [
    VillageItem(
      'flores',
      'Canteiro de flores',
      18,
      Rect.fromLTWH(8.9, 6.4, 0.8, 2),
    ),
    VillageItem('cerca', 'Cerquinha', 18, Rect.fromLTWH(0.4, 9.5, 5.8, 0.2)),
    VillageItem(
      'banco',
      'Banco da lagoa',
      24,
      Rect.fromLTWH(8.4, 2.9, 0.6, 1.3),
    ),
    VillageItem(
      'arvore',
      'Pé de acerola',
      24,
      Rect.fromLTWH(6.2, 0.7, 1.3, 1.3),
    ),
    VillageItem('barco', 'Barquinho', 30, Rect.fromLTWH(4, 4.3, 1.5, 0.7)),
    VillageItem('horta', 'Horta', 30, Rect.fromLTWH(0.9, 6.9, 2.4, 2)),
    VillageItem('poste', 'Poste de luz', 36, Rect.fromLTWH(8.2, 8.5, 0.2, 0.2)),
    VillageItem('pier', 'Píer', 36, Rect.fromLTWH(5.4, 5.9, 0.8, 1.8)),
    VillageItem(
      'casinha',
      'Casinha do Capi',
      42,
      Rect.fromLTWH(0.7, 2.9, 2.6, 2.6),
    ),
    VillageItem('balanco', 'Balanço', 48, Rect.fromLTWH(8.6, 0.8, 1, 1.6)),
    VillageItem('fonte', 'Fonte', 60, Rect.fromLTWH(2.95, 0.65, 1.9, 1.9)),
    VillageItem('roda', 'Roda-gigante', 72, Rect.fromLTWH(0.6, 0.3, 2, 2)),
  ];

  /// Where Capi stands when he isn't busy: on the path by the pier.
  static const capiSpot = Offset(6.6, 8.6);

  /// The items still to build, cheapest first.
  static List<VillageItem> toBuild(Iterable<String> built) {
    final done = built.toSet();
    return [
      for (final item in items)
        if (!done.contains(item.id)) item,
    ]..sort((a, b) => a.cost.compareTo(b.cost));
  }

  /// What the market points at first: the cheapest item left (so with
  /// enough stars for anything, there is something to build). Null when the
  /// village is complete.
  static VillageItem? suggestion(Iterable<String> built) {
    final left = toBuild(built);
    return left.isEmpty ? null : left.first;
  }

  static VillageItem byId(String id) => items.firstWhere((i) => i.id == id);
}
