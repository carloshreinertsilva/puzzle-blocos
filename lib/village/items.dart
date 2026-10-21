import 'dart:math';
import 'dart:ui';

import '../ui/palette.dart';
import 'iso.dart';

/// How one village item is drawn. [paint] draws the item itself; items that
/// aren't [animated] get it recorded once and replayed, with [overlay] (smoke,
/// glow, water) drawn on top every frame.
abstract class ItemArt {
  const ItemArt();

  /// Height above the ground, in world units (for hit tests and icons).
  double get height;
  bool get animated => false;

  void paint(IsoCanvas c, Rect s, double t);
  void overlay(IsoCanvas c, Rect s, double t) {}
}

/// The water level of the lagoon, a little below the grass.
const waterZ = -0.16;

const _wood = Color(0xFFC88A4E);
const _woodDark = Color(0xFF8E5732);
const _soil = Color(0xFF6B4226);
const _stone = Color(0xFFBDB8CF);
const _paint = Color(0xFFF7F0E2);
const _metal = Color(0xFF444B70);
const _leaf = Color(0xFF4DAA45);
const _water = Color(0xFF59C7EA);

final Map<String, ItemArt> itemArt = {
  'flores': const _Flowers(),
  'cerca': const _Fence(),
  'banco': const _Bench(),
  'arvore': const _Tree(),
  'barco': const _Boat(),
  'horta': const _Garden(),
  'poste': const _Lamp(),
  'pier': const _Pier(),
  'casinha': const _House(),
  'balanco': const _Swing(),
  'fonte': const _Fountain(),
  'roda': const _FerrisWheel(),
};

