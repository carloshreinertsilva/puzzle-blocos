import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/board.dart';
import 'palette.dart';
import 'pup.dart';

/// Paints blocks, rocks and gems. Used directly by Flutter widgets and, via
/// [BlockSprites], pre-rendered for the game scene.
abstract final class BlockPainter {
  static void block(Canvas canvas, Rect rect, Color color) {
    final s = rect.width;
    final outer = rect.deflate(s * 0.04);
    final radius = Radius.circular(s * 0.17);

    // Darker "lip" under the face gives the block depth.
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, radius),
      Paint()..color = Palette.darken(color, 0.35),
    );
    final face = Rect.fromLTRB(
      outer.left,
      outer.top,
      outer.right,
      outer.bottom - s * 0.08,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, radius),
      Paint()
        ..shader = ui.Gradient.linear(
          face.topCenter,
          face.bottomCenter,
          [Palette.lighten(color, 0.22), color, Palette.darken(color, 0.06)],
          [0, 0.55, 1],
        ),
    );
    // Glossy highlight on the top third.
    final gloss = Rect.fromLTWH(
      face.left + s * 0.12,
      face.top + s * 0.07,
      face.width - s * 0.24,
      face.height * 0.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(gloss, Radius.circular(s * 0.1)),
      Paint()
        ..shader = ui.Gradient.linear(gloss.topCenter, gloss.bottomCenter, [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.05),
        ]),
    );
  }

  static void rock(Canvas canvas, Rect rect, int hp) {
    final s = rect.width;
    final base = hp > 1 ? Palette.rockTough : Palette.rock;
    block(canvas, rect, base);
    final face = rect.deflate(s * 0.04);
    if (hp > 1) {
      // Rivets on reinforced rock.
      final rivet = Paint()..color = Palette.lighten(base, 0.45);
      for (final (dx, dy) in [
        (0.26, 0.26),
        (0.74, 0.26),
        (0.26, 0.66),
        (0.74, 0.66),
      ]) {
        canvas.drawCircle(
          Offset(rect.left + s * dx, rect.top + s * dy),
          s * 0.06,
          rivet,
        );
      }
    } else {
      final crack = Paint()
        ..color = Palette.darken(base, 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, s * 0.045)
        ..strokeCap = StrokeCap.round;
      final p = Path()
        ..moveTo(face.left + s * 0.3, face.top + s * 0.18)
        ..lineTo(face.left + s * 0.45, face.top + s * 0.42)
        ..lineTo(face.left + s * 0.36, face.top + s * 0.58)
        ..moveTo(face.left + s * 0.45, face.top + s * 0.42)
        ..lineTo(face.left + s * 0.66, face.top + s * 0.5);
      canvas.drawPath(p, crack);
    }
  }

  static void gem(Canvas canvas, Rect rect) {
    final s = rect.width;
    final c = rect.center.translate(0, -s * 0.04);
    final w = s * 0.26, h = s * 0.3;
    final top = Path()
      ..moveTo(c.dx - w, c.dy - h * 0.25)
      ..lineTo(c.dx - w * 0.5, c.dy - h * 0.7)
      ..lineTo(c.dx + w * 0.5, c.dy - h * 0.7)
      ..lineTo(c.dx + w, c.dy - h * 0.25)
      ..close();
    final bottom = Path()
      ..moveTo(c.dx - w, c.dy - h * 0.25)
      ..lineTo(c.dx + w, c.dy - h * 0.25)
      ..lineTo(c.dx, c.dy + h * 0.8)
      ..close();
    canvas.drawPath(bottom, Paint()..color = const Color(0xFF3FC8E8));
    canvas.drawPath(top, Paint()..color = Palette.gem);
    canvas.drawPath(
      Path()
        ..addPath(top, Offset.zero)
        ..addPath(bottom, Offset.zero),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, s * 0.03),
    );
  }

  static void emptyCell(Canvas canvas, Rect rect) {
    final s = rect.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(s * 0.05),
        Radius.circular(s * 0.14),
      ),
      Paint()..color = Palette.emptyCell,
    );
  }

  static void cell(Canvas canvas, Rect rect, Cell cell) {
    switch (cell.type) {
      case CellType.empty:
        return;
      case CellType.rock:
        rock(canvas, rect, cell.hp);
      case CellType.block:
        block(canvas, rect, Palette.blocks[cell.color]);
        if (cell.gem) gem(canvas, rect);
        if (cell.pup) PupPainter.trapped(canvas, rect);
    }
  }
}

