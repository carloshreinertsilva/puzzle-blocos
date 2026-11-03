import '../core/wardrobe.dart';
import '../core/hats.dart';

import 'package:flutter/material.dart';

import 'block_painter.dart';
import 'capi.dart';
import 'palette.dart';
import 'pup.dart';
import 'typography.dart';

/// Chunky rounded button with a 3D edge, used across menus and cards.
/// On wide screens (desktop browser, tablet) menus stay a phone-sized
/// column this wide instead of stretching edge to edge.
const menuMaxWidth = 520.0;

class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = Palette.accent,
    this.textColor = const Color(0xFF3A2200),
    this.icon,
    this.big = false,
    this.semanticLabel,
  });

  final String label;

  /// What a screen reader says, when the visible [label] is shortened.
  final String? semanticLabel;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final bool big;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.big ? 64.0 : 52.0;
    final edge = widget.big ? 6.0 : 5.0;
    final pressed = _down ? edge - 1 : 0.0;
    // Its own node: never merged with a title or text next to it.
    return Semantics(
      container: true,
      button: true,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: _body(h, edge, pressed),
    );
  }

  Widget _body(double h, double edge, double pressed) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: SizedBox(
        height: h + edge,
        child: Stack(
          children: [
            Positioned.fill(
              top: edge,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.darken(widget.color, 0.35),
                  borderRadius: BorderRadius.circular(h / 2.6),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: 0,
              right: 0,
              top: pressed,
              height: h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Palette.lighten(widget.color, 0.25), widget.color],
                  ),
                  borderRadius: BorderRadius.circular(h / 2.6),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.textColor,
                          size: h * 0.42,
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Long labels shrink instead of spilling out.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.label,
                            style: displayText(
                              widget.big ? 27 : 21,
                              color: widget.textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small square icon button for the HUD (pause, settings).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });
  final IconData icon;

  /// Read by screen readers (and by the browser tests).
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: Palette.panel.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Palette.text, size: 24),
              if (badge != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
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

/// Panel used for dialogs (win, lose, pause).
class CardPanel extends StatelessWidget {
  const CardPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 360),
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
    decoration: BoxDecoration(
      color: Palette.panel,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Palette.panelEdge, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x80000000),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: child,
  );
}

enum MiniIcon { rock, toughRock, gem, star, pup }

/// Tiny painted icons that match the board art.
class MiniGlyph extends StatelessWidget {
  const MiniGlyph(this.kind, {super.key, this.size = 22});
  final MiniIcon kind;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GlyphPainter(kind));
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.kind);
  final MiniIcon kind;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (kind) {
      case MiniIcon.rock:
        BlockPainter.rock(canvas, rect, 1);
      case MiniIcon.toughRock:
        BlockPainter.rock(canvas, rect, 2);
      case MiniIcon.gem:
        BlockPainter.gem(canvas, rect.inflate(size.width * 0.35));
      case MiniIcon.star:
        BlockPainter.block(canvas, rect, Palette.accent);
      case MiniIcon.pup:
        PupPainter.face(canvas, rect.inflate(size.width * 0.1));
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.kind != kind;
}

/// Logo: Capi beside the row of tilted blocks he built, over the title.
/// Tapping Capi gets a tip ([onCapiTap]).
class Logo extends StatelessWidget {
  const Logo({
    super.key,
    this.onCapiTap,
    this.compact = false,
    this.hat,
    this.look,
  });
  final VoidCallback? onCapiTap;

  /// Short screens: the title with Capi beside it, no row of blocks.
  final bool compact;
  final CapiHat? hat;
  final CapiLook? look;

  Widget _capi(double size) => Semantics(
    button: true,
    label: 'Capi',
    excludeSemantics: true,
    onTap: onCapiTap,
    child: GestureDetector(
      onTap: onCapiTap,
      child: Capi(size: size, hat: hat, look: look),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OutlinedTitle(appTitle, size: 40),
          const SizedBox(width: 6),
          _capi(60),
        ],
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 72,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 4; i++)
                Transform.rotate(
                  angle: (i - 1.5) * 0.12,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6 + (i - 1.5).abs() * 5),
                    child: CustomPaint(
                      size: const Size.square(42),
                      painter: _BlockLogoPainter(Palette.blocks[i + 1]),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              _capi(72),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const OutlinedTitle(appTitle, size: 46),
      ],
    );
  }
}

class _BlockLogoPainter extends CustomPainter {
  _BlockLogoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      BlockPainter.block(canvas, Offset.zero & size, color);

  @override
  bool shouldRepaint(_BlockLogoPainter old) => old.color != color;
}

/// Chunky title text: dark outline, drop shadow and a light-to-color
/// gradient fill, like the praise words in the game.
class OutlinedTitle extends StatelessWidget {
  const OutlinedTitle(
    this.text, {
    super.key,
    this.size = 32,
    this.colors = const [Color(0xFFFFFFFF), Color(0xFFFFE08A)],
  });

  final String text;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.18
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2A1458);
    // Three stacked copies make the outlined look; read it out once.
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: _layers(outline),
    );
  }

  Widget _layers(Paint outline) {
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(0, size * 0.08),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: displayText(size).copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.18
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0x66000000),
              color: null,
            ),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: displayText(size).copyWith(foreground: outline, color: null),
        ),
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ).createShader(rect),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: displayText(size, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Three stars, filled for the ones earned. With [animate], each pops in
/// after the previous one (the win card).
class StarRow extends StatefulWidget {
  const StarRow({
    super.key,
    required this.filled,
    this.size = 44,
    this.animate = false,
  });
  final List<bool> filled;
  final double size;
  final bool animate;

  @override
  State<StarRow> createState() => _StarRowState();
}

class _StarRowState extends State<StarRow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.filled.length;
    return Semantics(
      label: '${widget.filled.where((f) => f).length} de $n estrelas',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++)
              Transform.translate(
                // The middle star sits a little higher.
                offset: Offset(0, i == 1 && n == 3 ? -widget.size * 0.18 : 0),
                child: Transform.scale(
                  scale: widget.filled[i]
                      ? Curves.elasticOut.transform(
                          ((_c.value - i * 0.22) / 0.5).clamp(0.0, 1.0),
                        )
                      : 1,
                  child: Icon(
                    Icons.star_rounded,
                    size: widget.size,
                    color: widget.filled[i]
                        ? Palette.accent
                        : Palette.panelEdge,
                    shadows: widget.filled[i]
                        ? const [
                            Shadow(
                              color: Color(0xAA7A4A00),
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