/// A five-petal flower head.
void _flower(Canvas canvas, Offset at, double size, Color petal) {
  final paint = Paint()..color = petal;
  final rim = Paint()
    ..color = dark(petal, 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.18;
  for (var k = 0; k < 5; k++) {
    final a = k * 2 * pi / 5 - pi / 2;
    final c = at + Offset(cos(a), sin(a)) * size;
    canvas.drawCircle(c, size * 0.85, rim);
    canvas.drawCircle(c, size * 0.85, paint);
  }
  canvas.drawCircle(at, size * 0.6, Paint()..color = const Color(0xFFFFB300));
  canvas.drawCircle(
    at + Offset(-size * 0.2, -size * 0.2),
    size * 0.22,
    Paint()..color = const Color(0xFFFFF3C4),
  );
}

/// Plank seams along a box face, from a to b at the given heights.
void _seams(IsoCanvas c, P3 a, P3 b, List<double> zs, Color color) {
  for (final z in zs) {
    c.canvas.drawLine(
      c.p(a.$1, a.$2, z),
      c.p(b.$1, b.$2, z),
      Paint()
        ..color = color
        ..strokeWidth = c.tile * 0.016,
    );
  }
}

class _Flowers extends ItemArt {
  const _Flowers();
  @override
  double get height => 1.1;
  @override
  bool get animated => true;

  static const _colors = [
    Color(0xFFFF7EB6),
    Color(0xFFFFD43B),
    Color(0xFFB57CF7),
    Color(0xFFFF6B6B),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    const h = 0.42;
    c.boxShadow(s.left, s.top, s.width, s.height, 0.6);
    c.box(s.left, s.top, 0, s.width, s.height, h, _wood, top: _soil);
    final seam = dark(_wood, 0.4).withValues(alpha: 0.7);
    _seams(c, (s.left, s.bottom, 0), (s.right, s.bottom, 0), [
      0.14,
      0.28,
    ], seam);
    _seams(c, (s.right, s.top, 0), (s.right, s.bottom, 0), [0.14, 0.28], seam);

    final tile = c.tile;
    final stem = Paint()
      ..color = const Color(0xFF3E8E3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tile * 0.035
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final fx = s.left + 0.22 + (i % 2) * 0.36;
      final fy = s.top + 0.18 + (i ~/ 2) * 0.38 + (i % 2) * 0.14;
      final base = c.p(fx, fy, h);
      final sway = sin(t * 2.1 + i * 1.7) * tile * 0.05;
      final head = c.p(fx, fy, h + 0.42 + 0.07 * (i % 3)) + Offset(sway, 0);
      c.canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            base.dx,
            (base.dy + head.dy) / 2,
            head.dx,
            head.dy,
          ),
        stem,
      );
      final leafAt = Offset.lerp(base, head, 0.45)!;
      c.canvas.drawOval(
        Rect.fromCenter(
          center: leafAt + Offset(tile * 0.06, 0),
          width: tile * 0.13,
          height: tile * 0.06,
        ),
        Paint()..color = const Color(0xFF5DBB4C),
      );
      _flower(c.canvas, head, tile * 0.07, _colors[i % _colors.length]);
    }

    // Two butterflies flutter around the bed.
    for (var k = 0; k < 2; k++) {
      final center =
          c.p(s.center.dx, s.center.dy, 1.15 + 0.25 * sin(t * 1.3 + k * 2)) +
          Offset(
            cos(t * 0.8 + k * 3) * tile * 0.75,
            sin(t * 1.6 + k) * tile * 0.25,
          );
      final flap = 0.25 + 0.75 * sin(t * 15 + k).abs();
      final wing = Paint()
        ..color = k == 0 ? const Color(0xFFFFA94D) : const Color(0xFF74C0FC);
      for (final side in [-1.0, 1.0]) {
        c.canvas.drawOval(
          Rect.fromCenter(
            center: center + Offset(side * tile * 0.07 * flap, -tile * 0.03),
            width: tile * 0.14 * flap,
            height: tile * 0.12,
          ),
          wing,
        );
        c.canvas.drawOval(
          Rect.fromCenter(
            center: center + Offset(side * tile * 0.05 * flap, tile * 0.04),
            width: tile * 0.1 * flap,
            height: tile * 0.08,
          ),
          wing,
        );
      }
      c.canvas.drawLine(
        center + Offset(0, -tile * 0.05),
        center + Offset(0, tile * 0.06),
        Paint()
          ..color = const Color(0xFF3B2A1A)
          ..strokeWidth = tile * 0.03
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

class _Fence extends ItemArt {
  const _Fence();
  @override
  double get height => 1;

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    final y0 = s.top + 0.05;
    c.boxShadow(s.left, y0, s.width, 0.12, 0.9, 0.2);
    for (final z in [0.24, 0.56]) {
      c.box(s.left, y0, z, s.width, 0.05, 0.08, dark(_paint, 0.06));
    }
    for (var px = s.left + 0.04; px < s.right - 0.12; px += 0.4) {
      const y = 0.04, d = 0.09, h = 0.78;
      c.box(px, y0 + y, 0, 0.16, d, h, _paint);
      final apex = (px + 0.08, y0 + y + d / 2, h + 0.16);
      c.fill(
        c.iso.path([(px, y0 + y + d, h), (px + 0.16, y0 + y + d, h), apex]),
        light(_paint, 0.1),
      );
      c.fill(
        c.iso.path([(px + 0.16, y0 + y, h), (px + 0.16, y0 + y + d, h), apex]),
        dark(_paint, 0.32),
      );
      c.stroke(
        c.iso.path([
          (px, y0 + y + d, h),
          apex,
          (px + 0.16, y0 + y, h),
          (px + 0.16, y0 + y + d, h),
        ]),
        dark(_paint, 0.6).withValues(alpha: 0.7),
        0.016,
      );
    }
  }
}

class _Bench extends ItemArt {
  const _Bench();
  @override
  double get height => 1;

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    final x = s.left, y = s.top;
    c.boxShadow(x, y, 0.6, s.height, 0.8, 0.22);
    for (final (lx, ly) in [
      (x + 0.05, y + 0.05),
      (x + 0.42, y + 0.05),
      (x + 0.05, y + s.height - 0.13),
      (x + 0.42, y + s.height - 0.13),
    ]) {
      c.box(lx, ly, 0, 0.08, 0.08, 0.32, _woodDark);
    }
    c.box(x, y, 0.32, 0.55, s.height, 0.08, _wood);
    final seam = dark(_wood, 0.4).withValues(alpha: 0.6);
    for (final sx in [x + 0.18, x + 0.36]) {
      c.canvas.drawLine(
        c.p(sx, y, 0.4),
        c.p(sx, y + s.height, 0.4),
        Paint()
          ..color = seam
          ..strokeWidth = c.tile * 0.016,
      );
    }
    for (final py in [y + 0.05, y + s.height - 0.13]) {
      c.box(x + 0.5, py, 0.32, 0.08, 0.08, 0.66, _woodDark);
    }
    c.box(x + 0.48, y - 0.02, 0.56, 0.09, s.height + 0.04, 0.13, _wood);
    c.box(x + 0.48, y - 0.02, 0.78, 0.09, s.height + 0.04, 0.13, _wood);
  }
}

class _Tree extends ItemArt {
  const _Tree();
  @override
  double get height => 3;
  @override
  bool get animated => true;

  static const _bark = Color(0xFF8A5530);
  static const _canopy = [
    (6.75, 1.05, 2.35, 0.6),
    (6.45, 1.45, 1.75, 0.66),
    (7.25, 1.15, 1.8, 0.66),
    (6.85, 1.35, 2.0, 0.85),
    (6.6, 1.75, 2.25, 0.55),
    (7.05, 1.7, 1.55, 0.6),
    (7.15, 1.55, 2.4, 0.55),
  ];

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    const cx = 6.85, cy = 1.35;
    c.shadow(cx + 0.2, cy + 0.15, 1.2, 0.26);
    c.beam((cx, cy, 0.9), (6.45, 1.55, 1.5), _bark, 0.1);
    c.beam((cx, cy, 1.0), (7.25, 1.2, 1.6), _bark, 0.1);
    c.cylinder(cx, cy, 0, 0.17, 1.45, _bark);
    // Roots flaring out at the foot.
    for (final (dx, dy) in [(-0.2, 0.12), (0.18, 0.16), (0.05, 0.22)]) {
      c.beam((cx, cy, 0.18), (cx + dx, cy + dy, 0), _bark, 0.08);
    }

    final sway = sin(t * 1.2) * c.tile * 0.03;
    c.canvas.save();
    c.canvas.translate(sway, 0);
    final order = [..._canopy]
      ..sort((a, b) => (a.$1 + a.$2 + a.$3).compareTo(b.$1 + b.$2 + b.$3));
    for (final (i, ball) in order.indexed) {
      c.ball(
        ball.$1,
        ball.$2,
        ball.$3,
        ball.$4,
        i.isEven ? _leaf : const Color(0xFF5DBB4C),
      );
    }
    // Acerolas on the sunny side of the leaves.
    final rnd = Random(7);
    for (final ball in order) {
      final center = c.p(ball.$1, ball.$2, ball.$3);
      final r = ball.$4 * c.tile * 0.72;
      for (var k = 0; k < 2; k++) {
        final a = pi * (0.15 + rnd.nextDouble() * 0.8);
        final d = r * (0.45 + rnd.nextDouble() * 0.4);
        final at = center + Offset(cos(a) * d - r * 0.1, sin(a) * d * 0.8);
        c.canvas.drawCircle(
          at,
          c.tile * 0.075,
          Paint()..color = const Color(0xFFE53935),
        );
        c.canvas.drawCircle(
          at + Offset(-c.tile * 0.025, -c.tile * 0.025),
          c.tile * 0.025,
          Paint()..color = const Color(0xFFFFCDD2),
        );
      }
    }
    c.canvas.restore();

    // Now and then a leaf drifts down.
    final q = (t / 4.5) % 1;
    final leafAt =
        c.p(7.3 + sin(q * 9) * 0.18, 1.8 + q * 0.4, 1.6 * (1 - q)) +
        Offset(sway, 0);
    c.canvas.save();
    c.canvas.translate(leafAt.dx, leafAt.dy);
    c.canvas.rotate(sin(q * 12) * 0.9);
    c.canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: c.tile * 0.16,
        height: c.tile * 0.08,
      ),
      Paint()
        ..color = const Color(0xFF8BC34A)
            .withValues(alpha: q > 0.85 ? (1 - q) / 0.15 : 1),
    );
    c.canvas.restore();
  }
}

