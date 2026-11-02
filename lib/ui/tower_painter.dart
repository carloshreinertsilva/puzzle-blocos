import '../core/hats.dart';

import 'dart:math';

import 'package:flutter/material.dart';

import '../tower/tower_controller.dart';
import '../village/iso.dart';
import 'capi.dart';
import '../core/wardrobe.dart';

/// Rainbow/block color palette for the tower blocks.
const towerPalette = [
  Color(0xFF10B981), // Emerald
  Color(0xFF06B6D4), // Cyan
  Color(0xFF3B82F6), // Blue
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Purple
  Color(0xFFEC4899), // Pink
  Color(0xFFF43F5E), // Rose
  Color(0xFFF97316), // Orange
  Color(0xFFFBBF24), // Amber
];

/// Renders Capi's 2.5D stacking tower game.
class TowerWorldPainter extends CustomPainter {
  const TowerWorldPainter({required this.controller})
    : super(repaint: controller);

  final TowerController controller;

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient: gentle sky
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E2640), Color(0xFF151928)],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Dynamic isometric projection centered horizontally
    final tileWidth = min(size.width * 0.22, 90.0);
    // Origin shifts down with cameraZ
    final originY =
        size.height * 0.72 + (controller.cameraZ * tileWidth * 0.62);
    final iso = Iso(Offset(size.width / 2, originY), tileWidth);
    final c = IsoCanvas(canvas, iso);

    // Base ground shadow
    c.boxShadow(-2.0, -2.0, 4.0, 4.0, 0.5, 0.35);

    // 1. Render all placed blocks from bottom to top
    for (var i = 0; i < controller.blocks.length; i++) {
      final b = controller.blocks[i];
      final col = towerPalette[b.colorIndex % towerPalette.length];
      c.box(b.x, b.y, b.z, b.dx, b.dy, b.dz, col, outline: true);

      // Level number indicator on the side of every 5th floor
      if (i > 0 && i % 5 == 0) {
        final pt = iso.p(b.x + b.dx + 0.4, b.y + b.dy / 2, b.z + b.dz / 2);
        _drawFloorLabel(canvas, pt, '$i');
      }
    }

    // 2. Render falling slices
    for (final slice in controller.fallingSlices) {
      final col = towerPalette[slice.colorIndex % towerPalette.length];
      c.box(
        slice.x,
        slice.y,
        slice.z,
        slice.dx,
        slice.dy,
        slice.dz,
        col.withValues(alpha: 0.85),
        outline: true,
      );
    }

    // 3. Render moving active block (if game is still on)
    if (!controller.gameOver) {
      final activeCol = towerPalette[controller.height % towerPalette.length];
      final z = controller.height * TowerController.blockDz;

      c.box(
        controller.currentX,
        controller.currentY,
        z,
        controller.currentDx,
        controller.currentDy,
        TowerController.blockDz,
        activeCol,
        outline: true,
      );
    }

    // 4. Render Capi on top of the highest placed block!
    if (controller.blocks.isNotEmpty) {
      final topBlock = controller.blocks.last;
      final topPt = iso.p(
        topBlock.x + topBlock.dx / 2,
        topBlock.y + topBlock.dy / 2,
        topBlock.z + topBlock.dz,
      );
      _drawMiniCapi(canvas, topPt, controller.combo);
    }
  }

  void _drawFloorLabel(Canvas canvas, Offset pt, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFDE047),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pt - Offset(tp.width / 2, tp.height / 2));
  }

  /// The same Capi as everywhere else, small, standing on the top block.
  void _drawMiniCapi(Canvas canvas, Offset center, int combo) {
    const size = 38.0;
    canvas.save();
    canvas.translate(center.dx - size / 2, center.dy - 4 - size * 0.95);
    CapiPainter(
      mood: combo > 0 ? CapiMood.cheer : CapiMood.happy,
      t: 0,
      hat: CapiHat.fromId(controller.store.equippedHat),
      look: CapiLook.of(controller.store),
    ).paint(canvas, const Size.square(size));
    canvas.restore();

    // Sparkles on a combo of 2 or more.
    if (combo >= 2) {
      final starPaint = Paint()..color = const Color(0xFFFDE047);
      canvas.drawCircle(center + const Offset(-16, -34), 2.5, starPaint);
      canvas.drawCircle(center + const Offset(16, -38), 3.0, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TowerWorldPainter oldDelegate) => true;
}

/// Standalone vector Tower icon for menu cards and buttons.
class TowerIcon extends StatelessWidget {
  const TowerIcon({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _TowerIconPainter(),
    );
  }
}

class _TowerIconPainter extends CustomPainter {
  const _TowerIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;
    canvas.save();
    canvas.scale(s, s);

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(const Rect.fromLTWH(0, 0, 512, 512));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 16, 480, 480),
        const Radius.circular(110),
      ),
      bgPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF0C4A6E)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 16, 480, 480),
        const Radius.circular(110),
      ),
      borderPaint,
    );

    // Isometric Blocks
    // Block 1 (Bottom Emerald)
    _drawIsoBox(
      canvas,
      top: [
        const Offset(256, 310),
        const Offset(380, 350),
        const Offset(256, 390),
        const Offset(132, 350),
      ],
      left: [
        const Offset(132, 350),
        const Offset(256, 390),
        const Offset(256, 435),
        const Offset(132, 395),
      ],
      right: [
        const Offset(256, 390),
        const Offset(380, 350),
        const Offset(380, 395),
        const Offset(256, 435),
      ],
      topCol: const Color(0xFF34D399),
      leftCol: const Color(0xFF10B981),
      rightCol: const Color(0xFF059669),
    );

    // Block 2 (Middle Orange)
    _drawIsoBox(
      canvas,
      top: [
        const Offset(256, 225),
        const Offset(360, 260),
        const Offset(256, 295),
        const Offset(152, 260),
      ],
      left: [
        const Offset(152, 260),
        const Offset(256, 295),
        const Offset(256, 340),
        const Offset(152, 305),
      ],
      right: [
        const Offset(256, 295),
        const Offset(360, 260),
        const Offset(360, 305),
        const Offset(256, 340),
      ],
      topCol: const Color(0xFFFB923C),
      leftCol: const Color(0xFFF97316),
      rightCol: const Color(0xFFEA580C),
    );

    // Block 3 (Top Golden)
    _drawIsoBox(
      canvas,
      top: [
        const Offset(256, 145),
        const Offset(340, 175),
        const Offset(256, 205),
        const Offset(172, 175),
      ],
      left: [
        const Offset(172, 175),
        const Offset(256, 205),
        const Offset(256, 245),
        const Offset(172, 215),
      ],
      right: [
        const Offset(256, 205),
        const Offset(340, 175),
        const Offset(340, 215),
        const Offset(256, 245),
      ],
      topCol: const Color(0xFFFDE047),
      leftCol: const Color(0xFFFACC15),
      rightCol: const Color(0xFFEAB308),
    );

    // Helmet on top
    canvas.save();
    canvas.translate(256, 130);
    final hPaint = Paint()..color = const Color(0xFFFFD43B);
    final hBorder = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final hPath = Path()
      ..moveTo(-36, -8)
      ..quadraticBezierTo(0, -42, 36, -8)
      ..close();
    canvas.drawPath(hPath, hPaint);
    canvas.drawPath(hPath, hBorder);
    canvas.drawLine(
      const Offset(-42, -6),
      const Offset(42, -6),
      hBorder..strokeWidth = 8,
    );
    canvas.restore();

    canvas.restore();
  }

  void _drawIsoBox(
    Canvas canvas, {
    required List<Offset> top,
    required List<Offset> left,
    required List<Offset> right,
    required Color topCol,
    required Color leftCol,
    required Color rightCol,
  }) {
    final edgePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final topPath = Path()..addPolygon(top, true);
    final leftPath = Path()..addPolygon(left, true);
    final rightPath = Path()..addPolygon(right, true);

    canvas.drawPath(leftPath, Paint()..color = leftCol);
    canvas.drawPath(leftPath, edgePaint);

    canvas.drawPath(rightPath, Paint()..color = rightCol);
    canvas.drawPath(rightPath, edgePaint);

    canvas.drawPath(topPath, Paint()..color = topCol);
    canvas.drawPath(topPath, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
