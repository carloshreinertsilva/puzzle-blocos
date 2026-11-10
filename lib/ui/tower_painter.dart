import 'dart:math';

import 'package:flutter/material.dart';

import '../core/hats.dart';
import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import '../tower/tower_controller.dart';
import '../village/iso.dart';
import 'capi.dart';
import 'typography.dart';

/// Rainbow/block color palette for the tower blocks.
const towerPalette = [
  Color(0xFF10B981), // Emerald
  Color(0xFF06B6D4), // Cyan
  Color(0xFF3B82F6), // Blue
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Purple
  Color(0xFFEC4899), // Pink
  Color(0xFFF43F5E), // Rose
  Color(0xFFF97316), // Orange
  Color(0xFFFBBF24), // Amber
];

/// The sky at a floor: its top and bottom colors.
typedef _Sky = (int floor, Color top, Color bottom);

/// The climb's sky, from the village's morning to deep space: the colors
/// blend from one stop to the next (the stops are the zones' first floors).
const _skies = <_Sky>[
  (0, Color(0xFF3FA9F5), Color(0xFFBDE9FF)),
  (10, Color(0xFF2F86E0), Color(0xFF9FD8FF)),
  (20, Color(0xFF4B2E96), Color(0xFFFF9A62)),
  (30, Color(0xFF10163F), Color(0xFF3A2A78)),
  (45, Color(0xFF060818), Color(0xFF1A1340)),
  (60, Color(0xFF020308), Color(0xFF0C0A22)),
];

/// A steady pseudo-random number in [0, 1) for [i] (the same on every frame).
double _rnd(int i) {
  final v = sin(i * 12.9898 + 78.233) * 43758.5453;
  return v - v.floorToDouble();
}

double _ease(double t) => t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;

/// Overshoots a little, then settles (for texts that pop in).
double _pop(double t) {
  if (t >= 1) return 1;
  const c = 1.9;
  return 1 + (c + 1) * pow(t - 1, 3) + c * pow(t - 1, 2);
}

/// Renders Capi's Tower: the climb from the village up to the Moon, with
/// Capi, big, on top of it all, reacting to every block.
class TowerWorldPainter extends CustomPainter {
  const TowerWorldPainter({required this.controller})
    : super(repaint: controller);

  final TowerController controller;

  static const _dz = TowerController.blockDz;

  @override
  void paint(Canvas canvas, Size size) {
    final c = controller;
    final t = c.time;
    final tile0 = min(size.width * 0.22, 90.0);

    // When the climb ends, the camera pulls back to show the whole tower.
    final over = c.gameOver
        ? _ease(((t - c.overAt - 0.3) / 1.1).clamp(0, 1))
        : 0.0;
    final towerPx = (c.blocks.length * _dz) * tile0 * 0.62 + tile0 * 2.2;
    final fit = min(1.0, size.height * 0.62 / towerPx);
    final zoom = 1 + (fit - 1) * over;
    final tile = tile0 * zoom;
    final following = size.height * 0.66 + c.cameraZ * tile0 * 0.62;
    final originY = following + (size.height * 0.84 - following) * over;
    final iso = Iso(Offset(size.width / 2, originY), tile);
    final ic = IsoCanvas(canvas, iso);
    final step = _dz * iso.zScale;

    // How high the camera is, in floors, and where a thing floating at
    // floor [f] sits on screen ([k] < 1: far away, it moves less).
    final alt = c.cameraZ / _dz * (1 - over);
    double skyY(double f, double k) =>
        size.height * 0.66 - (f - alt) * step * k + (originY - following) * k;

    _sky(canvas, size, alt);
    _stars(canvas, size, alt, t);
    _moon(canvas, size, skyY, tile);
    _hills(canvas, size, skyY(0, 0.55), tile);
    _clouds(canvas, size, skyY, t, tile, front: false);
    _flyers(canvas, size, skyY, t, tile);

    canvas.save();
    if (c.shake > 0) {
      final a = c.shake * c.shake * 7;
      canvas.translate(sin(t * 61) * a, cos(t * 53) * a * 0.6);
    }

    _island(ic);
    _lines(canvas, size, iso);

    // Placed blocks, bottom to top (only the ones on screen).
    for (var i = 0; i < c.blocks.length; i++) {
      final b = c.blocks[i];
      final y = iso.p(0, 0, b.z).dy;
      if (y < -step * 4 || y > size.height + tile * 3) continue;
      final col = towerPalette[b.colorIndex % towerPalette.length];
      ic.box(b.x, b.y, b.z, b.dx, b.dy, b.dz, col, outline: true);
      if (i > 0 && i % 5 == 0 && zoom > 0.6) {
        final pt = iso.p(b.x + b.dx + 0.45, b.y + b.dy / 2, b.z + b.dz / 2);
        _text(canvas, '$i', pt, 13, const Color(0xFFFDE047));
      }
    }
    _rings(canvas, iso, t);

    for (final s in c.fallingSlices) {
      final col = towerPalette[s.colorIndex % towerPalette.length];
      ic.box(s.x, s.y, s.z, s.dx, s.dy, s.dz, col.withValues(alpha: 0.85));
    }

    if (!c.gameOver) {
      final col = towerPalette[c.height % towerPalette.length];
      ic.box(
        c.currentX,
        c.currentY,
        c.height * _dz,
        c.currentDx,
        c.currentDy,
        _dz,
        col,
        outline: true,
      );
    }

    final head = _capi(canvas, iso, t, tile);
    _particles(canvas, iso, t, tile);
    canvas.restore();

    _clouds(canvas, size, skyY, t, tile, front: true);
    _popups(canvas, size, t, head);
  }

