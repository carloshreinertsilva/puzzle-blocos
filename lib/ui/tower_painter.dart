import '../core/hats.dart';

import 'dart:math';

import 'package:flutter/material.dart';

import '../tower/tower_controller.dart';
import '../village/iso.dart';

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

  void _drawMiniCapi(Canvas canvas, Offset center, int combo) {
    canvas.save();
    canvas.translate(center.dx, center.dy - 16);

    // Little body
    final bodyPaint = Paint()..color = const Color(0xFFA06030);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 22, height: 16),
      bodyPaint,
    );

    // Head
    canvas.drawCircle(const Offset(0, -4), 10, bodyPaint);

    // Snout
    final snoutPaint = Paint()..color = const Color(0xFFC4824D);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -2), width: 12, height: 8),
      snoutPaint,
    );

    // Hat according to equipped hat
    final hat = CapiHat.fromId(controller.store.equippedHat);
    switch (hat) {
      case CapiHat.helmet:
        final helmetPaint = Paint()..color = const Color(0xFFFFD43B);
        final rimPaint = Paint()
          ..color = const Color(0xFFFCC419)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        final helmetPath = Path()
          ..moveTo(-11, -8)
          ..quadraticBezierTo(0, -20, 11, -8)
          ..close();
        canvas.drawPath(helmetPath, helmetPaint);
        canvas.drawLine(const Offset(-13, -8), const Offset(13, -8), rimPaint);
      case CapiHat.crown:
        final crownPath = Path()
          ..moveTo(-10, -8)
          ..lineTo(-11, -17)
          ..lineTo(-5, -13)
          ..lineTo(0, -21)
          ..lineTo(5, -13)
          ..lineTo(11, -17)
          ..lineTo(10, -8)
          ..close();
        canvas.drawPath(crownPath, Paint()..color = const Color(0xFFFDE047));
        canvas.drawCircle(
          const Offset(0, -21),
          2.2,
          Paint()..color = const Color(0xFF38BDF8),
        );
      case CapiHat.party:
        final partyPath = Path()
          ..moveTo(-8, -8)
          ..lineTo(0, -22)
          ..lineTo(8, -8)
          ..close();
        canvas.drawPath(partyPath, Paint()..color = const Color(0xFFEC4899));
        canvas.drawCircle(
          const Offset(0, -23),
          2.5,
          Paint()..color = const Color(0xFFFDE047),
        );
      case CapiHat.chef:
        final chefPath = Path()
          ..moveTo(-9, -8)
          ..cubicTo(-13, -16, -6, -21, 0, -20)
          ..cubicTo(6, -21, 13, -16, 9, -8)
          ..close();
        canvas.drawPath(chefPath, Paint()..color = Colors.white);
      case CapiHat.pirate:
        final tricorn = Path()
          ..moveTo(-13, -7)
          ..quadraticBezierTo(0, -16, 13, -7)
          ..lineTo(10, -5)
          ..quadraticBezierTo(0, -11, -10, -5)
          ..close();
        canvas.drawPath(tricorn, Paint()..color = const Color(0xFF0F172A));
      case CapiHat.straw:
        final brim = Rect.fromCenter(
          center: const Offset(0, -7),
          width: 26,
          height: 4,
        );
        canvas.drawOval(brim, Paint()..color = const Color(0xFFFDE68A));
        final dome = Rect.fromCenter(
          center: const Offset(0, -11),
          width: 14,
          height: 8,
        );
        canvas.drawOval(dome, Paint()..color = const Color(0xFFD97706));
      case CapiHat.wizard:
        final cone = Path()
          ..moveTo(-9, -8)
          ..lineTo(6, -24)
          ..lineTo(9, -8)
          ..close();
        canvas.drawPath(cone, Paint()..color = const Color(0xFF6D28D9));
        canvas.drawCircle(
          const Offset(2, -18),
          1.5,
          Paint()..color = const Color(0xFFFDE047),
        );
      case CapiHat.vip:
        canvas.drawRect(
          const Rect.fromLTWH(-7, -21, 14, 13),
          Paint()..color = const Color(0xFF15172A),
        );
        canvas.drawRect(
          const Rect.fromLTWH(-7, -13, 14, 2.5),
          Paint()..color = const Color(0xFFFFC94D),
        );
        canvas.drawLine(
          const Offset(-12, -8),
          const Offset(12, -8),
          Paint()
            ..color = const Color(0xFF15172A)
            ..strokeWidth = 3,
        );
      case CapiHat.fundador:
        final dome = Path()
          ..moveTo(-11, -8)
          ..quadraticBezierTo(0, -20, 11, -8)
          ..close();
        canvas.drawPath(dome, Paint()..color = const Color(0xFFFFD84D));
        canvas.drawLine(
          const Offset(-13, -8),
          const Offset(13, -8),
          Paint()
            ..color = const Color(0xFFC98A00)
            ..strokeWidth = 3,
        );
        canvas.drawCircle(
          const Offset(0, -12),
          2,
          Paint()..color = Colors.white,
        );
    }

    // Cheering eyes if combo > 0
    final eyePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (combo > 0) {
      // Arcs
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(-4, -5), radius: 2.5),
        pi,
        pi,
        false,
        eyePaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(4, -5), radius: 2.5),
        pi,
        pi,
        false,
        eyePaint,
      );
    } else {
      // Dots
      final dotPaint = Paint()..color = const Color(0xFF1E293B);
      canvas.drawCircle(const Offset(-4, -5), 1.2, dotPaint);
      canvas.drawCircle(const Offset(4, -5), 1.2, dotPaint);
    }

    // Sparkles if combo >= 2
    if (combo >= 2) {
      final starPaint = Paint()..color = const Color(0xFFFDE047);
      canvas.drawCircle(const Offset(-14, -16), 2.5, starPaint);
      canvas.drawCircle(const Offset(14, -18), 3.0, starPaint);
    }

    canvas.restore();
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
