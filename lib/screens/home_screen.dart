import '../core/daily_missions.dart';
import '../core/hats.dart';
import 'daily_missions_dialog.dart';
import 'wardrobe_dialog.dart';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../core/missions.dart';
import '../core/village.dart';
import '../game/onboarding.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../services/progress_store.dart';
import '../ui/capi.dart';
import '../ui/menu_widgets.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';
import '../shop/produtos.dart';
import 'game_screen.dart';
import 'loja_sheet.dart';
import 'obra_screen.dart';
import 'settings_sheet.dart';
import 'stats_sheet.dart';
import 'village_screen.dart';
import 'tower_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// What Capi says over the menu (news first, then any hint), if anything.
  late List<MenuNews> _news = Onboarding.pendingNews(widget.services.store);
  String? _hint;

  String? get _capiLine => _news.isNotEmpty ? _news.first.text : _hint;

  // The shop button shows once the store answers (and the starter pack
  // badge as soon as it is on offer).
  @override
  void initState() {
    super.initState();
    widget.services.loja.addListener(_lojaMudou);
  }

  @override
  void dispose() {
    widget.services.loja.removeListener(_lojaMudou);
    super.dispose();
  }

  void _lojaMudou() {
    if (mounted) setState(() {});
  }

  Future<void> _openLoja() async {
    await showLoja(context, widget.services);
    if (mounted) setState(() {});
  }

  void _dismissCapi() {
    widget.services.feedback.click();
    setState(() {
      if (_news.isNotEmpty) {
        widget.services.store.markSeen(_news.removeAt(0).key);
      } else {
        _hint = null;
      }
    });
  }

  static const _tips = [
    'Dica: guarde espaço para as peças grandes, como o quadradão 3x3.',
    'Limpar duas linhas de uma vez vale muito mais pontos!',
    'Limpando linhas em seguida você faz combo e multiplica os pontos.',
    'Gemas só contam quando a linha ou a coluna delas some.',
    'Ficou parado? Eu dou uma dica de onde encaixar a peça.',
  ];
  int _tipIndex = 0;

  void _tip() {
    widget.services.feedback.click();
    setState(() => _hint = _tips[_tipIndex++ % _tips.length]);
  }

  Future<void> _openWardrobe() async {
    Analytics.event('screen_open', {'screen': 'wardrobe'});
    widget.services.feedback.click();
    await WardrobeDialog.show(context, widget.services);
    if (mounted) setState(() {});
  }

  Future<void> _openDailyMissions() async {
    Analytics.event('screen_open', {'screen': 'missions'});
    widget.services.feedback.click();
    await DailyMissionsDialog.show(context, widget.services);
    if (mounted) setState(() {});
  }

  void _locked(String mode, int level) {
    widget.services.feedback.click();
    setState(
      () => _hint = 'Chegue na fase $level que eu libero o $mode pra você!',
    );
  }

  Future<void> _openVillage() async {
    Analytics.event('screen_open', {'screen': 'village'});
    widget.services.feedback.click();
    final play = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => VillageScreen(services: widget.services),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (!mounted) return;
    setState(() {});
    // "Jogar" in the village: straight into the current level.
    if (play == true) await _open(GameMode.levels);
  }

  Future<void> _open(
    GameMode mode, {
    int? replayLevel,
    int? duelSeed,
    int? duelTargetScore,
    String? duelRivalName,
  }) async {
    widget.services.feedback.click();
    if (mode == GameMode.endless) {
      widget.services.store.markSeen('opened_endless');
    }
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => GameScreen(
          services: widget.services,
          mode: mode,
          replayLevel: replayLevel,
          duelSeed: duelSeed,
          duelTargetScore: duelTargetScore,
          duelRivalName: duelRivalName,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    // Level, record and streak may have changed, and modes may unlock.
    setState(() => _news = Onboarding.pendingNews(widget.services.store));
  }

  Future<void> _openTower() async {
    Analytics.event('screen_open', {'screen': 'tower'});
    widget.services.feedback.click();
    widget.services.store.markSeen('opened_tower');
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => TowerScreen(services: widget.services),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (!mounted) return;
    setState(() => _news = Onboarding.pendingNews(widget.services.store));
  }

  Widget _towerCard(ProgressStore store) {
    if (!Onboarding.towerUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: 'Torre do Capi',
        subtitle: 'Libera na fase ${Onboarding.towerAt}',
        onTap: () => _locked('Torre do Capi', Onboarding.towerAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.layers_rounded,
      color: const Color(0xFF0284C7),
      title: 'Torre do Capi',
      subtitle: store.towerBestHeight > 0
          ? 'Recorde ${store.towerBestHeight} andares'
          : 'Suba em 2.5D',
      badge: store.hasSeen('opened_tower') ? null : 'NOVO',
      onTap: _openTower,
    );
  }

  Widget _blitzCard(ProgressStore store) {
    if (!Onboarding.blitzUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: 'Blitz 60s',
        subtitle: 'Libera na fase ${Onboarding.blitzAt}',
        onTap: () => _locked('Blitz 60s', Onboarding.blitzAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.bolt_rounded,
      color: const Color(0xFFFA5252),
      title: 'Blitz 60s',
      subtitle: store.blitzBestScore > 0
          ? 'Recorde ${formatInt(store.blitzBestScore)}'
          : 'Corrida de 60s',
      badge: store.hasSeen('opened_blitz') ? null : 'NOVO',
      onTap: () {
        store.markSeen('opened_blitz');
        _open(GameMode.blitz);
      },
    );
  }

  Widget _duelCard(ProgressStore store) {
    if (!Onboarding.duelUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: 'Duelo',
        subtitle: 'Libera na fase ${Onboarding.duelAt}',
        onTap: () => _locked('Duelo', Onboarding.duelAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.sports_kabaddi_rounded,
      color: const Color(0xFF228BE6),
      title: 'Duelo',
      subtitle: store.duelsWon > 0
          ? '${store.duelsWon} vitórias'
          : 'Desafie amigos',
      badge: store.hasSeen('opened_duel') ? null : 'NOVO',
      onTap: () {
        store.markSeen('opened_duel');
        _openDuelDialog();
      },
    );
  }

  void _openDuelDialog() {
    widget.services.feedback.click();
    final seed = DateTime.now().millisecondsSinceEpoch % 1000000;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141938),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.sports_kabaddi_rounded,
              color: Color(0xFF339AF0),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text('Modo Duelo', style: displayText(22, color: Palette.text)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No Duelo, dois jogadores jogam exatamente a mesma sequência de peças para ver quem pontua mais!',
              style: bodyText(15, color: Palette.textDim),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x33228BE6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66228BE6)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.vpn_key_rounded,
                    color: Color(0xFF339AF0),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Semente da partida: #$seed',
                    style: displayText(14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Fechar',
              style: displayText(16, color: Palette.textDim),
            ),
          ),
          ChunkyButton(
            label: 'Começar Duelo',
            icon: Icons.play_arrow_rounded,
            color: const Color(0xFF228BE6),
            textColor: Colors.white,
            onTap: () {
              Navigator.of(ctx).pop();
              _open(GameMode.duel, duelSeed: seed, duelTargetScore: 1000);
            },
          ),
        ],
      ),
    );
  }

  Widget _villageCard(ProgressStore store) {
    final built = store.villageBuilt;
    final next = Village.next(built);
    final canBuild = next != null && store.stars >= next.cost;
    return MenuCard(
      icon: Icons.cottage_rounded,
      color: Palette.blocks[3],
      title: 'Vila do Capi',
      subtitle: next == null
          ? 'Vila completa!'
          : '$built de ${Village.items.length} prontos',
      badge: canBuild ? 'CONSTRUIR!' : null,
      onTap: _openVillage,
    );
  }

  Widget _obrasCard(ProgressStore store) {
    if (!Onboarding.obrasUnlocked(store)) {
      return MenuCard(
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: 'Obras',
        subtitle: 'Libera na fase ${Onboarding.obrasAt}',
        onTap: () => _locked('Obras', Onboarding.obrasAt),
      );
    }
    return MenuCard(
      icon: Icons.architecture_rounded,
      color: Palette.blocks[6],
      title: 'Obras',
      subtitle: 'Obra ${store.obraLevel}',
      badge: store.hasSeen('opened_obras') ? null : 'NOVO',
      onTap: _openObras,
    );
  }

  Future<void> _openObras() async {
    Analytics.event('screen_open', {'screen': 'obras'});
    widget.services.feedback.click();
    widget.services.store.markSeen('opened_obras');
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => ObraScreen(services: widget.services),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final today = DateTime.now();
    final dailyDone = store.dailyDone(today);
    final streak = store.dailyStreak(today);
    final dailyOpen = Onboarding.dailyUnlocked(store);
    final endlessOpen = Onboarding.endlessUnlocked(store);
    final hasExtraModes =
        Onboarding.blitzUnlocked(store) ||
        Onboarding.duelUnlocked(store) ||
        Onboarding.towerUnlocked(store);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = MediaQuery.sizeOf(context).height < 720;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 20.0;
    final buttonGap = screenWidth < 360 ? 4.0 : 6.0;
    final capiLine = _capiLine;

    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGradient,
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBlocks()),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: menuMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Semantics(
                              button: true,
                              label: '${store.stars} estrelas, abrir a vila',
                              excludeSemantics: true,
                              onTap: _openVillage,
                              child: GestureDetector(
                                onTap: _openVillage,
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  height: 44,
                                  child: Center(
                                    child: StatChip(
                                      icon: Icons.star_rounded,
                                      color: Palette.accent,
                                      value: formatInt(store.stars),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: buttonGap),
                            StatChip(
                              icon: Icons.local_fire_department_rounded,
                              color: Palette.accentDeep,
                              value: '$streak',
                            ),
                            const Spacer(),
                            RoundIconButton(
                              icon: Icons.assignment_turned_in_rounded,
                              label: 'Missões Diárias',
                              badge:
                                  DailyMissionsManager.unclaimedCount(
                                        store,
                                        today,
                                      ) >
                                      0
                                  ? '${DailyMissionsManager.unclaimedCount(store, today)}'
                                  : null,
                              onTap: _openDailyMissions,
                            ),
                            SizedBox(width: buttonGap),
                            RoundIconButton(
                              icon: Icons.checkroom_rounded,
                              label: 'Guarda-Roupa',
                              onTap: _openWardrobe,
                            ),
                            SizedBox(width: buttonGap),
                            // No room for one more button on small phones:
                            // with a shop, the statistics move to the
                            // settings.
                            if (widget.services.loja.disponivel)
                              RoundIconButton(
                                icon: Icons.storefront_rounded,
                                label: 'Loja',
                                badge:
                                    Entrega.mostraPacoteInicial(
                                      store,
                                      DateTime.now(),
                                    )
                                    ? '!'
                                    : null,
                                onTap: _openLoja,
                              )
                            else
                              RoundIconButton(
                                icon: Icons.bar_chart_rounded,
                                label: 'Estatísticas',
                                onTap: () =>
                                    showStats(context, widget.services),
                              ),
                            SizedBox(width: buttonGap),
                            RoundIconButton(
                              icon: Icons.settings_rounded,
                              label: 'Configurações',
                              onTap: () =>
                                  showSettings(context, widget.services),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmall ? 8 : 18),
                        Logo(
                          onCapiTap: _tip,
                          compact: isSmall,
                          hat: CapiHat.fromId(store.equippedHat),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmall ? 4 : 10,
                            ),
                            child: LevelPath(
                              current: store.level,
                              onPlay: () => _open(GameMode.levels),
                              starsFor: (n) =>
                                  Missions.count(store.levelStars(n)),
                              onReplay: (n) =>
                                  _open(GameMode.levels, replayLevel: n),
                            ),
                          ),
                        ),
                        ChunkyButton(
                          big: true,
                          icon: Icons.play_arrow_rounded,
                          label: 'Jogar · Fase ${store.level}',
                          onTap: () => _open(GameMode.levels),
                        ),
                        SizedBox(height: isSmall ? 10 : 22),
                        Row(
                          children: [
                            Expanded(child: _villageCard(store)),
                            const SizedBox(width: 12),
                            Expanded(child: _obrasCard(store)),
                          ],
                        ),
                        SizedBox(height: isSmall ? 10 : 26),
                        Row(
                          children: [
                            Expanded(
                              child: dailyOpen
                                  ? MenuCard(
                                      icon: dailyDone
                                          ? Icons.check_circle_rounded
                                          : Icons.calendar_today_rounded,
                                      color: Palette.blocks[0],
                                      title: 'Desafio diário',
                                      subtitle: dailyDone
                                          ? 'Feito! Volte amanhã'
                                          : streak > 0
                                          ? 'Sequência: $streak dias'
                                          : 'Um novo a cada dia',
                                      badge: dailyDone ? null : 'NOVO',
                                      onTap: () => _open(GameMode.daily),
                                    )
                                  : MenuCard(
                                      icon: Icons.lock_rounded,
                                      color: Palette.panelEdge,
                                      title: 'Desafio diário',
                                      subtitle:
                                          'Libera na fase ${Onboarding.dailyAt}',
                                      onTap: () => _locked(
                                        'Desafio diário',
                                        Onboarding.dailyAt,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: endlessOpen
                                  ? MenuCard(
                                      icon: Icons.all_inclusive_rounded,
                                      color: Palette.blocks[5],
                                      title: 'Infinito',
                                      subtitle: store.bestScore > 0
                                          ? 'Recorde ${formatInt(store.bestScore)}'
                                          : 'Sem metas, sem fim',
                                      badge: store.hasSeen('opened_endless')
                                          ? null
                                          : 'NOVO',
                                      onTap: () => _open(GameMode.endless),
                                    )
                                  : MenuCard(
                                      icon: Icons.lock_rounded,
                                      color: Palette.panelEdge,
                                      title: 'Infinito',
                                      subtitle:
                                          'Libera na fase ${Onboarding.endlessAt}',
                                      onTap: () => _locked(
                                        'Infinito',
                                        Onboarding.endlessAt,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        if (hasExtraModes) ...[
                          SizedBox(height: isSmall ? 10 : 12),
                          Row(
                            children: [
                              Expanded(child: _blitzCard(store)),
                              const SizedBox(width: 10),
                              Expanded(child: _duelCard(store)),
                              const SizedBox(width: 10),
                              Expanded(child: _towerCard(store)),
                            ],
                          ),
                        ],
                        SizedBox(height: isSmall ? 10 : 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (capiLine != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _dismissCapi,
                  child: const ColoredBox(color: Color(0x88080A20)),
                ),
              ),
            if (capiLine != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24 + MediaQuery.paddingOf(context).bottom,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: menuMaxWidth),
                    child: CapiSays(
                      text: capiLine,
                      capiSize: 96,
                      action: _news.isNotEmpty ? 'Bora!' : 'Beleza!',
                      onAction: _dismissCapi,
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
