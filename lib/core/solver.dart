import 'board.dart';
import 'shapes.dart';

/// Answers "can these pieces still all be placed?" on occupancy bitmasks.
///
/// Rocks with hp > 1 are passed as [sticky]: they stay filled when their
/// line clears. The solver keeps them sticky afterwards too, which makes it
/// slightly pessimistic, never optimistic.
class Solver {
  Solver({this.budget = 6000});

  /// Maximum placements tried before giving up (treated as "not solvable").
  final int budget;
  int _spent = 0;

  bool canPlaceAll(List<int> masks, List<int> sticky, List<Shape> pieces) {
    _spent = 0;
    return _search(masks, sticky, pieces);
  }

  bool _search(List<int> masks, List<int> sticky, List<Shape> pieces) {
    if (pieces.isEmpty) return true;
    final tried = <String>{};
    for (var i = 0; i < pieces.length; i++) {
      final s = pieces[i];
      if (!tried.add(s.id)) continue;
      final rest = [...pieces]..removeAt(i);
      for (var r = 0; r + s.rows <= Board.size; r++) {
        for (var c = 0; c + s.cols <= Board.size; c++) {
          if (!fits(masks, s, r, c)) continue;
          if (++_spent > budget) return false;
          if (_search(apply(masks, sticky, s, r, c), sticky, rest)) return true;
        }
      }
    }
    return false;
  }

  static bool fits(List<int> masks, Shape s, int r, int c) {
    for (var i = 0; i < s.rows; i++) {
      if (masks[r + i] & (s.rowMasks[i] << c) != 0) return false;
    }
    return true;
  }

  /// Masks after placing [s] at (r, c) and clearing full lines.
  static List<int> apply(
    List<int> masks,
    List<int> sticky,
    Shape s,
    int r,
    int c,
  ) {
    final next = List.of(masks);
    for (var i = 0; i < s.rows; i++) {
      next[r + i] |= s.rowMasks[i] << c;
    }
    final colMask = next.fold(Board.fullRow, (a, b) => a & b);
    for (var row = 0; row < Board.size; row++) {
      final rowFull = next[row] == Board.fullRow;
      var keep = rowFull ? 0 : next[row] & ~colMask;
      if (rowFull || colMask != 0) keep |= next[row] & sticky[row];
      next[row] = keep;
    }
    return next;
  }

  /// Most lines [s] can complete in one placement, or -1 if it does not fit.
  static int bestLines(List<int> masks, Shape s) {
    var best = -1;
    for (var r = 0; r + s.rows <= Board.size; r++) {
      for (var c = 0; c + s.cols <= Board.size; c++) {
        if (!fits(masks, s, r, c)) continue;
        final next = List.of(masks);
        for (var i = 0; i < s.rows; i++) {
          next[r + i] |= s.rowMasks[i] << c;
        }
        var lines = next.where((m) => m == Board.fullRow).length;
        var colMask = next.fold(Board.fullRow, (a, b) => a & b);
        while (colMask != 0) {
          lines += colMask & 1;
          colMask >>= 1;
        }
        if (lines > best) best = lines;
      }
    }
    return best;
  }
}