  // --- The world around the tower ---

  void _sky(Canvas canvas, Size size, double alt) {
    var i = 0;
    while (i < _skies.length - 2 && alt >= _skies[i + 1].$1) {
      i++;
    }
    final a = _skies[i], b = _skies[i + 1];
    final k = ((alt - a.$1) / (b.$1 - a.$1)).clamp(0.0, 1.0);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(a.$2, b.$2, k)!, Color.lerp(a.$3, b.$3, k)!],
        ).createShader(rect),
    );
  }

  void _stars(Canvas canvas, Size size, double alt, double t) {
    final show = ((alt - 19) / 9).clamp(0.0, 1.0);
    if (show <= 0) return;
    final p = Paint();
    for (var i = 0; i < 70; i++) {
      final x = _rnd(i) * size.width;
      // They drift down slowly as the tower climbs.
      final y = (_rnd(i + 100) * size.height + alt * 2.2) % size.height;
      final twinkle = 0.55 + 0.45 * sin(t * (1.2 + _rnd(i + 200) * 2) + i);
      p.color = Colors.white.withValues(alpha: show * twinkle * 0.9);
      canvas.drawCircle(Offset(x, y), 0.7 + _rnd(i + 300) * 1.5, p);
    }
  }

  void _moon(
    Canvas canvas,
    Size size,
    double Function(double, double) skyY,
    double tile,
  ) {
    final y = skyY(88, 0.6);
    final r = tile * 1.15;
    if (y < -r * 2 || y > size.height + r) return;
    final o = Offset(size.width * 0.74, y);
    canvas.drawCircle(o, r * 1.5, Paint()..color = const Color(0x22FFF4C2));
    canvas.drawCircle(o, r, Paint()..color = const Color(0xFFFFF4C2));
    final crater = Paint()..color = const Color(0x33B59A55);
    for (final (dx, dy, k) in [
      (-.35, -.2, .22),
      (.3, .25, .16),
      (.1, -.45, .1),
    ]) {
      canvas.drawCircle(o + Offset(dx * r, dy * r), k * r, crater);
    }
    // A ringed planet on the way there.
    final py = skyY(72, 0.6);
    final po = Offset(size.width * 0.2, py);
    final pr = tile * 0.42;
    canvas.drawCircle(po, pr, Paint()..color = const Color(0xFFE8A86B));
    canvas.drawOval(
      Rect.fromCenter(center: po, width: pr * 3.6, height: pr * 0.9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pr * 0.16
        ..color = const Color(0xCCF6D7A8),
    );
  }

  void _hills(Canvas canvas, Size size, double y, double tile) {
    if (y > size.height + tile * 3) return;
    for (final (k, col, h) in [
      (0.0, Color(0xFF6CC58A), 1.5),
      (1.0, Color(0xFF4FAE74), 1.05),
    ]) {
      final path = Path()..moveTo(0, size.height + 10);
      final base = y + tile * (0.4 + k * 0.55);
      for (var x = 0.0; x <= size.width + 20; x += 20) {
        final w = sin(x / size.width * pi * (2.2 + k) + k * 2.1);
        path.lineTo(x, base - (w * 0.5 + 0.5) * tile * h);
      }
      path
        ..lineTo(size.width, size.height + 10)
        ..close();
      canvas.drawPath(path, Paint()..color = col);
    }
  }

  void _clouds(
    Canvas canvas,
    Size size,
    double Function(double, double) skyY,
    double t,
    double tile, {
    required bool front,
  }) {
    final p = Paint();
    for (var i = 0; i < 16; i++) {
      // A few pass in front of the tower, close to the camera.
      if ((i % 5 == 0) != front) continue;
      final k = front ? 1.25 : 0.6 + _rnd(i + 7) * 0.3;
      final y = skyY(5 + _rnd(i) * 22, k);
      final w = tile * (0.9 + _rnd(i + 20) * 1.1) * (front ? 1.5 : 1);
      if (y < -w || y > size.height + w) continue;
      final span = size.width + w * 3;
      final dir = i.isEven ? 1 : -1;
      final x =
          (_rnd(i + 40) * span + dir * t * (4 + _rnd(i + 60) * 7)) % span -
          w * 1.5;
      p.color = Colors.white.withValues(alpha: front ? 0.22 : 0.8);
      for (final (dx, dy, r) in [
        (0.0, 0.0, 0.34),
        (-0.3, 0.06, 0.25),
        (0.3, 0.05, 0.27),
        (0.08, -0.14, 0.26),
      ]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + dx * w, y + dy * w),
            width: r * w * 2.2,
            height: r * w * 1.5,
          ),
          p,
        );
      }
    }
  }

  /// Birds low down, hot-air balloons a little higher.
  void _flyers(
    Canvas canvas,
    Size size,
    double Function(double, double) skyY,
    double t,
    double tile,
  ) {
    final bird = Paint()
      ..color = const Color(0xAA1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = skyY(3 + i * 2.6, 0.8) + sin(t * 1.3 + i) * 6;
      if (y < -20 || y > size.height + 20) continue;
      final span = size.width + 80;
      final x = (_rnd(i + 500) * span + t * (18 + i * 4)) % span - 40;
      final flap = sin(t * 9 + i) * 4;
      canvas.drawPath(
        Path()
          ..moveTo(x - 8, y - flap)
          ..quadraticBezierTo(x - 3, y - 4, x, y)
          ..quadraticBezierTo(x + 3, y - 4, x + 8, y - flap),
        bird,
      );
    }
    for (var i = 0; i < 2; i++) {
      final y = skyY(9.0 + i * 8, 0.7) + sin(t * 0.7 + i * 2) * 8;
      final r = tile * 0.38;
      if (y < -r * 4 || y > size.height + r * 4) continue;
      final x = size.width * (i == 0 ? 0.14 : 0.86) + sin(t * 0.25 + i) * 14;
      final col = i == 0 ? const Color(0xFFF43F5E) : const Color(0xFFFBBF24);
      final line = Paint()
        ..color = const Color(0x994A2A12)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(x - r * 0.5, y + r * 0.7),
        Offset(x - r * 0.22, y + r * 1.6),
        line,
      );
      canvas.drawLine(
        Offset(x + r * 0.5, y + r * 0.7),
        Offset(x + r * 0.22, y + r * 1.6),
        line,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 2.2),
        Paint()..color = col,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: r * 0.8, height: r * 2.2),
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y + r * 1.8),
            width: r * 0.6,
            height: r * 0.45,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF8B5A2B),
      );
    }
  }

  /// The patch of the village the tower stands on.
  void _island(IsoCanvas ic) {
    ic.box(-3.4, -3.4, -1.1, 6.8, 6.8, 0.75, const Color(0xFF8B5A2B));
    ic.box(
      -3.4,
      -3.4,
      -0.35,
      6.8,
      6.8,
      0.35,
      const Color(0xFF4FAE74),
      top: const Color(0xFF7BD389),
    );
    ic.boxShadow(-1.9, -1.9, 3.8, 3.8, 0.5, 0.3);
    for (final (x, y) in [(-2.8, 2.2), (2.3, -2.9), (2.6, 2.5), (-2.9, -2.4)]) {
      ic.shadow(x, y, 0.3);
      ic.cone(x, y, 0, 0.32, 0.75, const Color(0xFF2F9E62));
    }
  }

  /// The record to beat and the next zone: lines across the sky.
  void _lines(Canvas canvas, Size size, Iso iso) {
    final c = controller;
    void line(double y, Color col, String label, {required bool right}) {
      if (y < 170 || y > size.height) return;
      final p = Paint()
        ..color = col
        ..strokeWidth = 2;
      for (var x = 0.0; x < size.width; x += 14) {
        canvas.drawLine(Offset(x, y), Offset(x + 7, y), p);
      }
      final tp = _layout(label, 12, const Color(0xFF1E1B4B));
      final w = tp.width + 14;
      final box = Rect.fromLTWH(
        right ? size.width - w - 6 : 6,
        y - tp.height - 7,
        w,
        tp.height + 5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(7)),
        Paint()..color = col.withValues(alpha: 1),
      );
      tp.paint(canvas, box.topLeft + const Offset(7, 2.5));
    }

    final next = c.nextZone;
    if (next != null) {
      line(
        iso.p(0, 0, (next.floor + 1) * _dz).dy,
        const Color(0xB3FFFFFF),
        tr(next.name),
        right: false,
      );
    }
    if (c.recordToBeat > 0) {
      line(
        iso.p(0, 0, (c.recordToBeat + 1) * _dz).dy,
        c.recordBeaten ? const Color(0x66FFD43B) : const Color(0xFFFFD43B),
        tr('Recorde {n}', {'n': c.recordToBeat}),
        right: true,
      );
    }
  }

  /// A ring that opens from the block on a perfect floor.
  void _rings(Canvas canvas, Iso iso, double t) {
    for (final e in controller.fx) {
      if (e.kind != TowerFxKind.perfect) continue;
      final k = (t - e.at) / 0.55;
      if (k < 0 || k > 1) continue;
      final b = controller.blocks.last;
      final g = 0.15 + k * (0.7 + e.combo * 0.08);
      final path = iso.path([
        (e.x - b.dx / 2 - g, e.y - b.dy / 2 - g, e.z),
        (e.x + b.dx / 2 + g, e.y - b.dy / 2 - g, e.z),
        (e.x + b.dx / 2 + g, e.y + b.dy / 2 + g, e.z),
        (e.x - b.dx / 2 - g, e.y + b.dy / 2 + g, e.z),
      ]);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * (1 - k) + 1
          ..color = Colors.white.withValues(alpha: (1 - k) * 0.9),
      );
    }
  }

  // --- Capi ---

  /// Capi on top of the tower. Returns where the top of his head is, for
  /// the texts that pop up above him.
  Offset _capi(Canvas canvas, Iso iso, double t, double tile) {
    final c = controller;
    final size = tile * 1.4;
    final (tx, ty, tz) = c.top;
    var feet = iso.p(tx, ty, tz);

    final sincePlaced = t - c.placedAt;
    var lift = 0.0;
    var squash = 1.0;
    // He hops from the floor below onto the block that just landed.
    if (c.blocks.length > 1 && sincePlaced < 0.3 && !c.gameOver) {
      final k = sincePlaced / 0.3;
      final below = c.blocks[c.blocks.length - 2];
      final from = iso.p(
        below.x + below.dx / 2,
        below.y + below.dy / 2,
        below.z + below.dz,
      );
      feet = Offset.lerp(from, feet, _ease(k))!;
      lift = sin(k * pi) * size * 0.45;
    } else if (sincePlaced < 0.45) {
      squash = 1 - 0.14 * sin(((sincePlaced - 0.3) / 0.15).clamp(0, 1) * pi);
    }

    final recent = c.fx.isEmpty ? null : c.fx.last;
    final recentAge = recent == null ? 9.0 : t - recent.at;
    var mood = CapiMood.happy;
    var tilt = 0.0;
    if (c.gameOver) {
      mood = c.isNewBest ? CapiMood.cheer : CapiMood.sad;
      if (c.isNewBest) lift = sin(t * 7).abs() * size * 0.18;
    } else if (recent != null &&
        recentAge < 1.1 &&
        recent.kind == TowerFxKind.closeCall) {
      mood = CapiMood.worried;
      tilt = sin(t * 26) * 0.09 * (1.1 - recentAge);
    } else if (recent != null &&
        recentAge < 0.9 &&
        recent.kind != TowerFxKind.cut) {
      mood = CapiMood.cheer;
    } else if (c.tense) {
      // Barely any room left under his feet.
      mood = CapiMood.worried;
      tilt = sin(t * 9) * 0.07;
    } else if (c.fever) {
      mood = CapiMood.cheer;
    }

    if (c.fever) _aura(canvas, feet - Offset(0, size * 0.45 + lift), size, t);

    // His shadow on the block.
    canvas.drawOval(
      Rect.fromCenter(
        center: feet,
        width: size * 0.62 * (1 - lift / size * 0.6),
        height: size * 0.18 * (1 - lift / size * 0.6),
      ),
      Paint()..color = const Color(0x40231546),
    );

    canvas.save();
    canvas.translate(feet.dx, feet.dy - lift);
    canvas.rotate(tilt);
    canvas.scale(2 - squash, squash);
    canvas.translate(-size / 2, -size * 0.95);
    CapiPainter(
      mood: mood,
      t: (t * 0.9) % 1,
      hat: CapiHat.fromId(c.store.equippedHat),
      look: CapiLook.of(c.store),
    ).paint(canvas, Size.square(size));
    canvas.restore();
    return feet - Offset(0, size + lift);
  }

  /// "On fire": a warm glow and flames going up behind Capi.
  void _aura(Canvas canvas, Offset center, double size, double t) {
    final pulse = 0.85 + 0.15 * sin(t * 8);
    final r = size * 0.75 * pulse;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xB3FFD43B), Color(0x66FF7A1A), Color(0x00FF7A1A)],
          stops: [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    final flame = Paint();
    for (var i = 0; i < 9; i++) {
      final k = (t * (0.9 + _rnd(i + 800) * 0.8) + _rnd(i + 810)) % 1;
      final x = center.dx + (_rnd(i + 820) - 0.5) * size * 0.9;
      final y = center.dy + size * 0.35 - k * size * 1.1;
      flame.color = Color.lerp(
        const Color(0xFFFFE066),
        const Color(0xFFFF5A1F),
        k,
      )!.withValues(alpha: (1 - k) * 0.85);
      canvas.drawCircle(Offset(x, y), size * 0.07 * (1 - k * 0.6), flame);
    }
  }

  // --- Effects ---

  void _particles(Canvas canvas, Iso iso, double t, double tile) {
    final p = Paint();
    for (var n = 0; n < controller.fx.length; n++) {
      final e = controller.fx[n];
      final age = t - e.at;
      final o = iso.p(e.x, e.y, e.z);
      final seed = (e.at * 1000).round() + n * 31;
      switch (e.kind) {
        case TowerFxKind.perfect:
          // Sparks flying off the block.
          if (age > 0.7) continue;
          final k = age / 0.7;
          for (var i = 0; i < 10 + min(e.combo, 8) * 2; i++) {
            final a = _rnd(seed + i) * pi * 2;
            final d = tile * (0.5 + _rnd(seed + i + 50) * 1.4) * _ease(k);
            p.color = (i.isEven ? const Color(0xFFFFF3B0) : Colors.white)
                .withValues(alpha: 1 - k);
            canvas.drawCircle(
              o + Offset(cos(a) * d, sin(a) * d * 0.5 - k * tile * 0.3),
              2.6 * (1 - k) + 0.8,
              p,
            );
          }
        case TowerFxKind.cut || TowerFxKind.closeCall:
          // Dust where the block was cut.
          if (age > 0.6) continue;
          final k = age / 0.6;
          for (var i = 0; i < 7; i++) {
            final a = _rnd(seed + i) * pi * 2;
            final d = tile * (0.3 + _rnd(seed + i + 9) * 0.7) * k;
            p.color = Colors.white.withValues(alpha: (1 - k) * 0.55);
            canvas.drawCircle(
              o + Offset(cos(a) * d, sin(a) * d * 0.4 - k * tile * 0.25),
              tile * 0.1 * (0.6 + k),
              p,
            );
          }
        case TowerFxKind.zone || TowerFxKind.record || TowerFxKind.revive:
          // Confetti.
          if (age > 2.2) continue;
          final count = e.kind == TowerFxKind.record ? 70 : 44;
          for (var i = 0; i < count; i++) {
            final a = -pi / 2 + (_rnd(seed + i) - 0.5) * pi * 1.3;
            final v = tile * (3.5 + _rnd(seed + i + 70) * 5.5);
            final x = cos(a) * v * age;
            final y = sin(a) * v * age + tile * 5.5 * age * age;
            p.color = towerPalette[i % towerPalette.length].withValues(
              alpha: (1 - age / 2.2).clamp(0, 1),
            );
            canvas.save();
            canvas.translate(o.dx + x, o.dy + y);
            canvas.rotate(age * (4 + _rnd(seed + i + 90) * 8));
            canvas.drawRect(const Rect.fromLTWH(-4, -2.5, 8, 5), p);
            canvas.restore();
          }
      }
    }
  }

  /// The words that pop up: small ones above Capi, big ones across the sky.
  void _popups(Canvas canvas, Size size, double t, Offset head) {
    final c = controller;
    TowerFx? small, big;
    for (final e in c.fx) {
      switch (e.kind) {
        case TowerFxKind.perfect || TowerFxKind.closeCall:
          small = e;
        case TowerFxKind.zone || TowerFxKind.record || TowerFxKind.revive:
          big = e;
        case TowerFxKind.cut:
          small = null;
      }
    }
    if (c.gameOver) return;
    // One thing at a time: the big moments have the sky to themselves.
    final bigOn = big != null && t - big.at < 2.3;

    if (!bigOn && small != null && t - small.at < 1.15) {
      final age = t - small.at;
      final close = small.kind == TowerFxKind.closeCall;
      final n = small.combo;
      final text = close
          ? tr('Por um fio!')
          : n >= 8
          ? tr('Lendário!')
          : n >= 5
          ? tr('Imbatível!')
          : n >= 3
          ? tr('Em chamas!')
          : n == 2
          ? tr('Demais!')
          : tr('Perfeito!');
      final color = close
          ? const Color(0xFFFF8A8A)
          : n >= 3
          ? const Color(0xFFFFB02E)
          : const Color(0xFFFFF3B0);
      final scale =
          _pop((age / 0.3).clamp(0, 1)) * (close ? 1 : 1 + min(n, 8) * 0.04);
      final alpha = (1 - (age - 0.8) / 0.35).clamp(0.0, 1.0);
      final at = Offset(
        head.dx.clamp(90.0, size.width - 90),
        max(150.0, head.dy - 26 - age * 22),
      );
      _burst(
        canvas,
        n > 1 && !close ? '$text x$n' : text,
        at,
        30,
        color,
        scale,
        alpha,
      );
    }

    if (bigOn) {
      final age = t - big.at;
      final scale = _pop((age / 0.4).clamp(0, 1));
      final alpha = (1 - (age - 1.8) / 0.5).clamp(0.0, 1.0);
      final at = Offset(size.width / 2, size.height * 0.27);
      final (title, sub, color) = switch (big.kind) {
        TowerFxKind.record => (
          tr('NOVO RECORDE!'),
          tr('Agora é só subir!'),
          const Color(0xFFFFD43B),
        ),
        TowerFxKind.revive => (
          tr('De volta!'),
          tr('Mais uma chance'),
          const Color(0xFF8CE99A),
        ),
        _ => (
          tr(big.zone!.name).toUpperCase(),
          tr('Andar {n}', {'n': big.zone!.floor}),
          Colors.white,
        ),
      };
      // A band of light behind the words.
      canvas.drawRect(
        Rect.fromCenter(center: at, width: size.width, height: 96 * scale),
        Paint()
          ..color = const Color(0xFF1E1B4B).withValues(alpha: 0.45 * alpha),
      );
      _burst(canvas, title, at - const Offset(0, 12), 38, color, scale, alpha);
      _burst(
        canvas,
        sub,
        at + const Offset(0, 26),
        17,
        Colors.white,
        scale,
        alpha,
      );
    }
  }

  TextPainter _layout(String text, double size, Color color, {Paint? stroke}) =>
      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: Fonts.display,
            fontSize: size,
            letterSpacing: 0.4,
            color: stroke == null ? color : null,
            foreground: stroke,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

  void _text(Canvas canvas, String text, Offset center, double size, Color c) {
    final tp = _layout(text, size, c);
    final at = center - Offset(tp.width / 2, tp.height / 2);
    _layout(
      text,
      size,
      c,
      stroke: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.22
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF1E1B4B),
    ).paint(canvas, at);
    tp.paint(canvas, at);
  }

  /// [text] with a dark outline, scaled around [center].
  void _burst(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
    double scale,
    double alpha,
  ) {
    if (alpha <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    final o = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.2
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF1E1B4B).withValues(alpha: alpha);
    final outline = _layout(text, size, color, stroke: o);
    final at = Offset(-outline.width / 2, -outline.height / 2);
    outline.paint(canvas, at + const Offset(0, 3));
    outline.paint(canvas, at);
    _layout(text, size, color.withValues(alpha: alpha)).paint(canvas, at);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TowerWorldPainter oldDelegate) => true;
}

