import 'dart:math';

import 'package:flutter/material.dart';

/// Vector painter for the 60s Blitz mode icon.
class BlitzIconPainter extends CustomPainter {
  const BlitzIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final cx = size.width / 2;
    final cy = size.height / 2;

    final darkOutline = Paint()
      ..color = const Color(0xFF4A2A12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer glow / speed flame behind
    final flamePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFFFF6B6B), Color(0xFFFFA94D), Color(0xFFFFD43B)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final flamePath = Path()
      ..moveTo(cx - s * 0.15, cy - s * 0.35)
      ..cubicTo(
        cx - s * 0.25,
        cy - s * 0.5,
        cx,
        cy - s * 0.55,
        cx - s * 0.05,
        cy - s * 0.35,
      )
      ..cubicTo(
        cx + s * 0.1,
        cy - s * 0.55,
        cx + s * 0.28,
        cy - s * 0.45,
        cx + s * 0.18,
        cy - s * 0.35,
      )
      ..close();
    canvas.drawPath(flamePath, flamePaint);
    canvas.drawPath(flamePath, darkOutline);

    // Stopwatch Ring Body
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF922B), Color(0xFFFFD43B), Color(0xFFFF6B6B)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: s * 0.42));

    canvas.drawCircle(Offset(cx, cy), s * 0.42, ringPaint);
    canvas.drawCircle(Offset(cx, cy), s * 0.42, darkOutline);

    // Inner dial
    final dialPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A3356), Color(0xFF141938)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: s * 0.33));
    canvas.drawCircle(Offset(cx, cy), s * 0.33, dialPaint);
    canvas.drawCircle(Offset(cx, cy), s * 0.33, darkOutline);

    // Crown / Top Button
    final crownR = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy - s * 0.44),
        width: s * 0.18,
        height: s * 0.08,
      ),
      Radius.circular(s * 0.02),
    );
    canvas.drawRRect(crownR, Paint()..color = const Color(0xFFFFD43B));
    canvas.drawRRect(crownR, darkOutline);

    // Dynamic Lightning Bolt
    final boltPath = Path()
      ..moveTo(cx + s * 0.08, cy - s * 0.24)
      ..lineTo(cx - s * 0.14, cy + s * 0.02)
      ..lineTo(cx + s * 0.01, cy + s * 0.02)
      ..lineTo(cx - s * 0.1, cy + s * 0.26)
      ..lineTo(cx + s * 0.16, cy - s * 0.04)
      ..lineTo(cx + s * 0.02, cy - s * 0.04)
      ..close();

    final boltPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3BF), Color(0xFFFFD43B), Color(0xFFF59F00)],
          ).createShader(
            Rect.fromLTWH(cx - s * 0.2, cy - s * 0.25, s * 0.4, s * 0.5),
          );

    canvas.drawPath(boltPath, boltPaint);
    canvas.drawPath(boltPath, darkOutline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vector painter for the Duel / Challenge icon.
class DuelIconPainter extends CustomPainter {
  const DuelIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final cx = size.width / 2;
    final cy = size.height / 2;

    final darkOutline = Paint()
      ..color = const Color(0xFF4A2A12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Crossed Swords in background
    void drawSword(double angle) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      // Blade
      final blade = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -s * 0.15),
          width: s * 0.07,
          height: s * 0.6,
        ),
        Radius.circular(s * 0.02),
      );
      canvas.drawRRect(blade, Paint()..color = const Color(0xFFE9ECEF));
      canvas.drawRRect(blade, darkOutline);

      // Guard
      final guard = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, s * 0.15),
          width: s * 0.24,
          height: s * 0.05,
        ),
        Radius.circular(s * 0.015),
      );
      canvas.drawRRect(guard, Paint()..color = const Color(0xFFFFD43B));
      canvas.drawRRect(guard, darkOutline);

      // Handle & Pommel
      final pommel = Rect.fromCircle(
        center: Offset(0, s * 0.28),
        radius: s * 0.04,
      );
      canvas.drawOval(pommel, Paint()..color = const Color(0xFFFFD43B));
      canvas.drawOval(pommel, darkOutline);

      canvas.restore();
    }

    drawSword(pi / 4);
    drawSword(-pi / 4);

    // Shield
    final shieldPath = Path()
      ..moveTo(cx, cy - s * 0.35)
      ..cubicTo(
        cx + s * 0.3,
        cy - s * 0.35,
        cx + s * 0.34,
        cy - s * 0.15,
        cx + s * 0.34,
        cy + s * 0.05,
      )
      ..cubicTo(
        cx + s * 0.34,
        cy + s * 0.26,
        cx + s * 0.15,
        cy + s * 0.38,
        cx,
        cy + s * 0.44,
      )
      ..cubicTo(
        cx - s * 0.15,
        cy + s * 0.38,
        cx - s * 0.34,
        cy + s * 0.26,
        cx - s * 0.34,
        cy + s * 0.05,
      )
      ..cubicTo(
        cx - s * 0.34,
        cy - s * 0.15,
        cx - s * 0.3,
        cy - s * 0.35,
        cx,
        cy - s * 0.35,
      )
      ..close();

    final goldPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE066), Color(0xFFFCC419), Color(0xFFD9480F)],
          ).createShader(
            Rect.fromLTWH(cx - s * 0.35, cy - s * 0.35, s * 0.7, s * 0.8),
          );

    canvas.drawPath(shieldPath, goldPaint);
    canvas.drawPath(shieldPath, darkOutline);

    // Inner Shield Blue
    final innerShield = Path()
      ..moveTo(cx, cy - s * 0.3)
      ..cubicTo(
        cx + s * 0.24,
        cy - s * 0.3,
        cx + s * 0.27,
        cy - s * 0.12,
        cx + s * 0.27,
        cy + s * 0.05,
      )
      ..cubicTo(
        cx + s * 0.27,
        cy + s * 0.22,
        cx + s * 0.12,
        cy + s * 0.32,
        cx,
        cy + s * 0.37,
      )
      ..cubicTo(
        cx - s * 0.12,
        cy + s * 0.32,
        cx - s * 0.27,
        cy + s * 0.22,
        cx - s * 0.27,
        cy + s * 0.05,
      )
      ..cubicTo(
        cx - s * 0.27,
        cy - s * 0.12,
        cx - s * 0.24,
        cy - s * 0.3,
        cx,
        cy - s * 0.3,
      )
      ..close();

    final bluePaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF339AF0), Color(0xFF1864AB)],
          ).createShader(
            Rect.fromLTWH(cx - s * 0.3, cy - s * 0.3, s * 0.6, s * 0.7),
          );

    canvas.drawPath(innerShield, bluePaint);
    canvas.drawPath(innerShield, darkOutline);

    // Central "VS" Emblem Badge
    final vsBg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8787), Color(0xFFFA5252), Color(0xFFC92A2A)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: s * 0.16));

    canvas.drawCircle(Offset(cx, cy), s * 0.16, vsBg);
    canvas.drawCircle(
      Offset(cx, cy),
      s * 0.16,
      Paint()
        ..color = const Color(0xFFFFD43B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03,
    );
    canvas.drawCircle(Offset(cx, cy), s * 0.16, darkOutline);

    // Text "VS"
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'VS',
        style: TextStyle(
          color: Colors.white,
          fontSize: s * 0.16,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(
              color: Color(0xFF4A2A12),
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BlitzIcon extends StatelessWidget {
  const BlitzIcon({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: BlitzIconPainter()),
    );
  }
}

class DuelIcon extends StatelessWidget {
  const DuelIcon({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: DuelIconPainter()),
    );
  }
}
