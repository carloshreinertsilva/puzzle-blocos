import '../core/wardrobe.dart';

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/village.dart';
import '../ui/capi.dart';
import '../ui/pup.dart';
import 'iso.dart';
import 'items.dart';

/// What the village scene shows right now. The screen changes it; the
/// painter reads it every frame.
class VillageModel {
  /// Ids of the items built.
  Set<String> built = {};

  /// The item picked in the market: its spot glows on the island.
  String? selected;

  /// The item being built and when (clock seconds) it started dropping in.
  String? building;
  double buildStart = -10;

  /// The painted art of the items (see [VillageSprites]); an item without
  /// one is drawn in code.
  Map<String, ui.Image> sprites = const {};

  /// Pups saved in the levels; up to [Pups.max] wander on the island.
  int pups = 0;

  /// What Capi is wearing.
  CapiLook look = const CapiLook();

  /// Items (or 'capi', or 'pup3') tapped recently, and when.
  final Map<String, double> pokes = {};

  bool get cheering => building != null;
}

const _n = Village.island;
const _cliff = 1.1;
const _lagoonX = 5.8, _lagoonY = 5.0;
const _buildTime = 1.6;
const _pokeTime = 0.6;

double _lagoonR(double a) =>
    2.0 + 0.2 * sin(3 * a + 0.5) + 0.12 * cos(5 * a + 1.3);

List<P3> _lagoon(double grow, double z) => [
  for (var i = 0; i < 64; i++)
    (
      _lagoonX + cos(i * pi / 32) * (_lagoonR(i * pi / 32) + grow),
      _lagoonY + sin(i * pi / 32) * (_lagoonR(i * pi / 32) + grow),
      z,
    ),
];

bool _inLagoon(double x, double y, double grow) {
  final dx = x - _lagoonX, dy = y - _lagoonY;
  return sqrt(dx * dx + dy * dy) < _lagoonR(atan2(dy, dx)) + grow;
}

bool _inStream(double x, double y, double grow) =>
    x > 7.3 && y > 4.6 - grow && y < 5.4 + grow;

const _pathLine = [
  (7.75, 10.0),
  (7.35, 9.25),
  (6.8, 8.55),
  (6.15, 7.95),
  (5.8, 7.6),
];

