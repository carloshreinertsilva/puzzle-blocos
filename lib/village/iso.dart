import 'dart:math';
import 'dart:ui';

/// A point in the village's world: x runs to the lower right of the screen,
/// y to the lower left and z up. One unit is one ground tile.
typedef P3 = (double, double, double);

/// World → screen for the village's isometric (2:1) projection.
class Iso {
  const Iso(this.origin, this.tile);

  /// Screen position of the world's (0, 0, 0): the island's back corner.
  final Offset origin;

  /// Screen width of one tile.
  final double tile;

  double get zScale => tile * 0.62;

  /// Screen radii of a ground circle of radius [r].
  double rx(double r) => r * tile * 0.7071;
  double ry(double r) => r * tile * 0.3536;

  Offset p(double x, double y, [double z = 0]) => Offset(
    origin.dx + (x - y) * tile / 2,
    origin.dy + (x + y) * tile / 4 - z * zScale,
  );

  Offset at(P3 q) => p(q.$1, q.$2, q.$3);

  Path path(Iterable<P3> points) {
    final out = Path();
    var first = true;
    for (final q in points) {
      final s = at(q);
      first ? out.moveTo(s.dx, s.dy) : out.lineTo(s.dx, s.dy);
      first = false;
    }
    return out..close();
  }
}

/// Shadows lean blue-purple and light leans warm, which reads better than
/// plain black and white.
const _shadowTint = Color(0xFF231546);
const _lightTint = Color(0xFFFFF6DC);

Color dark(Color c, double t) => Color.lerp(c, _shadowTint, t)!;
Color light(Color c, double t) => Color.lerp(c, _lightTint, t)!;

/// Drawing helpers in world coordinates. The sun is to the upper left: tops
/// are brightest, faces looking down-left (+y) are lit and faces looking
/// down-right (+x) are in shade; cast shadows fall toward +x.
class IsoCanvas {
  IsoCanvas(this.canvas, this.iso);
  final Canvas canvas;
  final Iso iso;

  double get tile => iso.tile;
  Offset p(double x, double y, [double z = 0]) => iso.p(x, y, z);

  void fill(Path path, Color c) => canvas.drawPath(path, Paint()..color = c);

