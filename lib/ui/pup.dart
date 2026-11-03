import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Capybara pups: trapped in blocks on the board, then free in Capi's
/// village. Same fur colors as Capi, rounder and smaller.
abstract final class PupPainter {
  // Same soft, glossy 2.5D look as Capi (see capi.dart).
  static const _line = Color(0xAA4A2A12);
  static const _furLight = Color(0xFFF6D3A6);
  static const _furMid = Color(0xFFD9A06A);
  static const _furDark = Color(0xFFA66C3C);
  static const _snout = Color(0xFF8E5A30);
  static const _ink = Color(0xFF2A1A0E);

  /// Bow colors, so the pups in the village look a little different.
  static const bows = [
    Color(0xFFFF7EB6),
    Color(0xFF74C0FC),
    Color(0xFFFFD43B),
    Color(0xFF8CE99A),
    Color(0xFFB57CF7),
    Color(0xFFFF8A3D),
  ];

  /// Fur lit from the top left, so each shape reads as a soft ball.
  static Paint _fur(Rect r) => Paint()
    ..shader = ui.Gradient.radial(
      r.topLeft + Offset(r.width * 0.36, r.height * 0.28),
      r.longestSide * 0.85,
      const [_furLight, _furMid, _furDark],
      const [0.0, 0.55, 1.0],
    );

  /// A blurred light spot: shine on the fur, blush on the cheeks.
  static void _glow(Canvas canvas, Rect r, Color color) {
    // A radial gradient (cheaper than a blur, drawn often on the board).
    final big = r.inflate(r.shortestSide * 0.35);
    canvas.drawOval(
      big,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(big),
    );
  }

  static Paint _outline(double w) => Paint()
    ..color = _line
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round;