/// One pre-rendered block kind: a bitmap when the engine can rasterize
/// offscreen, otherwise the recorded picture (replayed on each draw).
class BlockArt {
  BlockArt._(this._image, this._picture, this._cellSize);

  factory BlockArt.render(
    double cellSize,
    double pixelRatio,
    void Function(Canvas, Rect) paint,
  ) {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), Rect.fromLTWH(0, 0, cellSize, cellSize));
    final picture = recorder.endRecording();
    final px = (cellSize * pixelRatio).ceil();
    try {
      final scaled = ui.PictureRecorder();
      Canvas(scaled)
        ..scale(px / cellSize)
        ..drawPicture(picture);
      final image = scaled.endRecording().toImageSync(px, px);
      picture.dispose();
      return BlockArt._(image, null, cellSize);
    } catch (_) {
      return BlockArt._(null, picture, cellSize);
    }
  }

  final ui.Image? _image;
  final ui.Picture? _picture;
  final double _cellSize;

  void draw(Canvas canvas, Rect dst, {double opacity = 1}) {
    final image = _image;
    if (image != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final paint = Paint()..filterQuality = FilterQuality.medium;
      if (opacity < 1) paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawImageRect(image, src, dst, paint);
      return;
    }
    canvas.save();
    if (opacity < 1) {
      canvas.saveLayer(
        dst,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
    canvas.translate(dst.left, dst.top);
    canvas.scale(dst.width / _cellSize);
    canvas.drawPicture(_picture!);
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  void dispose() {
    _image?.dispose();
    _picture?.dispose();
  }
}

/// Pre-rendered art for each block kind at the current cell size, so the
/// game does not rebuild gradients for every cell on every frame.
class BlockSprites {
  BlockSprites(this.cellSize, this.pixelRatio) {
    blocks = [
      for (final c in Palette.blocks)
        _render((cv, r) => BlockPainter.block(cv, r, c)),
    ];
    rock1 = _render((cv, r) => BlockPainter.rock(cv, r, 1));
    rock2 = _render((cv, r) => BlockPainter.rock(cv, r, 2));
    gem = _render(BlockPainter.gem);
    pup = _render(PupPainter.trapped);
    empty = _render(BlockPainter.emptyCell);
  }

  final double cellSize;
  final double pixelRatio;
  late final List<BlockArt> blocks;
  late final BlockArt rock1;
  late final BlockArt rock2;
  late final BlockArt gem;
  late final BlockArt pup;
  late final BlockArt empty;

  BlockArt _render(void Function(Canvas, Rect) paint) =>
      BlockArt.render(cellSize, pixelRatio, paint);

  BlockArt forCell(Cell cell) => switch (cell.type) {
    CellType.rock => cell.hp > 1 ? rock2 : rock1,
    _ => blocks[cell.color],
  };

  void draw(Canvas canvas, BlockArt art, Rect dst, {double opacity = 1}) =>
      art.draw(canvas, dst, opacity: opacity);

  void drawCell(Canvas canvas, Cell cell, Rect dst, {double opacity = 1}) {
    if (cell.isEmpty) return;
    forCell(cell).draw(canvas, dst, opacity: opacity);
    if (cell.gem) gem.draw(canvas, dst, opacity: opacity);
    if (cell.pup) pup.draw(canvas, dst, opacity: opacity);
  }

  void dispose() {
    for (final a in [...blocks, rock1, rock2, gem, pup, empty]) {
      a.dispose();
    }
  }
}
