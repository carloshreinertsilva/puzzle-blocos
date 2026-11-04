import 'dart:math';
import 'dart:async';

import '../core/passe.dart';
import '../core/presente_diario.dart';
import '../core/wardrobe.dart';
import '../core/daily_missions.dart';
import 'daily_missions_dialog.dart';
import 'wardrobe_dialog.dart';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../core/missions.dart';
import '../core/village.dart';
import '../game/onboarding.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../services/avisos.dart';
import '../services/placares.dart';
import '../services/progress_store.dart';
import '../ui/capi.dart';
import '../ui/menu_widgets.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';
import '../shop/produtos.dart';
import 'game_screen.dart';
import 'loja_sheet.dart';
import 'presente_dialog.dart';
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
  Timer? _abertura;

  @override
  void initState() {
    super.initState();
    widget.services.loja.addListener(_lojaMudou);
    // Let the menu show first, then the gift (and any update) over it.
    _abertura = Timer(const Duration(milliseconds: 600), () async {
      await _presenteDoDia();
      if (mounted) {
        await Avisos.verificarAtualizacao(context, widget.services.store);
      }
    });
  }

  /// Once a day, after the first levels, the daily gift opens by itself.
  Future<void> _presenteDoDia() async {
    final store = widget.services.store;
    final agora = DateTime.now();
    final hoje = ProgressStore.dayKey(agora);
    // Not over Capi's first words on the menu: the gift waits for them.
    if (!mounted ||
        _news.isNotEmpty ||
        !store.hasSeen('menu') ||
        !PresenteDiario.disponivel(store, agora) ||
        store.giftShownDay == hoje) {
      return;
    }
    await store.setGiftShown(hoje);
    if (!mounted) return;
    await showPresente(context, widget.services);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.services.loja.removeListener(_lojaMudou);
    _abertura?.cancel();
    super.dispose();
  }

  void _lojaMudou() {
    if (mounted) setState(() {});
  }

  Future<void> _openLoja() async {
    await showLoja(context, widget.services);
    if (mounted) setState(() {});
  }

  int _waiting(ProgressStore store, DateTime today) =>
      DailyMissionsManager.unclaimedCount(store, today) +
      PasseDoCapi.prontas(store, today) +
      (PresenteDiario.disponivel(store, today) ? 1 : 0);

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
    setState(() => _hint = tr(_tips[_tipIndex++ % _tips.length]));
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
      () => _hint = tr('Chegue na fase {n} que eu libero o {modo} pra você!', {
        'n': level,
        'modo': tr(mode),
      }),
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
    unawaited(Placares.enviar(widget.services.store));
    if (!mounted) return;
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
    unawaited(Placares.enviar(widget.services.store));
    if (!mounted) return;
    setState(() => _news = Onboarding.pendingNews(widget.services.store));
  }

  Widget _towerCard(ProgressStore store) {
    if (!Onboarding.towerUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Torre do Capi'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.towerAt}),
        onTap: () => _locked('Torre do Capi', Onboarding.towerAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.layers_rounded,
      color: const Color(0xFF0284C7),
      title: tr('Torre do Capi'),
      subtitle: store.towerBestHeight > 0
          ? tr('Recorde {n} andares', {'n': store.towerBestHeight})
          : tr('Suba em 2.5D'),
      badge: store.hasSeen('opened_tower') ? null : tr('NOVO'),
      onTap: _openTower,
    );
  }

  Widget _blitzCard(ProgressStore store) {
    if (!Onboarding.blitzUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Blitz 60s'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.blitzAt}),
        onTap: () => _locked('Blitz 60s', Onboarding.blitzAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.bolt_rounded,
      color: const Color(0xFFFA5252),
      title: tr('Blitz 60s'),
      subtitle: store.blitzBestScore > 0
          ? tr('Recorde {n}', {'n': formatInt(store.blitzBestScore)})
          : tr('Corrida de 60s'),
      badge: store.hasSeen('opened_blitz') ? null : tr('NOVO'),
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
        title: tr('Duelo'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.duelAt}),
        onTap: () => _locked('Duelo', Onboarding.duelAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.sports_kabaddi_rounded,
      color: const Color(0xFF228BE6),
      title: tr('Duelo'),
      subtitle: store.duelsWon > 0
          ? tr('{n} vitórias', {'n': store.duelsWon})
          : tr('Desafie amigos'),
      badge: store.hasSeen('opened_duel') ? null : tr('NOVO'),
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
            Text(tr('Modo Duelo'), style: displayText(22, color: Palette.text)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'No Duelo, dois jogadores jogam exatamente a mesma sequência de peças para ver quem pontua mais!',
              ),
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
                    tr('Semente da partida: #{seed}', {'seed': seed}),
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
              tr('Fechar'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
          ChunkyButton(
            label: tr('Começar Duelo'),
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
    final next = Village.suggestion(store.villageItems);
    final canBuild = next != null && store.stars >= next.cost;
    return MenuCard(
      icon: Icons.cottage_rounded,
      color: Palette.blocks[3],
      title: tr('Vila do Capi'),
      subtitle: next == null
          ? tr('Vila completa!')
          : tr('{n} de {total} prontos', {
              'n': built,
              'total': Village.items.length,
            }),
      badge: canBuild ? tr('CONSTRUIR!') : null,
      onTap: _openVillage,
    );
  }

  Widget _obrasCard(ProgressStore store) {
    if (!Onboarding.obrasUnlocked(store)) {
      return MenuCard(
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Obras'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.obrasAt}),
        onTap: () => _locked('Obras', Onboarding.obrasAt),
      );
    }
    return MenuCard(
      icon: Icons.architecture_rounded,
      color: Palette.blocks[6],
      title: tr('Obras'),
      subtitle: tr('Obra {n}', {'n': store.obraLevel}),
      badge: store.hasSeen('opened_obras') ? null : tr('NOVO'),
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
                              label: tr('{n} estrelas, abrir a vila', {
                                'n': store.stars,
                              }),
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
                              label: tr('Missões Diárias'),
                              // Missions, chest and Passe rewards waiting.
                              badge: _waiting(store, today) > 0
                                  ? '${_waiting(store, today)}'
                                  : null,
                              onTap: _openDailyMissions,
                            ),
                            SizedBox(width: buttonGap),
                            RoundIconButton(
                              icon: Icons.checkroom_rounded,
                              label: tr('Guarda-Roupa'),
                              onTap: _openWardrobe,
                            ),
                            SizedBox(width: buttonGap),
                            // No room for one more button on small phones:
                            // with a shop, the statistics move to the
                            // settings.
                            if (widget.services.loja.disponivel)
                              _LojaBotao(
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
                                label: tr('Estatísticas'),
                                onTap: () =>
                                    showStats(context, widget.services),
                              ),
                            SizedBox(width: buttonGap),
                            RoundIconButton(
                              icon: Icons.settings_rounded,
                              label: tr('Configurações'),
                              onTap: () =>
                                  showSettings(context, widget.services),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmall ? 8 : 18),
                        Logo(compact: isSmall, showCapi: false),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmall ? 4 : 10,
                            ),
                            // Capi stands big by the road, in everything
                            // he wears; the road keeps clear of him.
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final capi = min(
                                  150.0,
                                  max(96.0, box.maxHeight * 0.42),
                                );
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: LevelPath(
                                        current: store.level,
                                        leftInset: capi * 0.78,
                                        onPlay: () => _open(GameMode.levels),
                                        starsFor: (n) =>
                                            Missions.count(store.levelStars(n)),
                                        onReplay: (n) => _open(
                                          GameMode.levels,
                                          replayLevel: n,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: -capi * 0.1,
                                      bottom: 0,
                                      child: Semantics(
                                        button: true,
                                        label: 'Capi',
                                        excludeSemantics: true,
                                        onTap: _tip,
                                        child: GestureDetector(
                                          onTap: _tip,
                                          child: Capi(
                                            size: capi,
                                            look: CapiLook.of(store),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        ChunkyButton(
                          big: true,
                          icon: Icons.play_arrow_rounded,
                          label: tr('Jogar · Fase {n}', {'n': store.level}),
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
                                      title: tr('Desafio diário'),
                                      subtitle: dailyDone
                                          ? tr('Feito! Volte amanhã')
                                          : streak > 0
                                          ? tr('Sequência: {n} dias', {
                                              'n': streak,
                                            })
                                          : tr('Um novo a cada dia'),
                                      badge: dailyDone ? null : tr('NOVO'),
                                      onTap: () => _open(GameMode.daily),
                                    )
                                  : MenuCard(
                                      icon: Icons.lock_rounded,
                                      color: Palette.panelEdge,
                                      title: tr('Desafio diário'),
                                      subtitle: tr('Libera na fase {n}', {
                                        'n': Onboarding.dailyAt,
                                      }),
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
                                      title: tr('Infinito'),
                                      subtitle: store.bestScore > 0
                                          ? tr('Recorde {n}', {
                                              'n': formatInt(store.bestScore),
                                            })
                                          : tr('Sem metas, sem fim'),
                                      badge: store.hasSeen('opened_endless')
                                          ? null
                                          : tr('NOVO'),
                                      onTap: () => _open(GameMode.endless),
                                    )
                                  : MenuCard(
                                      icon: Icons.lock_rounded,
                                      color: Palette.panelEdge,
                                      title: tr('Infinito'),
                                      subtitle: tr('Libera na fase {n}', {
                                        'n': Onboarding.endlessAt,
                                      }),
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
                      action: _news.isNotEmpty ? tr('Bora!') : tr('Beleza!'),
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

/// The shop button: glows gold, unlike the others, and now and then Capi's
/// balloon calls the player to it.
class _LojaBotao extends StatefulWidget {
  const _LojaBotao({required this.onTap, this.badge});
  final VoidCallback onTap;
  final String? badge;

  @override
  State<_LojaBotao> createState() => _LojaBotaoState();
}

class _LojaBotaoState extends State<_LojaBotao>
    with SingleTickerProviderStateMixin {
  static const _falas = [
    'Novidades na loja!',
    'Olha o Mercado do Capi de hoje!',
    'Tem oferta na loja!',
  ];

  late final AnimationController _brilho = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  Timer? _timer;
  String? _fala;
  int _vez = 0;

  @override
  void initState() {
    super.initState();
    // The first call comes soon after opening the menu, then every so often.
    _timer = Timer(const Duration(seconds: 4), _chamar);
  }

  void _chamar() {
    if (!mounted) return;
    // The balloon goes in the overlay, above the logo under the bar.
    if (!_portal.isShowing) _portal.show();
    setState(() => _fala = tr(_falas[_vez++ % _falas.length]));
    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _fala = null);
      _timer = Timer(const Duration(seconds: 40), _chamar);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _brilho.dispose();
    super.dispose();
  }

  final _link = LayerLink();
  final _portal = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(8, 6),
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _fala == null
                  ? const SizedBox.shrink()
                  : _Balao(key: ValueKey(_fala), texto: _fala!),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: AnimatedBuilder(
          animation: _brilho,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_brilho.value);
            final borda = BorderRadius.circular(14);
            return Container(
              decoration: BoxDecoration(
                borderRadius: borda,
                boxShadow: [
                  BoxShadow(
                    color: Palette.accent.withValues(alpha: 0.3 + 0.45 * t),
                    blurRadius: 6 + 12 * t,
                    spreadRadius: 1 + 2.5 * t,
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: borda,
                border: Border.all(
                  color: Color.lerp(
                    Palette.accent.withValues(alpha: 0.6),
                    const Color(0xFFFFF1B8),
                    t,
                  )!,
                  width: 2,
                ),
              ),
              child: child,
            );
          },
          child: RoundIconButton(
            icon: Icons.storefront_rounded,
            label: tr('Loja'),
            badge: widget.badge,
            iconColor: Palette.accent,
            fill: const Color(0xFF5A3A12),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

/// A small balloon pointing up at the shop button.
class _Balao extends StatelessWidget {
  const _Balao({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 18),
        child: CustomPaint(size: const Size(12, 7), painter: _PontaBalao()),
      ),
      Container(
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: displayText(13, color: const Color(0xFF2A1458)),
        ),
      ),
    ],
  );
}

class _PontaBalao extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PontaBalao old) => false;
}
