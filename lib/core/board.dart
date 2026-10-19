import 'shapes.dart';

enum CellType { empty, block, rock }

/// One square of the board. Values are immutable; the board swaps them.
class Cell {
  const Cell.empty() : type = CellType.empty, color = 0, hp = 0, gem = false;
  const Cell.block(this.color, {this.gem = false})
    : type = CellType.block,
      hp = 0;
  const Cell.rock(this.hp) : type = CellType.rock, color = 0, gem = false;

  final CellType type;
  final int color;

  /// Line clears a rock still needs before it breaks.
  final int hp;
  final bool gem;

  bool get isEmpty => type == CellType.empty;
  bool get isFilled => type != CellType.empty;
}

/// A piece offered in the tray: a shape, its color and an optional gem.
class Piece {
  Piece(this.shape, {int? color, this.gemCell = -1})
    : color = color ?? shape.color;

  final Shape shape;
  final int color;

  /// Index into [Shape.cells] carrying a gem, or -1.
  final int gemCell;
}

class ClearedCell {
  const ClearedCell(this.row, this.col, this.before, this.after);
  final int row;
  final int col;
  final Cell before;
  final Cell after;
}

class PlaceOutcome {
  PlaceOutcome({
    required this.placed,
    required this.rows,
    required this.cols,
    required this.cleared,
    required this.gems,
    required this.rocksBroken,
  });

  final List<(int, int)> placed;
  final List<int> rows;
  final List<int> cols;
  final List<ClearedCell> cleared;
  final int gems;
  final int rocksBroken;

  int get lines => rows.length + cols.length;
}

class Board {
  Board() : _cells = List.filled(size * size, const Cell.empty());

  Board.copy(Board other) : _cells = List.of(other._cells);

  static const size = 8;
  static const fullRow = (1 << size) - 1;

  final List<Cell> _cells;

  Cell at(int r, int c) => _cells[r * size + c];
  void set(int r, int c, Cell cell) => _cells[r * size + c] = cell;

  int get filledCount => _cells.where((c) => c.isFilled).length;
  bool get isEmpty => _cells.every((c) => c.isEmpty);
  int get rockCount => _cells.where((c) => c.type == CellType.rock).length;

  /// Occupancy bitmask per row.
  List<int> get rowMasks => List.generate(size, (r) {
    var mask = 0;
    for (var c = 0; c < size; c++) {
      if (at(r, c).isFilled) mask |= 1 << c;
    }
    return mask;
  });

  /// Cells that survive one line clear (rocks with more than one hp left).
  List<int> get stickyMasks => List.generate(size, (r) {
    var mask = 0;
    for (var c = 0; c < size; c++) {
      final cell = at(r, c);
      if (cell.type == CellType.rock && cell.hp > 1) mask |= 1 << c;
    }
    return mask;
  });

  bool canPlace(Shape s, int r, int c) {
    if (r < 0 || c < 0 || r + s.rows > size || c + s.cols > size) return false;
    for (final (dr, dc) in s.cells) {
      if (at(r + dr, c + dc).isFilled) return false;
    }
    return true;
  }

  bool fitsAnywhere(Shape s) {
    for (var r = 0; r + s.rows <= size; r++) {
      for (var c = 0; c + s.cols <= size; c++) {
        if (canPlace(s, r, c)) return true;
      }
    }
    return false;
  }

  /// Rows and columns that would be complete if [s] were placed at (r, c).
  (List<int>, List<int>) linesCompletedBy(Shape s, int r, int c) {
    final masks = rowMasks;
    for (var i = 0; i < s.rows; i++) {
      masks[r + i] |= s.rowMasks[i] << c;
    }
    return _fullLines(masks);
  }

  static (List<int>, List<int>) _fullLines(List<int> masks) {
    final rows = [
      for (var r = 0; r < size; r++)
        if (masks[r] == fullRow) r,
    ];
    final colMask = masks.fold(fullRow, (a, b) => a & b);
    final cols = [
      for (var c = 0; c < size; c++)
        if (colMask & (1 << c) != 0) c,
    ];
    return (rows, cols);
  }

  /// Places [piece] at (r, c) and clears completed lines.
  /// The caller must check [canPlace] first.
  PlaceOutcome place(Piece piece, int r, int c) {
    final s = piece.shape;
    final placed = <(int, int)>[];
    for (var i = 0; i < s.cells.length; i++) {
      final (dr, dc) = s.cells[i];
      set(r + dr, c + dc, Cell.block(piece.color, gem: i == piece.gemCell));
      placed.add((r + dr, c + dc));
    }

    final (rows, cols) = _fullLines(rowMasks);
    final hit = <int>{
      for (final row in rows)
        for (var col = 0; col < size; col++) row * size + col,
      for (final col in cols)
        for (var row = 0; row < size; row++) row * size + col,
    };

    final cleared = <ClearedCell>[];
    var gems = 0;
    var rocksBroken = 0;
    for (final index in hit) {
      final before = _cells[index];
      Cell after;
      if (before.type == CellType.rock && before.hp > 1) {
        after = Cell.rock(before.hp - 1);
      } else {
        after = const Cell.empty();
        if (before.gem) gems++;
        if (before.type == CellType.rock) rocksBroken++;
      }
      _cells[index] = after;
      cleared.add(ClearedCell(index ~/ size, index % size, before, after));
    }

    return PlaceOutcome(
      placed: placed,
      rows: rows,
      cols: cols,
      cleared: cleared,
      gems: gems,
      rocksBroken: rocksBroken,
    );
  }
}