bool _onPath(double x, double y, double grow) {
  for (var i = 0; i < _pathLine.length - 1; i++) {
    final (ax, ay) = _pathLine[i];
    final (bx, by) = _pathLine[i + 1];
    final vx = bx - ax, vy = by - ay;
    final f = (((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy)).clamp(
      0.0,
      1.0,
    );
    final dx = x - (ax + vx * f), dy = y - (ay + vy * f);
    if (dx * dx + dy * dy < pow(0.45 + grow, 2)) return true;
  }
  return false;
}

/// Where the scene sits on screen and what's under a finger.
class VillageLayout {
  VillageLayout(this.size) {
    tile = min(size.width / 10.4, size.height / 10.4);
    final top = (size.height - 10 * tile) * 0.62;
    origin = Offset(size.width / 2, top + 2.3 * tile);
  }

  final Size size;
  late final double tile;
  late final Offset origin;

  Iso get iso => Iso(origin, tile);

  static Rect bounds(Iso iso, Rect spot, double height) {
    var r = Rect.fromPoints(
      iso.p(spot.left, spot.top),
      iso.p(spot.left, spot.top),
    );
    for (final x in [spot.left, spot.right]) {
      for (final y in [spot.top, spot.bottom]) {
        for (final z in [0.0, height]) {
          r = r.expandToInclude(
            Rect.fromCircle(center: iso.p(x, y, z), radius: 0),
          );
        }
      }
    }
    return r;
  }

  /// The item id (or 'capi') at [point], front-most first.
  String? hit(Offset point, VillageModel model, double t) {
    final iso = this.iso;
    for (var i = min(model.pups, Pups.max) - 1; i >= 0; i--) {
      final at = Pups.at(i, t);
      final feet = iso.p(at.dx, at.dy);
      final size = tile * 0.8;
      if (Rect.fromLTWH(
        feet.dx - size / 2,
        feet.dy - size,
        size,
        size,
      ).inflate(tile * 0.15).contains(point)) {
        return 'pup$i';
      }
    }
    final built = model.built;
    final capi = iso.p(Village.capiSpot.dx, Village.capiSpot.dy);
    final capiSize = tile * 1.35;
    if (Rect.fromLTWH(
      capi.dx - capiSize * 0.4,
      capi.dy - capiSize,
      capiSize * 0.8,
      capiSize,
    ).contains(point)) {
      return 'capi';
    }
    final items = Village.items.where((i) => built.contains(i.id)).toList()
      ..sort((a, b) => _depth(b.spot).compareTo(_depth(a.spot)));
    for (final item in items) {
      final art = itemArt[item.id]!;
      if (bounds(
        iso,
        item.spot,
        art.height,
      ).inflate(tile * 0.1).contains(point)) {
        return item.id;
      }
    }
    return null;
  }
}

double _depth(Rect spot) => spot.right + spot.bottom;

/// The pups living on the island: each strolls around its own spot.
abstract final class Pups {
  /// Only a few at a time, so the island and its buildings stay the stars
  /// (the count of pups saved keeps growing).
  static const max = 5;
  static const _homes = [
    (8.0, 6.3),
    (2.4, 6.2),
    (5.5, 1.6),
    (4.4, 8.3),
    (7.8, 9.3),
  ];

  /// Where pup [i] is at time [t] (world x, y).
  static Offset at(int i, double t) {
    final (hx, hy) = _homes[i % _homes.length];
    return Offset(
      hx + 0.35 * sin(t * 0.32 + i * 1.7),
      hy + 0.25 * sin(t * 0.21 + i * 2.3),
    );
  }

  /// True while the pup walks toward +x on screen (for facing).
  static double speed(int i, double t) => cos(t * 0.32 + i * 1.7);
}

/// Recorded pictures of the parts that don't move, redrawn only when the
/// size or the village changes.
class VillageCache {
  double? _tile;
  int? _built;
  ui.Picture? _base;
  final Map<String, ui.Picture> _items = {};

  void _ensure(double tile, int built) {
    if (tile != _tile) {
      for (final p in _items.values) {
        p.dispose();
      }
      _items.clear();
    }
    if (tile != _tile || built != _built) {
      _base?.dispose();
      _base = _record((c) => _paintIsland(c, built));
    }
    _tile = tile;
    _built = built;
  }

  ui.Picture _record(void Function(IsoCanvas c) draw) {
    final recorder = ui.PictureRecorder();
    draw(IsoCanvas(Canvas(recorder), Iso(Offset.zero, _tileFor)));
    return recorder.endRecording();
  }

  double _tileFor = 1;

  ui.Picture base(double tile, int built) {
    _tileFor = tile;
    _ensure(tile, built);
    return _base!;
  }

  ui.Picture item(VillageItem item, double tile) {
    _tileFor = tile;
    return _items[item.id] ??= _record(
      (c) => itemArt[item.id]!.paint(c, item.spot, 0),
    );
  }

  void dispose() {
    _base?.dispose();
    for (final p in _items.values) {
      p.dispose();
    }
  }
}

class VillagePainter extends CustomPainter {
  VillagePainter({
    required this.clock,
    required this.model,
    required this.cache,
  }) : super(repaint: clock);

  final ValueListenable<double> clock;
  final VillageModel model;
  final VillageCache cache;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final layout = VillageLayout(size);
    final tile = layout.tile;

    _paintSky(canvas, size, tile, t);

    // The island floats, bobbing gently.
    final bob = sin(t * 0.9) * tile * 0.06;
    final origin = layout.origin + Offset(0, bob);
    _floatingRock(
      canvas,
      origin + Offset(tile * 5.3, tile * 4.1),
      tile * 0.55,
      t,
      0,
    );

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    final c = IsoCanvas(canvas, Iso(Offset.zero, tile));
    canvas.drawPicture(cache.base(tile, model.built.length));
    _paintWater(c, t);

    final sel = model.selected;
    final next = sel == null || model.built.contains(sel)
        ? null
        : Village.byId(sel);
    final showNext = next != null && model.building == null;
    if (showNext) _placeholder(c, next, t);

    // Items, decor and Capi, back to front.
    final things = <(double, void Function())>[
      for (final item in Village.items.where((i) => model.built.contains(i.id)))
        (_depth(item.spot), () => _paintItem(c, item, t)),
      for (final d in _decor) (d.$1 + d.$2 + 0.4, () => _paintDecor(c, d)),
      (Village.capiSpot.dx + Village.capiSpot.dy + 0.3, () => _paintCapi(c, t)),
      for (var i = 0; i < min(model.pups, Pups.max); i++)
        (Pups.at(i, t).dx + Pups.at(i, t).dy + 0.2, () => _paintPup(c, i, t)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, draw) in things) {
      draw();
    }

    if (showNext) _marker(c, next, t);
    final building = model.building;
    if (building != null) {
      _buildBurst(c, Village.items.firstWhere((i) => i.id == building), t);
    }
    canvas.restore();

    _floatingRock(
      canvas,
      origin + Offset(-tile * 5.0, tile * 5.6),
      tile * 0.75,
      t,
      1.7,
    );
    _paintClouds(canvas, size, tile, t, near: true);
    _paintBirds(canvas, size, tile, t);
  }

  // --- Sky -----------------------------------------------------------------

  void _paintSky(Canvas canvas, Size size, double tile, double t) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [
            const Color(0xFF5DB6EE),
            const Color(0xFFA7DAF4),
            const Color(0xFFE2F4F6),
          ],
          [0, 0.55, 1],
        ),
    );
    final sun = Offset(size.width * 0.14, size.height * 0.1);
    final r = tile * 0.9;
    canvas.save();
    canvas.translate(sun.dx, sun.dy);
    canvas.rotate(t * 0.08);
    final ray = Paint()..color = const Color(0x33FFF6C8);
    for (var k = 0; k < 12; k++) {
      canvas.rotate(pi / 6);
      canvas.drawPath(
        Path()
          ..moveTo(-r * 0.25, 0)
          ..lineTo(r * 0.25, 0)
          ..lineTo(0, -r * 3.2)
          ..close(),
        ray,
      );
    }
    canvas.restore();
    canvas.drawCircle(
      sun,
      r * 1.6,
      Paint()
        ..shader = ui.Gradient.radial(sun, r * 1.6, [
          const Color(0x88FFF6C8),
          const Color(0x00FFF6C8),
        ]),
    );
    canvas.drawCircle(sun, r, Paint()..color = const Color(0xFFFFE680));
    canvas.drawCircle(sun, r * 0.8, Paint()..color = const Color(0xFFFFF3B0));
    _paintClouds(canvas, size, tile, t, near: false);
  }

  void _paintClouds(
    Canvas canvas,
    Size size,
    double tile,
    double t, {
    required bool near,
  }) {
    final clouds = near
        ? const [(0.1, 0.92, 1.5, 9.0), (0.7, 0.97, 1.8, 7.0)]
        : const [
            (0.3, 0.16, 0.9, 5.0),
            (0.85, 0.26, 0.7, 4.0),
            (0.55, 0.42, 0.6, 3.0),
          ];
    for (final (x, y, scale, speed) in clouds) {
      final s = tile * scale;
      final span = size.width + s * 6;
      final cx = (x * span + t * speed * tile * 0.12) % span - s * 3;
      _cloud(canvas, Offset(cx, size.height * y), s, near ? 0.95 : 0.85);
    }
  }

  void _cloud(Canvas canvas, Offset at, double s, double alpha) {
    final shade = Paint()..color = Color.fromRGBO(206, 226, 245, alpha);
    final white = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);
    const puffs = [
      (-1.1, 0.1, 0.55),
      (-0.4, -0.25, 0.75),
      (0.45, -0.15, 0.65),
      (1.1, 0.12, 0.5),
      (0.0, 0.2, 0.6),
    ];
    for (final (dx, dy, r) in puffs) {
      canvas.drawCircle(at + Offset(dx * s, dy * s + s * 0.12), r * s, shade);
    }
    for (final (dx, dy, r) in puffs) {
      canvas.drawCircle(at + Offset(dx * s, dy * s), r * s * 0.92, white);
    }
  }

  void _paintBirds(Canvas canvas, Size size, double tile, double t) {
    final wing = Paint()
      ..color = const Color(0xCC2E3557)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tile * 0.05
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 2; k++) {
      final span = size.width + tile * 8;
      final x = (t * tile * 0.9 + k * tile * 1.2) % (span * 1.6) - tile * 2;
      if (x > span) continue;
      final y =
          size.height * 0.2 + k * tile * 0.5 + sin(t * 1.5 + k) * tile * 0.2;
      final flap = sin(t * 9 + k * 2) * tile * 0.12;
      final w = tile * 0.22;
      canvas.drawPath(
        Path()
          ..moveTo(x - w, y - flap)
          ..quadraticBezierTo(x - w / 2, y - w * 0.5, x, y)
          ..quadraticBezierTo(x + w / 2, y - w * 0.5, x + w, y - flap),
        wing,
      );
    }
  }

  void _floatingRock(
    Canvas canvas,
    Offset at,
    double s,
    double t,
    double phase,
  ) {
    final c = at + Offset(0, sin(t * 1.1 + phase) * s * 0.15);
    final top = Path()
      ..addOval(Rect.fromCenter(center: c, width: s * 1.6, height: s * 0.8));
    final body = Path()
      ..moveTo(c.dx - s * 0.8, c.dy)
      ..quadraticBezierTo(c.dx - s * 0.5, c.dy + s * 0.9, c.dx, c.dy + s * 1.2)
      ..quadraticBezierTo(c.dx + s * 0.6, c.dy + s * 0.8, c.dx + s * 0.8, c.dy)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(c + Offset(-s, 0), c + Offset(s, 0), [
          const Color(0xFF9A7A60),
          const Color(0xFF5E4334),
        ]),
    );
    canvas.drawPath(top, Paint()..color = const Color(0xFF7CC55A));
    canvas.drawCircle(
      c + Offset(-s * 0.2, -s * 0.12),
      s * 0.18,
      Paint()..color = const Color(0xFF5DAE48),
    );
  }

  // --- Water ---------------------------------------------------------------

  void _paintWater(IsoCanvas c, double t) {
    final tile = c.tile;
    // Sparkles on the lagoon.
    final rnd = Random(11);
    for (var i = 0; i < 16; i++) {
      final a = rnd.nextDouble() * 2 * pi;
      final d = sqrt(rnd.nextDouble()) * 1.7;
      final x = _lagoonX + cos(a) * d, y = _lagoonY + sin(a) * d;
      final on = pow(max(0.0, sin(t * 1.8 + i * 1.9)), 6).toDouble();
      if (on < 0.05) continue;
      final at = c.p(x, y, waterZ);
      final r = tile * 0.1 * on;
      c.canvas.drawPath(
        Path()
          ..moveTo(at.dx - r, at.dy)
          ..lineTo(at.dx, at.dy - r * 0.35)
          ..lineTo(at.dx + r, at.dy)
          ..lineTo(at.dx, at.dy + r * 0.35)
          ..close(),
        Paint()..color = Color.fromRGBO(255, 255, 255, on),
      );
    }
    // Slow ripples drifting across.
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tile * 0.025
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final x = _lagoonX - 1.2 + i * 0.55 + sin(t * 0.4 + i) * 0.25;
      final y = _lagoonY - 1.0 + (i * 0.73) % 2.2;
      final at = c.p(x, y, waterZ);
      ripple.color = Color.fromRGBO(255, 255, 255, 0.35 + 0.2 * sin(t + i));
      c.canvas.drawArc(
        Rect.fromCenter(center: at, width: tile * 0.5, height: tile * 0.14),
        pi * 1.1,
        pi * 0.8,
        false,
        ripple,
      );
    }

    // The stream spills off the edge as a waterfall.
    final fall = c.iso.path([
      (_n, 4.65, waterZ),
      (_n, 5.35, waterZ),
      (_n, 5.35, -_cliff - 2.6),
      (_n, 4.65, -_cliff - 2.6),
    ]);
    final b = fall.getBounds();
    c.canvas.drawPath(
      fall,
      Paint()
        ..shader = ui.Gradient.linear(
          b.topCenter,
          b.bottomCenter,
          [
            const Color(0xEE7FD8F2),
            const Color(0xCC4FB8E6),
            const Color(0x004FB8E6),
          ],
          [0, 0.6, 1],
        ),
    );
    final streak = Paint()
      ..strokeWidth = tile * 0.04
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 6; k++) {
      final y = 4.72 + k * 0.11;
      final q = (t * 0.9 + k * 0.37) % 1;
      final z0 = waterZ - q * (_cliff + 2.2);
      streak.color = Color.fromRGBO(255, 255, 255, 0.7 * (1 - q));
      c.canvas.drawLine(c.p(_n, y, z0), c.p(_n, y, z0 - 0.35), streak);
    }
    final lip = c.p(_n, 5.0, waterZ);
    for (var k = 0; k < 3; k++) {
      final q = (t * 1.2 + k / 3) % 1;
      c.canvas.drawCircle(
        lip + Offset(tile * (0.05 + q * 0.2), tile * q * 0.1),
        tile * 0.07 * (1 - q),
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }
  }

  // --- Things on the island --------------------------------------------------

  /// The squash and lift for an item that is dropping in or was tapped.
  (double, double, double) _motion(String id, double t) {
    var lift = 0.0, sx = 1.0, sy = 1.0;
    if (model.building == id) {
      final q = ((t - model.buildStart) / _buildTime).clamp(0.0, 1.0);
      if (q < 0.35) {
        final f = q / 0.35;
        lift = 6 * (1 - f * f);
      } else {
        final s = (q - 0.35) / 0.65;
        final wobble = exp(-4 * s) * cos(s * pi * 3);
        sy = 1 - 0.22 * wobble;
        sx = 1 + 0.14 * wobble;
      }
    }
    final poked = model.pokes[id];
    if (poked != null && t - poked < _pokeTime) {
      final s = (t - poked) / _pokeTime;
      final w = sin(s * pi * 3) * (1 - s);
      sy *= 1 - 0.16 * w;
      sx *= 1 + 0.1 * w;
    }
    return (lift, sx, sy);
  }

  void _paintItem(IsoCanvas c, VillageItem item, double t) {
    final art = itemArt[item.id]!;
    final (lift, sx, sy) = _motion(item.id, t);
    final base = c.p(item.spot.center.dx, item.spot.center.dy);
    final canvas = c.canvas;
    canvas.save();
    canvas.translate(base.dx, base.dy - lift * c.iso.zScale);
    canvas.scale(sx, sy);
    canvas.translate(-base.dx, -base.dy);
    final sprite = model.sprites[item.id];
    if (sprite != null) {
      VillageSprites.paint(c, item, sprite);
    } else if (art.animated) {
      art.paint(c, item.spot, t);
    } else {
      canvas.drawPicture(cache.item(item, c.tile));
      art.overlay(c, item.spot, t);
    }
    canvas.restore();
  }

  static const _decor = [
    (0.45, 6.35, true),
    (9.5, 9.4, true),
    (9.55, 0.35, true),
    (4.75, 8.7, false),
    (0.3, 2.4, false),
  ];

  void _paintDecor(IsoCanvas c, (double, double, bool) d) {
    final (x, y, bush) = d;
    if (bush) {
      c.shadow(x, y, 0.4, 0.2);
      c.ball(x - 0.15, y + 0.05, 0.22, 0.3, const Color(0xFF3F9A3E));
      c.ball(x + 0.15, y - 0.1, 0.28, 0.32, const Color(0xFF4DAA45));
      c.ball(x + 0.05, y + 0.18, 0.2, 0.26, const Color(0xFF5DBB4C));
      for (final (dx, dz) in [(-0.1, 0.4), (0.2, 0.45), (0.1, 0.25)]) {
        c.canvas.drawCircle(
          c.p(x + dx, y + 0.2, dz),
          c.tile * 0.045,
          Paint()..color = const Color(0xFFFFF3F8),
        );
      }
    } else {
      c.shadow(x, y, 0.3, 0.2);
      c.ball(x, y, 0.12, 0.26, const Color(0xFFA9A4BC));
      c.ball(x + 0.25, y + 0.15, 0.07, 0.16, const Color(0xFF9792AD));
    }
  }

  void _paintPup(IsoCanvas c, int i, double t) {
    final at = Pups.at(i, t);
    final feet = c.p(at.dx, at.dy);
    final size = c.tile * 0.62;
    final poked = model.pokes['pup$i'];
    var hop = 0.0;
    if (poked != null && t - poked < 0.6) {
      hop = sin((t - poked) / 0.6 * pi) * c.tile * 0.4;
    } else {
      hop = sin(t * 6 + i).abs() * c.tile * 0.03;
    }
    c.canvas.drawOval(
      Rect.fromCenter(center: feet, width: size * 0.6, height: size * 0.2),
      Paint()
        ..color = const Color(0x40231546)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, c.tile * 0.04),
    );
    // Screen-right when x grows faster than y; mirror to face the way it
    // walks.
    final facing = Pups.speed(i, t) >= 0 ? 1.0 : -1.0;
    c.canvas.save();
    c.canvas.translate(feet.dx, feet.dy - hop);
    c.canvas.scale(facing, 1);
    c.canvas.translate(-size / 2, -size);
    PupPainter.body(
      c.canvas,
      Size.square(size),
      t: (t * 0.8 + i * 0.13) % 1,
      bow: PupPainter.bows[i % PupPainter.bows.length],
    );
    c.canvas.restore();
  }

  void _paintCapi(IsoCanvas c, double t) {
    final feet = c.p(Village.capiSpot.dx, Village.capiSpot.dy);
    final size = c.tile * 1.35;
    // Hops: while cheering, when poked, and now and then on his own.
    var hop = 0.0;
    final poked = model.pokes['capi'];
    if (model.cheering) {
      hop = sin(t * 9).abs() * c.tile * 0.25;
    } else if (poked != null && t - poked < 0.7) {
      hop = sin((t - poked) / 0.7 * pi * 2).abs() * c.tile * 0.3;
    } else if (t % 7 < 0.8) {
      hop = sin((t % 7) / 0.8 * pi * 2).abs() * c.tile * 0.15;
    }
    c.canvas.drawOval(
      Rect.fromCenter(
        center: feet + Offset(c.tile * 0.05, 0),
        width: size * (0.5 - hop / size * 0.4),
        height: size * 0.16,
      ),
      Paint()
        ..color = const Color(0x40231546)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, c.tile * 0.05),
    );
    c.canvas.save();
    c.canvas.translate(feet.dx - size / 2, feet.dy - size - hop);
    CapiPainter(
      mood: model.cheering || (poked != null && t - poked < 1.2)
          ? CapiMood.cheer
          : CapiMood.happy,
      t: (t * 0.55) % 1,
      hat: model.look.hat,
      look: model.look,
    ).paint(c.canvas, Size.square(size));
    c.canvas.restore();
  }

  void _placeholder(IsoCanvas c, VillageItem item, double t) {
    final s = item.spot.inflate(0.08);
    final z = item.id == 'barco' ? waterZ + 0.02 : 0.02;
    final pulse = 0.5 + 0.5 * sin(t * 3);
    final area = c.iso.path([
      (s.left, s.top, z),
      (s.right, s.top, z),
      (s.right, s.bottom, z),
      (s.left, s.bottom, z),
    ]);
    c.fill(area, Color.fromRGBO(255, 255, 255, 0.12 + 0.12 * pulse));
    final dash = Paint()
      ..color = Color.fromRGBO(255, 255, 255, 0.6 + 0.35 * pulse)
      ..strokeWidth = c.tile * 0.04
      ..strokeCap = StrokeCap.round;
    final corners = [
      (s.left, s.top),
      (s.right, s.top),
      (s.right, s.bottom),
      (s.left, s.bottom),
    ];
    for (var i = 0; i < 4; i++) {
      final (ax, ay) = corners[i];
      final (bx, by) = corners[(i + 1) % 4];
      final len = sqrt(pow(bx - ax, 2) + pow(by - ay, 2));
      final n = max(1, (len / 0.22).floor());
      for (var k = 0; k < n; k += 2) {
        final f0 = k / n, f1 = min(1.0, (k + 1) / n);
        c.canvas.drawLine(
          c.p(ax + (bx - ax) * f0, ay + (by - ay) * f0, z),
          c.p(ax + (bx - ax) * f1, ay + (by - ay) * f1, z),
          dash,
        );
      }
    }
  }

  /// A golden star spinning over the next item's spot, over everything.
  void _marker(IsoCanvas c, VillageItem item, double t) {
    final pulse = 0.5 + 0.5 * sin(t * 3);
    final art = itemArt[item.id]!;
    final starZ = min(art.height * 0.5, 1.6) + 0.9 + 0.15 * sin(t * 3);
    final at = c.p(item.spot.center.dx, item.spot.center.dy, starZ);
    final r = c.tile * 0.32;
    c.canvas.drawCircle(
      at,
      r * 1.9,
      Paint()
        ..shader = ui.Gradient.radial(at, r * 1.9, [
          Color.fromRGBO(255, 236, 140, 0.35 + 0.2 * pulse),
          const Color(0x00FFEC8C),
        ]),
    );
    c.canvas.save();
    c.canvas.translate(at.dx, at.dy);
    c.canvas.scale(max(0.15, cos(t * 2.2).abs()), 1);
    _star(c.canvas, r, const Color(0xFFFFC94D));
    c.canvas.restore();
  }

  void _buildBurst(IsoCanvas c, VillageItem item, double t) {
    final q = (t - model.buildStart) / _buildTime;
    if (q < 0.35 || q > 1) return;
    final s = (q - 0.35) / 0.65;
    final ease = 1 - pow(1 - s, 3).toDouble();
    final cx = item.spot.center.dx, cy = item.spot.center.dy;
    final reach = 0.4 + max(item.spot.width, item.spot.height) * 0.5;
    final z = item.id == 'barco' ? waterZ : 0.0;
    for (var k = 0; k < 12; k++) {
      final a = k * pi / 6 + 0.2;
      final d = reach * (0.6 + ease * 0.6);
      final at = c.p(cx + cos(a) * d, cy + sin(a) * d, z + ease * 0.3);
      final r = c.tile * (0.14 + 0.2 * s);
      c.canvas.drawCircle(
        at,
        r,
        Paint()..color = Color.fromRGBO(214, 196, 170, 0.75 * (1 - s)),
      );
      c.canvas.drawCircle(
        at + Offset(-r * 0.3, -r * 0.3),
        r * 0.6,
        Paint()..color = Color.fromRGBO(255, 250, 238, 0.8 * (1 - s)),
      );
    }
    for (var k = 0; k < 7; k++) {
      final a = k * 2 * pi / 7;
      final at = c.p(
        cx + cos(a) * ease * 1.1,
        cy + sin(a) * ease * 1.1,
        z + 0.5 + s * 2.2 - s * s * 1.4,
      );
      c.canvas.save();
      c.canvas.translate(at.dx, at.dy);
      c.canvas.rotate(s * 4 + k);
      _star(
        c.canvas,
        c.tile * 0.16 * (1 - s * 0.5),
        Color.fromRGBO(255, 201, 77, 1 - s),
      );
      c.canvas.restore();
    }
  }

  static void _star(Canvas canvas, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final p = Offset(cos(a) * rr, sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(
          color,
          const Color(0xFF8A4B00),
          0.6,
        )!.withValues(alpha: color.a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      Offset(-r * 0.15, -r * 0.2),
      r * 0.18,
      Paint()..color = Color.fromRGBO(255, 255, 255, 0.7 * color.a),
    );
  }

  @override
  bool shouldRepaint(VillagePainter old) => true;
}