class _Boat extends ItemArt {
  const _Boat();
  @override
  double get height => 1.6;
  @override
  bool get animated => true;

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    final cx = s.center.dx, cy = s.center.dy;
    final tile = c.tile;
    // Rings spreading on the water.
    for (var k = 0; k < 3; k++) {
      final q = (t * 0.45 + k / 3) % 1;
      c.canvas.drawOval(
        Rect.fromCenter(
          center: c.p(cx, cy, waterZ),
          width: c.iso.rx(0.9 + q * 0.9) * 2,
          height: c.iso.ry(0.9 + q * 0.9) * 2,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tile * 0.025
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45 * (1 - q)),
      );
    }
    final pivot = c.p(cx, cy, waterZ);
    c.canvas.save();
    c.canvas.translate(pivot.dx, pivot.dy - sin(t * 1.7) * tile * 0.035);
    c.canvas.rotate(sin(t * 1.3) * 0.05);
    c.canvas.translate(-pivot.dx, -pivot.dy);

    final hull = [
      (cx - 0.62, cy - 0.27),
      (cx + 0.3, cy - 0.3),
      (cx + 0.8, cy),
      (cx + 0.3, cy + 0.3),
      (cx - 0.62, cy + 0.27),
    ];
    c.prism(
      hull,
      waterZ - 0.04,
      waterZ + 0.2,
      const Color(0xFFE8574C),
      inset: 0.3,
    );
    c.prism(hull, waterZ + 0.2, waterZ + 0.3, _paint, top: _wood);
    c.box(cx - 0.35, cy - 0.22, waterZ + 0.3, 0.2, 0.44, 0.06, _woodDark);

    const z0 = waterZ + 0.3;
    c.cylinder(cx + 0.05, cy, z0, 0.035, 1.25, _woodDark);
    final sail = c.iso.path([
      (cx + 0.1, cy, z0 + 0.15),
      (cx + 0.1, cy, z0 + 1.2),
      (cx + 0.72, cy, z0 + 0.18),
    ]);
    c.fillH(sail, [const Color(0xFFFFFFFF), const Color(0xFFE6E1F2)]);
    c.stroke(sail, const Color(0xFF8C86A8), 0.018);
    final jib = c.iso.path([
      (cx, cy, z0 + 0.15),
      (cx, cy, z0 + 0.95),
      (cx - 0.45, cy, z0 + 0.15),
    ]);
    c.fill(jib, const Color(0xFFFFD43B));
    c.stroke(jib, dark(const Color(0xFFFFD43B), 0.55), 0.018);
    final top = c.p(cx + 0.05, cy, z0 + 1.25);
    final wave = sin(t * 7) * tile * 0.04;
    c.canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(top.dx + tile * 0.28, top.dy + tile * 0.06 + wave)
        ..lineTo(top.dx, top.dy + tile * 0.14)
        ..close(),
      Paint()..color = const Color(0xFFFF6B6B),
    );
    c.canvas.restore();
  }
}

