import 'dart:math';

import 'board.dart';
import 'shapes.dart';
import 'solver.dart';

/// Deals trays of three pieces.
///
/// Every tray it returns can be placed completely on the current board with
/// some order of moves (checked by [Solver]), so a loss is always caused by
/// earlier moves, never by an impossible deal. [difficulty] (0..1) shifts the
/// mix toward big, awkward shapes; [mercy] (0..1) shifts it back and offers
/// pieces that complete lines.
class PieceGenerator {
  PieceGenerator(this.rng, {Solver? solver}) : solver = solver ?? Solver();

  final Random rng;
  final Solver solver;

  static const traySize = 3;
  static const _attempts = 14;

  List<Piece> deal(
    Board board, {
    required double difficulty,
    double mercy = 0,
    double gemChance = 0,
  }) {
    final masks = board.rowMasks;
    final sticky = board.stickyMasks;
    final fill = board.filledCount / (Board.size * Board.size);

    // A crowded board eases the mix so the player can dig out.
    var d = difficulty - mercy * 0.5 - max(0.0, fill - 0.5) * 1.2;
    final helpChance = (mercy * 0.8 + max(0.0, fill - 0.45)).clamp(0.0, 0.9);

    for (var attempt = 0; attempt < _attempts; attempt++) {
      final shapes = List.generate(traySize, (_) => _pick(d.clamp(0.0, 1.0)));
      if (rng.nextDouble() < helpChance) {
        final helper = _lineHelper(masks);
        if (helper != null) shapes[rng.nextInt(traySize)] = helper;
      }
      if (solver.canPlaceAll(masks, sticky, shapes)) {
        return _withGems(shapes, gemChance);
      }
      d -= 0.08;
    }
    return _withGems(_fallback(board, masks, sticky), gemChance);
  }

  Shape _pick(double d) {
    final weights = [
      _lerp(1.0, 0.3, d),
      _lerp(0.55, 1.0, d),
      _lerp(0.08, 0.75, d),
    ];
    final tier = _weighted(weights);
    final families = shapeFamilies.where((f) => f.tier == tier).toList();
    final family = families[rng.nextInt(families.length)];
    return family.variants[rng.nextInt(family.variants.length)];
  }

  /// A shape that completes at least one line right now, if any does.
  Shape? _lineHelper(List<int> masks) {
    var best = 0;
    final candidates = <Shape>[];
    for (final s in allShapes) {
      final lines = Solver.bestLines(masks, s);
      if (lines <= 0) continue;
      if (lines > best) {
        best = lines;
        candidates.clear();
      }
      if (lines == best) candidates.add(s);
    }
    if (candidates.isEmpty) return null;
    return candidates[rng.nextInt(candidates.length)];
  }

  /// Small shapes that fit, smallest first; used when random deals fail.
  List<Shape> _fallback(Board board, List<int> masks, List<int> sticky) {
    final fitting = allShapes.where(board.fitsAnywhere).toList()
      ..sort((a, b) => a.size.compareTo(b.size));
    if (fitting.isEmpty) {
      return List.filled(traySize, shapeFamilies.first.variants.first);
    }
    final small = fitting.take(6).toList();
    for (var attempt = 0; attempt < 20; attempt++) {
      final shapes = List.generate(
        traySize,
        (_) => small[rng.nextInt(small.length)],
      );
      if (solver.canPlaceAll(masks, sticky, shapes)) return shapes;
    }
    return List.filled(traySize, fitting.first);
  }

  List<Piece> _withGems(List<Shape> shapes, double gemChance) => [
    for (final s in shapes)
      Piece(
        s,
        gemCell: rng.nextDouble() < gemChance
            ? rng.nextInt(s.cells.length)
            : -1,
      ),
  ];

  int _weighted(List<double> weights) {
    final total = weights.reduce((a, b) => a + b);
    var roll = rng.nextDouble() * total;
    for (var i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return i;
    }
    return weights.length - 1;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
