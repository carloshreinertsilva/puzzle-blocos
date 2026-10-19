/// Piece shapes and the catalog the generator draws from.
///
/// Shapes are written as small ASCII grids ('X' = cell). Each one keeps a
/// bitmask per row (bit c = column c) so the solver can test placements
/// quickly; masks stay under 8 bits, which keeps them safe on the web too.
class Shape {
  Shape(this.id, List<String> art, {required this.tier, required this.color})
    : rows = art.length,
      cols = art.first.length,
      cells = [
        for (var r = 0; r < art.length; r++)
          for (var c = 0; c < art[r].length; c++)
            if (art[r][c] == 'X') (r, c),
      ] {
    rowMasks = List.generate(rows, (r) {
      var mask = 0;
      for (var c = 0; c < cols; c++) {
        if (art[r][c] == 'X') mask |= 1 << c;
      }
      return mask;
    });
  }

  final String id;
  final int rows;
  final int cols;
  final List<(int, int)> cells;

  /// 0 = easy (small), 1 = medium, 2 = hard (big or awkward).
  final int tier;

  /// Index into the block palette.
  final int color;

  late final List<int> rowMasks;

  int get size => cells.length;

  @override
  String toString() => 'Shape($id)';
}

/// A family groups the rotations of one shape so that a shape with many
/// rotations is not drawn more often than one with a single orientation.
class ShapeFamily {
  ShapeFamily(this.name, this.tier, this.color, List<List<String>> variants)
    : variants = [
        for (var i = 0; i < variants.length; i++)
          Shape('$name$i', variants[i], tier: tier, color: color),
      ];

  final String name;
  final int tier;
  final int color;
  final List<Shape> variants;
}

final List<ShapeFamily> shapeFamilies = [
  // Easy
  ShapeFamily('dot', 0, 0, [
    ['X'],
  ]),
  ShapeFamily('i2', 0, 1, [
    ['XX'],
    ['X', 'X'],
  ]),
  ShapeFamily('i3', 0, 2, [
    ['XXX'],
    ['X', 'X', 'X'],
  ]),
  ShapeFamily('o2', 0, 3, [
    ['XX', 'XX'],
  ]),
  ShapeFamily('v3', 0, 4, [
    ['XX', 'X.'],
    ['XX', '.X'],
    ['X.', 'XX'],
    ['.X', 'XX'],
  ]),
  // Medium
  ShapeFamily('i4', 1, 5, [
    ['XXXX'],
    ['X', 'X', 'X', 'X'],
  ]),
  ShapeFamily('l4', 1, 6, [
    ['X.', 'X.', 'XX'],
    ['.X', '.X', 'XX'],
    ['XX', 'X.', 'X.'],
    ['XX', '.X', '.X'],
    ['XXX', 'X..'],
    ['XXX', '..X'],
    ['X..', 'XXX'],
    ['..X', 'XXX'],
  ]),
  ShapeFamily('t4', 1, 1, [
    ['XXX', '.X.'],
    ['.X.', 'XXX'],
    ['X.', 'XX', 'X.'],
    ['.X', 'XX', '.X'],
  ]),
  ShapeFamily('s4', 1, 4, [
    ['.XX', 'XX.'],
    ['XX.', '.XX'],
    ['X.', 'XX', '.X'],
    ['.X', 'XX', 'X.'],
  ]),
  ShapeFamily('r6', 1, 2, [
    ['XXX', 'XXX'],
    ['XX', 'XX', 'XX'],
  ]),
  // Hard
  ShapeFamily('i5', 2, 0, [
    ['XXXXX'],
    ['X', 'X', 'X', 'X', 'X'],
  ]),
  ShapeFamily('o3', 2, 3, [
    ['XXX', 'XXX', 'XXX'],
  ]),
  ShapeFamily('l5', 2, 5, [
    ['X..', 'X..', 'XXX'],
    ['..X', '..X', 'XXX'],
    ['XXX', 'X..', 'X..'],
    ['XXX', '..X', '..X'],
  ]),
];

final List<Shape> allShapes = [for (final f in shapeFamilies) ...f.variants];
