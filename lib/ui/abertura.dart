import 'dart:math';

import 'package:flutter/material.dart';

import 'capi.dart';
import 'palette.dart';
import 'typography.dart';

/// The opening screen while the game loads. It continues Android's own
/// splash (same colors, Capi in the middle, the name at the bottom) and
/// adds four hopping blocks, like the web loading screen. If loading fails,
/// it says so and offers to try again instead of hanging.
class Abertura extends StatelessWidget {
  const Abertura({super.key, this.erro = false, this.onTentarDeNovo});

  final bool erro;
  final VoidCallback? onTentarDeNovo;

  @override
  Widget build(BuildContext context) {
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
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Balances the blocks below, so Capi sits right in the
                  // middle, where Android's own splash drew him.
                  if (!erro) const SizedBox(height: 64),
                  Capi(
                    size: 165,
                    mood: erro ? CapiMood.worried : CapiMood.happy,
                  ),
                  const SizedBox(height: 18),
                  if (erro)
                    _Erro(onTentarDeNovo: onTentarDeNovo)
                  else
                    Semantics(
                      label: 'Carregando',
                      child: const _BlocosPulando(),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 48 + MediaQuery.paddingOf(context).bottom,
              child: Text(
                appTitle,
                textAlign: TextAlign.center,
                style: displayText(
                  44,
                  shadows: const [
                    Shadow(color: Color(0xFF2A1458), offset: Offset(0, 3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlocosPulando extends StatefulWidget {
  const _BlocosPulando();

  @override
  State<_BlocosPulando> createState() => _BlocosPulandoState();
}

class _BlocosPulandoState extends State<_BlocosPulando>
    with SingleTickerProviderStateMixin {
  static const _cores = [
    Color(0xFFFFA94D),
    Color(0xFFFFD43B),
    Color(0xFF51CF66),
    Color(0xFF22B8CF),
  ];

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semMovimento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox(
      height: 46,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _cores.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.translate(
                  offset: Offset(
                    0,
                    semMovimento ? 0 : -14 * _pulo(_anim.value - i * 0.12),
                  ),
                  child: _Bloco(cor: _cores[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 0..1..0: up quickly, down again, then a rest (like the web's "hop").
  static double _pulo(double t) {
    final f = t % 1;
    return f < 0.8 ? sin(f / 0.8 * pi) : 0;
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({required this.cor});
  final Color cor;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: cor,
      borderRadius: BorderRadius.circular(7),
    ),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(7),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55FFFFFF), Color(0x00FFFFFF), Color(0x40000000)],
        stops: [0, 0.4, 1],
      ),
    ),
  );
}

class _Erro extends StatelessWidget {
  const _Erro({this.onTentarDeNovo});
  final VoidCallback? onTentarDeNovo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ops! O jogo não conseguiu abrir.',
          textAlign: TextAlign.center,
          style: bodyText(18),
        ),
        const SizedBox(height: 16),
        Semantics(
          button: true,
          label: 'Tentar de novo',
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
                  'Tentar de novo',
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
