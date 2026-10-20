import 'board.dart';

/// A good move to suggest: the most lines cleared, then the snuggest fit
/// (cells touching blocks or walls), then the biggest piece. Returns
/// (tray slot, row, col), or null when nothing fits.
(int, int, int)? suggestMove(Board board, List<Piece?> tray) {
  (int, int, int)? best;
  var bestScore = -1;
  for (var slot = 0; slot < tray.length; slot++) {
    final shape = tray[slot]?.shape;
    if (shape == null) continue;
    for (var r = 0; r + shape.rows <= Board.size; r++) {
      for (var c = 0; c + shape.cols <= Board.size; c++) {
        if (!board.canPlace(shape, r, c)) continue;
        final (rows, cols) = board.linesCompletedBy(shape, r, c);
        var touching = 0;
        for (final (dr, dc) in shape.cells) {
          for (final (nr, nc) in [
            (r + dr - 1, c + dc),
            (r + dr + 1, c + dc),
            (r + dr, c + dc - 1),
            (r + dr, c + dc + 1),
          ]) {
            final outside =
                nr < 0 || nc < 0 || nr >= Board.size || nc >= Board.size;
            if (outside || board.at(nr, nc).isFilled) touching++;
          }
        }
        final score =
            (rows.length + cols.length) * 1000 +
            touching * 10 +
            shape.cells.length;
        if (score > bestScore) {
          bestScore = score;
          best = (slot, r, c);
        }
      }
    }
  }
  return best;
}