  /// A pup's face filling [rect] (front view). [blink] closes the eyes.
  static void face(Canvas canvas, Rect rect, {bool blink = false, Color? bow}) {
    final s = rect.width;
    final c = rect.center;
    final stroke = max(0.8, s * 0.035);
    // Ears.
    for (final side in [-1.0, 1.0]) {
      final ear = Rect.fromCenter(
        center: c + Offset(side * s * 0.3, -s * 0.3),
        width: s * 0.2,
        height: s * 0.18,
      );
      canvas.drawOval(ear, Paint()..color = _snout);
      canvas.drawOval(ear, _outline(stroke));
    }
    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: s * 0.78, height: s * 0.7),
      Radius.circular(s * 0.3),
    );
    canvas.drawRRect(head, _fur(head.outerRect));
    canvas.drawRRect(head, _outline(stroke));
    _glow(
      canvas,
      Rect.fromCenter(
        center: c + Offset(-s * 0.12, -s * 0.24),
        width: s * 0.3,
        height: s * 0.12,
      ),
      const Color(0x66FFFFFF),
    );
    // Muzzle, like Capi's: a broad band with the nostrils on top and a
    // little buck-toothed smile.
    final snout = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, s * 0.14),
        width: s * 0.52,
        height: s * 0.3,
      ),
      Radius.circular(s * 0.15),
    );
    canvas.drawRRect(
      snout,
      Paint()
        ..shader = ui.Gradient.linear(
          snout.outerRect.topCenter,
          snout.outerRect.bottomCenter,
          const [Color(0xFFF3CC9C), Color(0xFFC98E58)],
        ),
    );
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(side * s * 0.09, s * 0.07),
          width: s * 0.07,
          height: s * 0.045,
        ),
        Paint()..color = _ink,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s * 0.1, c.dy + s * 0.17)
        ..quadraticBezierTo(
          c.dx,
          c.dy + s * 0.25,
          c.dx + s * 0.1,
          c.dy + s * 0.17,
        ),
      _outline(stroke)..color = _ink,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: c + Offset(0, s * 0.235),
        width: s * 0.06,
        height: s * 0.045,
      ),
      Paint()..color = Colors.white,
    );
    // Eyes and cheeks.
    for (final side in [-1.0, 1.0]) {
      final eye = c + Offset(side * s * 0.17, -s * 0.08);
      if (blink) {
        canvas.drawArc(
          Rect.fromCenter(center: eye, width: s * 0.12, height: s * 0.08),
          0,
          pi,
          false,
          _outline(stroke)..color = _ink,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: eye, width: s * 0.1, height: s * 0.12),
          Paint()..color = _ink,
        );
        canvas.drawCircle(
          eye + Offset(-s * 0.017, -s * 0.026),
          s * 0.026,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          eye + Offset(s * 0.02, s * 0.025),
          s * 0.011,
          Paint()..color = Colors.white70,
        );
      }
      _glow(
        canvas,
        Rect.fromCenter(
          center: c + Offset(side * s * 0.27, s * 0.05),
          width: s * 0.14,
          height: s * 0.08,
        ),
        const Color(0x99FF8A9A),
      );
    }
    if (bow != null) {
      _bow(canvas, c + Offset(s * 0.2, -s * 0.33), s * 0.22, bow);
    }
  }

  static void _bow(Canvas canvas, Offset at, double s, Color color) {
    final paint = Paint()..color = color;
    final edge = _outline(max(0.6, s * 0.08));
    for (final side in [-1.0, 1.0]) {
      final wing = Path()
        ..moveTo(at.dx, at.dy)
        ..lineTo(at.dx + side * s * 0.6, at.dy - s * 0.35)
        ..lineTo(at.dx + side * s * 0.6, at.dy + s * 0.35)
        ..close();
      canvas.drawPath(wing, paint);
      canvas.drawPath(wing, edge);
    }
    canvas.drawCircle(at, s * 0.18, paint);
    canvas.drawCircle(at, s * 0.18, edge);
  }

  /// A whole pup standing, feet at the bottom center of [size]. [t] (0..1)
  /// drives a little waddle.
  static void body(Canvas canvas, Size size, {double t = 0, Color? bow}) {
    final s = size.width;
    final waddle = sin(t * 2 * pi) * 0.06;
    canvas.save();
    canvas.translate(s / 2, size.height);
    canvas.rotate(waddle);
    canvas.translate(-s / 2, -size.height);
    final stroke = max(0.8, s * 0.035);
    // Feet.
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s / 2 + side * s * 0.18, size.height - s * 0.05),
          width: s * 0.22,
          height: s * 0.12,
        ),
        _fur(
          Rect.fromCenter(
            center: Offset(s / 2 + side * s * 0.18, size.height - s * 0.05),
            width: s * 0.22,
            height: s * 0.12,
          ),
        ),
      );
    }
    final belly = Rect.fromCenter(
      center: Offset(s / 2, size.height - s * 0.32),
      width: s * 0.74,
      height: s * 0.5,
    );
    canvas.drawOval(belly, _fur(belly));
    canvas.drawOval(belly, _outline(stroke));
    canvas.drawOval(
      belly.deflate(s * 0.13).translate(0, s * 0.04),
      Paint()..color = const Color(0x40FFF1DC),
    );
    face(
      canvas,
      Rect.fromCenter(
        center: Offset(s / 2, size.height - s * 0.66),
        width: s * 0.8,
        height: s * 0.8,
      ),
      blink: (t * 7 + 0.5) % 1 < 0.06,
      bow: bow,
    );
    canvas.restore();
  }

  /// A pup trapped in a glass bubble, over a block on the board.
  static void trapped(Canvas canvas, Rect rect) {
    final s = rect.width;
    final c = rect.center.translate(0, -s * 0.04);
    final r = s * 0.36;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xCCFFF8EC));
    face(canvas, Rect.fromCircle(center: c, radius: r * 0.92));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, s * 0.04)
        ..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.78),
      pi * 1.1,
      pi * 0.35,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, s * 0.05)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.8),
    );
  }
}

/// A pup standing, for menus and cards.
class Pup extends StatelessWidget {
  const Pup({super.key, this.size = 40, this.bow});
  final double size;
  final Color? bow;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _PupPainter(bow)),
  );
}

class _PupPainter extends CustomPainter {
  _PupPainter(this.bow);
  final Color? bow;

  @override
  void paint(Canvas canvas, Size size) =>
      PupPainter.body(canvas, size, bow: bow);

  @override
  bool shouldRepaint(_PupPainter old) => old.bow != bow;
}
