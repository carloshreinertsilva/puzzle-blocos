import 'dart:math';

import 'package:flutter/material.dart';

import '../core/level.dart';
import '../l10n/idioma.dart';
import 'block_painter.dart';
import 'palette.dart';
import 'typography.dart';
import 'widgets.dart';

/// Blocks drifting slowly behind the menu.
class FloatingBlocks extends StatefulWidget {
  const FloatingBlocks({super.key});

  @override
  State<FloatingBlocks> createState() => _FloatingBlocksState();
}

class _FloatingBlocksState extends State<FloatingBlocks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  final _blocks = () {
    final rng = Random(3);
    return List.generate(
      14,
      (i) => (
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 18 + rng.nextDouble() * 30,
        speed: 0.6 + rng.nextDouble(),
        spin: (rng.nextDouble() - 0.5) * 2,
        color: Palette.blocks[i % Palette.blocks.length],
      ),
    );
  }();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _FloatingPainter(_clock, _blocks),
      size: Size.infinite,
    ),
  );
}

class _FloatingPainter extends CustomPainter {
  _FloatingPainter(this.clock, this.blocks) : super(repaint: clock);

  final Animation<double> clock;
  final List<
    ({double x, double y, double size, double speed, double spin, Color color})
  >
  blocks;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    // One translucent layer for all blocks: a layer per block (full-screen
    // each) made the menu crawl on slower devices.
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: 0.13),
    );
    for (final b in blocks) {
      // Rise slowly and wrap around.
      final y = ((b.y - t * b.speed * 2) % 1.0) * (size.height + 80) - 40;
      final x = b.x * size.width + sin(t * 2 * pi * 3 + b.y * 9) * 12;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 2 * pi * b.spin);
      BlockPainter.block(
        canvas,
        Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size),
        b.color,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FloatingPainter old) => false;
}

/// Small rounded chip with an icon and a value (record, streak).
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
    decoration: BoxDecoration(
      color: Palette.panel.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        Text(value, style: displayText(18)),
      ],
    ),
  );
}

/// The road of levels, from level 1 at the bottom up to two levels ahead.
/// It scrolls: it opens with the current level in the middle, and the
/// player drags it down to replay old levels for their missing stars. A
/// level with all 3 stars wears a gold check; one with fewer shows a lighter
/// disc and its empty stars. Hard levels ahead have a red ring. Only the
/// part on screen is built, however many levels there are.
class LevelPath extends StatefulWidget {
  const LevelPath({
    super.key,
    required this.current,
    required this.onPlay,
    this.starsFor,
    this.onReplay,
    this.leftInset = 0,
  });
  final int current;
  final VoidCallback onPlay;

  /// Room kept free on the left (Capi stands there on the menu).
  final double leftInset;

  /// Stars earned on a finished level (0-3), and playing it again.
  final int Function(int level)? starsFor;
  final void Function(int level)? onReplay;

  /// Vertical distance between two levels.
  static const step = 86.0;

  @override
  State<LevelPath> createState() => _LevelPathState();
}

class _LevelPathState extends State<LevelPath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  final _scroll = ScrollController();
  double _viewport = 0;
  bool _centered = false;

  /// Levels on the road: 1 up to two ahead of the current one.
  int get _last => widget.current + 2;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Height of the whole road.
  double get _height => (_last + 0.6) * LevelPath.step;

  /// Where level [n]'s centre sits, from the top of the whole road.
  Offset _at(int n, double w) {
    final i = n - 1;
    final road = w - widget.leftInset;
    return Offset(
      widget.leftInset + road / 2 + sin(i * 1.3 + 0.4) * road * 0.3,
      _height - LevelPath.step * (i + 0.8),
    );
  }

  void _center(double viewport) {
    if (_centered || !_scroll.hasClients) return;
    _centered = true;
    final y = _at(widget.current, 1).dy;
    final max = _scroll.position.maxScrollExtent;
    // A little above the middle, so the last level played shows below.
    _scroll.jumpTo((y - viewport * 0.42).clamp(0.0, max));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        _viewport = box.maxHeight;
        if (!_centered) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _center(_viewport),
          );
        }
        final top = _scroll.hasClients ? _scroll.offset : 0.0;
        // Only the levels near the screen (plus a margin) are built.
        final from = max(
          1,
          ((_height - top - _viewport) / LevelPath.step).floor() - 1,
        );
        final to = min(_last, ((_height - top) / LevelPath.step).ceil() + 1);
        final levels = [for (var n = from; n <= to; n++) n];
        final points = [for (final n in levels) _at(n, w)];
        // The road fades out at the top and bottom edges as it scrolls.
        return ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: [0, 0.08, 0.92, 1],
          ).createShader(r),
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: _scroll,
            child: SizedBox(
              width: w,
              height: _height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      // The road is green up to the current level.
                      painter: _RoadPainter(
                        points,
                        (widget.current - from).clamp(0, points.length - 1),
                      ),
                    ),
                  ),
                  for (var i = 0; i < levels.length; i++)
                    _node(levels[i], points[i]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _node(int n, Offset p) {
    final current = n == widget.current;
    final done = n < widget.current;
    final size = current ? 74.0 : 50.0;
    final config = n > widget.current ? LevelGenerator.build(n) : null;
    final stars = done && widget.starsFor != null ? widget.starsFor!(n) : 0;
    final all = stars >= 3;

    Widget body;
    if (done) {
      body = _Disc(
        size: size,
        // All stars: the full green. Missing some: a lighter teal, worth
        // a second visit.
        color: all || widget.starsFor == null
            ? Palette.good
            : const Color(0xFF3FA7C4),
        child: Text('$n', style: displayText(20, color: Colors.white)),
      );
    } else if (current) {
      body = ScaleTransition(
        scale: Tween(
          begin: 0.94,
          end: 1.06,
        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: _Disc(
          size: size,
          color: Palette.accent,
          glow: true,
          child: Text(
            '$n',
            style: displayText(30, color: const Color(0xFF3A2200)),
          ),
        ),
      );
    } else {
      final hard = config!.isHard;
      body = _Disc(
        size: size,
        color: Palette.panelEdge,
        ring: hard ? Palette.danger : null,
        child: Text('$n', style: displayText(20, color: Palette.textDim)),
      );
    }

    final replay = done && widget.onReplay != null;
    // A level cut by the edge of the scrolling road is only half on screen:
    // screen readers (and browser tests) skip it until it scrolls in.
    final top = _scroll.hasClients ? _scroll.offset : 0.0;
    final whole = p.dy - size / 2 >= top && p.dy + size / 2 <= top + _viewport;
    return Positioned(
      left: p.dx - size / 2,
      top: p.dy - size / 2,
      width: size,
      height: size,
      child: ExcludeSemantics(
        excluding: !whole,
        child: Semantics(
          // A finished level is a button (play it again), read with its stars.
          button: replay,
          label: done && widget.starsFor != null
              ? tr('Fase {n}, {estrelas} de 3 estrelas', {
                  'n': n,
                  'estrelas': stars,
                })
              : null,
          excludeSemantics: replay,
          onTap: replay ? () => widget.onReplay!(n) : null,
          child: GestureDetector(
            // The current level plays; a finished one can be played again for
            // its missing stars.
            onTap: current
                ? widget.onPlay
                : replay
                ? () => widget.onReplay!(n)
                : null,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: body),
                if (config != null)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: _GoalBadge(config: config),
                  ),
                if (done && all)
                  const Positioned(right: -8, top: -8, child: _CheckBadge()),
                if (done && widget.starsFor != null)
                  Positioned(
                    left: -6,
                    right: -6,
                    bottom: -14,
                    child: Center(
                      child: StarRow(
                        filled: [for (var i = 0; i < 3; i++) i < stars],
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gold check on a level won with all 3 stars.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE082), Palette.accent],
      ),
      border: Border.all(color: const Color(0xFF8A5A00), width: 2),
      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
    ),
    child: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF5A3A00)),
  );
}

