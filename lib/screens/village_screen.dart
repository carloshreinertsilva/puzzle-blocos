import '../core/wardrobe.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/village.dart';
import '../main.dart';
import '../testing/test_bridge.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';
import '../village/scene.dart';
import 'obra_screen.dart';

/// Capi's village: a floating island that fills up with things built with
/// the stars earned in the levels. Pops with `true` when the player wants to
/// go play for more stars.
class VillageScreen extends StatefulWidget {
  const VillageScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  final _clock = ValueNotifier<double>(0);
  final _model = VillageModel();
  final _cache = VillageCache();
  late final Ticker _ticker;
  late String _line = _idleLine();
  Timer? _lineTimer;

  /// What Capi says when an item is tapped.
  static const _remarks = {
    'flores': 'As borboletas não largam essas flores!',
    'cerca': 'Cerquinha branquinha, pintada por mim!',
    'banco': 'Melhor lugar pra ver o pôr do sol.',
    'arvore': 'Acerola fresquinha! Quer uma?',
    'barco': 'Bora dar uma volta na lagoa?',
    'horta': 'Cenoura e repolho: almoço garantido!',
    'poste': 'De noite os vaga-lumes vêm brincar aqui.',
    'pier': 'Daqui eu pulo na água. Tchibum!',
    'casinha': 'Lar, doce lar! Até a chaminé funciona.',
    'balanco': 'Uiii! Mais alto, mais alto!',
    'fonte': 'Dizem que quem joga uma moeda volta sempre.',
    'roda': 'Lá de cima dá pra ver as nuvens!',
  };

  static const _pupLines = [
    'Esse filhote você salvou de um bloco! Olha a alegria dele.',
    'Os filhotes adoram brincar perto da lagoa.',
    'Os filhotes que você salva vêm brincar aqui!',
  ];

  static const _capiLines = [
    'Ei, isso faz cócegas!',
    'Bora construir mais coisa?',
    'Cada estrela vira um tijolinho!',
    'Essa ilha tá ficando um charme.',
  ];

  @override
  void initState() {
    super.initState();
    _model
      ..built = _built.toSet()
      ..selected = Village.suggestion(_built)?.id
      ..pups = widget.services.store.pupsSaved
      ..look = CapiLook.of(widget.services.store);
    VillageSprites.load().then((sprites) {
      if (mounted) setState(() => _model.sprites = sprites);
    });
    _ticker = createTicker((elapsed) {
      _clock.value = elapsed.inMicroseconds / 1e6;
    })..start();
    if (kTestBridge) TestBridge.instance.screen = 'village';
  }

  @override
  void dispose() {
    // The next screen may already have opened (the game, on "Jogar").
    if (kTestBridge && TestBridge.instance.screen == 'village') {
      TestBridge.instance.screen = 'home';
    }
    _lineTimer?.cancel();
    _ticker.dispose();
    _clock.dispose();
    _cache.dispose();
    for (final image in _model.sprites.values) {
      image.dispose();
    }
    super.dispose();
  }

  List<String> get _built => widget.services.store.villageItems;

  /// The item picked in the market.
  VillageItem? get _selected {
    final id = _model.selected;
    return id == null || _built.contains(id) ? null : Village.byId(id);
  }

  void _select(VillageItem item) {
    if (_model.building != null) return;
    widget.services.feedback.click();
    setState(() => _model.selected = item.id);
    _say(_lineFor(item), hold: const Duration(seconds: 4));
  }

  String _lineFor(VillageItem item) {
    final missing = item.cost - _stars;
    return missing > 0
        ? 'Faltam $missing ${missing == 1 ? 'estrela' : 'estrelas'} para '
              '${item.name.toLowerCase()}. Bora jogar?'
        : 'Já dá para construir ${item.name.toLowerCase()}! Toque em '
              'Construir e monte a obra.';
  }

  int get _stars => widget.services.store.stars;

  String _idleLine() {
    final next = _selected ?? Village.suggestion(_built);
    if (next == null) return 'A vila ficou linda! Obrigado, construtor!';
    if (_built.isEmpty) {
      return 'Bem-vindo à minha ilha! Escolha no mercado o que a gente '
          'constrói primeiro.';
    }
    return _lineFor(next);
  }

  /// Shows [line] for a while, then goes back to the idle line.
  void _say(String line, {Duration hold = const Duration(seconds: 3)}) {
    _lineTimer?.cancel();
    setState(() => _line = line);
    _lineTimer = Timer(hold, () {
      if (mounted) setState(() => _line = _idleLine());
    });
  }