  /// Fills with a vertical gradient over the path's bounds.
  void fillV(Path path, Color top, Color bottom) {
    final b = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(b.topCenter, b.bottomCenter, [top, bottom]),
    );
  }

  /// Fills with a horizontal gradient over the path's bounds.
  void fillH(Path path, List<Color> colors, [List<double>? stops]) {
    final b = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(b.centerLeft, b.centerRight, colors, stops),
    );
  }

  void stroke(Path path, Color c, [double width = 0.022]) => canvas.drawPath(
    path,
    Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = tile * width
      ..strokeJoin = StrokeJoin.round,
  );

  /// A straight beam between two world points, with a darker rim.
  void beam(P3 a, P3 b, Color c, double width) {
    final pa = iso.at(a), pb = iso.at(b);
    final w = tile * width;
    canvas.drawLine(
      pa,
      pb,
      Paint()
        ..color = dark(c, 0.55)
        ..strokeWidth = w + tile * 0.04
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pa,
      pb,
      Paint()
        ..color = c
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  /// A soft shadow on the ground under something round of radius [r].
  void shadow(double x, double y, double r, [double alpha = 0.24]) {
    final c = p(x + r * 0.2, y - r * 0.05);
    canvas.drawOval(
      Rect.fromCenter(
        center: c,
        width: iso.rx(r) * 2.3,
        height: iso.ry(r) * 2.3,
      ),
      Paint()
        ..color = Color.fromRGBO(30, 20, 60, alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, tile * 0.08),
    );
  }

  /// The shadow a box of height [h] casts: its footprint stretched toward +x.
  void boxShadow(
    double x,
    double y,
    double dx,
    double dy,
    double h, [
    double alpha = 0.26,
  ]) {
    final s = h * 0.55;
    canvas.drawPath(
      iso.path([
        (x - 0.04, y + 0.02, 0),
        (x + dx + s, y + 0.02, 0),
        (x + dx + s, y + dy + 0.08, 0),
        (x - 0.04, y + dy + 0.08, 0),
      ]),
      Paint()
        ..color = Color.fromRGBO(30, 20, 60, alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, tile * 0.07),
    );
  }

  /// A box from (x, y, z) with size (dx, dy, dz): top, lit face, shaded face.
  void box(
    double x,
    double y,
    double z,
    double dx,
    double dy,
    double dz,
    Color c, {
    Color? top,
    bool outline = true,
  }) {
    final x1 = x + dx, y1 = y + dy, z1 = z + dz;
    final lit = iso.path([(x, y1, z), (x1, y1, z), (x1, y1, z1), (x, y1, z1)]);
    final shade = iso.path([
      (x1, y, z),
      (x1, y1, z),
      (x1, y1, z1),
      (x1, y, z1),
    ]);
    final cap = iso.path([(x, y, z1), (x1, y, z1), (x1, y1, z1), (x, y1, z1)]);
    fillV(lit, c, dark(c, 0.14));
    fillV(shade, dark(c, 0.3), dark(c, 0.42));
    fill(cap, top ?? light(c, 0.2));
    if (outline) {
      final edge = dark(c, 0.62).withValues(alpha: 0.75);
      stroke(lit, edge, 0.016);
      stroke(shade, edge, 0.016);
      stroke(cap, edge, 0.016);
    }
  }

  /// An upright cylinder standing at (x, y, z).
  void cylinder(
    double x,
    double y,
    double z,
    double r,
    double h,
    Color c, {
    Color? top,
    bool outline = true,
  }) {
    final rx = iso.rx(r), ry = iso.ry(r);
    final b = p(x, y, z), t = p(x, y, z + h);
    final side = Path()
      ..moveTo(t.dx - rx, t.dy)
      ..lineTo(b.dx - rx, b.dy)
      ..arcTo(
        Rect.fromCenter(center: b, width: rx * 2, height: ry * 2),
        pi,
        -pi,
        false,
      )
      ..lineTo(t.dx + rx, t.dy)
      ..close();
    fillH(side, [light(c, 0.12), c, dark(c, 0.38)], [0, 0.35, 1]);
    final cap = Path()
      ..addOval(Rect.fromCenter(center: t, width: rx * 2, height: ry * 2));
    fill(cap, top ?? light(c, 0.22));
    if (outline) {
      final edge = dark(c, 0.62).withValues(alpha: 0.75);
      stroke(side, edge, 0.016);
      stroke(cap, edge, 0.016);
    }
  }

  /// A cone (round roofs, carrot tips) standing at (x, y, z).
  void cone(double x, double y, double z, double r, double h, Color c) {
    final rx = iso.rx(r), ry = iso.ry(r);
    final b = p(x, y, z), apex = p(x, y, z + h);
    final side = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(b.dx - rx, b.dy)
      ..arcTo(
        Rect.fromCenter(center: b, width: rx * 2, height: ry * 2),
        pi,
        -pi,
        false,
      )
      ..close();
    fillH(side, [light(c, 0.15), c, dark(c, 0.4)], [0, 0.35, 1]);
    stroke(side, dark(c, 0.62).withValues(alpha: 0.7), 0.016);
  }

  /// A shaded ball (foliage, fruit, lamps), lit from the upper left.
  void ball(
    double x,
    double y,
    double z,
    double r,
    Color c, {
    bool rim = true,
  }) {
    final center = p(x, y, z);
    final rr = r * tile * 0.72;
    final rect = Rect.fromCircle(center: center, radius: rr);
    canvas.drawCircle(
      center,
      rr,
      Paint()
        ..shader = Gradient.radial(
          center + Offset(-rr * 0.38, -rr * 0.42),
          rr * 1.5,
          [light(c, 0.35), c, dark(c, 0.4)],
          [0, 0.45, 1],
        ),
    );
    if (rim) {
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tile * 0.016
          ..color = dark(c, 0.6).withValues(alpha: 0.6),
      );
    }
  }

  /// An outlined prism: the convex-ish ground polygon [outline] extruded
  /// from z0 to z1, its sides shaded by where they face.
  /// [inset] pulls the bottom in (boat hulls).
  void prism(
    List<(double, double)> outline,
    double z0,
    double z1,
    Color c, {
    Color? top,
    double inset = 0,
  }) {
    var cx = 0.0, cy = 0.0;
    for (final (x, y) in outline) {
      cx += x;
      cy += y;
    }
    cx /= outline.length;
    cy /= outline.length;
    (double, double) low((double, double) q) =>
        (q.$1 + (cx - q.$1) * inset, q.$2 + (cy - q.$2) * inset);

    final n = outline.length;
    final edge = dark(c, 0.62).withValues(alpha: 0.7);
    for (var i = 0; i < n; i++) {
      final a = outline[i], b = outline[(i + 1) % n];
      // The edge's normal, turned to point away from the middle.
      var nx = b.$2 - a.$2, ny = -(b.$1 - a.$1);
      final mx = (a.$1 + b.$1) / 2 - cx, my = (a.$2 + b.$2) / 2 - cy;
      if (nx * mx + ny * my < 0) {
        nx = -nx;
        ny = -ny;
      }
      final len = sqrt(nx * nx + ny * ny);
      if (len == 0 || nx + ny <= 0) continue;
      final f = (0.5 + 0.5 * (ny - nx) / len).clamp(0.0, 1.0);
      final face = iso.path([
        (low(a).$1, low(a).$2, z0),
        (low(b).$1, low(b).$2, z0),
        (b.$1, b.$2, z1),
        (a.$1, a.$2, z1),
      ]);
      final col = Color.lerp(dark(c, 0.38), c, f)!;
      fill(face, col);
      stroke(face, edge, 0.012);
    }
    final cap = iso.path([for (final (x, y) in outline) (x, y, z1)]);
    fill(cap, top ?? light(c, 0.2));
    stroke(cap, edge, 0.016);
  }
}