/// Standalone vector Tower icon for menu cards and buttons.
class TowerIcon extends StatelessWidget {
  const TowerIcon({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _TowerIconPainter(),
    );
  }
}

class _TowerIconPainter extends CustomPainter {
  const _TowerIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;
    canvas.save();
    canvas.scale(s, s);

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(const Rect.fromLTWH(0, 0, 512, 512));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 16, 480, 480),
        const Radius.circular(110),
      ),
      bgPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF0C4A6E)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 16, 480, 480),
        const Radius.circular(110),
      ),
      borderPaint,
    );

    // Isometric Blocks
    // Block 1 (Bottom Emerald)
    _drawIsoBox(
      canvas,
      top: [
        const Offset(256, 310),
        const Offset(380, 350),
        const Offset(256, 390),
        const Offset(132, 350),
      ],
      left: [
        const Offset(132, 350),
        const Offset(256, 390),
        const Offset(256, 435),
        const Offset(132, 395),
      ],
      right: [
        const Offset(256, 390),
        const Offset(380, 350),
        const Offset(380, 395),
        const Offset(256, 435),
      ],
      topCol: const Color(0xFF34D399),
      leftCol: const Color(0xFF10B981),
      rightCol: const Color(0xFF059669),
    );

    // Block 2 (Middle Orange)
    _drawIsoBox(
      canvas,
      top: [
        const Offset(256, 225),
        const Offset(360, 260),
        const Offset(256, 295),
        const Offset(152, 260),
      ],
      left: [
        const Offset(152, 260),
        const Offset(256, 295),
        const Offset(256, 340),
        const Offset(152, 305),
      ],
      right: [
        const Offset(256, 295),
        const Offset(360, 260),
        const Offset(360, 305),
        const Offset(256, 340),
      ],
      topCol: const Color(0xFFFB923C),
      leftCol: const Color(0xFFF97316),
      rightCol: const Color(0xFFEA580C),
    );

    // Block 3 (Top Golden)
    _drawIsoBox(
      canvas,
      top: [
        const Offset(256, 145),
        const Offset(340, 175),
        const Offset(256, 205),
        const Offset(172, 175),
      ],
      left: [
        const Offset(172, 175),
        const Offset(256, 205),
        const Offset(256, 245),
        const Offset(172, 215),
      ],
      right: [
        const Offset(256, 205),
        const Offset(340, 175),
        const Offset(340, 215),
        const Offset(256, 245),
      ],
      topCol: const Color(0xFFFDE047),
      leftCol: const Color(0xFFFACC15),
      rightCol: const Color(0xFFEAB308),
    );

    // Helmet on top
    canvas.save();
    canvas.translate(256, 130);
    final hPaint = Paint()..color = const Color(0xFFFFD43B);
    final hBorder = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final hPath = Path()
      ..moveTo(-36, -8)
      ..quadraticBezierTo(0, -42, 36, -8)
      ..close();
    canvas.drawPath(hPath, hPaint);
    canvas.drawPath(hPath, hBorder);
    canvas.drawLine(
      const Offset(-42, -6),
      const Offset(42, -6),
      hBorder..strokeWidth = 8,
    );
    canvas.restore();

    canvas.restore();
  }

  void _drawIsoBox(
    Canvas canvas, {
    required List<Offset> top,
    required List<Offset> left,
    required List<Offset> right,
    required Color topCol,
    required Color leftCol,
    required Color rightCol,
  }) {
    final edgePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final topPath = Path()..addPolygon(top, true);
    final leftPath = Path()..addPolygon(left, true);
    final rightPath = Path()..addPolygon(right, true);

    canvas.drawPath(leftPath, Paint()..color = leftCol);
    canvas.drawPath(leftPath, edgePaint);

    canvas.drawPath(rightPath, Paint()..color = rightCol);
    canvas.drawPath(rightPath, edgePaint);

    canvas.drawPath(topPath, Paint()..color = topCol);
    canvas.drawPath(topPath, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
