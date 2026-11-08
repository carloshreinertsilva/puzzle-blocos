import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/idioma.dart';
import 'palette.dart';
import 'typography.dart';

/// The opening screen while the game loads: Capi hauling a big block into
/// the Vila do Capi (painted with Gemini, assets/abertura/), the name on top
/// and a loading bar at the bottom that fills up when the game is ready
/// ([pronto]). If loading fails, it says so and offers to try again instead
/// of hanging.
class Abertura extends StatelessWidget {
  const Abertura({
    super.key,
    this.erro = false,
    this.onTentarDeNovo,
    this.pronto,
  });

  final bool erro;
  final VoidCallback? onTentarDeNovo;

  /// Becomes true when the game has loaded: the bar runs to the end.
  final ValueListenable<bool>? pronto;

  static const imagem = 'assets/abertura/abertura.webp';

  @override
  Widget build(BuildContext context) {
    final margens = MediaQuery.paddingOf(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.bgTop, Palette.bgBottom],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Covers the screen; on wider screens it keeps Capi (lower
            // middle) in sight and loses some sky.
            Image.asset(
              imagem,
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.4),
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              frameBuilder: (context, child, frame, sincrona) => sincrona
                  ? child
                  : AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: child,
                    ),
            ),
            // Shade behind the name and the bar, so both read on the art.
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 230,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xB31C2155), Color(0x001C2155)],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00160F33), Color(0xE6160F33)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: margens.top + 40,
              child: Text(
                appTitle,
                textAlign: TextAlign.center,
                style: displayText(
                  52,
                  shadows: const [
                    Shadow(color: Color(0xFF2A1458), offset: Offset(0, 4)),
                    Shadow(color: Color(0x88000000), blurRadius: 12),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: margens.bottom + 36,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: erro
                        ? _Erro(onTentarDeNovo: onTentarDeNovo)
                        : _BarraDeCarregamento(pronto: pronto),
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

/// Fills towards 90% while the game loads (quickly at first, then slowing
/// down), and runs to 100% once [pronto] says it is ready.
class _BarraDeCarregamento extends StatefulWidget {
  const _BarraDeCarregamento({this.pronto});
  final ValueListenable<bool>? pronto;

  @override
  State<_BarraDeCarregamento> createState() => _BarraDeCarregamentoState();
}

class _BarraDeCarregamentoState extends State<_BarraDeCarregamento>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    widget.pronto?.addListener(_mudou);
    _mudou();
  }

  void _mudou() {
    if (widget.pronto?.value ?? false) {
      _anim.animateTo(
        1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _anim.animateTo(
        0.9,
        duration: const Duration(milliseconds: 3200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    widget.pronto?.removeListener(_mudou);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (context, _) {
      final p = _anim.value;
      final pct = '${(p * 100).round()}%';
      return Semantics(
        label: tr('Carregando'),
        value: pct,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(tr('Carregando'), style: displayText(18)),
                  const Spacer(),
                  Text(pct, style: displayText(18)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 20,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0x66000000),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0x55FFFFFF),
                    width: 1.5,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: p.clamp(0.04, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A3D), Color(0xFFFFC94D)],
                        ),
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                          stops: [0, 0.6],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Erro extends StatelessWidget {
  const _Erro({this.onTentarDeNovo});
  final VoidCallback? onTentarDeNovo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
    decoration: BoxDecoration(
      color: const Color(0xD91C2155),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tr('Ops! O jogo não conseguiu abrir.'),
          textAlign: TextAlign.center,
          style: bodyText(18),
        ),
        const SizedBox(height: 16),
        Semantics(
          button: true,
          label: tr('Tentar de novo'),
          child: GestureDetector(
            onTap: onTentarDeNovo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: Palette.accent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: ExcludeSemantics(
                child: Text(
                  tr('Tentar de novo'),
                  style: displayText(20, color: Palette.panel),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
