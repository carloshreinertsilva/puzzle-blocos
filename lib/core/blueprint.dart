import 'dart:math';

import 'board.dart';
import 'level.dart';
import 'shapes.dart';

/// A construction puzzle ("obra"): fill a drawing exactly with a given set
/// of pieces. Nothing clears; each piece goes in once, anywhere it fits
/// inside the drawing. Every blueprint is built by cutting the drawing into
/// pieces, so it always has at least one solution.
class Blueprint {
  Blueprint({
    required this.id,
    required this.name,
    required this.cells,
    required this.pieces,
    required this.colors,
    required this.solution,
  });

  /// 'casinha', 'obra7'...
  final String id;
  final String name;

  /// The drawing: cells to fill, as row * 8 + col.
  final Set<int> cells;
  final List<Shape> pieces;

  /// Color of each piece (palette index).
  final List<int> colors;

  /// Where each piece goes in the solution it was cut from (top-left).
  final List<(int, int)> solution;
}

/// Star rating: 3 without undoing or hints, 2 with a little help, else 1.
int blueprintStars({required int undos, required int hints}) {
  final help = undos + hints * 2;
  return help == 0
      ? 3
      : help <= 3
      ? 2
      : 1;
}

abstract final class Blueprints {
  /// Drawings for the village items, in build order (see Village.items).
  static const village = <String, List<String>>{
    'flores': [
      '........',
      '........',
      '..#..#..',
      '.######.',
      '.######.',
      '........',
      '........',
      '........',
    ],
    'cerca': [
      '........',
      '........',
      '#..#..#.',
      '########',
      '########',
      '#..#..#.',
      '........',
      '........',
    ],
    'banco': [
      '........',
      '.######.',
      '.######.',
      '.######.',
      '.#....#.',
      '.#....#.',
      '........',
      '........',
    ],
    'arvore': [
      '..####..',
      '.######.',
      '.######.',
      '..####..',
      '...##...',
      '...##...',
      '..####..',
      '........',
    ],
    'barco': [
      '....#...',
      '....##..',
      '....###.',
      '....####',
      '########',
      '.######.',
      '..####..',
      '........',
    ],
    'horta': [
      '........',
      '#.#.#.#.',
      '########',
      '########',
      '.######.',
      '.######.',
      '........',
      '........',
    ],
    'poste': [
      '..####..',
      '..####..',
      '...##...',
      '...##...',
      '...##...',
      '...##...',
      '..####..',
      '.######.',
    ],
    'pier': [
      '........',
      '........',
      '########',
      '########',
      '.#..#..#',
      '.#..#..#',
      '.#..#..#',
      '........',
    ],
    'casinha': [
      '...##...',
      '..####..',
      '.######.',
      '########',
      '.######.',
      '.######.',
      '.######.',
      '........',
    ],
    'balanco': [
      '########',
      '.#....#.',
      '.#....#.',
      '.#.##.#.',
      '.#.##.#.',
      '##....##',
      '........',
      '........',
    ],
    'fonte': [
      '...##...',
      '..####..',
      '...##...',
      '...##...',
      '########',
      '.######.',
      '..####..',
      '........',
    ],
    'roda': [
      '..####..',
      '.##..##.',
      '##.##.##',
      '##.##.##',
      '.##..##.',
      '..####..',
      '..#..#..',
      '.######.',
    ],
  };

  /// The Obras mode's drawings, roughly from small to big.
  static const library = <(String, List<String>)>[
    (
      'Coração',
      [
        '........',
        '.##..##.',
        '########',
        '########',
        '.######.',
        '..####..',
        '...##...',
        '........',
      ],
    ),
    (
      'Peixe',
      [
        '........',
        '...###..',
        '#.#####.',
        '########',
        '#.#####.',
        '...###..',
        '........',
        '........',
      ],
    ),
    (
      'Cogumelo',
      [
        '..####..',
        '.######.',
        '########',
        '########',
        '..####..',
        '..####..',
        '........',
        '........',
      ],
    ),
    (
      'Estrela',
      [
        '...##...',
        '...##...',
        '########',
        '.######.',
        '..####..',
        '.##..##.',
        '##....##',
        '........',
      ],
    ),
    (
      'Xícara',
      [
        '........',
        '#######.',
        '########',
        '#######.',
        '######..',
        '.####...',
        '########',
        '........',
      ],
    ),
    (
      'Foguete',
      [
        '...##...',
        '..####..',
        '..####..',
        '..####..',
        '.######.',
        '##.##.##',
        '#..##..#',
        '...##...',
      ],
    ),
    (
      'Gato',
      [
        '#.....#.',
        '##...##.',
        '#######.',
        '#######.',
        '.#####..',
        '.######.',
        '.#######',
        '........',
      ],
    ),
    (
      'Coroa',
      [
        '#..##..#',
        '##.##.##',
        '########',
        '########',
        '########',
        '.######.',
        '........',
        '........',
      ],
    ),
    (
      'Guarda-chuva',
      [
        '...##...',
        '.######.',
        '########',
        '########',
        '...##...',
        '...##...',
        '.#.##...',
        '.####...',
      ],
    ),
    (
      'Capivara',
      [
        '.#..#...',
        '######..',
        '#######.',
        '########',
        '.#######',
        '.#######',
        '.##..##.',
        '.##..##.',
      ],
    ),
    (
      'Castelo',
      [
        '#.#..#.#',
        '###..###',
        '########',
        '########',
        '###..###',
        '###..###',
        '########',
        '........',
      ],
    ),
    (
      'Âncora',
      [
        '...##...',
        '..####..',
        '...##...',
        '########',
        '...##...',
        '#..##..#',
        '##.##.##',
        '.######.',
      ],
    ),
  ];

