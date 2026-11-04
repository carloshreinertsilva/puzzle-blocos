import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/board.dart';
import '../l10n/idioma.dart';
import '../ui/capi.dart';
import '../ui/typography.dart';
import 'effects.dart';
import 'puzzle_game.dart';

/// The idle hint: Capi hops out of the tray with the suggested piece over
/// his head, walks it to where it fits, drops it in (it stays as a pulsing
/// ghost), cheers and says so. Then again, until the player moves.
class CapiCarrier extends Component with HasGameReference<PuzzleGame> {
  double _t = 0;
  (int, int, int)? _shown;
  TextPainter? _bubble;
  String _bubbleText = '';

  static const _loop = 3.8;

  @override
  void update(double dt) {
    final hint = game.controller.tutorial ? null : game.controller.hint;
    if (hint != _shown) {
      _shown = hint;
      _t = 0;
    }
    if (hint != null) _t = (_t + dt) % _loop;
  }

  @override
  void render(Canvas canvas) {
    final hint = _shown;
    final sprites = game.sprites;
    if (hint == null || sprites == null || game.activeDrag != null) return;
    final (slot, row, col) = hint;
    final piece = game.controller.session.tray[slot];
    if (piece == null) return;

    final shape = piece.shape;
    final cell = game.cellSize;
    final capi = cell * 2.3;
    final p = _t / _loop;

    final target = Rect.fromLTWH(
      game.boardRect.left + col * cell,
      game.boardRect.top + row * cell,
      shape.cols * cell,
      shape.rows * cell,
    );
    final tray = game.trays[slot];
    final from = Offset(
      tray.position.x + tray.size.x / 2,
      min(tray.position.y + tray.size.y, game.size.y - 6),
    );
    // Capi stops just under the spot, piece held over his head.
    final to = Offset(
      target.center.dx.clamp(capi / 2, game.size.x - capi / 2),
      min(target.bottom + capi * 0.82, game.size.y - 6),
    );

    // The spot pulses the whole time, a little brighter once it's placed.
    final placed = p >= 0.68;
    final pulse = (placed ? 0.5 : 0.22) + 0.12 * sin(_t * 2 * pi * 1.4);
    if (p >= 0.6) {
      _drawPiece(canvas, piece, target.topLeft, cell, pulse);
    }

    // Where Capi is, how high he hops, which way he leans.
    var feet = to;
    var hop = 0.0;
    var tilt = 0.0;
    if (p < 0.5) {
      final q = p / 0.5;
      final eased = 0.5 - cos(q * pi) / 2;
      feet = Offset.lerp(from, to, eased)!;
      hop = sin(q * pi * 7).abs() * cell * 0.32;
      tilt = sin(q * pi * 7) * 0.07;
    } else if (placed) {
      hop = sin((p - 0.68) / 0.32 * pi * 3).abs() * cell * 0.22;
    }

    // Pop in at the start and out at the end of each round.
    final grow = p < 0.06
        ? easeOutBack(p / 0.06)
        : p > 0.93
        ? 1 - (p - 0.93) / 0.07
        : 1.0;
    if (grow <= 0) return;

    // The carried piece rides on his paws, then drops into the spot.
    if (!placed) {
      final carryCell = cell * 0.7;
      final carried = Offset(
        feet.dx - shape.cols * carryCell / 2,
        feet.dy - hop - capi * 0.97 - shape.rows * carryCell,
      );
      if (p < 0.6) {
        _drawPiece(canvas, piece, carried, carryCell * grow, 1);
      } else {
        final d = easeOutCubic((p - 0.6) / 0.08);
        final c = carryCell + (cell - carryCell) * d;
        final at = Offset.lerp(carried, target.topLeft, d)!;
        _drawPiece(canvas, piece, at, c, 1 - 0.5 * d);
      }
    }

    canvas.save();
    canvas.translate(feet.dx, feet.dy - hop);
    canvas.rotate(tilt);
    canvas.scale(grow);
    canvas.translate(-capi / 2, -capi);
    CapiPainter(
      mood: placed ? CapiMood.cheer : CapiMood.carry,
      t: (_t * 1.6) % 1,
    ).paint(canvas, Size.square(capi));
    canvas.restore();

    if (placed && grow > 0.5) {
      _drawBubble(canvas, Offset(feet.dx, feet.dy - capi - hop), cell);
    }
  }

  void _drawPiece(
    Canvas canvas,
    Piece piece,
    Offset topLeft,
    double cell,
    double opacity,
  ) {
    final sprites = game.sprites!;
    for (final (r, c) in piece.shape.cells) {
      sprites.draw(
        canvas,
        sprites.blocks[piece.color],
        Rect.fromLTWH(topLeft.dx + c * cell, topLeft.dy + r * cell, cell, cell),
        opacity: opacity,
      );
    }
  }

  void _drawBubble(Canvas canvas, Offset anchor, double cell) {
    final text = game.controller.capiSays.isEmpty
        ? tr('Aqui!')
        : game.controller.capiSays;
    if (_bubble == null || text != _bubbleText) {
      _bubbleText = text;
      _bubble = TextPainter(
        text: TextSpan(
          text: text,
          style: displayText(cell * 0.42, color: const Color(0xFF2A1458)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    final tp = _bubble!;
    final pad = cell * 0.22;
    final w = tp.width + pad * 2;
    final h = tp.height + pad * 1.4;
    final left = (anchor.dx - w / 2).clamp(4.0, game.size.x - w - 4);
    final top = anchor.dy - h - cell * 0.2;
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      Radius.circular(h / 2),
    );
    canvas.drawRRect(
      box.shift(Offset(0, cell * 0.06)),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawRRect(box, Paint()..color = const Color(0xFFFFFFFF));
    tp.paint(canvas, Offset(left + pad, top + pad * 0.7));
  }
}
