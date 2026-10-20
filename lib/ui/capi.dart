import 'dart:math';

import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';
import 'widgets.dart';

enum CapiMood { happy, cheer }

/// Capi, the builder capybara: the game's mascot. Drawn in code (a first
/// version until the final art), with a gentle idle bob.
class Capi extends StatefulWidget {
  const Capi({super.key, this.size = 80, this.mood = CapiMood.happy});
  final double size;
  final CapiMood mood;

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
        painter: CapiPainter(mood: widget.mood, t: _bob.value),
      ),
    ),
  );
}

class CapiPainter extends CustomPainter {
  CapiPainter({required this.mood, required this.t});
  final CapiMood mood;

  /// Idle animation phase, 0..1.
  final double t;

  static const _fur = Color(0xFFB9824F);
  static const _furDark = Color(0xFF8E5D34);
  static const _snout = Color(0xFF9A6A40);
  static const _ink = Color(0xFF3A2414);
  static const _helmet = Color(0xFFFFC93C);

  @override
  void paint(Canvas canvas, Size size) {
    // Everything is drawn on a 100x100 grid.
    canvas.scale(size.width / 100);
    final bob = sin(t * 2 * pi) * 1.6;
    final cheer = mood == CapiMood.cheer;

    // Shadow.
    canvas.drawOval(
      const Rect.fromLTWH(18, 90, 64, 8),
      Paint()..color = const Color(0x33000000),
    );

    // Body, with little arms (raised when cheering).
    final body = Paint()..color = _fur;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 60, 56, 34),
        const Radius.circular(20),
      ),
      body,
    );
    canvas.drawOval(
      const Rect.fromLTWH(36, 70, 28, 20),
      Paint()..color = Palette.lighten(_fur, 0.25),
    );
    final arm = Paint()
      ..color = _furDark
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    if (cheer) {
      canvas.drawLine(const Offset(26, 66), Offset(14, 50 + bob), arm);
      canvas.drawLine(const Offset(74, 66), Offset(86, 50 + bob), arm);
    } else {
      canvas.drawLine(const Offset(27, 70), const Offset(22, 84), arm);
      canvas.drawLine(const Offset(73, 70), const Offset(78, 84), arm);
    }

    canvas.save();
    canvas.translate(0, bob);

    // Ears.
    final ear = Paint()..color = _furDark;
    canvas.drawOval(const Rect.fromLTWH(18, 22, 13, 11), ear);
    canvas.drawOval(const Rect.fromLTWH(69, 22, 13, 11), ear);

    // Head: a wide rounded box, the capybara look.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 24, 64, 44),
        const Radius.circular(22),
      ),
      body,
    );
    // Snout.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 44, 40, 24),
        const Radius.circular(12),
      ),
      Paint()..color = _snout,
    );
    final ink = Paint()..color = _ink;
    canvas.drawOval(const Rect.fromLTWH(40, 47, 6, 4), ink);
    canvas.drawOval(const Rect.fromLTWH(54, 47, 6, 4), ink);
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(43, cheer ? 57 : 58)
        ..quadraticBezierTo(50, cheer ? 66 : 63, 57, cheer ? 57 : 58),
      line,
    );

    // Eyes: dots with a shine, or happy arcs when cheering.
    if (cheer) {
      for (final x in [33.0, 61.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, 40)
            ..quadraticBezierTo(x + 3.5, 34, x + 7, 40),
          line..strokeWidth = 2.6,
        );
      }
    } else {
      final blink = t > 0.94;
      for (final x in [36.5, 63.5]) {
        if (blink) {
          canvas.drawLine(Offset(x - 3, 38), Offset(x + 3, 38), line);
        } else {
          canvas.drawCircle(Offset(x, 38), 3.6, ink);
          canvas.drawCircle(
            Offset(x + 1.2, 36.8),
            1.2,
            Paint()..color = Colors.white,
          );
        }
      }
    }
    final blush = Paint()..color = const Color(0x55FF7A8A);
    canvas.drawOval(const Rect.fromLTWH(24, 44, 9, 5), blush);
    canvas.drawOval(const Rect.fromLTWH(67, 44, 9, 5), blush);

    // Builder's helmet.
    canvas.drawPath(
      Path()
        ..moveTo(26, 28)
        ..cubicTo(26, 4, 74, 4, 74, 28)
        ..close(),
      Paint()..color = _helmet,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 25, 60, 6),
        const Radius.circular(3),
      ),
      Paint()..color = Palette.darken(_helmet, 0.12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(46, 9, 8, 17),
        const Radius.circular(3),
      ),
      Paint()..color = Palette.lighten(_helmet, 0.3),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CapiPainter old) => old.t != t || old.mood != mood;
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
