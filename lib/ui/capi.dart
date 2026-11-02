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

  static const _line = Color(0xFF4A2A12);
  static const _furTop = Color(0xFFD69E66);
  static const _furBottom = Color(0xFFB07A47);
  static const _bodyTop = Color(0xFFCF975F);
  static const _bodyBottom = Color(0xFF9E673A);
  static const _arm = Color(0xFFA56C3C);
  static const _dark = Color(0xFF8E5A30);
  static const _ink = Color(0xFF2A1A0E);
  static const _helmetTop = Color(0xFFFFD95A);
  static const _helmetBottom = Color(0xFFF5B21E);

  static final _outline = Paint()
    ..color = _line
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
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

  void _limb(Canvas canvas, Path path) {
    canvas.drawPath(
      path,
      Paint()
        ..color = _line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _arm
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paw(Canvas canvas, Offset c) {
    final r = Rect.fromCenter(center: c, width: 6.4, height: 6.8);
    canvas.drawOval(r, Paint()..color = _dark);
    canvas.drawOval(r, _outline);
  }

  void _block(Canvas canvas, Rect r) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(2.9));
    canvas.drawRRect(
      rr.shift(const Offset(0, 1)),
      Paint()..color = const Color(0xFFC9582B),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB56B), Color(0xFFFF8A3D)],
        ).createShader(r),
    );
    canvas.drawRRect(rr, _outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + 2.3, r.top + 1.8, r.width - 4.6, 2.9),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0x73FFFFFF),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Everything is drawn on a 100x100 grid (the art's 1024 grid / 10.24).
    canvas.scale(size.width / 100);
    final bob = sin(t * 2 * pi) * 1.4;
    final cheer = mood == CapiMood.cheer;
    final worried = mood == CapiMood.worried;
    final sad = mood == CapiMood.sad;
    final armsUp = cheer || mood == CapiMood.carry;
    final holdsBlock = mood == CapiMood.happy || worried;

    // Shadow and feet.
    canvas.drawOval(
      const Rect.fromLTWH(24.4, 90.3, 51.2, 5.9),
      Paint()..color = const Color(0x2E000000),
    );
    for (final x in [32.2, 53.1]) {
      final r = Rect.fromLTWH(x, 86, 14.6, 7.8);
      canvas.drawOval(r, Paint()..color = const Color(0xFF7A4C26));
      canvas.drawOval(r, _outline);
    }

    // Body and belly.
    _shape(
      canvas,
      Path()
        ..moveTo(29.3, 74.2)
        ..cubicTo(29.3, 58.6, 39.1, 52.7, 50, 52.7)
        ..cubicTo(60.9, 52.7, 70.7, 58.6, 70.7, 74.2)
        ..cubicTo(70.7, 85.9, 62.5, 90.8, 50, 90.8)
        ..cubicTo(37.5, 90.8, 29.3, 85.9, 29.3, 74.2)
        ..close(),
      _bodyTop,
      _bodyBottom,
    );
    canvas.drawOval(
      const Rect.fromLTWH(38.3, 62.5, 23.4, 24.4),
      Paint()..color = const Color(0xFFE8C496),
    );

    // Arms (and the block he holds), before the head so the shoulders tuck
    // under it.
    if (armsUp) {
      // Cheering: arms out and up. Carrying: straight up past the helmet,
      // paws where the load sits (y 4).
      final up = cheer ? bob : 0.0;
      final carry = mood == CapiMood.carry;
      final reach = carry ? 5.0 : 46 + up;
      final side = carry ? 20.0 : 17.0;
      _limb(
        canvas,
        Path()
          ..moveTo(33, 63)
          ..quadraticBezierTo(16, 50, side, reach),
      );
      _limb(
        canvas,
        Path()
          ..moveTo(67, 63)
          ..quadraticBezierTo(84, 50, 100 - side, reach),
      );
      _paw(canvas, Offset(side, reach - 1));
      _paw(canvas, Offset(100 - side, reach - 1));
    } else if (holdsBlock) {
      _block(canvas, const Rect.fromLTWH(41.2, 62.5, 17.6, 16.8));
      _limb(
        canvas,
        Path()
          ..moveTo(33, 63.5)
          ..quadraticBezierTo(35.2, 72.3, 42.2, 72.5),
      );
      _limb(
        canvas,
        Path()
          ..moveTo(67, 63.5)
          ..quadraticBezierTo(64.8, 72.3, 57.8, 72.5),
      );
      _paw(canvas, const Offset(42.7, 72.5));
      _paw(canvas, const Offset(57.3, 72.5));
    } else if (mood == CapiMood.point) {
      _limb(
        canvas,
        Path()
          ..moveTo(33, 63.5)
          ..quadraticBezierTo(30, 72, 31, 80),
      );
      _limb(
        canvas,
        Path()
          ..moveTo(67, 63)
          ..quadraticBezierTo(78, 58, 88, 50 + bob),
      );
      _paw(canvas, const Offset(31, 80));
      _paw(canvas, Offset(89, 49 + bob));
    } else {
      // Sad: arms hanging down.
      for (final (a, b) in [
        (const Offset(33, 63.5), const Offset(31, 81)),
        (const Offset(67, 63.5), const Offset(69, 81)),
      ]) {
        _limb(
          canvas,
          Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy),
        );
        _paw(canvas, b);
      }
    }

    canvas.save();
    canvas.translate(0, bob);

    // Ears, head, snout.
    for (final x in [21.7, 66.6]) {
      final r = Rect.fromLTWH(x, 19.1, 11.7, 9.8);
      canvas.drawOval(r, Paint()..color = _dark);
      canvas.drawOval(r, _outline);
      canvas.drawOval(
        Rect.fromLTWH(x + 2.5, 21.7, 6.4, 5.1),
        Paint()..color = const Color(0xFFE59A8E),
      );
    }
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(20.5, 20.5, 59, 40),
          const Radius.circular(19.5),
        ),
      ),
      _furTop,
      _furBottom,
    );
    _shape(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(32.2, 40, 35.5, 21.5),
          const Radius.circular(10.3),
        ),
      ),
      const Color(0xFFA87446),
      const Color(0xFF8A5A32),
    );
    final ink = Paint()..color = const Color(0xFF3A2414);
    canvas.drawOval(const Rect.fromLTWH(41, 43, 4.9, 3.3), ink);
    canvas.drawOval(const Rect.fromLTWH(54.1, 43, 4.9, 3.3), ink);

    // Mouth (with the two front teeth when smiling).
    final stroke = Paint()
      ..color = const Color(0xFF3A2414)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    if (worried) {
      canvas.drawOval(const Rect.fromLTWH(46.8, 52.5, 6.4, 5.5), ink);
    } else if (sad) {
      canvas.drawPath(
        Path()
          ..moveTo(44, 57)
          ..quadraticBezierTo(50, 51.5, 56, 57),
        stroke,
      );
    } else {
      final open = cheer ? 3.0 : 0.0;
      canvas.drawPath(
        Path()
          ..moveTo(43, 52.7)
          ..quadraticBezierTo(50, 58.6 + open, 57, 52.7),
        stroke,
      );
      final teeth = RRect.fromRectAndRadius(
        Rect.fromLTWH(47.9, 54.4 + open / 2, 4.3, 3.3),
        const Radius.circular(0.8),
      );
      canvas.drawRRect(teeth, Paint()..color = Colors.white);
    }

    // Eyes.
    if (cheer) {
      for (final x in [32.2, 60.9]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, 34)
            ..quadraticBezierTo(x + 3.4, 28, x + 6.8, 34),
          stroke..strokeWidth = 2,
        );
      }
    } else if (sad) {
      for (final x in [32.2, 60.9]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, 32)
            ..quadraticBezierTo(x + 3.4, 36, x + 6.8, 32),
          stroke..strokeWidth = 2,
        );
      }
    } else {
      if (worried) {
        // Raised, slanted brows and a drop of sweat.
        canvas.drawLine(const Offset(31, 27), const Offset(39, 25), stroke);
        canvas.drawLine(const Offset(61, 25), const Offset(69, 27), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(84, 30)
            ..quadraticBezierTo(80, 38, 84, 40)
            ..quadraticBezierTo(88, 38, 84, 30),
          Paint()..color = const Color(0xFF7FD3FF),
        );
      }
      final blink = t > 0.94;
      for (final x in [32.2, 60.9]) {
        if (blink) {
          canvas.drawLine(Offset(x, 33.3), Offset(x + 6.8, 33.3), stroke);
        } else {
          canvas.drawOval(
            Rect.fromLTWH(x, 29.3, 6.8, 8),
            Paint()..color = _ink,
          );
          canvas.drawCircle(
            Offset(x + 3.4, 31.7),
            1.3,
            Paint()..color = Colors.white,
          );
        }
      }
    }
    final blush = Paint()..color = const Color(0x73FF7A8A);
    canvas.drawOval(const Rect.fromLTWH(24.4, 39, 7.8, 4.5), blush);
    canvas.drawOval(const Rect.fromLTWH(67.8, 39, 7.8, 4.5), blush);

    // Equipped Hat.
    _drawHat(canvas, hat);
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
