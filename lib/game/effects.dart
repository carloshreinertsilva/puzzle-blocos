import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../ui/block_painter.dart';
import '../ui/palette.dart';

double easeOutBack(double t) {
  const c1 = 1.70158, c3 = c1 + 1;
  return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
}

double easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();

/// A cleared cell: waits [delay], then shrinks, spins a little and fades.
class VanishingCell extends PositionComponent {
  VanishingCell({
    required this.image,
    required Rect rect,
    required this.delay,
    this.overlay,
  }) : super(
         position: Vector2(rect.center.dx, rect.center.dy),
         size: Vector2(rect.width, rect.height),
         anchor: Anchor.center,
       );

  final BlockArt image;
  final BlockArt? overlay;
  final double delay;
  double _t = 0;
  static const duration = 0.32;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > delay + duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = ((_t - delay) / duration).clamp(0.0, 1.0);
    final scale = p < 0.25
        ? 1 + p * 0.5
        : 1.125 * (1 - easeOutCubic((p - 0.25) / 0.75));
    if (scale <= 0.01) return;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(p * 0.6);
    canvas.scale(scale);
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    final alpha = 1 - p * 0.6;
    image.draw(canvas, dst, opacity: alpha);
    overlay?.draw(canvas, dst, opacity: alpha);
    // White flash at the start.
    if (p < 0.3) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          dst.deflate(size.x * 0.05),
          Radius.circular(size.x * 0.16),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.7 * (1 - p / 0.3)),
      );
    }
    canvas.restore();
  }
}

class _Particle {
  _Particle(this.pos, this.vel, this.color, this.size, this.life, this.spin);
  Offset pos;
  Offset vel;
  final Color color;
  final double size;
  final double life;
  final double spin;
  double age = 0;
}

/// Little squares that fly out of cleared cells and fall with gravity.
class Sparks extends Component {
  Sparks(this.cellSize);

  final double cellSize;
  final _rng = Random();
  final _particles = <_Particle>[];

  void burst(Offset at, Color color, {int count = 5, double delay = 0}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = cellSize * (2.5 + _rng.nextDouble() * 4);
      _particles.add(
        _Particle(
          at,
          Offset(cos(angle) * speed, sin(angle) * speed - cellSize * 3),
          i.isEven ? color : Palette.lighten(color, 0.5),
          cellSize * (0.12 + _rng.nextDouble() * 0.14),
          0.55 + _rng.nextDouble() * 0.35,
          (_rng.nextDouble() - 0.5) * 12,
        )..age = -delay,
      );
    }
  }

  @override
  void update(double dt) {
    final gravity = cellSize * 22;
    for (final p in _particles) {
      p.age += dt;
      if (p.age < 0) continue;
      p.vel = Offset(p.vel.dx * 0.985, p.vel.dy + gravity * dt);
      p.pos += p.vel * dt;
    }
    _particles.removeWhere((p) => p.age > p.life);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (final p in _particles) {
      if (p.age < 0) continue;
      final t = p.age / p.life;
      paint.color = p.color.withValues(alpha: 1 - t * t);
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.age * p.spin);
      final s = p.size * (1 - t * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          Radius.circular(s * 0.25),
        ),
        paint,
      );
      canvas.restore();
    }
  }
}

/// Text that pops in, floats up and fades ("+120", "Combo x3!").
class PopText extends PositionComponent {
  PopText(
    this.text, {
    required Vector2 position,
    required this.fontSize,
    this.color = Palette.text,
    this.rise = 60,
    this.life = 0.9,
    this.delay = 0,
  }) : super(position: position, anchor: Anchor.center);

  final String text;
  final double fontSize;
  final Color color;
  final double rise;
  final double life;
  final double delay;
  double _t = 0;
  late final TextPainter _fill = _painter(false);
  late final TextPainter _stroke = _painter(true);

  TextPainter _painter(bool stroke) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        foreground: stroke
            ? (Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * 0.16
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xCC1A1240))
            : (Paint()..color = color),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void update(double dt) {
    _t += dt;
    if (_t > delay + life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = ((_t - delay) / life).clamp(0.0, 1.0);
    if (_t < delay) return;
    final pop = t < 0.2 ? easeOutBack(t / 0.2) : 1.0;
    final alpha = t > 0.7 ? 1 - (t - 0.7) / 0.3 : 1.0;
    canvas.save();
    canvas.translate(0, -rise * easeOutCubic(t));
    canvas.scale(pop);
    final offset = Offset(-_fill.width / 2, -_fill.height / 2);
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    _stroke.paint(canvas, offset);
    _fill.paint(canvas, offset);
    canvas.restore();
    canvas.restore();
  }
}
