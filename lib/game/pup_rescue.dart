import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../ui/pup.dart';
import 'effects.dart';

/// A freed pup pops out of its block, hops up with little hearts and
/// bounces off toward the goals at the top of the screen.
class PupRescue extends Component {
  PupRescue({
    required this.from,
    required this.to,
    required this.cell,
    this.delay = 0,
  });

  final Offset from;
  final Offset to;
  final double cell;
  final double delay;
  double _t = 0;

  static const _life = 1.5;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > delay + _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final q = (_t - delay) / _life;
    if (q < 0) return;
    final size = cell * 1.25;
    // First a happy hop on the spot, then off to the top.
    Offset at;
    var scale = 1.0;
    if (q < 0.4) {
      final h = sin(q / 0.4 * pi);
      at = from - Offset(0, h * cell * 0.9);
      scale = 0.6 + easeOutBack((q / 0.4).clamp(0.0, 1.0)) * 0.4;
    } else {
      final f = (q - 0.4) / 0.6;
      final e = f * f;
      at = Offset.lerp(from, to, e)! - Offset(0, sin(f * pi) * cell * 1.5);
      scale = 1 - f * 0.55;
    }
    final alpha = q > 0.88 ? (1 - q) / 0.12 : 1.0;

    // Hearts float up while it hops.
    if (q < 0.6) {
      for (var k = 0; k < 3; k++) {
        final hq = (q / 0.6 + k * 0.22) % 1;
        final hp =
            from + Offset((k - 1) * cell * 0.4, -cell * (0.6 + hq * 1.2));
        _heart(canvas, hp, cell * 0.18 * (1 - hq * 0.4), 1 - hq);
      }
    }
    canvas.saveLayer(
      null,
      Paint()..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0)),
    );
    canvas.translate(at.dx - size * scale / 2, at.dy - size * scale);
    canvas.scale(scale);
    PupPainter.body(canvas, Size.square(size), t: q * 3);
    canvas.restore();
  }

  void _heart(Canvas canvas, Offset c, double r, double alpha) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r)
      ..cubicTo(
        c.dx - r * 2,
        c.dy - r * 0.3,
        c.dx - r * 0.8,
        c.dy - r * 1.6,
        c.dx,
        c.dy - r * 0.5,
      )
      ..cubicTo(
        c.dx + r * 0.8,
        c.dy - r * 1.6,
        c.dx + r * 2,
        c.dy - r * 0.3,
        c.dx,
        c.dy + r,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = Color.fromRGBO(255, 107, 150, alpha.clamp(0.0, 1.0)),
    );
  }
}
