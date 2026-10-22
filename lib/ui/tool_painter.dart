import 'dart:math';

import 'package:flutter/material.dart';

import '../services/progress_store.dart';

/// Renders crisp vector tool icons matching the vectorcraft masters in `art/tools/`.
class ToolIcon extends StatelessWidget {
  const ToolIcon({super.key, required this.tool, this.size = 48});

  final CapiTool tool;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: switch (tool) {
        CapiTool.hammer => HammerPainter(),
        CapiTool.rotate => RotatePainter(),
        CapiTool.reroll => RerollPainter(),
        CapiTool.shovel => ShovelPainter(),
      },
    );
  }
}

class ToolboxIcon extends StatelessWidget {
  const ToolboxIcon({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: ToolboxPainter());
  }
}

// Common outline paint
const _outlineColor = Color(0xFF4A2A12);

Paint _strokePaint(double width) => Paint()
  ..color = _outlineColor
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Hammer: wooden handle, chunky gold head, steel face, sparkle.
class HammerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;
    canvas.save();
    canvas.scale(s, s);

    // Sparkle top right
    final star = Path()
      ..moveTo(420, 180)
      ..lineTo(432, 205)
      ..lineTo(457, 217)
      ..lineTo(432, 229)
      ..lineTo(420, 254)
      ..lineTo(408, 229)
      ..lineTo(383, 217)
      ..lineTo(408, 205)
      ..close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFFFD43B));
    canvas.drawPath(star, _strokePaint(6));

    // Handle
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE8B886), Color(0xFFC88E52), Color(0xFF9A622A)],
      ).createShader(const Rect.fromLTWH(95, 235, 140, 180))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      const Offset(235, 235),
      const Offset(95, 415),
      _strokePaint(44),
    );
    canvas.drawLine(const Offset(235, 235), const Offset(95, 415), handlePaint);

    // Grip lines
    canvas.drawLine(
      const Offset(165, 325),
      const Offset(145, 351),
      _strokePaint(8),
    );
    canvas.drawLine(
      const Offset(145, 351),
      const Offset(125, 377),
      _strokePaint(8),
    );
    canvas.drawLine(
      const Offset(125, 377),
      const Offset(105, 403),
      _strokePaint(8),
    );

    // Pommel cap
    canvas.drawCircle(
      const Offset(95, 415),
      22,
      Paint()..color = const Color(0xFFFFD95A),
    );
    canvas.drawCircle(const Offset(95, 415), 22, _strokePaint(8));
    canvas.drawCircle(
      const Offset(95, 415),
      10,
      Paint()..color = const Color(0xFFF5B21E),
    );

    // Head
    canvas.save();
    canvas.translate(260, 205);
    canvas.rotate(-38 * pi / 180);

    // Back claw
    final claw = Path()
      ..moveTo(-90, -35)
      ..cubicTo(-120, -20, -130, 10, -115, 35)
      ..lineTo(-80, 25)
      ..close();
    canvas.drawPath(claw, Paint()..color = const Color(0xFF9EB2C0));
    canvas.drawPath(claw, _strokePaint(10));

    // Main head block
    final headRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-85, -45, 170, 90),
      const Radius.circular(20),
    );
    final headGrad = const LinearGradient(
      colors: [Color(0xFFFFD95A), Color(0xFFF5B21E), Color(0xFFD48208)],
    ).createShader(headRect.outerRect);
    canvas.drawRRect(headRect, Paint()..shader = headGrad);
    canvas.drawRRect(headRect, _strokePaint(10));

    // Safety band
    final bandRect = const Rect.fromLTWH(-25, -45, 50, 90);
    canvas.drawRect(bandRect, Paint()..color = const Color(0xFFF08C00));
    canvas.drawRect(bandRect, _strokePaint(10));

    // Strike face
    final face = Path()
      ..moveTo(85, -40)
      ..lineTo(120, -35)
      ..cubicTo(130, -15, 130, 15, 120, 35)
      ..lineTo(85, 40)
      ..close();
    final faceGrad = const LinearGradient(
      colors: [Color(0xFFE0E8F0), Color(0xFF9EB2C0), Color(0xFF627888)],
    ).createShader(const Rect.fromLTWH(85, -40, 45, 80));
    canvas.drawPath(face, Paint()..shader = faceGrad);
    canvas.drawPath(face, _strokePaint(10));

    // Highlight
    final hl = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-70, -35, 140, 14),
      const Radius.circular(7),
    );
    canvas.drawRRect(hl, Paint()..color = const Color(0x99FFFFFF));

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rotate: circular twin arrows with central rotating piece.
class RotatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;
    canvas.save();
    canvas.scale(s, s);

    // Track
    final trackPaint = Paint()
      ..color = const Color(0x6622B8CF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(const Offset(256, 256), 195, trackPaint);

    // Top arrow arc
    final arrow1Paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      ).createShader(const Rect.fromLTWH(120, 120, 280, 280))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round;

    final arc1 = Path()
      ..arcTo(
        Rect.fromCircle(center: const Offset(256, 256), radius: 185),
        -pi * 0.9,
        pi * 0.8,
        false,
      );
    canvas.drawPath(arc1, _strokePaint(48));
    canvas.drawPath(arc1, arrow1Paint);

    // Arrowhead 1
    final head1 = Path()
      ..moveTo(370, 110)
      ..lineTo(440, 160)
      ..lineTo(370, 210)
      ..close();
    canvas.drawPath(head1, Paint()..color = const Color(0xFF00F2FE));
    canvas.drawPath(head1, _strokePaint(10));

    // Bottom arrow arc
    final arrow2Paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD95A), Color(0xFFF5B21E)],
      ).createShader(const Rect.fromLTWH(120, 120, 280, 280))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round;

    final arc2 = Path()
      ..arcTo(
        Rect.fromCircle(center: const Offset(256, 256), radius: 185),
        pi * 0.1,
        pi * 0.8,
        false,
      );
    canvas.drawPath(arc2, _strokePaint(48));
    canvas.drawPath(arc2, arrow2Paint);

    // Arrowhead 2
    final head2 = Path()
      ..moveTo(142, 402)
      ..lineTo(72, 352)
      ..lineTo(142, 302)
      ..close();
    canvas.drawPath(head2, Paint()..color = const Color(0xFFFFD95A));
    canvas.drawPath(head2, _strokePaint(10));

    // Center rotating block
    canvas.save();
    canvas.translate(256, 256);
    canvas.rotate(25 * pi / 180);

    final blockGrad = const LinearGradient(
      colors: [Color(0xFFFF9A44), Color(0xFFE8590C)],
    ).createShader(const Rect.fromLTWH(-65, -65, 130, 130));
    final blockFill = Paint()..shader = blockGrad;

    for (final offset in const [
      Offset(-65, -65),
      Offset(0, -65),
      Offset(0, 0),
      Offset(-65, 0),
    ]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(offset.dx, offset.dy, 65, 65),
        const Radius.circular(14),
      );
      canvas.drawRRect(r, blockFill);
      canvas.drawRRect(r, _strokePaint(8));
      final shine = RRect.fromRectAndRadius(
        Rect.fromLTWH(offset.dx + 7, offset.dy + 7, 51, 14),
        const Radius.circular(7),
      );
      canvas.drawRRect(shine, Paint()..color = const Color(0x99FFFFFF));
    }

    // Pivot button
    canvas.drawCircle(
      Offset.zero,
      22,
      Paint()..color = const Color(0xFFFFD95A),
    );
    canvas.drawCircle(Offset.zero, 22, _strokePaint(7));
    canvas.drawCircle(
      Offset.zero,
      10,
      Paint()..color = const Color(0xFFF5B21E),
    );

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Reroll: 3 blocks in orbit with cyclical arrows.
class RerollPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;
    canvas.save();
    canvas.scale(s, s);

    // Swap Arrows
    final arrowGrad = const LinearGradient(
      colors: [Color(0xFFFFD95A), Color(0xFFF59F00)],
    ).createShader(const Rect.fromLTWH(100, 100, 312, 312));
    final arrowPaint = Paint()
      ..shader = arrowGrad
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      const Offset(256, 256),
      155,
      Paint()
        ..color = const Color(0x33FFD95A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20,
    );

    final p1 = Path()
      ..arcTo(
        Rect.fromCircle(center: const Offset(256, 256), radius: 155),
        -pi * 0.4,
        pi * 0.55,
        false,
      );
    canvas.drawPath(p1, arrowPaint);

    final p2 = Path()
      ..arcTo(
        Rect.fromCircle(center: const Offset(256, 256), radius: 155),
        pi * 0.25,
        pi * 0.55,
        false,
      );
    canvas.drawPath(p2, arrowPaint);

    final p3 = Path()
      ..arcTo(
        Rect.fromCircle(center: const Offset(256, 256), radius: 155),
        pi * 0.9,
        pi * 0.55,
        false,
      );
    canvas.drawPath(p3, arrowPaint);

    // Block 1 (Top)
    _drawOrbitBlock(
      canvas,
      const Offset(256, 115),
      const Color(0xFFFF6B6B),
      const Color(0xFFC92A2A),
    );
    // Block 2 (Bottom-Right)
    _drawOrbitBlock(
      canvas,
      const Offset(365, 335),
      const Color(0xFF38D9A9),
      const Color(0xFF099268),
    );
    // Block 3 (Bottom-Left)
    _drawOrbitBlock(
      canvas,
      const Offset(147, 335),
      const Color(0xFFDA77F2),
      const Color(0xFF862E9C),
    );

    // Center icon
    canvas.drawCircle(
      const Offset(256, 260),
      38,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(const Offset(256, 260), 38, _strokePaint(8));

    // Center arrows
    final shuf1 = Path()
      ..moveTo(238, 250)
      ..lineTo(274, 250)
      ..moveTo(264, 242)
      ..lineTo(274, 250)
      ..lineTo(264, 258);
    canvas.drawPath(
      shuf1,
      Paint()
        ..color = const Color(0xFFF59F00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final shuf2 = Path()
      ..moveTo(274, 270)
      ..lineTo(238, 270)
      ..moveTo(248, 262)
      ..lineTo(238, 270)
      ..lineTo(248, 278);
    canvas.drawPath(
      shuf2,
      Paint()
        ..color = const Color(0xFF22B8CF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  void _drawOrbitBlock(Canvas canvas, Offset center, Color c1, Color c2) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final r = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-42, -42, 84, 84),
      const Radius.circular(18),
    );
    final grad = LinearGradient(colors: [c1, c2]).createShader(r.outerRect);
    canvas.drawRRect(r, Paint()..shader = grad);
    canvas.drawRRect(r, _strokePaint(9));
    final hl = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-32, -32, 64, 18),
      const Radius.circular(9),
    );
    canvas.drawRRect(hl, Paint()..color = const Color(0x99FFFFFF));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Shovel 3x3: angled spade head with glowing 3x3 blueprint grid.
class ShovelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;
    canvas.save();
    canvas.scale(s, s);

    // 3x3 Blueprint grid
    canvas.save();
    canvas.translate(80, 240);
    canvas.scale(0.72, 0.72);

    final bg = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 300, 300),
      const Radius.circular(28),
    );
    canvas.drawRRect(bg, Paint()..color = const Color(0x551864AB));
    canvas.drawRRect(
      bg,
      Paint()
        ..color = const Color(0xFF339AF0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final cell = RRect.fromRectAndRadius(
          Rect.fromLTWH(15 + c * 95.0, 15 + r * 95.0, 80, 80),
          const Radius.circular(14),
        );
        final isCenter = r == 1 && c == 1;
        canvas.drawRRect(
          cell,
          Paint()
            ..color = isCenter
                ? const Color(0xCCFFD43B)
                : const Color(0x664DABF7),
        );
        canvas.drawRRect(
          cell,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = isCenter ? 6 : 5,
        );
      }
    }
    canvas.restore();

    // Shovel shaft
    canvas.drawLine(
      const Offset(370, 105),
      const Offset(225, 295),
      _strokePaint(36),
    );
    canvas.drawLine(
      const Offset(370, 105),
      const Offset(225, 295),
      Paint()
        ..color = const Color(0xFFE8B886)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round,
    );

    // D-Grip
    canvas.save();
    canvas.translate(390, 80);
    canvas.rotate(-35 * pi / 180);
    final grip = Path()
      ..moveTo(-30, -30)
      ..cubicTo(-30, -60, 30, -60, 30, -30)
      ..lineTo(30, 10)
      ..lineTo(-30, 10)
      ..close();
    canvas.drawPath(grip, Paint()..color = const Color(0xFFFFD95A));
    canvas.drawPath(grip, _strokePaint(10));
    canvas.drawOval(
      const Rect.fromLTWH(-16, -44, 32, 24),
      Paint()..color = Colors.white,
    );
    canvas.restore();

    // Shovel Scoop Blade
    canvas.save();
    canvas.translate(190, 340);
    canvas.rotate(-35 * pi / 180);

    final blade = Path()
      ..moveTo(-60, -40)
      ..cubicTo(-70, 20, -40, 70, 0, 95)
      ..cubicTo(40, 70, 70, 20, 60, -40)
      ..close();
    final bladeGrad = const LinearGradient(
      colors: [Color(0xFFFFD95A), Color(0xFFF5B21E), Color(0xFFD48208)],
    ).createShader(const Rect.fromLTWH(-60, -40, 120, 135));
    canvas.drawPath(blade, Paint()..shader = bladeGrad);
    canvas.drawPath(blade, _strokePaint(10));

    // Steel cutting edge
    final edge = Path()
      ..moveTo(-45, 50)
      ..cubicTo(-25, 75, 0, 90, 0, 90)
      ..cubicTo(0, 90, 25, 75, 45, 50)
      ..lineTo(50, 65)
      ..cubicTo(25, 90, 0, 102, 0, 102)
      ..cubicTo(0, 102, -25, 90, -50, 65)
      ..close();
    canvas.drawPath(edge, Paint()..color = const Color(0xFFCED4DA));
    canvas.drawPath(edge, _strokePaint(8));

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Toolbox / Mochila: yellow builder box with leather strap, buckle & handle.
class ToolboxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;
    canvas.save();
    canvas.scale(s, s);

    // Handle
    final handle = Path()
      ..moveTo(200, 170)
      ..cubicTo(200, 115, 312, 115, 312, 170);
    canvas.drawPath(handle, _strokePaint(32));
    canvas.drawPath(
      handle,
      Paint()
        ..color = const Color(0xFF8E5A30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round,
    );

    // Box body
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(90, 210, 332, 210),
      const Radius.circular(36),
    );
    final bodyGrad = const LinearGradient(
      colors: [Color(0xFFFFD95A), Color(0xFFF5B21E), Color(0xFFE09A12)],
    ).createShader(body.outerRect);
    canvas.drawRRect(body, Paint()..shader = bodyGrad);
    canvas.drawRRect(body, _strokePaint(12));

    // Lid
    final lid = RRect.fromRectAndRadius(
      const Rect.fromLTWH(76, 180, 360, 60),
      const Radius.circular(20),
    );
    final lidGrad = const LinearGradient(
      colors: [Color(0xFFFF922B), Color(0xFFD9480F)],
    ).createShader(lid.outerRect);
    canvas.drawRRect(lid, Paint()..shader = lidGrad);
    canvas.drawRRect(lid, _strokePaint(12));

    // Center strap
    final strap = RRect.fromRectAndRadius(
      const Rect.fromLTWH(226, 176, 60, 248),
      const Radius.circular(14),
    );
    canvas.drawRRect(strap, Paint()..color = const Color(0xFF6B4226));
    canvas.drawRRect(strap, _strokePaint(10));

    // Buckle
    final buckle = RRect.fromRectAndRadius(
      const Rect.fromLTWH(216, 240, 80, 56),
      const Radius.circular(12),
    );
    canvas.drawRRect(buckle, Paint()..color = const Color(0xFFFFD95A));
    canvas.drawRRect(buckle, _strokePaint(10));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(234, 254, 44, 28),
        const Radius.circular(6),
      ),
      Paint()..color = _outlineColor,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
