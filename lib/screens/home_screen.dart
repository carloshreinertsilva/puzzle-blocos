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
import '../services/jogo_salvo.dart';
import '../services/musica.dart';
import '../services/placares.dart';
import '../services/progress_store.dart';
import '../testing/test_bridge.dart';
import '../ui/capi.dart';
import '../ui/menu_widgets.dart';
import '../ui/oferta_nuvem.dart';
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
    widget.services.feedback.musica.tocar(Trilha.menu);
    _talvezSugerir();
    // Let the menu show first, then the gift (and any update) over it.
    _abertura = Timer(const Duration(milliseconds: 600), () async {
      await _presenteDoDia();
      if (mounted) {
        await Avisos.verificarAtualizacao(context, widget.services.store);
      }
      await _convidarPlayGames();
      if (!mounted) return;
      final nuvem = await JogoSalvo.verificar(widget.services.store);
      if (!mounted) return;
      await oferecerProgressoDaNuvem(context, widget.services.store, nuvem);
    });
  }

  /// After the first levels, twice at most: sign in to Play Games to be on
  /// the leaderboards.
  Future<void> _convidarPlayGames() async {
    final store = widget.services.store;
    final hoje = ProgressStore.dayKey(DateTime.now());
    if (!mounted || !await Placares.deveConvidar(store, hoje)) return;
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    await store.marcarConvitePlayGames(hoje);
    if (!mounted) return;
    final entrar = await showDialog<bool>(
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
              Icons.leaderboard_rounded,
              color: Palette.accent,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('Salve seu progresso'),
                style: displayText(22, color: Palette.text),
              ),
            ),
          ],
        ),
        content: Text(
          tr(
            'Entre no Google Play Games para salvar seu progresso na nuvem '
            'e aparecer nos placares com seus amigos.',
          ),
          style: bodyText(15, color: Palette.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              tr('Agora não'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
          ChunkyButton(
            label: tr('Entrar'),
            icon: Icons.login_rounded,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (entrar != true) return;
    Analytics.event('play_games_convite', {'aceitou': 1});
    if (!await Placares.entrar(store)) return;
    final nuvem = await JogoSalvo.verificarDeNovo(store);
    if (!mounted) return;
    await oferecerProgressoDaNuvem(context, store, nuvem);
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
    _sugestaoTimer?.cancel();
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
    _sairDaFolha();
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
    _sairDaFolha();
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
    unawaited(JogoSalvo.salvar(widget.services.store));
    if (!mounted) return;
    setState(() => _news = Onboarding.pendingNews(widget.services.store));
  }

  Future<void> _openTower() async {
    _sairDaFolha();
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
    unawaited(JogoSalvo.salvar(widget.services.store));
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
    _sairDaFolha();
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
            for (final (i, passo) in [
              tr('Jogue e faça a sua pontuação.'),
              tr('No fim, toque em Desafiar Amigo e mande o link.'),
              tr('Seu amigo joga as mesmas peças e tenta passar você.'),
            ].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF228BE6),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: displayText(13, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        passo,
                        style: bodyText(15, color: Palette.text),
                      ),
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
              _open(GameMode.duel, duelSeed: seed);
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
      compact: true,
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
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Obras'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.obrasAt}),
        onTap: () => _locked('Obras', Onboarding.obrasAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.architecture_rounded,
      color: Palette.blocks[6],
      title: tr('Obras'),
      subtitle: tr('Obra {n}', {'n': store.obraLevel}),
      badge: store.hasSeen('opened_obras') ? null : tr('NOVO'),
      onTap: _openObras,
    );
  }

  Future<void> _openObras() async {
    _sairDaFolha();
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

  Widget _endlessCard(ProgressStore store) {
    if (!Onboarding.endlessUnlocked(store)) {
      return MenuCard(
        compact: true,
        icon: Icons.lock_rounded,
        color: Palette.panelEdge,
        title: tr('Infinito'),
        subtitle: tr('Libera na fase {n}', {'n': Onboarding.endlessAt}),
        onTap: () => _locked('Infinito', Onboarding.endlessAt),
      );
    }
    return MenuCard(
      compact: true,
      icon: Icons.all_inclusive_rounded,
      color: Palette.blocks[5],
      title: tr('Infinito'),
      subtitle: store.bestScore > 0
          ? tr('Recorde {n}', {'n': formatInt(store.bestScore)})
          : tr('Sem metas, sem fim'),
      badge: store.hasSeen('opened_endless') ? null : tr('NOVO'),
      onTap: () => _open(GameMode.endless),
    );
  }

  /// A mode the player has unlocked but never opened: "NOVO" on Modos.
  bool _modoNovo(ProgressStore store) =>
      (Onboarding.endlessUnlocked(store) && !store.hasSeen('opened_endless')) ||
      (Onboarding.blitzUnlocked(store) && !store.hasSeen('opened_blitz')) ||
      (Onboarding.duelUnlocked(store) && !store.hasSeen('opened_duel')) ||
      (Onboarding.towerUnlocked(store) && !store.hasSeen('opened_tower')) ||
      (Onboarding.obrasUnlocked(store) && !store.hasSeen('opened_obras'));

  /// Every other way to play, in one sheet: the menu keeps room for the
  /// road.
  Future<void> _openModos() async {
    Analytics.event('screen_open', {'screen': 'modos'});
    widget.services.feedback.click();
    final store = widget.services.store;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        _folha = Navigator.of(ctx);
        Widget toque(Widget Function(ProgressStore) card) => card(store);
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Palette.panel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Palette.panelEdge, width: 2),
            ),
            // A close button too: the iPhone has no back button.
            child: ComFechar(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        tr('Modos de jogo'),
                        style: displayText(20, color: Palette.text),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: toque(_endlessCard)),
                        const SizedBox(width: 10),
                        Expanded(child: toque(_blitzCard)),
                        const SizedBox(width: 10),
                        Expanded(child: toque(_duelCard)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: toque(_towerCard)),
                        const SizedBox(width: 10),
                        Expanded(child: toque(_obrasCard)),
                        const SizedBox(width: 10),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    _folha = null;
    if (mounted) setState(() {});
  }

  /// The Modos sheet while it is open: a mode chosen in it closes it first.
  NavigatorState? _folha;

  void _sairDaFolha() {
    final folha = _folha;
    _folha = null;
    if (folha != null && folha.mounted && folha.canPop()) folha.pop();
  }

  Future<void> _openMercado() async {
    Analytics.event('screen_open', {'screen': 'mercado'});
    widget.services.feedback.click();
    await WardrobeDialog.show(context, widget.services, mercado: true);
    if (mounted) setState(() {});
  }

  /// The leaderboards (Google Play Games, Game Center); on the web, where
  /// there are none, the player's own records.
  Future<void> _openRanking() async {
    Analytics.event('screen_open', {'screen': 'ranking'});
    widget.services.feedback.click();
    if (Placares.ativo &&
        await Placares.mostrar(widget.services.store) &&
        mounted) {
      return;
    }
    if (mounted) await showStats(context, widget.services);
  }

  /// Now and then Capi shows himself in something from the wardrobe: on
  /// the first menu of a session and then every third, when nothing else
  /// is being said.
  static int _menus = 0;
  Cosmetic? _sugestao;
  Timer? _sugestaoTimer;

  void _talvezSugerir() {
    // Browser tests keep Capi as he is (they look at the menu around him).
    if (kTestBridge || _menus++ % 3 != 0) return;
    _sugestaoTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted || _capiLine != null) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      final item = _escolherSugestao(widget.services.store);
      if (item == null) return;
      Analytics.event('capi_sugestao', {'item': item.id});
      setState(() => _sugestao = item);
      _sugestaoTimer = Timer(const Duration(seconds: 7), () {
        if (mounted) setState(() => _sugestao = null);
      });
    });
  }

  /// Something the player doesn't have yet, best one they can buy now.
  static Cosmetic? _escolherSugestao(ProgressStore store) {
    final faltam = [
      for (final c in Wardrobe.catalog)
        if (!Wardrobe.owns(store, c) && c.preco != null) c,
    ];
    if (faltam.isEmpty) return null;
    final cabe = [
      for (final c in faltam)
        if (c.preco! <= store.stars) c,
    ];
    final lista = cabe.isNotEmpty ? cabe : faltam;
    return lista[Random().nextInt(lista.length)];
  }

  Future<void> _verSugestao() async {
    _sugestaoTimer?.cancel();
    setState(() => _sugestao = null);
    await _openWardrobe();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final today = DateTime.now();
    final dailyDone = store.dailyDone(today);
    final streak = store.dailyStreak(today);
    final dailyOpen = Onboarding.dailyUnlocked(store);
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
                            if (widget.services.loja.disponivel) ...[
                              SizedBox(width: buttonGap),
                              _LojaBotao(
                                badge:
                                    Entrega.mostraPacoteInicial(
                                      store,
                                      DateTime.now(),
                                    )
                                    ? '!'
                                    : null,
                                onTap: _openLoja,
                              ),
                            ],
                            SizedBox(width: buttonGap),
                            RoundIconButton(
                              icon: Icons.settings_rounded,
                              label: tr('Configurações'),
                              onTap: () =>
                                  showSettings(context, widget.services),
                            ),
                          ],
                        ),
                        if (!isSmall) ...[
                          const SizedBox(height: 6),
                          Logo(compact: true, showCapi: false),
                        ],
                        SizedBox(height: isSmall ? 8 : 10),
                        // What the player looks at first: dressing Capi,
                        // the market and the leaderboards.
                        Row(
                          children: [
                            Expanded(
                              child: _Destaque(
                                icon: Icons.checkroom_rounded,
                                cor: const Color(0xFFE8590C),
                                titulo: tr('Guarda-Roupa'),
                                subtitulo: tr('Vista o Capi'),
                                onTap: _openWardrobe,
                              ),
                            ),
                            SizedBox(width: buttonGap + 2),
                            Expanded(
                              child: _Destaque(
                                icon: Icons.diamond_rounded,
                                cor: const Color(0xFF9C36B5),
                                titulo: tr('Mercado'),
                                subtitulo: tr('Lendário do dia'),
                                onTap: _openMercado,
                              ),
                            ),
                            SizedBox(width: buttonGap + 2),
                            Expanded(
                              child: _Destaque(
                                icon: Icons.emoji_events_rounded,
                                cor: const Color(0xFF1971C2),
                                titulo: tr('Ranking'),
                                subtitulo: store.bestScore > 0
                                    ? tr('Recorde {n}', {
                                        'n': formatInt(store.bestScore),
                                      })
                                    : tr('Placares'),
                                onTap: _openRanking,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmall ? 4 : 8,
                            ),
                            // Capi stands big by the road, in everything
                            // he wears; the road keeps clear of him.
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final capi = min(
                                  150.0,
                                  max(96.0, box.maxHeight * 0.42),
                                );
                                final sugestao = _sugestao;
                                final look = sugestao == null
                                    ? CapiLook.of(store)
                                    : CapiLook.of(store).wearing(sugestao);
                                return Stack(
                                  clipBehavior: Clip.none,
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
                                          onTap: sugestao == null
                                              ? _tip
                                              : _verSugestao,
                                          child: Capi(size: capi, look: look),
                                        ),
                                      ),
                                    ),
                                    if (sugestao != null)
                                      Positioned(
                                        left: 0,
                                        bottom: capi * 0.98,
                                        child: _SugestaoBalao(
                                          texto: tr(
                                            'Que tal {item}? Fica a minha cara!',
                                            {'item': sugestao.label},
                                          ),
                                          onTap: _verSugestao,
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
                        SizedBox(height: isSmall ? 10 : 18),
                        Row(
                          children: [
                            Expanded(child: _villageCard(store)),
                            SizedBox(width: buttonGap + 4),
                            Expanded(
                              child: dailyOpen
                                  ? MenuCard(
                                      compact: true,
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
                                      compact: true,
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
                            SizedBox(width: buttonGap + 4),
                            Expanded(
                              child: MenuCard(
                                compact: true,
                                icon: Icons.sports_esports_rounded,
                                color: Palette.blocks[5],
                                title: tr('Modos'),
                                subtitle: tr('Modos de jogo'),
                                badge: _modoNovo(store) ? tr('NOVO') : null,
                                onTap: _openModos,
                              ),
                            ),
                          ],
                        ),
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

/// One of the three big buttons under the top bar: wardrobe, market,
/// leaderboards.
class _Destaque extends StatelessWidget {
  const _Destaque({
    required this.icon,
    required this.cor,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icon;
  final Color cor;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: titulo,
      hint: subtitulo,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(cor, Colors.white, 0.15)!, cor],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(
                color: Color.lerp(cor, Colors.black, 0.35)!,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        titulo,
                        maxLines: 1,
                        style: displayText(15, color: Colors.white),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitulo,
                        maxLines: 1,
                        style: bodyText(11, color: const Color(0xDDFFFFFF)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Capi's balloon over his head when he shows himself in something new.
class _SugestaoBalao extends StatelessWidget {
  const _SugestaoBalao({required this.texto, required this.onTap});
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: texto,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(
            scale: v,
            alignment: Alignment.bottomLeft,
            child: child,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 190),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 6),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: displayText(13, color: const Color(0xFF2A1458)),
                ),
                const SizedBox(height: 2),
                Text(
                  tr('Ver no guarda-roupa ›'),
                  style: bodyText(11, color: const Color(0xFF7048E8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
