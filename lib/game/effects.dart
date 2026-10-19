import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../ui/block_painter.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';

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
  _Particle(
    this.pos,
    this.vel,
    this.color,
    this.size,
    this.life,
    this.spin, {
    this.gravity = 1,
    this.flat = false,
  });
  Offset pos;
  Offset vel;
  final Color color;
  final double size;
  final double life;
  final double spin;
  final double gravity;

  /// Confetti: a thin strip that flutters instead of a square.
  final bool flat;
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

  /// Confetti raining over [area] for the biggest moments.
  void confetti(Rect area, {int count = 40}) {
    for (var i = 0; i < count; i++) {
      final x = area.left + _rng.nextDouble() * area.width;
      final y = area.top - _rng.nextDouble() * area.height * 0.3;
      _particles.add(
        _Particle(
          Offset(x, y),
          Offset(
            (_rng.nextDouble() - 0.5) * cellSize * 3,
            -cellSize * (2 + _rng.nextDouble() * 4),
          ),
          Palette.blocks[_rng.nextInt(Palette.blocks.length)],
          cellSize * (0.22 + _rng.nextDouble() * 0.12),
          1.4 + _rng.nextDouble() * 0.8,
          (_rng.nextDouble() - 0.5) * 16,
          gravity: 0.35,
          flat: true,
        )..age = -_rng.nextDouble() * 0.25,
      );
    }
  }

  @override
  void update(double dt) {
    final gravity = cellSize * 22;
    for (final p in _particles) {
      p.age += dt;
      if (p.age < 0) continue;
      final drag = p.flat ? 0.96 : 0.985;
      p.vel = Offset(p.vel.dx * drag, p.vel.dy + gravity * p.gravity * dt);
      p.pos += p.vel * dt;
      if (p.flat) p.pos += Offset(sin(p.age * 9 + p.spin) * cellSize * 0.04, 0);
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
      final s = p.size * (p.flat ? 1 : 1 - t * 0.5);
      // Confetti strips flip as they fall.
      final h = p.flat ? s * 0.45 * cos(p.age * 7 + p.spin).abs() + 1 : s;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s, height: h),
          Radius.circular(s * 0.2),
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
        fontFamily: Fonts.display,
        fontSize: fontSize,
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

/// How a clear is celebrated, from a simple "Boa!" to "Lendário!".
class Praise {
  const Praise(this.tier, this.text, this.colors);

  /// 1 = one line, 2 = two lines, 3 = three, 4 = four or more (or a big
  /// combo / a cleared board).
  final int tier;
  final String text;
  final List<Color> colors;

  static const _words = [
    ['Boa!', 'Muito bem!', 'Mandou bem!', 'Legal!'],
    ['Ótimo!', 'Incrível!', 'Show!', 'Demais!'],
    ['Espetacular!', 'Fantástico!', 'Sensacional!'],
    ['Lendário!', 'Inacreditável!', 'Imbatível!'],
  ];

  static const _colors = [
    [Color(0xFFFFFFFF), Color(0xFFFFD43B)],
    [Color(0xFFB8F7FF), Color(0xFF22B8CF), Color(0xFF4C6EF5)],
    [Color(0xFFFFE3A3), Color(0xFFFF8A3D), Color(0xFFFF4D8D)],
    [
      Color(0xFFFF6B6B),
      Color(0xFFFFD43B),
      Color(0xFF51CF66),
      Color(0xFF22B8CF),
      Color(0xFFB05CF5),
    ],
  ];

  static Praise forClear({
    required int lines,
    required int combo,
    required bool boardCleared,
    required Random rng,
  }) {
    var tier = lines.clamp(1, 4);
    if (combo >= 4) tier = min(4, tier + 1);
    if (boardCleared) {
      return Praise(4, 'Tabuleiro limpo!', _colors[3]);
    }
    final words = _words[tier - 1];
    return Praise(tier, words[rng.nextInt(words.length)], _colors[tier - 1]);
  }
}

/// The big word in the middle of the board. Letters pop in one after the
/// other with a bounce, hold, then the word floats up and fades.
class PraiseBanner extends PositionComponent {
  PraiseBanner(
    this.praise, {
    required Vector2 position,
    required double cellSize,
    this.subtitle,
    this.hold = 0,
    this.maxWidth = double.infinity,
  }) : fontSize = cellSize * (0.95 + 0.17 * praise.tier),
       super(position: position, anchor: Anchor.center);

  final Praise praise;
  final String? subtitle;
  final double fontSize;

  /// Extra seconds on screen (used for the level-start banner).
  final double hold;

  /// Long words shrink to fit this width (the board's).
  final double maxWidth;
  double _t = 0;

  double get life => 1.15 + praise.tier * 0.12 + hold;

  late final List<(TextPainter, TextPainter, TextPainter)> _letters = [
    for (final (i, ch) in praise.text.characters.indexed) _letter(ch, i),
  ];
  late final double _width = _letters.fold(0.0, (w, l) => w + l.$1.width);
  late final TextPainter? _sub = subtitle == null
      ? null
      : (TextPainter(
          text: TextSpan(
            text: subtitle,
            style: TextStyle(
              fontFamily: Fonts.display,
              fontSize: fontSize * 0.42,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Color(0xCC1A1240),
                  blurRadius: 0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: fontSize * 9));

  (TextPainter, TextPainter, TextPainter) _letter(String ch, int index) {
    TextPainter make(Paint paint) => TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          fontFamily: Fonts.display,
          fontSize: fontSize,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final h = fontSize * 1.2;
    // The top tier gives each letter the next block color.
    final rainbow = praise.tier >= 4;
    final c = praise.colors[index % praise.colors.length];
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: rainbow
            ? [Palette.lighten(c, 0.55), c]
            : praise.colors.length > 2
            ? [Colors.white, ...praise.colors.take(2)]
            : praise.colors,
      ).createShader(Rect.fromLTWH(0, 0, fontSize, h));
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fontSize * 0.2
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2A1458);
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fontSize * 0.2
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0x66000000);
    return (make(fill), make(outline), make(shadow));
  }

  @override
  void update(double dt) {
    _t += dt;
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _t / life;
    final out = t > 0.78 ? (t - 0.78) / 0.22 : 0.0;
    final alpha = (1 - out).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(0, -fontSize * 0.8 * easeOutCubic(out));
    canvas.scale(
      (1 + out * 0.15) * min(1.0, maxWidth / (_width + fontSize * 0.4)),
    );
    if (alpha < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }

    var x = -_width / 2;
    for (var i = 0; i < _letters.length; i++) {
      final (fill, outline, shadow) = _letters[i];
      final local = ((_t - i * 0.035) / 0.28).clamp(0.0, 1.0);
      if (local > 0) {
        final s = easeOutBack(local);
        // Gentle wave while the word is on screen.
        final wave = sin(_t * 6 + i * 0.6) * fontSize * 0.04;
        canvas.save();
        canvas.translate(x + fill.width / 2, wave);
        canvas.scale(s);
        canvas.rotate((1 - local) * -0.4);
        final o = Offset(-fill.width / 2, -fill.height / 2);
        shadow.paint(canvas, o + Offset(0, fontSize * 0.09));
        outline.paint(canvas, o);
        fill.paint(canvas, o);
        canvas.restore();
      }
      x += fill.width;
    }

    final sub = _sub;
    if (sub != null && _t > 0.25) {
      final st = ((_t - 0.25) / 0.2).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(0, fontSize * 0.85);
      canvas.scale(easeOutBack(st));
      sub.paint(canvas, Offset(-sub.width / 2, -sub.height / 2));
      canvas.restore();
    }

    if (alpha < 1) canvas.restore();
    canvas.restore();
  }
}