  Future<void> _build(VillageItem item) async {
    final store = widget.services.store;
    if (_model.building != null || store.stars < item.cost) return;
    // First the obra: the item's drawing, filled with pieces. The stars
    // are only spent once it is done.
    widget.services.feedback.click();
    final done = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) =>
            ObraScreen(services: widget.services, item: item),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (done != true || !mounted) {
      if (mounted) setState(() => _line = _idleLine());
      return;
    }
    if (!await store.spendStars(item.cost)) return;
    await store.addVillageItem(item.id);
    if (!mounted) return;
    _model
      ..built = _built.toSet()
      ..selected = Village.suggestion(_built)?.id
      ..building = item.id
      ..buildStart = _clock.value;
    const cheers = [
      'Ficou lindo!',
      'Uhul! A vila tá crescendo!',
      'Que obra caprichada!',
      'Valeu, parceiro de obra!',
    ];
    _say(
      '${cheers[_rng.nextInt(cheers.length)]} Agora a vila tem: '
      '${item.name.toLowerCase()}.',
      hold: const Duration(milliseconds: 5000),
    );
    // It lands with a thud, then the fanfare.
    await Future<void>.delayed(const Duration(milliseconds: 560));
    widget.services.feedback.place();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    widget.services.feedback.win();
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _model.building = null);
  }

  void _tap(Offset at, Size size) {
    final id = VillageLayout(size).hit(at, _model, _clock.value);
    if (id == null) return;
    _model.pokes[id] = _clock.value;
    widget.services.feedback.pick();
    if (_model.building != null) return;
    _say(
      id == 'capi'
          ? _capiLines[_rng.nextInt(_capiLines.length)]
          : id.startsWith('pup')
          ? _pupLines[_rng.nextInt(_pupLines.length)]
          : _remarks[id] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = _selected;
    final left = Village.toBuild(_built);
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Positioned.fill(child: _scene()),
                        Positioned(
                          left: 10,
                          right: 10,
                          top: 10,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: menuMaxWidth,
                              ),
                              child: _Bubble(text: _line),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: menuMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                    child: left.isEmpty ? _done() : _mercado(left, next),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scene() => LayoutBuilder(
    builder: (context, box) {
      final size = box.biggest;
      return Semantics(
        label:
            'Ilha do Capi com ${_built.length} de ${Village.items.length} '
            'construções',
        excludeSemantics: true,
        // Pinch to zoom in on the island and look around.
        child: InteractiveViewer(
          maxScale: 2.5,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tap(d.localPosition, size),
            child: RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: VillagePainter(
                  clock: _clock,
                  model: _model,
                  cache: _cache,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  /// The village market: everything left to build, cheapest first. The
  /// player picks one (its spot glows on the island), then builds it.
  Widget _mercado(List<VillageItem> left, VillageItem? sel) {
    final canBuild = sel != null && _stars >= sel.cost;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: Palette.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.panelEdge, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: Palette.accent,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text('Mercado da vila', style: displayText(17)),
              const Spacer(),
              Text(
                '${_built.length} de ${Village.items.length} prontos',
                style: bodyText(13, color: Palette.textDim),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 118,
            // Only a dozen items: all built, so each can be found and read.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, item) in left.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _ItemCard(
                      item: item,
                      selected: item.id == sel?.id,
                      affordable: _stars >= item.cost,
                      onTap: () => _select(item),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (sel == null)
            Text(
              'Toque num item para escolher o que construir.',
              style: bodyText(14, color: Palette.textDim),
            )
          else if (canBuild)
            ChunkyButton(
              label: 'Construir · ${sel.cost} ★',
              semanticLabel: 'Construir ${sel.name}',
              icon: Icons.construction_rounded,
              color: Palette.good,
              textColor: const Color(0xFF0B3B16),
              onTap: _model.building == null ? () => _build(sel) : null,
            )
          else
            ChunkyButton(
              label: 'Faltam ${sel.cost - _stars} ★ · Jogar',
              semanticLabel: 'Jogar',
              icon: Icons.play_arrow_rounded,
              onTap: () => Navigator.of(context).pop(true),
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
    transitionBuilder: (child, anim) => ScaleTransition(
      scale: Tween(
        begin: 0.85,
        end: 1.0,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
      child: FadeTransition(opacity: anim, child: child),
    ),
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

/// One item in the village market: its picture, name and price.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.selected,
    required this.affordable,
    required this.onTap,
  });

  final VillageItem item;
  final bool selected;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${item.name}, ${item.cost} estrelas',
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 96,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: selected
              ? Palette.accent.withValues(alpha: 0.18)
              : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Palette.accent : const Color(0x33FFFFFF),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: VillageItemIcon(item: item, size: 56)),
            const SizedBox(height: 2),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyText(12, color: Palette.text, weight: 700),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: affordable ? Palette.accent : Palette.textDim,
                ),
                const SizedBox(width: 2),
                Text(
                  '${item.cost}',
                  style: displayText(
                    14,
                    color: affordable ? Palette.accent : Palette.textDim,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