class _Garden extends ItemArt {
  const _Garden();
  @override
  double get height => 0.8;

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    final x = s.left + 0.1, w = s.width - 0.2;
    const bedD = 0.8, h = 0.26;
    final tile = c.tile;
    for (final (i, by) in [s.top + 0.05, s.top + 1.15].indexed) {
      c.boxShadow(x, by, w, bedD, 0.4, 0.2);
      c.box(x, by, 0, w, bedD, h, _wood, top: _soil);
      // Furrows.
      for (final fy in [by + 0.27, by + 0.53]) {
        c.canvas.drawLine(
          c.p(x + 0.08, fy, h),
          c.p(x + w - 0.08, fy, h),
          Paint()
            ..color = dark(_soil, 0.35)
            ..strokeWidth = tile * 0.04
            ..strokeCap = StrokeCap.round,
        );
      }
      for (var k = 0; k < 5; k++) {
        final px = x + 0.28 + k * (w - 0.5) / 4;
        for (final py in [by + 0.25, by + 0.55]) {
          if (i == 0) {
            c.ball(px, py, h + 0.12, 0.16, const Color(0xFF9CCC65));
            c.ball(
              px + 0.02,
              py + 0.02,
              h + 0.15,
              0.09,
              const Color(0xFFC5E1A5),
              rim: false,
            );
          } else {
            final at = c.p(px, py, h);
            final orange = Paint()..color = const Color(0xFFFF8F2E);
            c.canvas.drawOval(
              Rect.fromCenter(
                center: at,
                width: tile * 0.14,
                height: tile * 0.08,
              ),
              orange,
            );
            final green = Paint()
              ..color = const Color(0xFF43A047)
              ..strokeWidth = tile * 0.04
              ..strokeCap = StrokeCap.round;
            for (final a in [-0.5, 0.0, 0.5]) {
              c.canvas.drawLine(
                at,
                at + Offset(sin(a) * tile * 0.16, -cos(a) * tile * 0.26),
                green,
              );
            }
          }
        }
      }
    }
  }
}

class _Lamp extends ItemArt {
  const _Lamp();
  @override
  double get height => 2.4;

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    final cx = s.center.dx, cy = s.center.dy;
    c.boxShadow(cx - 0.1, cy - 0.1, 0.2, 0.2, 2.2, 0.18);
    c.box(cx - 0.12, cy - 0.12, 0, 0.24, 0.24, 0.14, _metal);
    c.cylinder(cx, cy, 0.14, 0.05, 1.72, _metal);
    c.box(
      cx - 0.11,
      cy - 0.11,
      1.86,
      0.22,
      0.22,
      0.3,
      const Color(0xFFFFE08A),
      top: _metal,
    );
    c.box(cx - 0.15, cy - 0.15, 2.16, 0.3, 0.3, 0.05, _metal);
    c.cone(cx, cy, 2.21, 0.13, 0.16, _metal);
  }

  @override
  void overlay(IsoCanvas c, Rect s, double t) {
    final cx = s.center.dx, cy = s.center.dy;
    final tile = c.tile;
    final glow = c.p(cx, cy, 2.0);
    final r = tile * (0.8 + 0.06 * sin(t * 2.5));
    c.canvas.drawCircle(
      glow,
      r,
      Paint()
        ..shader = Gradient.radial(glow, r, [
          const Color(0x88FFF1A8),
          const Color(0x00FFF1A8),
        ]),
    );
    for (var k = 0; k < 3; k++) {
      final a = t * (0.7 + k * 0.2) + k * 2;
      final at =
          c.p(cx, cy, 1.2 + 0.35 * sin(t * 1.1 + k)) +
          Offset(cos(a) * tile * 0.55, sin(a) * tile * 0.25);
      final on = 0.4 + 0.6 * sin(t * 4 + k * 1.3).abs();
      c.canvas.drawCircle(
        at,
        tile * 0.09,
        Paint()..color = Color.fromRGBO(255, 241, 140, 0.25 * on),
      );
      c.canvas.drawCircle(
        at,
        tile * 0.035,
        Paint()..color = Color.fromRGBO(255, 250, 200, on),
      );
    }
  }
}

class _Pier extends ItemArt {
  const _Pier();
  @override
  double get height => 0.4;

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    final x = s.left, y = s.top;
    for (final py in [y + 0.08, y + 0.75]) {
      for (final px in [x + 0.06, x + s.width - 0.06]) {
        c.cylinder(px, py, -0.34, 0.06, 0.4, _woodDark);
      }
    }
    c.box(x, y, 0.02, s.width, s.height, 0.08, _wood);
    final seam = dark(_wood, 0.4).withValues(alpha: 0.6);
    for (var py = y + 0.2; py < y + s.height; py += 0.2) {
      c.canvas.drawLine(
        c.p(x, py, 0.1),
        c.p(x + s.width, py, 0.1),
        Paint()
          ..color = seam
          ..strokeWidth = c.tile * 0.014,
      );
    }
    c.cylinder(x + 0.14, y + 0.12, 0.1, 0.06, 0.18, _woodDark);
    c.cylinder(x + s.width - 0.14, y + 0.12, 0.1, 0.06, 0.18, _woodDark);
  }

  @override
  void overlay(IsoCanvas c, Rect s, double t) {
    for (final (i, px) in [s.left + 0.06, s.right - 0.06].indexed) {
      final q = (t * 0.6 + i * 0.5) % 1;
      c.canvas.drawOval(
        Rect.fromCenter(
          center: c.p(px, s.top + 0.08, waterZ),
          width: c.iso.rx(0.12 + q * 0.3) * 2,
          height: c.iso.ry(0.12 + q * 0.3) * 2,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = c.tile * 0.02
          ..color = Color.fromRGBO(255, 255, 255, 0.5 * (1 - q)),
      );
    }
  }
}

