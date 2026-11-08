import '../core/hats.dart';
import '../core/wardrobe.dart';
import 'capi_arte.dart';

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
  const Capi({
    super.key,
    this.size = 80,
    this.mood = CapiMood.happy,
    this.hat,
    this.look,
  });
  final double size;
  final CapiMood mood;
  final CapiHat? hat;

  /// Everything Capi wears; [hat], if given, replaces the look's hat.
  final CapiLook? look;

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
          hat: widget.hat ?? widget.look?.hat ?? CapiHat.helmet,
          look: widget.look,
        ),
      ),
    ),
  );
}

class CapiPainter extends CustomPainter {
  CapiPainter({
    required this.mood,
    required this.t,
    this.hat = CapiHat.helmet,
    CapiLook? look,
  }) : look = look ?? const CapiLook(),
       _coat = _Coat.of((look ?? const CapiLook()).pelagem),
       super(repaint: CapiArte.versao);
  final CapiMood mood;
  final double t;
  final CapiHat hat;

  /// The other items (face, neck, back, fur); the hat comes from [hat].
  final CapiLook look;
  final _Coat _coat;

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
    List<Color>? colors,
    List<double>? stops = _furStops,
    Alignment at = const Alignment(-0.35, -0.5),
  }) {
    final rr = RRect.fromRectAndRadius(
      r,
      Radius.circular(min(radius, r.shortestSide / 2)),
    );
    canvas.drawRRect(rr, _ball(r, colors ?? _coat.fur, at: at, stops: stops));
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
    // The painted Capi (capi_arte.dart) once its images are loaded.
    canvas.save();
    final pintado = pintarCapiArte(
      canvas,
      mood: mood,
      t: t,
      hat: hat,
      pelagem: look.pelagem,
      outros: [look.rosto, look.pescoco, look.costas],
    );
    canvas.restore();
    if (pintado) return;
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
        colors: _coat.feet,
        stops: null,
      );
    }

    // Back items, behind the body (wings, cape, backpack).
    _backBehind(canvas, look.costas);

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

    // Back items with a front part (straps, the swim ring).
    _backFront(canvas, look.costas);

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

    // Neck items, tucked under the head.
    _neck(canvas, look.pescoco);

    // Ears.
    for (final x in [25.0, 75.0]) {
      final ear = Rect.fromCenter(center: Offset(x, 21), width: 12, height: 10);
      _blob(canvas, ear, colors: _coat.ear, stops: null);
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
      colors: _coat.muzzle,
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

    // The galaxy coat twinkles.
    if (look.pelagem == 'galaxia') {
      for (final (x, y, r) in [
        (26.0, 26.0, 1.6),
        (72.0, 22.0, 1.3),
        (30.0, 52.0, 1.1),
        (70.0, 50.0, 1.5),
        (50.0, 20.0, 1.0),
      ]) {
        final tw = 0.6 + 0.4 * sin(t * 2 * pi * 3 + x);
        canvas.drawPath(
          _star(Offset(x, y), r * 2 * tw, 0.4),
          _fill(const Color(0xDDFFFFFF)),
        );
      }
    }

    // Face items, over the eyes.
    _face(canvas, look.rosto, closedEyes: cheer || sad);

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

      case CapiHat.touca ||
          CapiHat.junino ||
          CapiHat.coroaEstrelas ||
          CapiHat.gorroNatal ||
          CapiHat.chifresRena:
        _drawNewHat(canvas, h);

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

  // --- Wardrobe items (see core/wardrobe.dart). All on the 100x100 grid. ---

  Paint _fill(Color c) => Paint()..color = c;

  Paint get _line => Paint()
    ..color = const Color(0x997A4422)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..strokeJoin = StrokeJoin.round;

  /// A five-pointed star centered at [c].
  Path _star(Offset c, double r, [double inner = 0.45]) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * inner;
      final a = -pi / 2 + i * pi / 5;
      final o = Offset(c.dx + rr * cos(a), c.dy + rr * sin(a));
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  void _backBehind(Canvas canvas, String? id) {
    switch (id) {
      case 'jetpack':
        // Two silver tanks peeking out, with little flames.
        for (final s in [-1.0, 1.0]) {
          final tank = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(50 + s * 22, 70),
              width: 12,
              height: 26,
            ),
            const Radius.circular(6),
          );
          canvas.drawRRect(
            tank,
            _ball(tank.outerRect, const [Color(0xFFF1F3F5), Color(0xFF868E96)]),
          );
          canvas.drawRRect(tank, _line);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(50 + s * 22, 62),
              width: 12,
              height: 3,
            ),
            _fill(const Color(0xFFFF6B6B)),
          );
          final flick = 1 + sin(t * 2 * pi * 4 + s) * 0.18;
          final flame = Path()
            ..moveTo(50 + s * 22 - 4, 83)
            ..quadraticBezierTo(
              50 + s * 22,
              83 + 12 * flick,
              50 + s * 22 + 4,
              83,
            )
            ..close();
          canvas.drawPath(flame, _fill(const Color(0xFFFFA94D)));
          canvas.drawPath(
            Path()
              ..moveTo(50 + s * 22 - 2, 83)
              ..quadraticBezierTo(
                50 + s * 22,
                83 + 6 * flick,
                50 + s * 22 + 2,
                83,
              )
              ..close(),
            _fill(const Color(0xFFFFF3BF)),
          );
        }
      case 'asinhas':
        // Two feathered wings, flapping a little.
        final flap = sin(t * 2 * pi * 2) * 0.08;
        for (final s in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(50 + s * 18, 66);
          canvas.rotate(s * (0.25 + flap));
          for (var i = 0; i < 3; i++) {
            final f = Rect.fromLTWH(
              s > 0 ? 2 : -24 + i * 1.5,
              -14 + i * 7,
              22 - i * 3.0,
              10,
            );
            final feather = RRect.fromRectAndRadius(
              f,
              const Radius.circular(5),
            );
            canvas.drawRRect(
              feather,
              _ball(f, const [Color(0xFFFFFFFF), Color(0xFFD9E6F5)]),
            );
            canvas.drawRRect(feather, _line..color = const Color(0x667A8AA0));
          }
          canvas.restore();
        }
      case 'capa_real':
        final cape = Path()
          ..moveTo(32, 58)
          ..quadraticBezierTo(18, 76, 20, 94)
          ..lineTo(80, 94)
          ..quadraticBezierTo(82, 76, 68, 58)
          ..close();
        _shape(canvas, cape, const Color(0xFFE5484D), const Color(0xFF8E1D2C));
      case 'mochila':
        final bag = RRect.fromRectAndRadius(
          const Rect.fromLTWH(22, 60, 56, 28),
          const Radius.circular(9),
        );
        canvas.drawRRect(
          bag,
          _ball(bag.outerRect, const [Color(0xFF7BD389), Color(0xFF2F8F4E)]),
        );
        canvas.drawRRect(bag, _line);
    }
  }

  void _backFront(Canvas canvas, String? id) {
    switch (id) {
      case 'mochila':
        // Straps over the shoulders.
        for (final s in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(50 + s * 13, 58)
              ..quadraticBezierTo(50 + s * 14, 70, 50 + s * 18, 84),
            Paint()
              ..color = const Color(0xFF2F8F4E)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.2
              ..strokeCap = StrokeCap.round,
          );
        }
      case 'boia':
        // A yellow duck ring around the waist.
        final ring = Rect.fromCenter(
          center: const Offset(50, 82),
          width: 56,
          height: 16,
        );
        canvas.drawOval(
          ring,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF08A), Color(0xFFF2B705)],
            ).createShader(ring),
        );
        canvas.drawOval(ring, _line);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 80), width: 38, height: 7),
          _fill(const Color(0x33FFFFFF)),
        );
        // The duck's head on the side.
        canvas.drawCircle(
          const Offset(76, 76),
          5,
          _fill(const Color(0xFFFFE24A)),
        );
        canvas.drawCircle(const Offset(76, 76), 5, _line);
        canvas.drawCircle(
          const Offset(77.5, 75),
          0.9,
          _fill(const Color(0xFF2A1A0E)),
        );
        canvas.drawPath(
          Path()
            ..moveTo(80.5, 76)
            ..lineTo(84, 77)
            ..lineTo(80.5, 78.2)
            ..close(),
          _fill(const Color(0xFFFF8A3D)),
        );
      case 'capa_real':
        // The ermine collar, white with black dots.
        final collar = RRect.fromRectAndRadius(
          const Rect.fromLTWH(29, 56, 42, 8),
          const Radius.circular(4),
        );
        canvas.drawRRect(collar, _fill(const Color(0xFFFFFBF2)));
        canvas.drawRRect(collar, _line);
        for (final x in [35.0, 43.0, 57.0, 65.0]) {
          canvas.drawCircle(Offset(x, 60), 0.9, _fill(const Color(0xFF2A1A0E)));
        }
    }
  }

  void _neck(Canvas canvas, String? id) {
    switch (id) {
      case 'medalha':
        // Blue ribbon and a gold medal with a star.
        canvas.drawPath(
          Path()
            ..moveTo(40, 58)
            ..lineTo(50, 68)
            ..lineTo(60, 58),
          Paint()
            ..color = const Color(0xFF4DABF7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeJoin = StrokeJoin.round,
        );
        final medal = Rect.fromCircle(center: const Offset(50, 72), radius: 6);
        canvas.drawOval(
          medal,
          _ball(medal, const [Color(0xFFFFF3BF), Color(0xFFE0A100)]),
        );
        canvas.drawOval(medal, _line);
        canvas.drawPath(
          _star(const Offset(50, 72), 3.6),
          _fill(const Color(0xFFFFFFFF)),
        );
      case 'colar_diamante':
        for (var i = 0; i < 7; i++) {
          final a = pi * (0.2 + i * 0.1);
          canvas.drawCircle(
            Offset(50 - 18 * cos(a), 58 + 6 * sin(a)),
            1.4,
            _fill(const Color(0xFFE9ECEF)),
          );
        }
        final sparkle = 0.6 + 0.4 * sin(t * 2 * pi * 2).abs();
        final gem = Path()
          ..moveTo(50, 62)
          ..lineTo(55, 66)
          ..lineTo(50, 73)
          ..lineTo(45, 66)
          ..close();
        canvas.drawPath(
          gem,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFE3FAFC), Color(0xFF66D9E8), Color(0xFF1098AD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(const Rect.fromLTWH(45, 62, 10, 11)),
        );
        canvas.drawPath(gem, _line..color = const Color(0x990B7285));
        _glow(
          canvas,
          const Offset(48, 64),
          4 * sparkle,
          4 * sparkle,
          const Color(0xCCFFFFFF),
        );
      case 'cachecol':
        final band = RRect.fromRectAndRadius(
          const Rect.fromLTWH(26, 56, 48, 10),
          const Radius.circular(5),
        );
        canvas.drawRRect(
          band,
          _ball(band.outerRect, const [Color(0xFFFF6B6B), Color(0xFFC92A2A)]),
        );
        for (final x in [34.0, 46.0, 58.0, 70.0]) {
          canvas.drawRect(
            Rect.fromLTWH(x - 2, 56.5, 3.5, 9),
            _fill(const Color(0xCCFFFFFF)),
          );
        }
        canvas.drawRRect(band, _line);
        // The tail hanging down the chest.
        final tail = RRect.fromRectAndRadius(
          const Rect.fromLTWH(58, 62, 9, 17),
          const Radius.circular(3),
        );
        canvas.drawRRect(tail, _fill(const Color(0xFFE03131)));
        canvas.drawRect(
          const Rect.fromLTWH(58, 69, 9, 3),
          _fill(const Color(0xCCFFFFFF)),
        );
        canvas.drawRRect(tail, _line);
      case 'cachecol_natal':
        // Red and green stripes, with a tail down the chest.
        final band = RRect.fromRectAndRadius(
          const Rect.fromLTWH(26, 56, 48, 10),
          const Radius.circular(5),
        );
        canvas.drawRRect(
          band,
          _ball(band.outerRect, const [Color(0xFFFF6B6B), Color(0xFFC92A2A)]),
        );
        for (final x in [32.0, 44.0, 56.0, 68.0]) {
          canvas.drawRect(
            Rect.fromLTWH(x - 2, 56.5, 4, 9),
            _fill(const Color(0xFF2F9E44)),
          );
        }
        canvas.drawRRect(band, _line);
        final tail = RRect.fromRectAndRadius(
          const Rect.fromLTWH(33, 62, 9, 17),
          const Radius.circular(3),
        );
        canvas.drawRRect(tail, _fill(const Color(0xFFE03131)));
        for (final y in [66.0, 73.0]) {
          canvas.drawRect(
            Rect.fromLTWH(33, y, 9, 3),
            _fill(const Color(0xFF2F9E44)),
          );
        }
        canvas.drawRRect(tail, _line);
      case 'sininho':
        // A red ribbon with a golden bell, above the block Capi holds.
        canvas.drawPath(
          Path()
            ..moveTo(32, 54)
            ..quadraticBezierTo(50, 60, 68, 54),
          Paint()
            ..color = const Color(0xFFE03131)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round,
        );
        final swing = sin(t * 2 * pi * 1.5) * 0.18;
        canvas.save();
        canvas.translate(50, 56);
        canvas.rotate(swing);
        final bell = Path()
          ..moveTo(-4.5, 7)
          ..quadraticBezierTo(-4.5, 0, 0, 0)
          ..quadraticBezierTo(4.5, 0, 4.5, 7)
          ..close();
        canvas.drawPath(
          bell,
          _ball(const Rect.fromLTWH(-4.5, 0, 9, 7), const [
            Color(0xFFFFF3BF),
            Color(0xFFE0A100),
          ]),
        );
        canvas.drawPath(bell, _line);
        canvas.drawCircle(
          const Offset(0, 7.5),
          1.4,
          _fill(const Color(0xFF8B5A2B)),
        );
        canvas.restore();
      case 'gravata':
        for (final s in [-1.0, 1.0]) {
          final wing = Path()
            ..moveTo(50, 64)
            ..lineTo(50 + s * 10, 58.5)
            ..quadraticBezierTo(50 + s * 12, 64, 50 + s * 10, 69.5)
            ..close();
          _shape(
            canvas,
            wing,
            const Color(0xFFFF5C8A),
            const Color(0xFFB0124A),
          );
        }
        canvas.drawCircle(
          const Offset(50, 64),
          2.6,
          _fill(const Color(0xFFD6336C)),
        );
      case 'lenco':
        // A checkered kerchief, knotted at the front.
        final scarf = Path()
          ..moveTo(30, 58)
          ..lineTo(70, 58)
          ..lineTo(50, 76)
          ..close();
        canvas.save();
        canvas.clipPath(scarf);
        canvas.drawPath(scarf, _fill(const Color(0xFFE03131)));
        for (var x = 30.0; x < 70; x += 6) {
          canvas.drawRect(
            Rect.fromLTWH(x, 56, 3, 22),
            _fill(const Color(0x55FFFFFF)),
          );
        }
        for (var y = 58.0; y < 78; y += 6) {
          canvas.drawRect(
            Rect.fromLTWH(28, y, 44, 3),
            _fill(const Color(0x55FFFFFF)),
          );
        }
        canvas.restore();
        canvas.drawPath(scarf, _line);
      case 'colar_flores':
        const colors = [
          Color(0xFFFF6FA8),
          Color(0xFFFFD43B),
          Color(0xFF74C0FC),
          Color(0xFFB57CF7),
          Color(0xFFFF8A3D),
        ];
        for (var i = 0; i < 9; i++) {
          final a = pi * (0.1 + i * 0.1);
          final c = Offset(50 - 22 * cos(a), 58 + 9 * sin(a));
          for (var k = 0; k < 5; k++) {
            final pa = k * 2 * pi / 5;
            canvas.drawCircle(
              c + Offset(cos(pa) * 1.8, sin(pa) * 1.8),
              1.8,
              _fill(colors[i % colors.length]),
            );
          }
          canvas.drawCircle(c, 1.2, _fill(const Color(0xFFFFF3BF)));
        }
    }
  }

  void _face(Canvas canvas, String? id, {required bool closedEyes}) {
    const left = Offset(35, 31);
    const right = Offset(65, 31);
    switch (id) {
      case 'oculos_estrelados':
        for (final o in [left, right]) {
          final star = _star(o, 9, 0.5);
          canvas.drawPath(star, _fill(const Color(0xDDFFD43B)));
          canvas.drawPath(
            star,
            _line
              ..color = const Color(0xFFE67700)
              ..strokeWidth = 1.2,
          );
          canvas.drawCircle(o, 4.2, _fill(const Color(0x664DABF7)));
        }
        canvas.drawLine(
          const Offset(43, 30),
          const Offset(57, 30),
          Paint()
            ..color = const Color(0xFFE67700)
            ..strokeWidth = 1.3,
        );
      case 'oculos_sol':
        for (final o in [left, right]) {
          final lens = RRect.fromRectAndRadius(
            Rect.fromCenter(center: o, width: 17, height: 12),
            const Radius.circular(5),
          );
          canvas.drawRRect(
            lens,
            _ball(lens.outerRect, const [Color(0xFF4A5068), Color(0xFF14161F)]),
          );
          canvas.drawRRect(
            lens,
            _line
              ..color = const Color(0xFF14161F)
              ..strokeWidth = 1.4,
          );
          canvas.drawLine(
            o + const Offset(-5, -3),
            o + const Offset(-1.5, -4),
            Paint()
              ..color = const Color(0x88FFFFFF)
              ..strokeWidth = 1.4
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawLine(
          const Offset(43.5, 30),
          const Offset(56.5, 30),
          Paint()
            ..color = const Color(0xFF14161F)
            ..strokeWidth = 1.6,
        );
      case 'oculos_coracao':
        for (final o in [left, right]) {
          final heart = Path()
            ..moveTo(o.dx, o.dy + 6)
            ..cubicTo(o.dx - 10, o.dy, o.dx - 6, o.dy - 8, o.dx, o.dy - 3.5)
            ..cubicTo(o.dx + 6, o.dy - 8, o.dx + 10, o.dy, o.dx, o.dy + 6)
            ..close();
          canvas.drawPath(heart, _fill(const Color(0xDDFF4D8D)));
          canvas.drawPath(
            heart,
            _line
              ..color = const Color(0xFFC2185B)
              ..strokeWidth = 1.2,
          );
          canvas.drawCircle(
            o + const Offset(-3, -2.5),
            1.3,
            _fill(const Color(0xAAFFFFFF)),
          );
        }
        canvas.drawLine(
          const Offset(42, 29),
          const Offset(58, 29),
          Paint()
            ..color = const Color(0xFFC2185B)
            ..strokeWidth = 1.3,
        );
      case 'monoculo':
        canvas.drawCircle(
          right,
          7.5,
          Paint()
            ..color = const Color(0xFFFFC94D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        canvas.drawCircle(right, 6.8, _fill(const Color(0x22BFE7FF)));
        canvas.drawPath(
          Path()
            ..moveTo(71, 35)
            ..quadraticBezierTo(80, 48, 74, 58),
          Paint()
            ..color = const Color(0xFFE0A100)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      case 'bigode':
        for (final s in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(50, 48.5)
              ..cubicTo(50 + s * 6, 45, 50 + s * 12, 47, 50 + s * 14, 51)
              ..cubicTo(50 + s * 16, 53, 50 + s * 18, 50, 50 + s * 16.5, 48)
              ..cubicTo(50 + s * 15, 53.5, 50 + s * 7, 52, 50, 50.5)
              ..close(),
            _fill(const Color(0xFF3A2414)),
          );
        }
      case 'mascara_heroi':
        final mask = Path()
          ..moveTo(20, 30)
          ..quadraticBezierTo(50, 20, 80, 30)
          ..quadraticBezierTo(82, 38, 76, 40)
          ..quadraticBezierTo(50, 34, 24, 40)
          ..quadraticBezierTo(18, 38, 20, 30)
          ..close();
        canvas.save();
        final holes = Path()..fillType = PathFillType.evenOdd;
        holes.addPath(mask, Offset.zero);
        for (final o in [left, right]) {
          holes.addOval(Rect.fromCenter(center: o, width: 10, height: 11));
        }
        canvas.drawPath(
          holes,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFE5484D), Color(0xFF9B1C31)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(const Rect.fromLTWH(18, 22, 64, 20)),
        );
        canvas.restore();
        canvas.drawPath(mask, _line);
        // The knot's tails behind the head.
        for (final s in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(50 + s * 30, 33)
              ..lineTo(50 + s * 38, 30)
              ..lineTo(50 + s * 37, 38)
              ..close(),
            _fill(const Color(0xFFB0222F)),
          );
        }
    }
    if (closedEyes) return;
  }

  void _drawNewHat(Canvas canvas, CapiHat h) {
    switch (h) {
      case CapiHat.touca:
        final cap = Path()
          ..moveTo(23, 26)
          ..cubicTo(23, 2, 77, 2, 77, 26)
          ..close();
        _shape(canvas, cap, const Color(0xFF66D9E8), const Color(0xFF1C7ED6));
        // Ribbed cuff.
        final cuff = RRect.fromRectAndRadius(
          const Rect.fromLTWH(20, 21, 60, 8),
          const Radius.circular(4),
        );
        canvas.drawRRect(cuff, _fill(const Color(0xFFFFFFFF)));
        for (var x = 24.0; x < 78; x += 5) {
          canvas.drawLine(
            Offset(x, 22),
            Offset(x, 28),
            Paint()
              ..color = const Color(0x33000000)
              ..strokeWidth = 0.8,
          );
        }
        canvas.drawRRect(cuff, _outline);
        // Pompom.
        canvas.drawCircle(
          const Offset(50, 4),
          5.5,
          _ball(
            Rect.fromCircle(center: const Offset(50, 4), radius: 5.5),
            const [Color(0xFFFFFFFF), Color(0xFFD0D7E2)],
          ),
        );
      case CapiHat.junino:
        final brim = Path()
          ..moveTo(12, 25)
          ..quadraticBezierTo(50, 19, 88, 25)
          ..lineTo(85, 29)
          ..quadraticBezierTo(50, 24, 15, 29)
          ..close();
        _shape(canvas, brim, const Color(0xFFFDE68A), const Color(0xFFC98A1E));
        final crown = Path()
          ..moveTo(29, 23)
          ..cubicTo(29, 6, 71, 6, 71, 23)
          ..close();
        _shape(canvas, crown, const Color(0xFFFDE68A), const Color(0xFFC98A1E));
        // Checkered band.
        canvas.save();
        canvas.clipRect(const Rect.fromLTWH(28, 18.5, 44, 4.5));
        for (var x = 28.0; x < 72; x += 3) {
          canvas.drawRect(
            Rect.fromLTWH(x, 18.5, 1.5, 4.5),
            _fill(const Color(0xFFE03131)),
          );
          canvas.drawRect(
            Rect.fromLTWH(x + 1.5, 18.5, 1.5, 4.5),
            _fill(const Color(0xFFFFFFFF)),
          );
        }
        canvas.restore();
        // A patch.
        canvas.drawRect(
          const Rect.fromLTWH(56, 9, 7, 6),
          _fill(const Color(0xFFB07A47)),
        );
      case CapiHat.coroaEstrelas:
        // A glowing gold crown topped with stars.
        _glow(canvas, const Offset(50, 12), 30, 14, const Color(0x55FFE066));
        final band = RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 17, 52, 9),
          const Radius.circular(3),
        );
        canvas.drawRRect(
          band,
          _ball(band.outerRect, const [Color(0xFFFFF3BF), Color(0xFFE0A100)]),
        );
        canvas.drawRRect(band, _outline);
        final twinkle = 1 + sin(t * 2 * pi * 2) * 0.12;
        for (final (x, y, r) in [
          (30.0, 13.0, 5.0),
          (50.0, 7.0, 7.5),
          (70.0, 13.0, 5.0),
        ]) {
          final star = _star(Offset(x, y), r * twinkle);
          canvas.drawPath(star, _fill(const Color(0xFFFFD43B)));
          canvas.drawPath(star, _line..color = const Color(0xFFB8860B));
        }
        for (final x in [36.0, 50.0, 64.0]) {
          canvas.drawCircle(
            Offset(x, 21.5),
            1.8,
            _fill(const Color(0xFF74C0FC)),
          );
        }
      case CapiHat.gorroNatal:
        // A red Santa hat flopping to the side, white cuff and pompom.
        final gorro = Path()
          ..moveTo(23, 25)
          ..cubicTo(24, 6, 48, -2, 66, 4)
          ..cubicTo(76, 7, 84, 14, 86, 22)
          ..lineTo(80, 24)
          ..cubicTo(77, 18, 74, 15, 72, 14)
          ..cubicTo(76, 18, 77, 22, 77, 25)
          ..close();
        _shape(canvas, gorro, const Color(0xFFFF6B6B), const Color(0xFFC92A2A));
        final cuff = RRect.fromRectAndRadius(
          const Rect.fromLTWH(19, 20, 62, 9),
          const Radius.circular(4.5),
        );
        canvas.drawRRect(
          cuff,
          _ball(cuff.outerRect, const [Color(0xFFFFFFFF), Color(0xFFDDE3EA)]),
        );
        canvas.drawRRect(cuff, _outline);
        canvas.drawCircle(
          const Offset(84, 25),
          5.5,
          _ball(
            Rect.fromCircle(center: const Offset(84, 25), radius: 5.5),
            const [Color(0xFFFFFFFF), Color(0xFFD0D7E2)],
          ),
        );
      case CapiHat.chifresRena:
        // Brown antlers on a headband, with a little jingle bell.
        final antler = Paint()
          ..color = const Color(0xFF8B5A2B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        for (final sx in [-1.0, 1.0]) {
          double x(double d) => 50 + sx * d;
          canvas.drawPath(
            Path()
              ..moveTo(x(14), 21)
              ..quadraticBezierTo(x(18), 10, x(26), 3)
              ..moveTo(x(17), 13)
              ..lineTo(x(26), 12)
              ..moveTo(x(21), 7)
              ..lineTo(x(18), 1),
            antler,
          );
        }
        final band = Path()
          ..moveTo(24, 25)
          ..quadraticBezierTo(50, 12, 76, 25);
        canvas.drawPath(
          band,
          Paint()
            ..color = const Color(0xFFC92A2A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          const Offset(50, 18),
          3.2,
          _ball(
            Rect.fromCircle(center: const Offset(50, 18), radius: 3.2),
            const [Color(0xFFFFF3BF), Color(0xFFE0A100)],
          ),
        );
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(CapiPainter old) =>
      old.t != t || old.mood != mood || old.hat != hat || old.look != look;
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
    this.secondary,
    this.onSecondary,
  });

  final String text;
  final CapiMood mood;
  final double capiSize;

  /// Optional button inside the bubble ("Bora!").
  final String? action;
  final VoidCallback? onAction;

  /// Optional smaller second choice under the button.
  final String? secondary;
  final VoidCallback? onSecondary;

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
                  if (secondary != null)
                    TextButton(
                      onPressed: onSecondary,
                      child: Text(
                        secondary!,
                        style: displayText(15, color: const Color(0xFF5B3FA0)),
                      ),
                    ),
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

/// Fur colors for each coat (the "pelagem" slot).
class _Coat {
  const _Coat(this.fur, this.ear, this.feet, this.muzzle);
  final List<Color> fur;
  final List<Color> ear;
  final List<Color> feet;
  final List<Color> muzzle;

  static _Coat of(String id) => switch (id) {
    'chocolate' => const _Coat(
      [Color(0xFFC9997A), Color(0xFF8B5A3C), Color(0xFF5A3520)],
      [Color(0xFF8B5A3C), Color(0xFF4A2A18)],
      [Color(0xFF7A4A2E), Color(0xFF4A2A18)],
      [Color(0xFFA8754F), Color(0xFF7E4E30), Color(0xFF5A3520)],
    ),
    'neve' => const _Coat(
      [Color(0xFFFFFFFF), Color(0xFFEEE6DC), Color(0xFFC9BCAE)],
      [Color(0xFFEEE6DC), Color(0xFFB8A898)],
      [Color(0xFFE0D4C6), Color(0xFFA89888)],
      [Color(0xFFF5EDE4), Color(0xFFDCCFC0), Color(0xFFB8A898)],
    ),
    'dourado' => const _Coat(
      [Color(0xFFFFF0B0), Color(0xFFF2C14E), Color(0xFFB8860B)],
      [Color(0xFFF2C14E), Color(0xFFA0741A)],
      [Color(0xFFE0A830), Color(0xFF9A6A10)],
      [Color(0xFFF7D27A), Color(0xFFD9A23A), Color(0xFFA0741A)],
    ),
    'galaxia' => const _Coat(
      [Color(0xFF9775FA), Color(0xFF4C3FA6), Color(0xFF1B1F4A)],
      [Color(0xFF5F3DC4), Color(0xFF1B1F4A)],
      [Color(0xFF4C3FA6), Color(0xFF1B1F4A)],
      [Color(0xFFB197FC), Color(0xFF7048E8), Color(0xFF3B2A8C)],
    ),
    'arco_iris' => const _Coat(
      [Color(0xFFFFE0F0), Color(0xFFC9B8FF), Color(0xFF7FB8F0)],
      [Color(0xFFFFB3D9), Color(0xFFB18CFF)],
      [Color(0xFF9AD8FF), Color(0xFF6AA8E8)],
      [Color(0xFFFFE6A8), Color(0xFFFFC27A), Color(0xFFE09A50)],
    ),
    _ => const _Coat(
      [Color(0xFFF6D3A6), Color(0xFFD9A06A), Color(0xFFA66C3C)],
      [Color(0xFFD9A06A), Color(0xFF8E5A30)],
      [Color(0xFFC08350), Color(0xFF8E5A30)],
      [Color(0xFFD7A06A), Color(0xFFB27843), Color(0xFF8C5A30)],
    ),
  };
}
