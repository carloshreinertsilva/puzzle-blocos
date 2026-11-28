import 'dart:math';

import 'package:flutter/material.dart';

import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import 'capi.dart';
import 'palette.dart';
import 'typography.dart';
import 'widgets.dart';

/// A spotlight over the whole screen: everything dims except a rounded
/// cut-out around the widget of [alvo] (its glow pulses gently), and Capi
/// says [texto] in a balloon by it. A tap anywhere (or the button) calls
/// [onAvancar]; a tap inside the cut-out calls [onAlvo], when given. With
/// [onPular] there is always a "Pular" button too.
///
/// Changing [alvo] moves the cut-out to the new target. Used by the menu's
/// guide and by Capi's lines about a mode just unlocked.
class Destaque extends StatefulWidget {
  const Destaque({
    super.key,
    required this.alvo,
    required this.texto,
    required this.onAvancar,
    this.acao,
    this.onPular,
    this.onAlvo,
    this.look,
    this.mood = CapiMood.point,
    this.passo,
    this.total,
    this.pulsar = true,
  });

  /// The widget to light up (its key).
  final GlobalKey alvo;
  final String texto;
  final VoidCallback onAvancar;

  /// The balloon's button ("Continuar" if not given).
  final String? acao;
  final VoidCallback? onPular;
  final VoidCallback? onAlvo;

  /// What Capi wears in the balloon (his look on the menu by default).
  final CapiLook? look;
  final CapiMood mood;

  /// Which step of how many, for the dots under the text (both or none).
  final int? passo;
  final int? total;

  /// False keeps the glow still ("Reduzir efeitos").
  final bool pulsar;

  @override
  State<Destaque> createState() => _DestaqueState();
}

class _DestaqueState extends State<Destaque> with TickerProviderStateMixin {
  /// The glow's breathing: a few pixels, smooth at the screen's rate.
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  /// The cut-out sliding from one target to the next.
  late final AnimationController _mover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  /// The whole thing fading in.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  Rect? _de;
  Rect? _ultimo;

  @override
  void initState() {
    super.initState();
    if (widget.pulsar) _pulso.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(Destaque old) {
    super.didUpdateWidget(old);
    if (old.alvo != widget.alvo) {
      _de = _ultimo;
      _mover.forward(from: 0);
    }
    if (widget.pulsar != old.pulsar) {
      widget.pulsar ? _pulso.repeat(reverse: true) : _pulso.value = 0;
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    _mover.dispose();
    _entrada.dispose();
    super.dispose();
  }

  /// Where the target is, in this widget's coordinates (null before the
  /// first layout).
  Rect? _rectDoAlvo() {
    final alvo = widget.alvo.currentContext?.findRenderObject();
    final eu = context.findRenderObject();
    if (alvo is! RenderBox || eu is! RenderBox) return null;
    if (!alvo.attached || !alvo.hasSize || !eu.hasSize) return null;
    final topo = eu.globalToLocal(alvo.localToGlobal(Offset.zero));
    return topo & alvo.size;
  }

  bool _esperando = false;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entrada,
      // Only the guide's own buttons are reachable while it is up.
      child: BlockSemantics(
        child: LayoutBuilder(
          builder: (context, box) => AnimatedBuilder(
            animation: _mover,
            builder: (context, _) => _conteudo(box.biggest),
          ),
        ),
      ),
    );
  }