class _House extends ItemArt {
  const _House();
  @override
  double get height => 3;

  static const _wall = Color(0xFFF6DDB0);
  static const _roof = Color(0xFFE2583F);
  static const _brick = Color(0xFFB65A42);
  static const _glass = Color(0xFF8FD3F5);

  /// A window on the wall y = [y] (lit) between x0 and x1.
  void _windowLit(
    IsoCanvas c,
    double x0,
    double x1,
    double y,
    double z0,
    double z1,
  ) {
    c.fill(
      c.iso.path([(x0, y, z0), (x1, y, z0), (x1, y, z1), (x0, y, z1)]),
      _paint,
    );
    final glass = c.iso.path([
      (x0 + 0.05, y, z0 + 0.05),
      (x1 - 0.05, y, z0 + 0.05),
      (x1 - 0.05, y, z1 - 0.05),
      (x0 + 0.05, y, z1 - 0.05),
    ]);
    c.fillV(glass, light(_glass, 0.3), dark(_glass, 0.15));
    final mid = (x0 + x1) / 2, zm = (z0 + z1) / 2;
    final bar = Paint()
      ..color = _paint
      ..strokeWidth = c.tile * 0.035;
    c.canvas.drawLine(c.p(mid, y, z0), c.p(mid, y, z1), bar);
    c.canvas.drawLine(c.p(x0, y, zm), c.p(x1, y, zm), bar);
    c.stroke(
      c.iso.path([(x0, y, z0), (x1, y, z0), (x1, y, z1), (x0, y, z1)]),
      dark(_wall, 0.6),
      0.016,
    );
    // Flower box under the window.
    c.box(x0 - 0.04, y, z0 - 0.12, x1 - x0 + 0.08, 0.1, 0.1, _roof);
    for (var k = 0; k < 3; k++) {
      final at = c.p(x0 + 0.07 + k * (x1 - x0 - 0.14) / 2, y + 0.05, z0 + 0.02);
      _flower(
        c.canvas,
        at,
        c.tile * 0.035,
        k.isEven ? const Color(0xFFFFD43B) : const Color(0xFFFF7EB6),
      );
    }
  }

  /// A window on the wall x = [x] (shaded) between y0 and y1.
  void _windowShade(
    IsoCanvas c,
    double x,
    double y0,
    double y1,
    double z0,
    double z1,
  ) {
    final frame = dark(_paint, 0.25);
    c.fill(
      c.iso.path([(x, y0, z0), (x, y1, z0), (x, y1, z1), (x, y0, z1)]),
      frame,
    );
    final glass = c.iso.path([
      (x, y0 + 0.05, z0 + 0.05),
      (x, y1 - 0.05, z0 + 0.05),
      (x, y1 - 0.05, z1 - 0.05),
      (x, y0 + 0.05, z1 - 0.05),
    ]);
    c.fillV(glass, dark(_glass, 0.1), dark(_glass, 0.4));
    final bar = Paint()
      ..color = frame
      ..strokeWidth = c.tile * 0.035;
    c.canvas.drawLine(
      c.p(x, (y0 + y1) / 2, z0),
      c.p(x, (y0 + y1) / 2, z1),
      bar,
    );
    c.canvas.drawLine(
      c.p(x, y0, (z0 + z1) / 2),
      c.p(x, y1, (z0 + z1) / 2),
      bar,
    );
  }

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    const x0 = 0.8, x1 = 3.2, y0 = 3.0, y1 = 5.4, base = 0.16, top = 1.5;
    c.boxShadow(0.7, 2.9, 2.6, 2.6, 2.4, 0.26);
    c.box(0.7, 2.9, 0, 2.6, 2.6, base, _stone);
    c.box(x0, y0, base, x1 - x0, y1 - y0, top - base, _wall);
    // Timber at the corners and under the eaves.
    for (final (bx, by) in [
      (x0, y1 - 0.12),
      (x1 - 0.12, y1 - 0.12),
      (x1 - 0.12, y0),
    ]) {
      c.box(bx, by, base, 0.12, 0.12, top - base, _woodDark);
    }
    c.box(x0, y1 - 0.1, top - 0.08, x1 - x0, 0.1, 0.08, _woodDark);
    c.box(x1 - 0.1, y0, top - 0.08, 0.1, y1 - y0, 0.08, _woodDark);