// --- The island itself (recorded once) ---------------------------------------

void _paintIsland(IsoCanvas c, int built) {
  final iso = c.iso;
  final tile = c.tile;
  final canvas = c.canvas;
  final rnd = Random(5);

  // The rocky underside, hanging below the cliffs.
  final left = iso.p(0, _n, -_cliff);
  final front = iso.p(_n, _n, -_cliff);
  final right = iso.p(_n, 0, -_cliff);
  final tip = front + Offset(-tile * 0.3, tile * 1.9);
  Offset jag(Offset a, Offset ctrl, Offset b, double f, double j) {
    final p = Offset(
      (1 - f) * (1 - f) * a.dx + 2 * (1 - f) * f * ctrl.dx + f * f * b.dx,
      (1 - f) * (1 - f) * a.dy + 2 * (1 - f) * f * ctrl.dy + f * f * b.dy,
    );
    return p + Offset(0, (rnd.nextDouble() - 0.5) * tile * j);
  }

  final under = Path()..moveTo(left.dx, left.dy);
  final ctrlL = Offset(left.dx + tile * 0.6, tip.dy - tile * 0.3);
  final ctrlR = Offset(right.dx - tile * 0.6, tip.dy - tile * 0.3);
  for (var i = 1; i <= 10; i++) {
    final p = jag(left, ctrlL, tip, i / 10, i == 10 ? 0 : 0.35);
    under.lineTo(p.dx, p.dy);
  }
  final rightSide = <Offset>[];
  for (var i = 1; i <= 10; i++) {
    rightSide.add(jag(tip, ctrlR, right, i / 10, i == 10 ? 0 : 0.35));
  }
  for (final p in rightSide) {
    under.lineTo(p.dx, p.dy);
  }
  under
    ..lineTo(front.dx, front.dy)
    ..close();
  final ub = under.getBounds();
  canvas.drawPath(
    under,
    Paint()
      ..shader = ui.Gradient.linear(ub.topCenter, ub.bottomCenter, [
        const Color(0xFF8E6B52),
        const Color(0xFF5B3F33),
      ]),
  );
  final shadeSide = Path()
    ..moveTo(front.dx, front.dy)
    ..lineTo(tip.dx, tip.dy);
  for (final p in rightSide) {
    shadeSide.lineTo(p.dx, p.dy);
  }
  shadeSide.close();
  canvas.drawPath(shadeSide, Paint()..color = const Color(0x40231546));
  // A few gems in the rock.
  for (final (dx, dy, s) in [
    (-1.6, 0.6, 1.0),
    (1.2, 0.9, 0.8),
    (-0.4, 1.4, 0.7),
  ]) {
    final g = front + Offset(dx * tile, dy * tile);
    final r = tile * 0.18 * s;
    final gem = Path()
      ..moveTo(g.dx, g.dy - r * 1.4)
      ..lineTo(g.dx + r, g.dy)
      ..lineTo(g.dx, g.dy + r * 1.1)
      ..lineTo(g.dx - r, g.dy)
      ..close();
    canvas.drawPath(gem, Paint()..color = const Color(0xFF8CF0FF));
    canvas.drawPath(
      Path()
        ..moveTo(g.dx, g.dy - r * 1.4)
        ..lineTo(g.dx + r, g.dy)
        ..lineTo(g.dx, g.dy + r * 1.1)
        ..close(),
      Paint()..color = const Color(0xFF3FB6D8),
    );
  }

  // Cliffs: soil, then rock, under a grass lip.
  final lit = iso.path([
    (0, _n, 0),
    (_n, _n, 0),
    (_n, _n, -_cliff),
    (0, _n, -_cliff),
  ]);
  final shade = iso.path([
    (_n, 0, 0),
    (_n, _n, 0),
    (_n, _n, -_cliff),
    (_n, 0, -_cliff),
  ]);
  c.fillV(lit, const Color(0xFFA9774A), const Color(0xFF7A5236));
  c.fillV(shade, const Color(0xFF7D5535), const Color(0xFF573A27));
  c.fill(
    iso.path([
      (0, _n, -0.7),
      (_n, _n, -0.7),
      (_n, _n, -_cliff),
      (0, _n, -_cliff),
    ]),
    const Color(0x33231546),
  );
  c.fill(
    iso.path([
      (_n, 0, -0.7),
      (_n, _n, -0.7),
      (_n, _n, -_cliff),
      (_n, 0, -_cliff),
    ]),
    const Color(0x33231546),
  );
  // Stones set in the cliffs.
  for (var i = 0; i < 26; i++) {
    final onLit = i.isEven;
    final s = 0.3 + rnd.nextDouble() * 9.4;
    final z = -0.35 - rnd.nextDouble() * 0.65;
    final at = onLit ? iso.p(s, _n, z) : iso.p(_n, s, z);
    final w = tile * (0.16 + rnd.nextDouble() * 0.14);
    final base = onLit ? const Color(0xFFB59A84) : const Color(0xFF8C735F);
    canvas.drawOval(
      Rect.fromCenter(
        center: at + Offset(0, w * 0.12),
        width: w,
        height: w * 0.6,
      ),
      Paint()..color = dark(base, 0.45),
    );
    canvas.drawOval(
      Rect.fromCenter(center: at, width: w, height: w * 0.55),
      Paint()..color = base,
    );
  }
  // Roots dangling from the bottom edge.
  final root = Paint()
    ..color = const Color(0xFF5B3A24)
    ..style = PaintingStyle.stroke
    ..strokeWidth = tile * 0.035
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 9; i++) {
    final onLit = i.isEven;
    final s = 0.8 + i * 1.0;
    final from = onLit ? iso.p(s, _n, -_cliff) : iso.p(_n, s, -_cliff);
    final len = tile * (0.3 + rnd.nextDouble() * 0.45);
    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(
          from.dx + tile * 0.12,
          from.dy + len * 0.5,
          from.dx - tile * 0.05,
          from.dy + len,
        ),
      root,
    );
  }
  // The grass lip, drooping over the edge.
  List<P3> lip(bool onLit) {
    final pts = <P3>[];
    for (var s = 0.0; s <= _n + 0.001; s += 0.25) {
      final drip = (s * 1.7) % 2.3 < 0.3 ? 0.14 : 0.0;
      final z = -0.12 - 0.06 * sin(s * 2.3).abs() - drip;
      pts.add(onLit ? (s, _n, z) : (_n, s, z));
    }
    return pts;
  }

  c.fill(
    iso.path([(0, _n, 0), (_n, _n, 0), ...lip(true).reversed]),
    const Color(0xFF5FAE45),
  );
  c.fill(
    iso.path([(_n, 0, 0), (_n, _n, 0), ...lip(false).reversed]),
    const Color(0xFF4A8F3A),
  );

  // The grass, a soft checkerboard.
  final ground = iso.path([(0, 0, 0), (_n, 0, 0), (_n, _n, 0), (0, _n, 0)]);
  c.fill(ground, const Color(0xFF7BC459));
  final alt = Paint()..color = const Color(0xFF86CC64);
  for (var i = 0; i < _n; i++) {
    for (var j = 0; j < _n; j++) {
      if ((i + j).isEven) continue;
      final x = i.toDouble(), y = j.toDouble();
      canvas.drawPath(
        iso.path([(x, y, 0), (x + 1, y, 0), (x + 1, y + 1, 0), (x, y + 1, 0)]),
        alt,
      );
    }
  }
  canvas.drawPath(
    iso.path([(0, _n, 0), (_n, _n, 0), (_n, 0, 0)])..close(),
    Paint()
      ..color = const Color(0x55E8FFD0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tile * 0.04,
  );

  // The dirt path to the pier, with stepping stones.
  final pathPts = <(double, double)>[];
  final leftEdge = <P3>[], rightEdge = <P3>[];
  for (var i = 0; i < _pathLine.length; i++) {
    final (x, y) = _pathLine[i];
    final (ax, ay) = _pathLine[max(0, i - 1)];
    final (bx, by) = _pathLine[min(_pathLine.length - 1, i + 1)];
    final dx = bx - ax, dy = by - ay;
    final len = sqrt(dx * dx + dy * dy);
    final nx = -dy / len * 0.45, ny = dx / len * 0.45;
    leftEdge.add((x + nx, y + ny, 0));
    rightEdge.add((x - nx, y - ny, 0));
    pathPts.add((x, y));
  }
  final dirt = iso.path([...leftEdge, ...rightEdge.reversed]);
  c.fill(dirt, const Color(0xFFE5C68D));
  c.stroke(dirt, const Color(0xFFC9A46A), 0.03);
  for (var i = 0; i < pathPts.length - 1; i++) {
    final (x, y) = pathPts[i];
    final (bx, by) = pathPts[i + 1];
    final at = iso.p((x + bx) / 2 + 0.08, (y + by) / 2 - 0.05);
    final w = tile * 0.42;
    canvas.drawOval(
      Rect.fromCenter(
        center: at + Offset(0, tile * 0.03),
        width: w,
        height: w * 0.48,
      ),
      Paint()..color = const Color(0xFFA9A2B8),
    );
    canvas.drawOval(
      Rect.fromCenter(center: at, width: w, height: w * 0.45),
      Paint()..color = const Color(0xFFD9D4E4),
    );
  }

  // The lagoon: a sandy shore, the bank's inner wall, then the water.
  c.fill(iso.path(_lagoon(0.3, 0)), const Color(0xFFEAD49C));
  c.fill(
    iso.path([(7.2, 4.4, 0), (_n, 4.4, 0), (_n, 5.6, 0), (7.2, 5.6, 0)]),
    const Color(0xFFEAD49C),
  );
  final bank = Path.combine(
    PathOperation.union,
    iso.path(_lagoon(0, 0)),
    iso.path([(7.4, 4.65, 0), (_n, 4.65, 0), (_n, 5.35, 0), (7.4, 5.35, 0)]),
  );
  c.fill(bank, const Color(0xFF6F8F5A));
  final water = Path.combine(
    PathOperation.union,
    iso.path(_lagoon(0, waterZ)),
    iso.path([
      (7.4, 4.65, waterZ),
      (_n + 0.5, 4.65, waterZ),
      (_n + 0.5, 5.35, waterZ),
      (7.4, 5.35, waterZ),
    ]),
  );
  canvas.save();
  canvas.clipPath(bank);
  final wb = water.getBounds();
  canvas.drawPath(
    water,
    Paint()
      ..shader = ui.Gradient.linear(
        wb.topCenter,
        wb.bottomCenter,
        [
          const Color(0xFF86DDF3),
          const Color(0xFF3AA6DB),
          const Color(0xFF2B8BCB),
        ],
        [0, 0.6, 1],
      ),
  );
  canvas.drawPath(
    iso.path(_lagoon(-0.12, waterZ)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tile * 0.12
      ..color = const Color(0x55C8F4FF),
  );
  canvas.restore();
  canvas.drawPath(
    bank,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tile * 0.025
      ..color = const Color(0x66A88A50),
  );
  // Lily pads.
  for (final (x, y, flower) in [
    (4.85, 6.05, true),
    (7.0, 4.05, false),
    (6.75, 6.3, false),
    (4.3, 3.9, true),
  ]) {
    final at = iso.p(x, y, waterZ);
    final rect = Rect.fromCenter(
      center: at,
      width: tile * 0.42,
      height: tile * 0.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(at.dx, at.dy)
        ..arcTo(rect, 0.35, 2 * pi - 0.7, false)
        ..close(),
      Paint()..color = const Color(0xFF5DAF5A),
    );
    if (flower) {
      canvas.drawCircle(
        at + Offset(-tile * 0.04, -tile * 0.05),
        tile * 0.07,
        Paint()..color = const Color(0xFFFF9EC7),
      );
      canvas.drawCircle(
        at + Offset(-tile * 0.04, -tile * 0.06),
        tile * 0.03,
        Paint()..color = const Color(0xFFFFE680),
      );
    }
  }

  // Tufts, little flowers and pebbles in the grass, clear of what's built.
  final taken = [
    for (final i in Village.items.take(built)) i.spot.inflate(0.12),
  ];
  final tuft = Paint()
    ..color = const Color(0xFF4E9A3C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = tile * 0.03
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 170; i++) {
    final x = 0.2 + rnd.nextDouble() * 9.6, y = 0.2 + rnd.nextDouble() * 9.6;
    final kind = rnd.nextInt(10);
    if (_inLagoon(x, y, 0.45) || _inStream(x, y, 0.3) || _onPath(x, y, 0.1)) {
      continue;
    }
    if (taken.any((r) => r.contains(Offset(x, y)))) continue;
    final at = iso.p(x, y);
    if (kind < 6) {
      for (final a in [-0.5, 0.0, 0.45]) {
        canvas.drawLine(
          at,
          at + Offset(sin(a) * tile * 0.1, -cos(a) * tile * 0.14),
          tuft,
        );
      }
    } else if (kind < 9) {
      final color = kind == 6
          ? const Color(0xFFFFFFFF)
          : kind == 7
          ? const Color(0xFFFFE066)
          : const Color(0xFFFF9EC7);
      for (final o in [
        const Offset(0, 0),
        const Offset(0.12, 0.05),
        const Offset(-0.08, 0.07),
      ]) {
        canvas.drawCircle(at + o * tile, tile * 0.04, Paint()..color = color);
      }
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: at, width: tile * 0.16, height: tile * 0.08),
        Paint()..color = const Color(0xFFBDB8CF),
      );
    }
  }
}

