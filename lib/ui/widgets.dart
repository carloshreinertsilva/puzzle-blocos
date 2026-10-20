import 'package:flutter/material.dart';

import 'block_painter.dart';
import 'palette.dart';
import 'typography.dart';

/// Chunky rounded button with a 3D edge, used across menus and cards.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = Palette.accent,
    this.textColor = const Color(0xFF3A2200),
    this.icon,
    this.big = false,
  });

  final String label;
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
    return Semantics(
      button: true,
      label: widget.label,
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
                      Text(
                        widget.label,
                        style: displayText(
                          widget.big ? 27 : 21,
                          color: widget.textColor,
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
  });
  final IconData icon;

  /// Read by screen readers (and by the browser tests).
  final String label;
  final VoidCallback onTap;

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
          child: Icon(icon, color: Palette.text, size: 24),
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

enum MiniIcon { rock, toughRock, gem, star }

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
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.kind != kind;
}

/// Logo: the title over a row of tilted blocks.
class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 5; i++)
                Transform.rotate(
                  angle: (i - 2) * 0.12,
                  child: Padding(
                    padding: EdgeInsets.only(top: (i - 2).abs() * 6.0),
                    child: CustomPaint(
                      size: const Size.square(44),
                      painter: _BlockLogoPainter(Palette.blocks[i + 1]),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