    // Door with an arched top, and its step.
    const dz1 = 1.0;
    final door = Path()
      ..moveTo(c.p(1.65, y1, base).dx, c.p(1.65, y1, base).dy)
      ..lineTo(c.p(2.3, y1, base).dx, c.p(2.3, y1, base).dy)
      ..lineTo(c.p(2.3, y1, dz1).dx, c.p(2.3, y1, dz1).dy)
      ..quadraticBezierTo(
        c.p(1.975, y1, 1.36).dx,
        c.p(1.975, y1, 1.36).dy,
        c.p(1.65, y1, dz1).dx,
        c.p(1.65, y1, dz1).dy,
      )
      ..close();
    c.fillV(door, const Color(0xFFA9653A), const Color(0xFF7E4524));
    for (final px in [1.87, 2.08]) {
      c.canvas.drawLine(
        c.p(px, y1, base),
        c.p(px, y1, dz1 + 0.06),
        Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = c.tile * 0.016,
      );
    }
    c.stroke(door, _woodDark, 0.025);
    c.canvas.drawCircle(
      c.p(2.18, y1, 0.58),
      c.tile * 0.035,
      Paint()..color = const Color(0xFFFFC94D),
    );
    c.box(1.55, y1, 0, 0.85, 0.25, base, _stone);

    _windowLit(c, 0.98, 1.44, y1, 0.66, 1.1);
    _windowLit(c, 2.56, 3.0, y1, 0.66, 1.1);
    _windowShade(c, x1, 3.4, 3.88, 0.66, 1.1);
    _windowShade(c, x1, 4.45, 4.93, 0.66, 1.1);

    // Roof: ridge along x.
    const ry = 4.2, rz = 2.45, ex0 = 0.6, ex1 = 3.4, ey0 = 2.75, ey1 = 5.65;
    const ez = 1.48;
    final gable = c.iso.path([
      (x1, y0, top),
      (x1, y1, top),
      (x1, ry, rz - 0.06),
    ]);
    c.fill(gable, dark(_wall, 0.3));
    c.stroke(gable, dark(_wall, 0.62), 0.016);
    final attic = c.p(x1, ry, 1.9);
    c.canvas.drawOval(
      Rect.fromCenter(
        center: attic,
        width: c.tile * 0.24,
        height: c.tile * 0.3,
      ),
      Paint()..color = _paint,
    );
    c.canvas.drawOval(
      Rect.fromCenter(
        center: attic,
        width: c.tile * 0.16,
        height: c.tile * 0.22,
      ),
      Paint()..color = dark(_glass, 0.3),
    );
    c.fill(
      c.iso.path([
        (ex0, ey0, ez),
        (ex1, ey0, ez),
        (ex1, ry, rz),
        (ex0, ry, rz),
      ]),
      dark(_roof, 0.35),
    );
    c.fill(
      c.iso.path([
        (ex1, ey0, ez),
        (ex1, ry, rz),
        (ex1, ry, rz - 0.09),
        (ex1, ey0, ez - 0.09),
      ]),
      dark(_roof, 0.5),
    );
    // Chimney, behind the ridge.
    c.box(1.3, 3.35, 1.9, 0.38, 0.38, 1.0, _brick);
    for (final z in [2.15, 2.4, 2.65]) {
      _seams(c, (1.3, 3.73, 0), (1.68, 3.73, 0), [z], dark(_brick, 0.35));
    }
    c.box(1.26, 3.31, 2.9, 0.46, 0.46, 0.08, _stone);

    final front = c.iso.path([
      (ex0, ey1, ez),
      (ex1, ey1, ez),
      (ex1, ry, rz),
      (ex0, ry, rz),
    ]);
    c.fillV(front, light(_roof, 0.12), dark(_roof, 0.08));
    // Rows of tiles, each with a scalloped edge.
    final tileLine = Paint()
      ..color = dark(_roof, 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = c.tile * 0.02;
    for (var k = 1; k <= 4; k++) {
      final f = k / 5;
      final yy = ey1 + (ry - ey1) * f, zz = ez + (rz - ez) * f;
      final row = Path();
      const n = 9;
      for (var i = 0; i < n; i++) {
        final a = c.p(ex0 + (ex1 - ex0) * i / n, yy, zz);
        final b = c.p(ex0 + (ex1 - ex0) * (i + 1) / n, yy, zz);
        final mid = Offset.lerp(a, b, 0.5)! + Offset(0, c.tile * 0.07);
        row
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      }
      c.canvas.drawPath(row, tileLine);
    }
    c.stroke(front, dark(_roof, 0.6), 0.02);
    c.fill(
      c.iso.path([
        (ex1, ey1, ez),
        (ex1, ry, rz),
        (ex1, ry, rz - 0.09),
        (ex1, ey1, ez - 0.09),
      ]),
      dark(_roof, 0.45),
    );
    c.fill(
      c.iso.path([
        (ex0, ey1, ez),
        (ex1, ey1, ez),
        (ex1, ey1, ez - 0.09),
        (ex0, ey1, ez - 0.09),
      ]),
      dark(_roof, 0.3),
    );
    c.beam(
      (ex0 - 0.04, ry, rz + 0.02),
      (ex1 + 0.04, ry, rz + 0.02),
      dark(_roof, 0.15),
      0.1,
    );
  }