/// One item drawn on its own, fitted in a box: the "next" icon in the panel.
class VillageItemIcon extends StatelessWidget {
  const VillageItemIcon({super.key, required this.item, this.size = 62});
  final VillageItem item;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    VillageSprites.asset(item.id),
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    // Without the picture (not bundled yet), the drawing in code.
    errorBuilder: (_, _, _) =>
        CustomPaint(size: Size.square(size), painter: _IconPainter(item)),
  );
}

/// The village items' painted art: one picture per item in `assets/vila/`
/// (the sources are in `art/vila/`, cut out with `tool/vila_recorta.py`).
abstract final class VillageSprites {
  static String asset(String id) => 'assets/vila/$id.webp';

  /// How each picture sits on its spot: its width in tiles, how far below
  /// the spot's front corner its bottom goes (tiles), and in how many
  /// copies it is laid along the spot (the fence is two short stretches).
  static const fit = <String, (double, double, int)>{
    'flores': (1.22, 0.07, 1),
    'cerca': (1.5, 0.04, 2),
    'banco': (0.83, 0.04, 1),
    'arvore': (1.51, 0.11, 1),
    'barco': (1.12, 0.12, 1),
    'horta': (1.73, 0.07, 1),
    'poste': (0.6, 0.08, 1),
    'pier': (1.15, 0.07, 1),
    'casinha': (2.05, 0.07, 1),
    'balanco': (1.15, 0.07, 1),
    'fonte': (1.44, 0.07, 1),
    'roda': (1.73, 0.07, 1),
  };

