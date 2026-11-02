import '../core/hats.dart';

import 'dart:math';

import 'package:flutter/material.dart';

import 'typography.dart';
import 'widgets.dart';

/// happy: holding a block. cheer: arms up. worried: holding the block,
/// sweating. sad: arms down. point: one arm pointing. carry: both arms up,
/// holding something over his head (the hint draws the piece there).
enum CapiMood { happy, cheer, worried, sad, point, carry }

/// Capi, the builder capybara: the game's mascot, drawn in code to match the
/// art in `art/capi.vectorcraft`, with a gentle idle bob.
class Capi extends StatefulWidget {
  const Capi({super.key, this.size = 80, this.mood = CapiMood.happy, this.hat});
  final double size;
  final CapiMood mood;
  final CapiHat? hat;

  @override
  State<Capi> createState() => _CapiState();
}

class _CapiState extends State<Capi> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _bob,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: CapiPainter(
          mood: widget.mood,
          t: _bob.value,
          hat: widget.hat ?? CapiHat.helmet,
        ),
      ),
    ),
  );
}

class CapiPainter extends CustomPainter {
  CapiPainter({required this.mood, required this.t, this.hat = CapiHat.helmet});
  final CapiMood mood;
  final double t;
  final CapiHat hat;

  static const _helmetTop = Color(0xFFFFD95A);
  static const _helmetBottom = Color(0xFFF5B21E);

  static final _outline = Paint()
    ..color = const Color(0xAA4A2A12)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..strokeJoin = StrokeJoin.round;