  /// The drawing for a village item.
  static Blueprint forItem(String id, String name, int index) => _make(
    id: id,
    name: name,
    art: village[id]!,
    seed: index * 101 + 7,
    // The first builds use friendly pieces; later ones get trickier.
    hardness: (index / 11).clamp(0.0, 1.0),
  );

  /// Obra [n] of the Obras mode (from 1). Drawings repeat in later rounds,
  /// mirrored and cut into harder pieces.
  static Blueprint level(int n) {
    final i = (n - 1) % library.length;
    final round = (n - 1) ~/ library.length;
    final (name, art) = library[i];
    return _make(
      id: 'obra$n',
      name: name,
      art: round.isOdd ? [for (final row in art) _reverse(row)] : art,
      seed: n * 7919 + 13,
      hardness: (0.15 + i * 0.05 + round * 0.3).clamp(0.0, 1.0),
    );
  }

  static String _reverse(String s) =>
      String.fromCharCodes(s.codeUnits.reversed);

  static Blueprint _make({
    required String id,
    required String name,
    required List<String> art,
    required int seed,
    required double hardness,
  }) {
    final cells = <int>{
      for (var r = 0; r < Board.size; r++)
        for (var c = 0; c < Board.size; c++)
          if (art[r][c] == '#') r * Board.size + c,
    };
    final rng = Random(seed);
    for (var attempt = 0; ; attempt++) {
      // Give up on fussiness after a few tries: small pieces always fit.
      final tiling = _tile(cells, rng, hardness, allowTiny: attempt > 6);
      if (tiling == null) continue;
      tiling.shuffle(rng);
      final offset = rng.nextInt(blockColorCount);
      return Blueprint(
        id: id,
        name: name,
        cells: cells,
        pieces: [for (final t in tiling) t.$1],
        colors: [
          for (var i = 0; i < tiling.length; i++)
            (offset + i * 3) % blockColorCount,
        ],
        solution: [for (final t in tiling) (t.$2, t.$3)],
      );
    }
  }

  /// Cuts [cells] into pieces from the shape catalog. Harder blueprints
  /// prefer bigger, more awkward pieces.
  static List<(Shape, int, int)>? _tile(
    Set<int> cells,
    Random rng,
    double hardness, {
    required bool allowTiny,
  }) {
    final pool = [
      for (final s in allShapes)
        if (allowTiny || s.size >= 3) s,
    ];
    var budget = 4000;
    final out = <(Shape, int, int)>[];
    final todo = {...cells};

    double cost(Shape s) {
      // Lower is tried first.
      final small = s.size <= 2
          ? 2.0
          : s.size == 3
          ? 0.6 - hardness * 0.3
          : 0.0;
      final big = s.tier == 2 ? 0.6 - hardness * 0.9 : 0.0;
      final blocky = s.id.startsWith('r6') || s.id.startsWith('o3') ? 0.4 : 0.0;
      return rng.nextDouble() + small + big + blocky;
    }

    bool search() {
      if (todo.isEmpty) return true;
      if (--budget < 0) return false;
      final first = todo.reduce(min);
      final r = first ~/ Board.size, c = first % Board.size;
      final order = [for (final s in pool) (s, cost(s))]
        ..sort((a, b) => a.$2.compareTo(b.$2));
      for (final (s, _) in order) {
        final (dr, dc) = s.cells.first;
        final top = r - dr, left = c - dc;
        final covered = [
          for (final (cr, cc) in s.cells) (top + cr) * Board.size + left + cc,
        ];
        if (top < 0 || left < 0 || left + s.cols > Board.size) continue;
        if (!covered.every(todo.contains)) continue;
        todo.removeAll(covered);
        out.add((s, top, left));
        if (search()) return true;
        out.removeLast();
        todo.addAll(covered);
      }
      return false;
    }

    return search() ? out : null;
  }

  /// One move toward a solution from here: which unplaced piece goes
  /// where, or null when the pieces already placed make it impossible.
  /// [filled] are the drawing cells already covered.
  static (int, int, int)? hint(
    Blueprint bp,
    Set<int> filled,
    List<int> unplaced,
  ) {
    final todo = bp.cells.difference(filled);
    final left = [...unplaced];
    var budget = 20000;
    (int, int, int)? firstMove;

    bool search() {
      if (todo.isEmpty) return true;
      if (--budget < 0) return false;
      final first = todo.reduce(min);
      final r = first ~/ Board.size, c = first % Board.size;
      final tried = <String>{};
      for (var k = 0; k < left.length; k++) {
        final i = left[k];
        final s = bp.pieces[i];
        if (!tried.add(s.id)) continue;
        final (dr, dc) = s.cells.first;
        final top = r - dr, lft = c - dc;
        if (top < 0 || lft < 0 || lft + s.cols > Board.size) continue;
        final covered = [
          for (final (cr, cc) in s.cells) (top + cr) * Board.size + lft + cc,
        ];
        if (!covered.every(todo.contains)) continue;
        todo.removeAll(covered);
        left.removeAt(k);
        final isFirst = firstMove == null;
        if (isFirst) firstMove = (i, top, lft);
        if (search()) return true;
        if (isFirst) firstMove = null;
        left.insert(k, i);
        todo.addAll(covered);
      }
      return false;
    }

    return search() ? firstMove : null;
  }
}