class _GoalBadge extends StatelessWidget {
  const _GoalBadge({required this.config});
  final LevelConfig config;

  @override
  Widget build(BuildContext context) {
    final Widget icon = config.hasRockGoal
        ? const MiniGlyph(MiniIcon.rock, size: 16)
        : config.gemsTarget > 0
        ? const MiniGlyph(MiniIcon.gem, size: 16)
        : const Icon(Icons.star_rounded, color: Palette.accent, size: 18);
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.panel,
        shape: BoxShape.circle,
        border: Border.all(
          color: config.isHard ? Palette.danger : Palette.panelEdge,
          width: 2,
        ),
      ),
      child: icon,
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.size,
    required this.color,
    required this.child,
    this.ring,
    this.glow = false,
  });
  final double size;
  final Color color;
  final Widget child;
  final Color? ring;
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.lighten(color, 0.25), color],
      ),
      border: Border.all(
        color: ring ?? Palette.darken(color, 0.3),
        width: ring != null ? 3.5 : 3,
      ),
      boxShadow: [
        BoxShadow(
          color: glow ? color.withValues(alpha: 0.55) : const Color(0x55000000),
          blurRadius: glow ? 22 : 6,
          offset: Offset(0, glow ? 0 : 4),
        ),
      ],
    ),
    child: child,
  );
}

class _RoadPainter extends CustomPainter {
  _RoadPainter(this.points, this.currentIndex);
  final List<Offset> points;
  final int currentIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    Path segment(int from, int to) {
      final path = Path()..moveTo(points[from].dx, points[from].dy);
      for (var i = from + 1; i <= to; i++) {
        final a = points[i - 1], b = points[i];
        final mid = (a.dy + b.dy) / 2;
        path.cubicTo(a.dx, mid, b.dx, mid, b.dx, b.dy);
      }
      return path;
    }

    final road = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14;
    final done = max(0, currentIndex);
    if (done > 0) {
      canvas.drawPath(
        segment(0, done),
        road..color = Palette.good.withValues(alpha: 0.55),
      );
    }
    canvas.drawPath(
      segment(done, points.length - 1),
      road..color = Palette.panel.withValues(alpha: 0.9),
    );
    // Dashes along the road ahead.
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = Palette.panelEdge;
    for (final metric in segment(done, points.length - 1).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 16) {
        canvas.drawPath(metric.extractPath(d, d + 7), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.currentIndex != currentIndex || old.points != points;
}

/// A big tappable card on the menu (daily challenge, endless mode).
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.compact = false,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  /// Small tile (icon over the title, no subtitle), three to a row.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      excludeSemantics: true,
      onTap: onTap,
      child: _card(),
    );
  }

  Widget _tile() => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.lighten(color, 0.1), Palette.darken(color, 0.25)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border(
          bottom: BorderSide(color: Palette.darken(color, 0.45), width: 5),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(title, style: displayText(16, shadows: textDrop)),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              right: -4,
              top: -20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Palette.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!, style: displayText(11)),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _card() {
    if (compact) return _tile();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Palette.lighten(color, 0.1), Palette.darken(color, 0.25)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border(
            bottom: BorderSide(color: Palette.darken(color, 0.45), width: 5),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 26),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          title,
                          style: displayText(19, shadows: textDrop),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: bodyText(13, color: Colors.white),
                  maxLines: 2,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                right: -4,
                top: -22,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!, style: displayText(13)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
