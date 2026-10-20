import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'effects.dart';
import 'puzzle_game.dart';

/// Tutorial hint: a ghost of the piece pulses where it should go while a
/// finger slides from the tray to that spot, over and over.
class HintHand extends Component with HasGameReference<PuzzleGame> {
  double _t = 0;

  static const _loop = 2.2;

  @override
  void update(double dt) => _t = (_t + dt) % _loop;

  @override
  void render(Canvas canvas) {
    final hint = game.controller.tutorialHint;
    final sprites = game.sprites;
    final piece = hint == null ? null : game.controller.session.tray[hint.$1];
    if (hint == null || piece == null || sprites == null) return;
    if (game.activeDrag != null) return;

    final (slot, row, col) = hint;
    final shape = piece.shape;
    final cell = game.cellSize;

    // Ghost at the target.
    final pulse = 0.25 + 0.15 * sin(_t / _loop * 2 * pi * 2);
    for (final (r, c) in shape.cells) {
      sprites.draw(
        canvas,
        sprites.blocks[piece.color],
        game.cellRect(row + r, col + c),
        opacity: pulse,
      );
    }

    // Finger: press on the tray, slide up, lift at the target.
    final t = _t / _loop;
    final tray = game.trays[slot];
    final from = Offset(
      tray.position.x + tray.size.x / 2,
      tray.position.y + tray.size.y / 2,
    );
    final to = Offset(
      game.boardRect.left + (col + shape.cols / 2) * cell,
      game.boardRect.top + (row + shape.rows / 2) * cell + cell * 0.6,
    );
    final move = ((t - 0.15) / 0.55).clamp(0.0, 1.0);
    final at = Offset.lerp(from, to, easeOutCubic(move))!;
    final fade = t < 0.08
        ? t / 0.08
        : t > 0.85
        ? (1 - (t - 0.85) / 0.15)
        : 1.0;
    final pressed = t > 0.1 && t < 0.75;
    final r = cell * (pressed ? 0.34 : 0.4);

    canvas.drawCircle(
      at + Offset(0, cell * 0.08),
      r,
      Paint()..color = Color.fromRGBO(0, 0, 0, 0.25 * fade),
    );
    canvas.drawCircle(
      at,
      r,
      Paint()..color = Color.fromRGBO(255, 255, 255, 0.92 * fade),
    );
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.06
        ..color = Color.fromRGBO(42, 20, 88, 0.8 * fade),
    );
    if (pressed) {
      canvas.drawCircle(
        at,
        r * 1.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.04
          ..color = Color.fromRGBO(255, 255, 255, 0.35 * fade),
      );
    }
  }
}