  /// Loads every picture there is; a missing one is simply left out.
  static Future<Map<String, ui.Image>> load([AssetBundle? bundle]) async {
    final out = <String, ui.Image>{};
    for (final id in fit.keys) {
      try {
        final data = await (bundle ?? rootBundle).load(asset(id));
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        out[id] = (await codec.getNextFrame()).image;
      } catch (_) {
        // Not bundled: the item keeps its drawing in code.
      }
    }
    return out;
  }

  /// Draws [image] standing on [item]'s spot.
  static void paint(IsoCanvas c, VillageItem item, ui.Image image) {
    final (width, drop, copies) = fit[item.id] ?? (1.0, 0.0, 1);
    final spot = item.spot;
    final long = spot.width >= spot.height;
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;
    for (var i = 0; i < copies; i++) {
      // The spot cut in [copies] equal stretches along its long side.
      final part = long
          ? Rect.fromLTWH(
              spot.left + spot.width * i / copies,
              spot.top,
              spot.width / copies,
              spot.height,
            )
          : Rect.fromLTWH(
              spot.left,
              spot.top + spot.height * i / copies,
              spot.width,
              spot.height / copies,
            );
      final w = width * c.tile;
      final h = w * image.height / image.width;
      final x = c.p(part.center.dx, part.center.dy).dx;
      final bottom = c.p(part.right, part.bottom).dy + drop * c.tile;
      c.canvas.drawImageRect(
        image,
        src,
        Rect.fromLTWH(x - w / 2, bottom - h, w, h),
        paint,
      );
    }
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.item);
  final VillageItem item;

  @override
  void paint(Canvas canvas, Size size) {
    final art = itemArt[item.id]!;
    final unit = VillageLayout.bounds(
      const Iso(Offset.zero, 1),
      item.spot,
      art.height,
    );
    final tile = min(size.width / unit.width, size.height / unit.height) * 0.9;
    final origin = size.center(Offset.zero) - unit.center * tile;
    final c = IsoCanvas(canvas, Iso(origin, tile));
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    art.paint(c, item.spot, 1);
    art.overlay(c, item.spot, 1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.item != item;
}
