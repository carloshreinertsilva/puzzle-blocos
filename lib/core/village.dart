import 'dart:ui';

/// One thing Capi can build in his village: the art (`assets/vila/<id>.png`),
/// where it sits in the 1000x1300 scene, and its price in stars.
class VillageItem {
  const VillageItem(this.id, this.name, this.cost, this.rect);
  final String id;
  final String name;
  final int cost;
  final Rect rect;

  String get asset => 'assets/vila/$id.png';
}

/// The first village (Capi's lagoon), built in this order. Art drawn in
/// VectorCraft (art/vila/vila.vectorcraft).
abstract final class Village {
  static const sceneSize = Size(1000, 1300);
  static const background = 'assets/vila/fundo.png';

  static const items = [
    VillageItem(
      'flores',
      'Canteiro de flores',
      3,
      Rect.fromLTWH(617, 1114, 326, 129),
    ),
    VillageItem('cerca', 'Cerquinha', 3, Rect.fromLTWH(37.5, 1095.5, 345, 127)),
    VillageItem(
      'banco',
      'Banco da lagoa',
      4,
      Rect.fromLTWH(597.5, 677.5, 165, 104.5),
    ),
    VillageItem(
      'arvore',
      'Pé de acerola',
      4,
      Rect.fromLTWH(716.5, 356.5, 227, 347),
    ),
    VillageItem('barco', 'Barquinho', 5, Rect.fromLTWH(282, 816.5, 176, 136.5)),
    VillageItem('horta', 'Horta', 5, Rect.fromLTWH(27, 692.5, 206, 100.5)),
    VillageItem('poste', 'Poste de luz', 6, Rect.fromLTWH(532, 1000, 76, 238)),
    VillageItem('pier', 'Píer', 6, Rect.fromLTWH(627.5, 907.5, 195, 69)),
    VillageItem(
      'casinha',
      'Casinha do Capi',
      7,
      Rect.fromLTWH(66, 406, 268, 263),
    ),
    VillageItem('balanco', 'Balanço', 8, Rect.fromLTWH(855, 780, 125, 185)),
    VillageItem('fonte', 'Fonte', 10, Rect.fromLTWH(412, 578, 176, 171)),
    VillageItem('roda', 'Roda-gigante', 12, Rect.fromLTWH(368, 280, 204, 226)),
  ];

  /// Where Capi stands in the scene (his feet).
  static const capiFeet = Offset(470, 1080);

  /// The next item to build after [built] items, or null when complete.
  static VillageItem? next(int built) =>
      built < items.length ? items[built] : null;

  /// Built items in drawing order: further back (higher up) first.
  static List<VillageItem> drawn(int built) =>
      items.take(built).toList()
        ..sort((a, b) => a.rect.bottom.compareTo(b.rect.bottom));
}