  @override
  void overlay(IsoCanvas c, Rect s, double t) {
    for (var k = 0; k < 4; k++) {
      final q = (t * 0.32 + k / 4) % 1;
      final at = c.p(1.49 + q * 0.7, 3.54 - q * 0.25, 3.0 + q * 1.5);
      final r = c.tile * (0.09 + q * 0.2);
      final a = 0.55 * (1 - q) * min(1.0, q * 6);
      c.canvas.drawCircle(
        at,
        r,
        Paint()..color = Color.fromRGBO(240, 240, 248, a),
      );
      c.canvas.drawCircle(
        at + Offset(-r * 0.25, -r * 0.25),
        r * 0.55,
        Paint()..color = Color.fromRGBO(255, 255, 255, a * 0.8),
      );
    }
  }
}

class _Swing extends ItemArt {
  const _Swing();
  @override
  double get height => 1.9;
  @override
  bool get animated => true;

  static const _frame = Color(0xFF5C8DF5);

  void _aFrame(IsoCanvas c, double y) {
    c.beam((8.7, y, 0), (9.1, y, 1.65), _frame, 0.09);
    c.beam((9.5, y, 0), (9.1, y, 1.65), _frame, 0.09);
  }

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    final a = sin(t * 2.0) * 0.55;
    const len = 1.15, pz = 1.65;
    final sx = 9.1 + len * sin(a), sz = pz - len * cos(a);
    c.boxShadow(8.65, 0.85, 0.9, 1.5, 0.6, 0.12);
    c.shadow(sx + 0.05, 1.6, 0.3, 0.22);
    _aFrame(c, 0.9);
    c.beam((9.1, 0.85, pz), (9.1, 2.35, pz), dark(_frame, 0.15), 0.1);
    final chain = Paint()
      ..color = const Color(0xFF9AA0B8)
      ..strokeWidth = c.tile * 0.025;
    c.canvas.drawLine(c.p(9.1, 1.4, pz), c.p(sx, 1.4, sz + 0.06), chain);
    c.box(sx - 0.18, 1.33, sz, 0.36, 0.54, 0.06, const Color(0xFFFF6B6B));
    c.canvas.drawLine(c.p(9.1, 1.8, pz), c.p(sx, 1.8, sz + 0.06), chain);
    _aFrame(c, 2.3);
  }
}

class _Fountain extends ItemArt {
  const _Fountain();
  @override
  double get height => 1.8;

  static const _cx = 3.9, _cy = 1.6;

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    c.shadow(_cx + 0.1, _cy + 0.05, 1.0, 0.24);
    c.cylinder(_cx, _cy, 0, 0.95, 0.32, _stone);
    final pool = Rect.fromCenter(
      center: c.p(_cx, _cy, 0.32),
      width: c.iso.rx(0.8) * 2,
      height: c.iso.ry(0.8) * 2,
    );
    c.canvas.drawOval(
      pool,
      Paint()
        ..shader = Gradient.linear(pool.topCenter, pool.bottomCenter, [
          dark(_water, 0.25),
          light(_water, 0.2),
        ]),
    );
    c.cylinder(_cx, _cy, 0.28, 0.16, 0.75, _stone);
    c.cylinder(_cx, _cy, 1.0, 0.45, 0.12, _stone);
    final bowl = Rect.fromCenter(
      center: c.p(_cx, _cy, 1.12),
      width: c.iso.rx(0.36) * 2,
      height: c.iso.ry(0.36) * 2,
    );
    c.canvas.drawOval(bowl, Paint()..color = _water);
    c.ball(_cx, _cy, 1.2, 0.1, _stone);
  }

  @override
  void overlay(IsoCanvas c, Rect s, double t) {
    final tile = c.tile;
    for (var k = 0; k < 3; k++) {
      final q = (t * 0.5 + k / 3) % 1;
      c.canvas.drawOval(
        Rect.fromCenter(
          center: c.p(_cx, _cy, 0.32),
          width: c.iso.rx(0.25 + q * 0.5) * 2,
          height: c.iso.ry(0.25 + q * 0.5) * 2,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tile * 0.02
          ..color = Color.fromRGBO(255, 255, 255, 0.6 * (1 - q)),
      );
    }
    final jet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tile * 0.035
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xCCE3F7FF);
    final drop = Paint()..color = const Color(0xFFFFFFFF);
    P3 along(double a, double q) => (
      _cx + cos(a) * 0.6 * q,
      _cy + sin(a) * 0.6 * q,
      1.25 + 0.5 * q - 1.45 * q * q,
    );
    for (var k = 0; k < 6; k++) {
      final a = k * pi / 3 + 0.3;
      final path = Path();
      for (var i = 0; i <= 10; i++) {
        final at = c.iso.at(along(a, i / 10));
        i == 0 ? path.moveTo(at.dx, at.dy) : path.lineTo(at.dx, at.dy);
      }
      c.canvas.drawPath(path, jet);
      for (var j = 0; j < 2; j++) {
        final q = (t * 0.9 + j * 0.5 + k * 0.13) % 1;
        c.canvas.drawCircle(c.iso.at(along(a, q)), tile * 0.03, drop);
      }
    }
    // The spout bubbling up.
    final top = c.p(_cx, _cy, 1.3 + 0.04 * sin(t * 9));
    c.canvas.drawCircle(
      top,
      tile * 0.07,
      Paint()..color = const Color(0xDDE3F7FF),
    );
  }
}