  Widget _conteudo(Size tela) {
    final alvo = _rectDoAlvo();
    // The target lays out in this same frame (it may have moved, or not be
    // there yet): look again once it has, and follow it if it moved.
    if (!_esperando) {
      _esperando = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _esperando = false;
        if (mounted && _rectDoAlvo() != alvo) setState(() {});
      });
    }
    if (alvo == null) {
      return const SizedBox.expand(child: ColoredBox(color: Color(0xD0080A20)));
    }
    final de = _de;
    final t = Curves.easeOutCubic.transform(_mover.value);
    final rect = de == null ? alvo : Rect.lerp(de, alvo, t)!;
    _ultimo = rect;
    // The glow breathes in the painter alone; the balloon keeps still.
    final borda = rect.inflate(9);
    final emBaixo = rect.center.dy > tela.height * 0.5;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              if (widget.onAlvo != null && borda.contains(d.localPosition)) {
                widget.onAlvo!();
              } else {
                widget.onAvancar();
              }
            },
            child: CustomPaint(painter: _Recorte(rect, _pulso)),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: emBaixo ? null : borda.bottom + 14,
          bottom: emBaixo ? tela.height - borda.top + 14 : null,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: menuMaxWidth),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(0, emBaixo ? 0.06 : -0.06),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: _Balao(
                  key: ValueKey(widget.texto),
                  texto: widget.texto,
                  acao: widget.acao ?? tr('Continuar'),
                  onAcao: widget.onAvancar,
                  look: widget.look,
                  mood: widget.mood,
                  passo: widget.passo,
                  total: widget.total,
                  onPular: widget.onPular,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Capi and his balloon: the text, the button and, under it, the steps'
/// dots and a discreet "Pular" (inside the balloon, so it never sits over
/// the menu's own buttons).
class _Balao extends StatelessWidget {
  const _Balao({
    super.key,
    required this.texto,
    required this.acao,
    required this.onAcao,
    required this.look,
    required this.mood,
    required this.passo,
    required this.total,
    required this.onPular,
  });

  final String texto;
  final String acao;
  final VoidCallback onAcao;
  final CapiLook? look;
  final CapiMood mood;
  final int? passo;
  final int? total;
  final VoidCallback? onPular;

  @override
  Widget build(BuildContext context) {
    final passo = this.passo;
    final total = this.total;
    final onPular = this.onPular;
    final pontos = passo != null && total != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ExcludeSemantics(
          child: Capi(size: 76, mood: mood, look: look),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 12),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  texto,
                  style: bodyText(
                    16,
                    color: const Color(0xFF2A1458),
                    weight: 600,
                  ),
                ),
                const SizedBox(height: 10),
                ChunkyButton(label: acao, onTap: onAcao),
                if (pontos || onPular != null)
                  Row(
                    children: [
                      if (pontos)
                        ExcludeSemantics(
                          child: Row(
                            children: [
                              for (var i = 1; i <= total; i++)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == passo
                                        ? Palette.accentDeep
                                        : const Color(0xFFD9D4EE),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      if (onPular != null)
                        Semantics(
                          button: true,
                          label: tr('Pular'),
                          excludeSemantics: true,
                          onTap: onPular,
                          child: GestureDetector(
                            onTap: onPular,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: 40,
                                minWidth: 56,
                              ),
                              alignment: Alignment.centerRight,
                              child: Text(
                                tr('Pular'),
                                style: bodyText(
                                  15,
                                  color: const Color(0xFF6E6496),
                                  weight: 700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The dimmed screen with the glowing hole. The glow's breathing only
/// repaints this layer (nothing is built again each frame).
class _Recorte extends CustomPainter {
  _Recorte(this.alvo, this.animacao) : super(repaint: animacao);
  final Rect alvo;
  final Animation<double> animacao;

  @override
  void paint(Canvas canvas, Size size) {
    final pulso = Curves.easeInOut.transform(animacao.value);
    final furo = RRect.fromRectAndRadius(
      alvo.inflate(6 + 3 * pulso),
      Radius.circular(min(24.0, alvo.shortestSide / 2 + 6)),
    );
    final escuro = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(furo);
    canvas.drawPath(escuro, Paint()..color = const Color(0xD0080A20));
    canvas.drawRRect(
      furo.inflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Palette.accent.withValues(alpha: 0.18 + 0.22 * pulso)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      furo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Palette.accent.withValues(alpha: 0.6 + 0.35 * pulso),
    );
  }

  @override
  bool shouldRepaint(_Recorte old) =>
      old.alvo != alvo || old.animacao != animacao;
}