/// Rotating rays of light behind the praise word.
class LightBurst extends PositionComponent {
  LightBurst({
    required Vector2 position,
    required this.radius,
    required this.color,
    this.life = 1.2,
  }) : super(position: position, anchor: Anchor.center);

  final double radius;
  final Color color;
  final double life;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _t / life;
    final grow = easeOutCubic((t / 0.3).clamp(0.0, 1.0));
    final alpha = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
    final r = radius * grow;
    if (r <= 1) return;
    canvas.save();
    canvas.rotate(_t * 0.8);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.55 * alpha),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    const rays = 12;
    final path = Path();
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * pi / rays;
      path
        ..moveTo(0, 0)
        ..lineTo(cos(a - 0.11) * r, sin(a - 0.11) * r)
        ..lineTo(cos(a + 0.11) * r, sin(a + 0.11) * r)
        ..close();
    }
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset.zero,
      r * 0.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.35 * alpha),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 0.35)),
    );
    canvas.restore();
  }
}

/// A quick white flash over the whole screen.
class ScreenFlash extends Component {
  ScreenFlash(this.area, {this.strength = 0.35});

  final Rect area;
  final double strength;
  double _t = 0;
  static const life = 0.3;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = strength * (1 - _t / life);
    if (a <= 0) return;
    canvas.drawRect(area, Paint()..color = Colors.white.withValues(alpha: a));
  }
}