class _FerrisWheel extends ItemArt {
  const _FerrisWheel();
  @override
  double get height => 4.6;
  @override
  bool get animated => true;

  static const _cx = 1.6, _cy = 1.3, _hz = 2.45, _r = 1.85;
  static const _steel = Color(0xFFF1EEF9);

  @override
  void paint(IsoCanvas c, Rect s, double t) {
    final tile = c.tile;
    c.shadow(_cx + 0.3, _cy + 0.2, 1.3, 0.2);
    c.box(0.8, 0.5, 0, 1.6, 1.6, 0.12, _stone);
    const off = 0.17, foot = 0.95;
    void legs(double o) {
      c.beam(
        (_cx - foot + o, _cy + foot + o, 0.12),
        (_cx + o, _cy + o, _hz),
        _steel,
        0.1,
      );
      c.beam(
        (_cx + foot + o, _cy - foot + o, 0.12),
        (_cx + o, _cy + o, _hz),
        _steel,
        0.1,
      );
    }

    final rs = _r * c.iso.zScale;
    final back = c.p(_cx - off * 0.7, _cy - off * 0.7, _hz);
    final hub = c.p(_cx + off * 0.7, _cy + off * 0.7, _hz);
    final rot = t * 0.3;

    legs(-off);
    c.canvas.drawCircle(
      back,
      rs,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tile * 0.07
        ..color = dark(_steel, 0.35),
    );
    final spoke = Paint()
      ..color = dark(_steel, 0.15)
      ..strokeWidth = tile * 0.03;
    for (var k = 0; k < 12; k++) {
      final a = rot + k * pi / 6;
      final d = Offset(cos(a), sin(a)) * rs;
      c.canvas.drawLine(back, back + d, spoke..color = dark(_steel, 0.3));
      c.canvas.drawLine(hub, hub + d, spoke..color = _steel);
    }
    // Cabins hang from the rim and stay upright.
    for (var k = 0; k < 8; k++) {
      final a = rot + k * pi / 4;
      final at = hub + Offset(cos(a), sin(a)) * rs;
      final col = Palette.blocks[k % Palette.blocks.length];
      c.canvas.save();
      c.canvas.translate(at.dx, at.dy);
      c.canvas.rotate(sin(t * 1.8 + k) * 0.08);
      final w = tile * 0.36, h = tile * 0.3, drop = tile * 0.08;
      c.canvas.drawLine(
        Offset.zero,
        Offset(0, drop),
        Paint()
          ..color = dark(_steel, 0.4)
          ..strokeWidth = tile * 0.025,
      );
      final body = RRect.fromRectAndCorners(
        Rect.fromLTWH(-w / 2, drop, w, h),
        topLeft: Radius.circular(w * 0.45),
        topRight: Radius.circular(w * 0.45),
        bottomLeft: Radius.circular(w * 0.15),
        bottomRight: Radius.circular(w * 0.15),
      );
      c.canvas.drawRRect(
        body,
        Paint()
          ..shader = Gradient.linear(
            body.outerRect.centerLeft,
            body.outerRect.centerRight,
            [light(col, 0.25), dark(col, 0.3)],
          ),
      );
      c.canvas.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tile * 0.02
          ..color = dark(col, 0.6),
      );
      c.canvas.drawRect(
        Rect.fromLTWH(-w * 0.32, drop + h * 0.3, w * 0.64, h * 0.3),
        Paint()..color = const Color(0xCCE8F7FF),
      );
      c.canvas.restore();
    }
    c.canvas.drawCircle(
      hub,
      rs,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tile * 0.08
        ..color = _steel,
    );
    c.canvas.drawCircle(
      hub,
      rs * 0.84,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tile * 0.03
        ..color = const Color(0xFFFF8FB8),
    );
    // Rim lights, chasing around.
    final step = (t * 4).floor();
    for (var k = 0; k < 16; k++) {
      final a = rot + k * pi / 8;
      final on = (k + step) % 3 == 0;
      c.canvas.drawCircle(
        hub + Offset(cos(a), sin(a)) * rs,
        tile * (on ? 0.06 : 0.04),
        Paint()
          ..color = on
              ? const Color(0xFFFFF176)
              : const Color(0xFFFFC94D).withValues(alpha: 0.7),
      );
    }
    c.canvas.drawCircle(hub, tile * 0.13, Paint()..color = dark(_steel, 0.45));
    c.canvas.drawCircle(
      hub,
      tile * 0.06,
      Paint()..color = const Color(0xFFFFC94D),
    );
    legs(off);
  }
}