  /// Fills [path] with a top-to-bottom gradient and outlines it.
  void _shape(Canvas canvas, Path path, Color top, Color bottom) {
    final b = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(b),
    );
    canvas.drawPath(path, _outline);
  }

  // --- The soft, "toy 3D" look: light from the top left, volume from
  // radial gradients, a thin soft outline instead of a hard one. ---

  static const _fur = [Color(0xFFF6D3A6), Color(0xFFD9A06A), Color(0xFFA66C3C)];
  static const _furStops = [0.0, 0.55, 1.0];
  static final _soft = Paint()
    ..color = const Color(0x667A4422)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9;

  static Paint _ball(
    Rect r,
    List<Color> colors, {
    Alignment at = const Alignment(-0.35, -0.5),
    List<double>? stops,
  }) => Paint()
    ..shader = RadialGradient(
      center: at,
      radius: 0.95,
      colors: colors,
      stops: stops,
    ).createShader(r);

  /// A rounded shape with volume.
  void _blob(
    Canvas canvas,
    Rect r, {
    double radius = 999,
    List<Color> colors = _fur,
    List<double>? stops = _furStops,
    Alignment at = const Alignment(-0.35, -0.5),
  }) {
    final rr = RRect.fromRectAndRadius(
      r,
      Radius.circular(min(radius, r.shortestSide / 2)),
    );
    canvas.drawRRect(rr, _ball(r, colors, at: at, stops: stops));
    canvas.drawRRect(rr, _soft);
  }

  /// A soft glow (shadows, shine, blush), fading to nothing at the edge.
  void _glow(Canvas canvas, Offset c, double rx, double ry, Color color) {
    final r = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      r,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(r),
    );
  }

  /// A short chubby arm from [from] to [to], ending in a round paw.
  void _arm(Canvas canvas, Offset from, Offset to, {Offset? bend}) {
    final path = Path()..moveTo(from.dx, from.dy);
    if (bend != null) {
      path.quadraticBezierTo(bend.dx, bend.dy, to.dx, to.dy);
    } else {
      path.lineTo(to.dx, to.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x667A4422)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFC98F58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x40FFF1DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    _blob(
      canvas,
      Rect.fromCenter(center: to, width: 8.4, height: 8),
      colors: const [Color(0xFFE6B07A), Color(0xFFA66C3C)],
      stops: null,
    );
  }

  void _block(Canvas canvas, Rect r) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(3.4));
    canvas.drawRRect(
      rr.shift(const Offset(0, 1.2)),
      Paint()..color = const Color(0xFFC9582B),
    );
    canvas.drawRRect(
      rr,
      _ball(
        r,
        const [Color(0xFFFFC78A), Color(0xFFFF9A4D), Color(0xFFE5732B)],
        stops: const [0, 0.55, 1],
      ),
    );
    canvas.drawRRect(rr, _soft);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + 2.6, r.top + 2, r.width - 5.2, 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0x80FFFFFF),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Everything is drawn on a 100x100 grid.
    canvas.scale(size.width / 100);
    final bob = sin(t * 2 * pi) * 1.4;
    // A slow breath: the body swells a little.
    final breath = 1 + sin(t * 2 * pi + 1.2) * 0.012;
    final cheer = mood == CapiMood.cheer;
    final worried = mood == CapiMood.worried;
    final sad = mood == CapiMood.sad;
    final carry = mood == CapiMood.carry;
    final holdsBlock = mood == CapiMood.happy || worried;

    // Ground shadow and feet.
    _glow(canvas, const Offset(50, 94), 27, 4.6, const Color(0x55000000));
    for (final x in [39.0, 61.0]) {
      _blob(
        canvas,
        Rect.fromCenter(center: Offset(x, 90), width: 15, height: 8.5),
        colors: const [Color(0xFFC08350), Color(0xFF8E5A30)],
        stops: null,
      );
    }

    // Body and belly, breathing from the feet.
    canvas.save();
    canvas.translate(50, 94);
    canvas.scale(breath, breath);
    canvas.translate(-50, -94);
    _blob(canvas, const Rect.fromLTWH(28, 56, 44, 38));
    final belly = Rect.fromCenter(
      center: const Offset(50, 77),
      width: 26,
      height: 22,
    );
    canvas.drawOval(
      belly,
      _ball(belly, const [Color(0xFFFFF0D8), Color(0xFFEBC594)]),
    );
    canvas.restore();

    // Arms (and the block), before the head so the shoulders tuck under it.
    const leftShoulder = Offset(31, 64);
    const rightShoulder = Offset(69, 64);
    if (carry) {
      // Straight up past the head, paws where the load sits (y 5).
      _arm(
        canvas,
        leftShoulder,
        const Offset(20, 5),
        bend: const Offset(17, 40),
      );
      _arm(
        canvas,
        rightShoulder,
        const Offset(80, 5),
        bend: const Offset(83, 40),
      );
    } else if (cheer) {
      final up = bob;
      _arm(
        canvas,
        leftShoulder,
        Offset(16, 44 + up),
        bend: const Offset(19, 58),
      );
      _arm(
        canvas,
        rightShoulder,
        Offset(84, 44 + up),
        bend: const Offset(81, 58),
      );
    } else if (holdsBlock) {
      _block(canvas, const Rect.fromLTWH(40.5, 61.5, 19, 17));
      _arm(
        canvas,
        leftShoulder,
        const Offset(41.5, 71),
        bend: const Offset(33, 72),
      );
      _arm(
        canvas,
        rightShoulder,
        const Offset(58.5, 71),
        bend: const Offset(67, 72),
      );
    } else if (mood == CapiMood.point) {
      _arm(
        canvas,
        leftShoulder,
        const Offset(31, 80),
        bend: const Offset(28, 72),
      );
      _arm(
        canvas,
        rightShoulder,
        Offset(88, 50 + bob),
        bend: const Offset(79, 59),
      );
    } else {
      // Sad: arms hanging down.
      _arm(canvas, leftShoulder, const Offset(30, 81));
      _arm(canvas, rightShoulder, const Offset(70, 81));
    }

    canvas.save();
    canvas.translate(0, bob);

    // The head's soft shadow on the body.
    _glow(canvas, const Offset(50, 61), 22, 4.5, const Color(0x50553011));

    // Ears.
    for (final x in [25.0, 75.0]) {
      final ear = Rect.fromCenter(center: Offset(x, 21), width: 12, height: 10);
      _blob(
        canvas,
        ear,
        colors: const [Color(0xFFD9A06A), Color(0xFF8E5A30)],
        stops: null,
      );
      final inner = Rect.fromCenter(
        center: Offset(x, 21.8),
        width: 6,
        height: 4.6,
      );
      canvas.drawOval(
        inner,
        _ball(inner, const [Color(0xFFFFB6B0), Color(0xFFD9837A)]),
      );
    }

    // Head: big and round, with a rim light and a shine.
    _blob(canvas, const Rect.fromLTWH(18, 17, 64, 45), radius: 22);
    canvas.drawArc(
      const Rect.fromLTWH(20, 19, 60, 41),
      -0.55,
      1.05,
      false,
      Paint()
        ..color = const Color(0x55FFF4E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    _glow(canvas, const Offset(38, 24), 12, 5, const Color(0x55FFFFFF));

    // Muzzle: wide, with the nostrils on top.
    _blob(
      canvas,
      const Rect.fromLTWH(32, 39, 36, 21),
      radius: 10.5,
      colors: const [Color(0xFFD7A06A), Color(0xFFB27843), Color(0xFF8C5A30)],
      stops: const [0, 0.6, 1],
      at: const Alignment(-0.2, -0.7),
    );
    _glow(canvas, const Offset(47, 42), 9, 2.4, const Color(0x44FFFFFF));
    final ink = Paint()..color = const Color(0xFF3A2414);
    for (final s in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(50 + s * 6.5, 45.5),
          width: 4.6,
          height: 3,
        ),
        ink,
      );
    }

    // Mouth: the two front teeth when smiling.
    final stroke = Paint()
      ..color = const Color(0xFF3A2414)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    if (worried) {
      canvas.drawOval(const Rect.fromLTWH(47, 50.5, 6, 5.2), ink);
    } else if (sad) {
      canvas.drawPath(
        Path()
          ..moveTo(44.5, 56)
          ..quadraticBezierTo(50, 51, 55.5, 56),
        stroke,
      );
    } else {
      final open = cheer ? 2.6 : 0.0;
      canvas.drawPath(
        Path()
          ..moveTo(43.5, 51.5)
          ..quadraticBezierTo(50, 57 + open, 56.5, 51.5),
        stroke,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(47.8, 53.4 + open / 2, 4.4, 3.4),
          const Radius.circular(1),
        ),
        Paint()..color = Colors.white,
      );
    }

    // Eyes: big and glossy (closed arcs when cheering or sad).
    const eyeY = 31.0;
    if (cheer || sad) {
      for (final x in [35.0, 65.0]) {
        canvas.drawPath(
          cheer
              ? (Path()
                  ..moveTo(x - 4, eyeY + 2)
                  ..quadraticBezierTo(x, eyeY - 4, x + 4, eyeY + 2))
              : (Path()
                  ..moveTo(x - 4, eyeY - 1)
                  ..quadraticBezierTo(x, eyeY + 3.5, x + 4, eyeY - 1)),
          Paint()
            ..color = const Color(0xFF2A1A0E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    } else {
      if (worried) {
        // Raised, slanted brows and a drop of sweat.
        canvas.drawLine(const Offset(30, 24), const Offset(39, 22), stroke);
        canvas.drawLine(const Offset(61, 22), const Offset(70, 24), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(85, 28)
            ..quadraticBezierTo(81, 36, 85, 38)
            ..quadraticBezierTo(89, 36, 85, 28),
          Paint()..color = const Color(0xFF7FD3FF),
        );
      }
      final blink = t > 0.94;
      for (final x in [35.0, 65.0]) {
        final o = Offset(x, eyeY);
        if (blink) {
          canvas.drawLine(o.translate(-4.5, 0), o.translate(4.5, 0), stroke);
          continue;
        }
        final e = Rect.fromCenter(center: o, width: 9.5, height: 11.5);
        canvas.drawOval(
          e,
          _ball(e, const [
            Color(0xFF5A3A22),
            Color(0xFF1A0E06),
          ], at: const Alignment(0, 0.6)),
        );
        canvas.drawCircle(
          o + const Offset(-1.8, -2.6),
          2.1,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          o + const Offset(2, 2.4),
          0.9,
          Paint()..color = const Color(0xCCFFFFFF),
        );
      }
    }
    // Rosy cheeks.
    for (final x in [24.5, 75.5]) {
      _glow(canvas, Offset(x, 42), 6.5, 4, const Color(0xB3FF8A9A));
    }

    // Equipped hat. The hats were drawn for the old, smaller head: stretch
    // them to the new head's width and lift them onto its top.
    canvas.save();
    canvas.translate(50, 17);
    canvas.scale(64 / 59, 1);
    canvas.translate(-50, -20.5);
    _drawHat(canvas, hat);
    canvas.restore();
    canvas.restore();
  }

  void _drawHat(Canvas canvas, CapiHat h) {
    switch (h) {
      case CapiHat.helmet:
        _shape(
          canvas,
          Path()
            ..moveTo(25.6, 25.6)
            ..cubicTo(25.6, 3.9, 74.4, 3.9, 74.4, 25.6)
            ..close(),
          _helmetTop,
          _helmetBottom,
        );
        final brim = RRect.fromRectAndRadius(
          const Rect.fromLTWH(19.1, 23.2, 61.7, 4.9),
          const Radius.circular(2.4),
        );
        canvas.drawRRect(brim, Paint()..color = const Color(0xFFE09A12));
        canvas.drawRRect(brim, _outline);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(46.7, 9, 6.6, 14.6),
            const Radius.circular(2.5),
          ),
          Paint()..color = const Color(0xFFFFE58F),
        );
        canvas.drawPath(
          Path()
            ..moveTo(31.3, 19.5)
            ..cubicTo(32.2, 12.7, 37.1, 9.8, 42, 9),
          Paint()
            ..color = const Color(0xCCFFF4C7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );

      case CapiHat.crown:
        // Royal Crown
        final crownPath = Path()
          ..moveTo(24, 23)
          ..lineTo(22, 11)
          ..lineTo(36, 16)
          ..lineTo(50, 5)
          ..lineTo(64, 16)
          ..lineTo(78, 11)
          ..lineTo(76, 23)
          ..close();
        _shape(
          canvas,
          crownPath,
          const Color(0xFFFDE047),
          const Color(0xFFEAB308),
        );
        final crownBand = RRect.fromRectAndRadius(
          const Rect.fromLTWH(21, 21.5, 58, 5.5),
          const Radius.circular(2),
        );
        canvas.drawRRect(crownBand, Paint()..color = const Color(0xFFCA8A04));
        canvas.drawRRect(crownBand, _outline);
        // Jewels on peaks
        canvas.drawCircle(
          const Offset(22, 11),
          3.2,
          Paint()..color = const Color(0xFFEF4444),
        );
        canvas.drawCircle(const Offset(22, 11), 3.2, _outline);
        canvas.drawCircle(
          const Offset(50, 5),
          4.2,
          Paint()..color = const Color(0xFF38BDF8),
        );
        canvas.drawCircle(const Offset(50, 5), 4.2, _outline);
        canvas.drawCircle(
          const Offset(78, 11),
          3.2,
          Paint()..color = const Color(0xFF10B981),
        );
        canvas.drawCircle(const Offset(78, 11), 3.2, _outline);
        // Base band jewels
        for (final (x, c) in [
          (34.0, const Color(0xFFEF4444)),
          (50.0, const Color(0xFFFDE047)),
          (66.0, const Color(0xFF38BDF8)),
        ]) {
          canvas.drawCircle(Offset(x, 24.2), 2.0, Paint()..color = c);
        }

      case CapiHat.party:
        // Party Cone Hat
        final partyPath = Path()
          ..moveTo(28, 24)
          ..lineTo(50, 3)
          ..lineTo(72, 24)
          ..close();
        _shape(
          canvas,
          partyPath,
          const Color(0xFF38BDF8),
          const Color(0xFFEC4899),
        );
        // Yellow stripes
        final stripePaint = Paint()
          ..color = const Color(0xFFFDE047)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          const Offset(35, 17),
          const Offset(65, 17),
          stripePaint,
        );
        canvas.drawLine(
          const Offset(42, 10),
          const Offset(58, 10),
          stripePaint,
        );
        // Pom pom on apex
        canvas.drawCircle(
          const Offset(50, 3),
          4.5,
          Paint()..color = const Color(0xFFFDE047),
        );
        canvas.drawCircle(const Offset(50, 3), 4.5, _outline);

      case CapiHat.chef:
        // Chef's Toque Blanche
        final chefPath = Path()
          ..moveTo(26, 21)
          ..cubicTo(18, 10, 32, 2, 40, 5)
          ..cubicTo(45, 0, 55, 0, 60, 5)
          ..cubicTo(68, 2, 82, 10, 74, 21)
          ..close();
        _shape(
          canvas,
          chefPath,
          const Color(0xFFFFFFFF),
          const Color(0xFFE2E8F0),
        );
        final chefBand = RRect.fromRectAndRadius(
          const Rect.fromLTWH(26, 20.5, 48, 5.0),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(chefBand, Paint()..color = const Color(0xFFCBD5E1));
        canvas.drawRRect(chefBand, _outline);

      case CapiHat.pirate:
        // Pirate Tricorn Hat
        final tricorn = Path()
          ..moveTo(14, 23)
          ..cubicTo(20, 15, 36, 12, 50, 10)
          ..cubicTo(64, 12, 80, 15, 86, 23)
          ..lineTo(78, 27)
          ..cubicTo(66, 22, 34, 22, 22, 27)
          ..close();
        _shape(
          canvas,
          tricorn,
          const Color(0xFF1E293B),
          const Color(0xFF0F172A),
        );
        // Gold edge line
        final goldLine = Paint()
          ..color = const Color(0xFFFDE047)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        canvas.drawPath(tricorn, goldLine);
        // White block icon in center
        final skull = RRect.fromRectAndRadius(
          const Rect.fromLTWH(46, 15, 8, 8),
          const Radius.circular(2),
        );
        canvas.drawRRect(skull, Paint()..color = Colors.white);

      case CapiHat.straw:
        // Straw Hat
        final brim = Path()
          ..moveTo(14, 24)
          ..quadraticBezierTo(50, 19, 86, 24)
          ..lineTo(84, 28)
          ..quadraticBezierTo(50, 23, 16, 28)
          ..close();
        _shape(canvas, brim, const Color(0xFFFDE68A), const Color(0xFFD97706));
        final crown = Path()
          ..moveTo(28, 22)
          ..cubicTo(28, 8, 72, 8, 72, 22)
          ..close();
        _shape(canvas, crown, const Color(0xFFFDE68A), const Color(0xFFD97706));
        // Red Ribbon
        final ribbon = RRect.fromRectAndRadius(
          const Rect.fromLTWH(27, 19, 46, 4),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(ribbon, Paint()..color = const Color(0xFFEF4444));

      case CapiHat.wizard:
        // Wizard Hat
        final brim = Path()
          ..moveTo(16, 24)
          ..quadraticBezierTo(50, 18, 84, 24)
          ..lineTo(82, 28)
          ..quadraticBezierTo(50, 22, 18, 28)
          ..close();
        _shape(canvas, brim, const Color(0xFF6D28D9), const Color(0xFF4338CA));
        final cone = Path()
          ..moveTo(28, 22)
          ..cubicTo(36, 12, 54, 4, 68, 2)
          ..cubicTo(56, 10, 66, 16, 72, 22)
          ..close();
        _shape(canvas, cone, const Color(0xFF6D28D9), const Color(0xFF4338CA));
        // Magic yellow star on cone
        canvas.drawCircle(
          const Offset(48, 12),
          2.5,
          Paint()..color = const Color(0xFFFDE047),
        );
        canvas.drawCircle(
          const Offset(58, 7),
          2.0,
          Paint()..color = const Color(0xFFFDE047),
        );

      case CapiHat.vip:
        // Black top hat with a gold band.
        final brim = Path()
          ..moveTo(18, 24)
          ..quadraticBezierTo(50, 19, 82, 24)
          ..lineTo(80, 28)
          ..quadraticBezierTo(50, 23, 20, 28)
          ..close();
        _shape(canvas, brim, const Color(0xFF3B3F55), const Color(0xFF15172A));
        final tube = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(33, 1, 34, 22),
              const Radius.circular(3),
            ),
          );
        _shape(canvas, tube, const Color(0xFF3B3F55), const Color(0xFF15172A));
        canvas.drawRect(
          const Rect.fromLTWH(33.6, 15, 32.8, 4.5),
          Paint()..color = const Color(0xFFFFC94D),
        );
        // Shine down the side.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(37, 3, 3, 11),
            const Radius.circular(1.5),
          ),
          Paint()..color = const Color(0x40FFFFFF),
        );

      case CapiHat.fundador:
        // Capi's helmet, in gold, with a star on the front.
        final dome = Path()
          ..moveTo(26, 25.6)
          ..cubicTo(26, 3.9, 74, 3.9, 74, 25.6)
          ..close();
        _shape(canvas, dome, const Color(0xFFFFF1A8), const Color(0xFFE0A100));
        final brim = RRect.fromRectAndRadius(
          const Rect.fromLTWH(19.1, 23.2, 61.8, 4.9),
          const Radius.circular(2.4),
        );
        canvas.drawRRect(brim, Paint()..color = const Color(0xFFC98A00));
        canvas.drawRRect(brim, _outline);
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? 5.2 : 2.2;
          final a = -pi / 2 + i * pi / 5;
          final p = Offset(50 + r * cos(a), 15.5 + r * sin(a));
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        star.close();
        canvas.drawPath(star, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(CapiPainter old) =>
      old.t != t || old.mood != mood || old.hat != hat;
}

/// Capi with a speech bubble beside him.
class CapiSays extends StatelessWidget {
  const CapiSays({
    super.key,
    required this.text,
    this.mood = CapiMood.happy,
    this.capiSize = 76,
    this.action,
    this.onAction,
  });

  final String text;
  final CapiMood mood;
  final double capiSize;

  /// Optional button inside the bubble ("Bora!").
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Capi(size: capiSize, mood: mood),
        const SizedBox(width: 4),
        Expanded(
          child: CustomPaint(
            painter: _BubblePainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      text,
                      key: ValueKey(text),
                      style: bodyText(
                        16,
                        color: const Color(0xFF2A1458),
                        weight: 600,
                      ),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 10),
                    ChunkyButton(label: action!, onTap: onAction),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// White rounded bubble with a tail pointing left, at Capi.
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tail = 10.0;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(tail, 0, size.width - tail, size.height),
      const Radius.circular(18),
    );
    final path = Path()
      ..addRRect(body)
      ..moveTo(tail + 1, size.height - 30)
      ..lineTo(0, size.height - 14)
      ..lineTo(tail + 1, size.height - 16)
      ..close();
    canvas.drawShadow(path, const Color(0xFF000000), 4, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}
