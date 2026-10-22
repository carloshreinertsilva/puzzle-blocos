import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/board.dart';
import '../ui/palette.dart';
import 'puzzle_game.dart';

/// Where the dragged piece would land, and which lines it would complete.
class PlacementPreview {
  PlacementPreview(this.piece, this.row, this.col, this.rows, this.cols);
  final Piece piece;
  final int row;
  final int col;
  final List<int> rows;
  final List<int> cols;

  bool inLine(int r, int c) => rows.contains(r) || cols.contains(c);
}

/// Draws the board panel, the settled blocks and the drop preview.
class BoardView extends Component with HasGameReference<PuzzleGame> {
  PlacementPreview? preview;
  final Map<int, double> _pops = {};
  double _clock = 0;

  static const popTime = 0.18;

  void pop(Iterable<(int, int)> cells) {
    for (final (r, c) in cells) {
      _pops[r * Board.size + c] = popTime;
    }
  }

  @override
  void update(double dt) {
    _clock += dt;
    _pops.updateAll((_, v) => v - dt);
    _pops.removeWhere((_, v) => v <= 0);
  }

  @override
  void render(Canvas canvas) {
    final sprites = game.sprites;
    if (sprites == null) return;
    final board = game.controller.session.board;
    final rect = game.boardRect;
    final cell = game.cellSize;

    // Panel
    final panel = RRect.fromRectAndRadius(
      rect.inflate(cell * 0.18),
      Radius.circular(cell * 0.35),
    );
    canvas.drawRRect(
      panel.shift(Offset(0, cell * 0.08)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawRRect(panel, Paint()..color = Palette.panel);
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Palette.panelEdge,
    );

    final p = preview;
    final glow = 0.55 + 0.25 * sin(_clock * 10);

    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        final dst = game.cellRect(r, c);
        sprites.draw(canvas, sprites.empty, dst);
        final value = board.at(r, c);
        if (value.isEmpty) continue;

        final popLeft = _pops[r * Board.size + c];
        var drawRect = dst;
        if (popLeft != null) {
          final t = 1 - popLeft / popTime;
          final s = 1 + 0.14 * sin(t * pi);
          drawRect = Rect.fromCenter(
            center: dst.center,
            width: dst.width * s,
            height: dst.height * s,
          );
        }
        if (p != null && p.inLine(r, c) && value.type == CellType.block) {
          // Blocks about to clear take the dragged piece's color.
          sprites.draw(canvas, sprites.blocks[p.piece.color], drawRect);
          if (value.gem) sprites.draw(canvas, sprites.gem, drawRect);
          if (value.pup) sprites.draw(canvas, sprites.pup, drawRect);
        } else {
          sprites.drawCell(canvas, value, drawRect);
        }
        if (p != null && p.inLine(r, c)) _glow(canvas, dst, glow);
      }
    }

    if (p != null) {
      final s = p.piece.shape;
      for (var i = 0; i < s.cells.length; i++) {
        final (dr, dc) = s.cells[i];
        final dst = game.cellRect(p.row + dr, p.col + dc);
        sprites.draw(canvas, sprites.blocks[p.piece.color], dst, opacity: 0.45);
        if (p.rows.isNotEmpty || p.cols.isNotEmpty) _glow(canvas, dst, glow);
      }
    }
  }

  void _glow(Canvas canvas, Rect dst, double strength) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        dst.deflate(dst.width * 0.04),
        Radius.circular(dst.width * 0.17),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28 * strength),
    );
  }
}
