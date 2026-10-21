import 'dart:math';

import 'package:flutter/material.dart';

import '../core/village.dart';
import '../main.dart';
import '../testing/test_bridge.dart';
import '../ui/capi.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// Capi's village: a lagoon that fills up with things built with the stars
/// earned in the levels. Pops with `true` when the player wants to go play
/// for more stars.
class VillageScreen extends StatefulWidget {
  const VillageScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> {
  final _rng = Random();
  String? _justBuilt;
  late String _line = _idleLine();

  @override
  void initState() {
    super.initState();
    if (kTestBridge) TestBridge.instance.screen = 'village';
  }

  @override
  void dispose() {
    if (kTestBridge) TestBridge.instance.screen = 'home';
    super.dispose();
  }

  int get _built => widget.services.store.villageBuilt;
  int get _stars => widget.services.store.stars;

  String _idleLine() {
    final next = Village.next(_built);
    if (next == null) return 'A vila ficou linda! Obrigado, construtor!';
    if (_built == 0) {
      return 'Bem-vindo à minha lagoa! Com as estrelas das fases a gente '
          'constrói tudo aqui.';
    }
    final missing = next.cost - _stars;
    return missing > 0
        ? 'Faltam $missing ${missing == 1 ? 'estrela' : 'estrelas'} para '
              '${next.name.toLowerCase()}. Bora jogar?'
        : 'Já dá para construir ${next.name.toLowerCase()}!';
  }

  Future<void> _build(VillageItem item) async {
    final store = widget.services.store;
    if (!await store.spendStars(item.cost)) return;
    await store.setVillageBuilt(_built + 1);
    widget.services.feedback.win();
    const cheers = [
      'Ficou lindo!',
      'Uhul! A vila tá crescendo!',
      'Que obra caprichada!',
      'Valeu, parceiro de obra!',
    ];
    setState(() {
      _justBuilt = item.id;
      _line =
          '${cheers[_rng.nextInt(cheers.length)]} Agora a vila tem: '
          '${item.name.toLowerCase()}.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted || _justBuilt != item.id) return;
    setState(() {
      _justBuilt = null;
      _line = _idleLine();
    });
  }

  @override
  Widget build(BuildContext context) {
    final next = Village.next(_built);
    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Voltar',
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                    const Expanded(
                      child: Center(
                        child: OutlinedTitle('Vila do Capi', size: 28),
                      ),
                    ),
                    _StarCount(stars: _stars),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Stack(
                    children: [
                      Positioned.fill(child: _scene()),
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 10,
                        child: _Bubble(text: _line),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: next == null ? _done() : _nextPanel(next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scene() {
    return LayoutBuilder(
      builder: (context, box) {
        final s = min(
          box.maxWidth / Village.sceneSize.width,
          box.maxHeight / Village.sceneSize.height,
        );
        final w = Village.sceneSize.width * s;
        final h = Village.sceneSize.height * s;
        final capi = 150 * s;
        // The scene sits on the ground (bottom); any room left above or at
        // the sides is sky and grass.
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF7EC8F2),
                  Color(0xFFB9D8D6),
                  Color(0xFF5BAE55),
                ],
                stops: [0, 0.45, 0.62],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(Village.background, fit: BoxFit.fill),
                    ),
                    for (final item in Village.drawn(_built))
                      Positioned(
                        left: item.rect.left * s,
                        top: item.rect.top * s,
                        width: item.rect.width * s,
                        height: item.rect.height * s,
                        child: item.id == _justBuilt
                            ? TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.elasticOut,
                                builder: (context, v, child) => Transform.scale(
                                  scale: v,
                                  alignment: Alignment.bottomCenter,
                                  child: child,
                                ),
                                child: Image.asset(item.asset),
                              )
                            : Image.asset(item.asset),
                      ),
                    Positioned(
                      left: Village.capiFeet.dx * s - capi / 2,
                      top: Village.capiFeet.dy * s - capi,
                      child: Capi(
                        size: capi,
                        mood: _justBuilt != null
                            ? CapiMood.cheer
                            : CapiMood.happy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _nextPanel(VillageItem next) {
    final canBuild = _stars >= next.cost;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Palette.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.panelEdge, width: 2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Image.asset(next.asset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(next.name, style: displayText(19)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Palette.accent,
                      size: 18,
                    ),
                    Text(
                      ' ${next.cost} · ${_built + 1}º de ${Village.items.length}',
                      style: bodyText(14, color: Palette.textDim),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: canBuild
                ? ChunkyButton(
                    label: 'Construir',
                    color: Palette.good,
                    textColor: const Color(0xFF0B3B16),
                    onTap: () => _build(next),
                  )
                : ChunkyButton(
                    label: 'Jogar',
                    icon: Icons.play_arrow_rounded,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _done() => CardPanel(
    child: Text(
      'Vila completa! Novas áreas chegam em breve.',
      textAlign: TextAlign.center,
      style: displayText(18, color: Palette.accent),
    ),
  );
}

class _StarCount extends StatelessWidget {
  const _StarCount({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars estrelas',
    excludeSemantics: true,
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Palette.panel.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Palette.accent, size: 24),
          const SizedBox(width: 4),
          Text('$stars', style: displayText(20)),
        ],
      ),
    ),
  );
}

/// Capi's line over the scene.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 220),
    child: Container(
      key: ValueKey(text),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: bodyText(15, color: const Color(0xFF2A1458), weight: 600),
      ),
    ),
  );
}
