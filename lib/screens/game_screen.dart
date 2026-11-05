import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../ui/blitz_duel_painter.dart';

import '../ads/ad_service.dart';
import '../core/game_session.dart';
import '../services/musica.dart';
import '../services/analytics.dart';
import '../services/duelo_link.dart';
import '../core/missions.dart';
import '../l10n/idioma.dart';
import '../game/game_controller.dart';
import '../game/onboarding.dart';
import '../game/puzzle_game.dart';
import '../main.dart';
import '../testing/test_bridge.dart';
import '../ui/level_text.dart';
import '../ui/capi.dart';
import '../ui/dica_paga.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../core/board.dart';
import '../services/progress_store.dart';
import '../ui/tool_painter.dart';
import '../ui/widgets.dart';
import '../ui/premio.dart';

/// "Dobrar com vídeo" at most this many times a day, so watching every
/// video doesn't double the whole star economy.
const dobrarPorDia = 10;

/// A level, the daily challenge or an endless run. The play area stays
/// clean: a slim HUD on top, the board and the tray. No banners; cards only
/// appear before or after an attempt.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.services,
    required this.mode,
    this.onDone,
    this.replayLevel,
    this.duelSeed,
    this.duelTargetScore,
    this.duelRivalName,
  });
  final AppServices services;
  final GameMode mode;
  final int? duelSeed;
  final int? duelTargetScore;
  final String? duelRivalName;

  /// An earlier level, played again for its missing stars.
  final int? replayLevel;

  /// Set while onboarding (the tutorial, then the first levels with no
  /// menu): called when this stage is over. There is no way back to a menu
  /// in the meantime.
  final VoidCallback? onDone;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller = GameController(
    store: widget.services.store,
    feedback: widget.services.feedback,
    mode: widget.mode,
    replayLevel: widget.replayLevel,
    duelSeed: widget.duelSeed,
    duelTargetScore: widget.duelTargetScore,
    duelRivalName: widget.duelRivalName,
  );
  PuzzleGame? game;
  bool _busy = false;

  /// The tutorial's top bar holds Capi and his speech bubble.
  double get hudHeight => widget.mode == GameMode.tutorial ? 132 : 104;

  bool get _onboarding => widget.onDone != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    game ??= PuzzleGame(
      controller: controller,
      topInset: MediaQuery.paddingOf(context).top + hudHeight,
      bottomInset: MediaQuery.paddingOf(context).bottom,
    );
  }

  /// The level's three star challenges, shown for a moment when it starts
  /// (and again on a tap on the stars at the top).
  bool _desafios = false;
  Timer? _desafiosTimer;
  GameSession? _desafiosDe;

  bool get _comDesafios => widget.mode == GameMode.levels && !_onboarding;

  void _aoMudar() {
    if (!_comDesafios || !controller.playing) return;
    if (identical(_desafiosDe, controller.session)) return;
    _desafiosDe = controller.session;
    // After the level's title has played ("Fase 12 / Quebre as pedras").
    _desafiosTimer?.cancel();
    _desafiosTimer = Timer(const Duration(milliseconds: 2400), _verDesafios);
  }

  void _verDesafios() {
    if (!mounted) return;
    _desafiosTimer?.cancel();
    setState(() => _desafios = true);
    _desafiosTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _desafios = false);
    });
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_aoMudar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _aoMudar());
    widget.services.feedback.musica.entrarNoJogo(
      controller.isBlitz ? Trilha.blitz : Trilha.fases,
    );
    if (kTestBridge) {
      TestBridge.instance
        ..screen = 'game'
        ..controller = controller
        ..praises.clear();
    }
  }

  @override
  void dispose() {
    widget.services.feedback.musica.sairDoJogo();
    _desafiosTimer?.cancel();
    controller.removeListener(_aoMudar);
    if (kTestBridge && TestBridge.instance.controller == controller) {
      TestBridge.instance
        ..screen = 'home'
        ..controller = null;
    }
    controller.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  /// Whether this win's stars were already doubled with a video.
  bool _dobrado = false;

  Future<void> _dobrarEstrelas() => _guard(() async {
    final ganhas = controller.starsGained;
    if (_dobrado || ganhas <= 0) return;
    final ok = await widget.services.ads.rewarded(
      context,
      RewardPlacement.doubleStars,
    );
    if (!ok || !mounted) return;
    await widget.services.store.addVideoToday('dobrar', DateTime.now());
    await widget.services.store.addStars(ganhas);
    widget.services.feedback.praise(3);
    if (mounted) {
      mostrarPremio(
        context,
        tr('+{n} ★ pelo vídeo!', {'n': ganhas}),
        icon: Icons.star_rounded,
      );
    }
    setState(() => _dobrado = true);
  });

  Future<void> _next() => _guard(() async {
    _dobrado = false;
    widget.services.feedback.click();
    await widget.services.ads.betweenLevels(context, controller.level.number);
    if (_onboarding && controller.level.number >= Onboarding.railLevels) {
      // The first levels are done: on to the menu.
      await widget.services.store.markSeen('menu');
      Analytics.event('tutorial_complete');
      widget.onDone!();
      return;
    }
    controller.restart();
  });

  Future<void> _revive() => _guard(() async {
    final ok = await widget.services.ads.rewarded(
      context,
      RewardPlacement.revive,
    );
    if (!ok) return;
    controller.revive();
    widget.services.feedback.praise(2);
    if (mounted) {
      mostrarPremio(
        context,
        tr('Segunda chance liberada!'),
        icon: Icons.favorite_rounded,
      );
    }
  });

  /// Stuck after the free hint: Capi offers a paid hint, or the tools.
  Widget _hintOffer() {
    final show =
        controller.hintOffer &&
        controller.playing &&
        !controller.showOutcome &&
        controller.activeToolMode == null;
    if (!show) return const SizedBox.shrink();
    return Positioned(
      left: 8,
      right: 8,
      bottom: MediaQuery.paddingOf(context).bottom + 4,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: CapiSays(
            text: tr('Travou? Eu te mostro uma jogada.'),
            mood: CapiMood.point,
            capiSize: 70,
            action: tr('Ver dica'),
            onAction: _dicaPaga,
            secondary: tr('Usar ferramenta'),
            onSecondary: _openToolsSheet,
          ),
        ),
      ),
    );
  }

  Future<void> _dicaPaga() => _guard(() async {
    widget.services.feedback.click();
    final pago = await pagarDica(
      context,
      widget.services,
      RewardPlacement.gameHint,
      motivo: tr('A dica grátis desta fase já foi.'),
    );
    if (pago == null || !mounted) return;
    Analytics.event('fase_dica', {
      'level': controller.level.number,
      'pagamento': pago,
    });
    controller.showPaidHint();
  });

  /// The level's star challenges, for a moment at the start: they never
  /// block a touch.
  Widget _desafiosCard() {
    final show =
        _desafios &&
        controller.playing &&
        !controller.showOutcome &&
        controller.intros.isEmpty;
    final n = controller.level.number;
    final bits = controller.liveStarBits;
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + hudHeight + 6,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: !show
              ? const SizedBox.shrink()
              : Center(
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label: tr('Desafios da fase: {lista}', {
                      'lista': [
                        for (final m in Mission.values) Missions.text(m, n),
                      ].join(', '),
                    }),
                    excludeSemantics: true,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        decoration: BoxDecoration(
                          color: Palette.panel.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Palette.accent, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x66000000), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr('3 estrelas nesta fase'),
                              style: displayText(17, color: Palette.accent),
                            ),
                            const SizedBox(height: 4),
                            for (final m in Mission.values)
                              _MissionLine(
                                text: Missions.text(m, n),
                                done: Missions.has(bits, m),
                                star: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _openToolsSheet() {
    widget.services.feedback.click();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ToolsSheet(
        controller: controller,
        store: widget.services.store,
        onUseTool: (tool) {
          Navigator.of(context).pop();
          controller.selectTool(tool);
        },
        videoRewards: widget.services.ads.hasVideoAds,
        onRewardTool: (tool) async {
          final ok = await widget.services.ads.rewarded(
            context,
            RewardPlacement.forTool(tool),
          );
          if (ok) {
            await widget.services.store.addTool(tool, 1);
            widget.services.feedback.praise(2);
            if (mounted) {
              mostrarPremio(
                this.context,
                tr('+1 {ferramenta} pelo vídeo!', {'ferramenta': tool.label}),
                icon: Icons.handyman_rounded,
              );
              setState(() {});
            }
          }
        },
        onBuyTool: (tool) async {
          final ok = await widget.services.store.buyToolWithStars(tool);
          if (ok) {
            widget.services.feedback.click();
            if (mounted) setState(() {});
          } else {
            widget.services.feedback.lose();
          }
        },
      ),
    );
  }

  Widget _buildToolModeOverlay() {
    final mode = controller.activeToolMode;
    final g = game;
    if (mode == null || !controller.playing || g == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        if ((mode == CapiTool.hammer || mode == CapiTool.shovel) &&
            g.boardRect != Rect.zero)
          Positioned.fromRect(
            rect: g.boardRect,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Board.size,
              ),
              itemCount: Board.size * Board.size,
              itemBuilder: (context, idx) {
                final r = idx ~/ Board.size;
                final c = idx % Board.size;
                final cell = controller.session.board.at(r, c);
                final canTarget = mode == CapiTool.hammer
                    ? cell.isFilled
                    : true;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (mode == CapiTool.hammer) {
                      controller.executeHammer(r, c);
                    } else if (mode == CapiTool.shovel) {
                      controller.executeShovel(r, c);
                    }
                  },
                  child: Semantics(
                    button: true,
                    label: mode == CapiTool.hammer
                        ? tr('Quebrar célula {r} {c}', {'r': r, 'c': c})
                        : tr('Limpar área 3x3 {r} {c}', {'r': r, 'c': c}),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: canTarget
                              ? (mode == CapiTool.hammer
                                    ? const Color(0x66FFD95A)
                                    : const Color(0x66339AF0))
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (mode == CapiTool.rotate)
          for (var i = 0; i < 3; i++)
            if (i < g.trays.length)
              Positioned(
                left: g.trays[i].position.x,
                top: g.trays[i].position.y,
                width: g.trays[i].size.x,
                height: g.trays[i].size.y,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.executeRotate(i),
                  child: Semantics(
                    button: true,
                    label: tr('Girar peça {n}', {'n': i}),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + hudHeight + 4,
          left: 14,
          right: 14,
          child: _ActiveToolBanner(
            tool: mode,
            onCancel: controller.cancelToolMode,
          ),
        ),
      ],
    );
  }

  void _retry() {
    _dobrado = false;
    widget.services.feedback.click();
    controller.restart();
  }

  void _exit() {
    widget.services.feedback.click();
    Navigator.of(context).pop();
  }

  /// On the phone: the share sheet (WhatsApp & co.). On the web: copies
  /// the link.
  Future<void> _shareDuelLink(int score) async {
    widget.services.feedback.click();
    final convite = DueloConvite(
      semente:
          controller.level.seed ??
          (DateTime.now().millisecondsSinceEpoch % 1000000),
      meta: score,
      blitz: controller.isBlitz,
    );
    Analytics.event('duel_share', {'mode': controller.mode.name});
    if (!kIsWeb) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: convite.mensagem,
            subject: tr('Desafio no CapiBlocks'),
          ),
        );
        return;
      } catch (_) {
        // No share sheet: copy instead.
      }
    }
    await Clipboard.setData(ClipboardData(text: convite.mensagem));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Desafio copiado! Cole no WhatsApp para um amigo.')),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// The end of a duel: against a friend's score when it came from a
  /// challenge link, else the score just set, ready to send.
  Widget _duelCard(int score) {
    if (!controller.isChallenge) {
      return _DuelMarkCard(
        score: score,
        onShareDuel: () => _shareDuelLink(score),
        onRetry: _retry,
        onExit: _exit,
      );
    }
    return _DuelOutcomeCard(
      won: controller.duelWon,
      score: score,
      rivalScore: controller.duelTargetScore ?? 1000,
      rivalName: controller.duelRivalName ?? tr('Rival'),
      starsGained: controller.starsGained,
      onRetry: _retry,
      onExit: _exit,
      onShareDuel: () => _shareDuelLink(score),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGradient,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(game: game!),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _buildToolModeOverlay(),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: SizedBox(
                  height: hudHeight,
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => controller.tutorial
                        ? _TutorialBar(
                            controller: controller,
                            onSkip: controller.skipTutorial,
                          )
                        : _Hud(
                            controller: controller,
                            onPause: () => controller.setPaused(true),
                            onTools: _openToolsSheet,
                            onDesafios: _comDesafios ? _verDesafios : null,
                          ),
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _CapiPopUp(controller: controller),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _hintOffer(),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _desafiosCard(),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _overlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlay() {
    Widget? card;
    final s = controller.session;
    if (controller.tutorialFinished) {
      card = Padding(
        key: const ValueKey('tutorial-done'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: CapiSays(
            text: controller.capiLine,
            mood: CapiMood.cheer,
            capiSize: 110,
            action: tr('Bora!'),
            onAction: widget.onDone,
          ),
        ),
      );
    } else if (controller.intros.isNotEmpty) {
      card = _IntroCard(
        key: ValueKey(controller.intros.first),
        intro: controller.intros.first,
        onOk: () {
          widget.services.feedback.click();
          controller.dismissIntro();
        },
      );
    } else if (controller.paused) {
      card = _PauseCard(
        level: controller.mode == GameMode.levels
            ? controller.level.number
            : null,
        starBits: controller.previousStarBits,
        onResume: () => controller.setPaused(false),
        onRestart: () {
          controller.setPaused(false);
          _retry();
        },
        onExit: _onboarding ? null : _exit,
      );
    } else if (controller.showOutcome && s.status == SessionStatus.won) {
      if (controller.isChallenge || controller.isDuel) {
        card = _duelCard(s.score);
      } else if (controller.isBlitz) {
        card = _BlitzWinCard(
          score: s.score,
          best: controller.bestScore,
          newBest: controller.newBest,
          starsGained: controller.starsGained,
          onRetry: _retry,
          onExit: _exit,
          onShareDuel: () => _shareDuelLink(s.score),
        );
      } else {
        card = controller.level.isDaily
            ? _DailyWinCard(
                score: s.score,
                starsGained: controller.starsGained,
                streak: widget.services.store.dailyStreak(controller.today),
                onExit: _exit,
              )
            : _WinCard(
                level: controller.level.number,
                score: s.score,
                starBits: controller.starBits | controller.previousStarBits,
                newBits: controller.starBits & ~controller.previousStarBits,
                starsGained: controller.starsGained,
                dobrado: _dobrado,
                onDobrar:
                    widget.services.ads.hasVideoAds &&
                        controller.starsGained > 0 &&
                        widget.services.store.videosToday(
                              'dobrar',
                              DateTime.now(),
                            ) <
                            dobrarPorDia
                    ? _dobrarEstrelas
                    : null,
                replay: controller.isReplay,
                onNext: _next,
                onRetry: _retry,
                onExit: _onboarding ? null : _exit,
              );
      }
    } else if (controller.showOutcome && s.status == SessionStatus.lost) {
      if (controller.isChallenge || controller.isDuel) {
        card = _duelCard(s.score);
      } else if (controller.isBlitz) {
        card = _BlitzWinCard(
          score: s.score,
          best: controller.bestScore,
          newBest: controller.newBest,
          starsGained: controller.starsGained,
          onRetry: _retry,
          onExit: _exit,
          onShareDuel: () => _shareDuelLink(s.score),
        );
      } else {
        card = _LoseCard(
          endless: controller.endless,
          starsGained: controller.endless ? controller.starsGained : 0,
          score: s.score,
          best: controller.bestScore,
          newBest: controller.newBest,
          canRevive: controller.canRevive,
          videoRevive: widget.services.ads.hasVideoAds,
          onRevive: _revive,
          onRetry: _retry,
          onExit: _onboarding ? null : _exit,
        );
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(
            begin: 0.85,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      child: card == null
          ? const SizedBox.shrink()
          : Container(
              key: card.key ?? ValueKey(card.runtimeType),
              color: const Color(0x99080A20),
              alignment: Alignment.center,
              child: card,
            ),
    );
  }
}

/// The tutorial's top bar: Capi talking, and a way to skip.
/// Capi pops up from the bottom corner for a moment: cheering big moves,
/// worried when the board fills up, pointing at a hint when the player is
/// stuck. Never blocks touches.
class _CapiPopUp extends StatelessWidget {
  const _CapiPopUp({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final reaction = controller.capiReaction;
    // A hint is shown on the board by Capi carrying the piece.
    final visible =
        reaction != null &&
        reaction != CapiReaction.hint &&
        !controller.showOutcome &&
        !controller.paused &&
        controller.intros.isEmpty;
    final mood = switch (reaction) {
      CapiReaction.cheer => CapiMood.cheer,
      CapiReaction.worried => CapiMood.worried,
      _ => CapiMood.point,
    };
    return Positioned(
      left: 8,
      right: 8,
      bottom: MediaQuery.paddingOf(context).bottom + 4,
      child: IgnorePointer(
        // Faded out as well as slid down: on phones with a tall bottom bar
        // (iPhone), the slide alone left the top of his helmet showing.
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: visible ? 120 : 380),
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 1.3),
            duration: const Duration(milliseconds: 380),
            curve: visible ? Curves.easeOutBack : Curves.easeIn,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: CapiSays(
                  key: ValueKey(controller.capiSeq),
                  text: controller.capiSays,
                  mood: mood,
                  capiSize: 70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialBar extends StatelessWidget {
  const _TutorialBar({required this.controller, required this.onSkip});
  final GameController controller;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final finished = controller.tutorialFinished;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        children: [
          SizedBox(
            height: 22,
            child: finished
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      label: tr('Pular tutorial'),
                      excludeSemantics: true,
                      onTap: onSkip,
                      child: GestureDetector(
                        onTap: onSkip,
                        child: Text(
                          tr('Pular'),
                          style: displayText(16, color: Palette.textDim),
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              // The closing line shows in the middle of the screen.
              child: finished
                  ? null
                  : CapiSays(
                      text: controller.capiLine,
                      mood: controller.capiCheer
                          ? CapiMood.cheer
                          : CapiMood.happy,
                      capiSize: 84,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.controller,
    required this.onPause,
    required this.onTools,
    this.onDesafios,
  });
  final GameController controller;
  final VoidCallback onPause;
  final VoidCallback onTools;

  /// Levels mode: the three star challenges sit by the goals.
  final VoidCallback? onDesafios;

  @override
  Widget build(BuildContext context) {
    final s = controller.session;
    final level = controller.level;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        children: [
          Row(
            children: [
              RoundIconButton(
                icon: Icons.pause_rounded,
                label: tr('Pausar'),
                onTap: onPause,
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          levelTitle(level),
                          style: displayText(17, color: Palette.textDim),
                        ),
                        if (level.isHard) ...[
                          const SizedBox(width: 8),
                          _Tag(tr('DIFÍCIL'), Palette.danger),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _AnimatedScore(score: s.score),
                        if (level.isEndless || controller.isBlitz) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Palette.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            formatInt(controller.bestScore),
                            style: displayText(15, color: Palette.textDim),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: Icons.construction_rounded,
                label: tr('Ferramentas'),
                onTap: onTools,
              ),
            ],
          ),
          if (controller.isBlitz) ...[
            const SizedBox(height: 4),
            _BlitzTimerChip(secondsLeft: controller.blitzSecondsLeft),
          ],
          if (controller.isChallenge) ...[
            const SizedBox(height: 4),
            _DuelTargetChip(
              score: s.score,
              target: controller.duelTargetScore ?? 1000,
              rivalName: controller.duelRivalName ?? tr('Rival'),
              won: controller.duelWon,
            ),
          ] else if (controller.isDuel) ...[
            const SizedBox(height: 4),
            const _DuelHowChip(),
          ] else if (!level.isEndless && !controller.isBlitz) ...[
            const SizedBox(height: 6),
            _Goals(
              session: s,
              stars: onDesafios == null
                  ? null
                  : _StarStrip(
                      bits: controller.liveStarBits,
                      onTap: onDesafios!,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveToolBanner extends StatelessWidget {
  const _ActiveToolBanner({required this.tool, required this.onCancel});
  final CapiTool tool;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xF0181F42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.accent, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ToolIcon(tool: tool, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${tool.label}: ${tool.actionPrompt}',
              style: displayText(14, color: Palette.accent),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: tr('Cancelar'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tr('Cancelar'),
                  style: displayText(13, color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolsSheet extends StatefulWidget {
  const _ToolsSheet({
    required this.controller,
    required this.store,
    required this.onUseTool,
    required this.onRewardTool,
    required this.onBuyTool,
    this.videoRewards = true,
  });
  final GameController controller;

  /// Offer a free tool for a video (only when real video ads exist).
  final bool videoRewards;
  final ProgressStore store;
  final void Function(CapiTool tool) onUseTool;
  final void Function(CapiTool tool) onRewardTool;
  final void Function(CapiTool tool) onBuyTool;

  @override
  State<_ToolsSheet> createState() => _ToolsSheetState();
}

class _ToolsSheetState extends State<_ToolsSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141938),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x44FFFFFF), width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const ToolboxIcon(size: 32),
                const SizedBox(width: 10),
                Text(
                  tr('Ferramentas do Capi'),
                  style: displayText(20, color: Palette.text),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFD95A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x66FFD95A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Palette.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.store.stars}',
                        style: displayText(16, color: Palette.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: tr('Fechar'),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Palette.textDim,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final tool in CapiTool.values) ...[
              _buildToolCard(tool),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(CapiTool tool) {
    final count = widget.store.toolCount(tool);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2548),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        children: [
          ToolIcon(tool: tool, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tool.label,
                      style: displayText(16, color: Palette.text),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: count > 0
                            ? const Color(0x33FFD95A)
                            : const Color(0x22FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x$count',
                        style: displayText(
                          13,
                          color: count > 0 ? Palette.accent : Palette.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tool.description,
                  style: bodyText(12, color: Palette.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (count > 0)
            Semantics(
              button: true,
              label: tr('Usar {ferramenta}', {'ferramenta': tool.label}),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.accent,
                  foregroundColor: const Color(0xFF3A2414),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => widget.onUseTool(tool),
                child: Text(tr('USAR'), style: displayText(14)),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.videoRewards) ...[
                  Semantics(
                    button: true,
                    label: tr('Ganhar {ferramenta} com anúncio', {
                      'ferramenta': tool.label,
                    }),
                    child: InkWell(
                      onTap: () async {
                        widget.onRewardTool(tool);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x3322B8CF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x6622B8CF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF22B8CF),
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              tr('Grátis'),
                              style: const TextStyle(
                                color: Color(0xFF22B8CF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Semantics(
                  button: true,
                  label: tr('Comprar {ferramenta}', {'ferramenta': tool.label}),
                  child: InkWell(
                    onTap: () async {
                      widget.onBuyTool(tool);
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFD95A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x66FFD95A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Palette.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${tool.starCost}',
                            style: const TextStyle(
                              color: Palette.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: displayText(12, color: Colors.white)),
  );
}

class _AnimatedScore extends StatelessWidget {
  const _AnimatedScore({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: score.toDouble()),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => Text(
      formatInt(v.round()),
      style: displayText(38, shadows: textDrop).copyWith(height: 1.05),
    ),
  );
}

class _Goals extends StatelessWidget {
  const _Goals({required this.session, this.stars});
  final GameSession session;
  final Widget? stars;

  @override
  Widget build(BuildContext context) {
    final level = session.level;
    final chips = <Widget>[
      if (level.targetScore > 0)
        _GoalChip(
          icon: const Icon(Icons.star_rounded, color: Palette.accent, size: 20),
          progress: session.score / level.targetScore,
          label: formatInt(level.targetScore),
        ),
      if (level.hasRockGoal)
        _GoalChip(
          icon: const MiniGlyph(MiniIcon.rock, size: 18),
          progress: session.rocksBroken / session.rocksAtStart,
          label: '${session.rocksLeft}',
        ),
      if (level.hasPupGoal)
        _GoalChip(
          icon: const MiniGlyph(MiniIcon.pup, size: 20),
          progress: 1 - session.pupsLeft / level.pupCount,
          label: '${level.pupCount - session.pupsLeft}/${level.pupCount}',
        ),
      if (level.gemsTarget > 0)
        _GoalChip(
          icon: const MiniGlyph(MiniIcon.gem, size: 18),
          progress: session.gems / level.gemsTarget,
          label:
              '${session.gems.clamp(0, level.gemsTarget)}/${level.gemsTarget}',
        ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in chips)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c),
        if (stars case final st?)
          Padding(padding: const EdgeInsets.only(left: 6), child: st),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.icon,
    required this.progress,
    required this.label,
  });
  final Widget icon;
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final done = progress >= 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: Palette.panel.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 400),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: Palette.emptyCell,
                  color: done ? Palette.good : Palette.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          done
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Palette.good,
                  size: 18,
                )
              : Text(label, style: displayText(15)),
        ],
      ),
    );
  }
}

TextStyle get _bodyStyle => bodyText(16, color: Palette.textDim, weight: 500);

class _IntroCard extends StatelessWidget {
  const _IntroCard({super.key, required this.intro, required this.onOk});
  final Intro intro;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final (Widget icon, String title, String text) = switch (intro) {
      Intro.rocks => (
        const MiniGlyph(MiniIcon.rock, size: 56),
        tr('Pedras'),
        tr(
          'Complete a linha ou a coluna de uma pedra para quebrá-la. '
          'Quebre todas para vencer a fase.',
        ),
      ),
      Intro.toughRocks => (
        const MiniGlyph(MiniIcon.toughRock, size: 56),
        tr('Pedras reforçadas'),
        tr(
          'As pedras com rebites precisam de duas limpezas: '
          'a primeira só racha.',
        ),
      ),
      Intro.gems => (
        const MiniGlyph(MiniIcon.gem, size: 56),
        tr('Gemas'),
        tr(
          'Algumas peças trazem gemas. Limpe a linha onde elas estão '
          'para coletar.',
        ),
      ),
      Intro.pups => (
        const MiniGlyph(MiniIcon.pup, size: 60),
        tr('Filhotes!'),
        tr(
          'Uns filhotes de capivara ficaram presos nos blocos! Limpe a linha '
          'ou a coluna de cada um para soltar. Eles vão morar na vila.',
        ),
      ),
      Intro.doubleGoal => (
        const Icon(Icons.flag_rounded, color: Palette.accent, size: 56),
        tr('Duas metas'),
        tr(
          'Agora algumas fases pedem duas coisas ao mesmo tempo. '
          'Fique de olho nas metas no topo da tela.',
        ),
      ),
    };
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('NOVIDADE!'), style: displayText(16, color: Palette.accent)),
          const SizedBox(height: 12),
          icon,
          const SizedBox(height: 12),
          OutlinedTitle(title, size: 30),
          const SizedBox(height: 10),
          Text(text, style: _bodyStyle, textAlign: TextAlign.center),
          const SizedBox(height: 22),
          ChunkyButton(label: tr('Entendi!'), big: true, onTap: onOk),
        ],
      ),
    );
  }
}

class _WinCard extends StatelessWidget {
  const _WinCard({
    required this.level,
    required this.score,
    required this.starBits,
    required this.newBits,
    required this.starsGained,
    required this.replay,
    required this.onNext,
    required this.onRetry,
    required this.onExit,
    this.dobrado = false,
    this.onDobrar,
  });
  final int level;

  /// Watch a video to get this win's stars again (once per win).
  final bool dobrado;
  final VoidCallback? onDobrar;
  final int score;

  /// Missions done on this level so far, and the ones this win added.
  final int starBits;
  final int newBits;
  final int starsGained;

  /// An earlier level played again: no "next level" from here.
  final bool replay;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  /// Back to the menu (not while the first levels are on rails).
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => CardPanel(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Capi(size: 84, mood: CapiMood.cheer),
        OutlinedTitle(tr('Fase {n} concluída!', {'n': level}), size: 30),
        const SizedBox(height: 10),
        StarRow(
          filled: [for (var i = 0; i < 3; i++) i < Missions.count(starBits)],
          animate: true,
        ),
        const SizedBox(height: 10),
        for (final m in Mission.values)
          _MissionLine(
            text: Missions.text(m, level),
            done: Missions.has(starBits, m),
            isNew: Missions.has(newBits, m),
          ),
        const SizedBox(height: 6),
        Text(
          starsGained > 0
              ? trN(
                  starsGained,
                  '+{n} estrela · {pontos} pontos',
                  '+{n} estrelas · {pontos} pontos',
                  {'pontos': formatInt(score)},
                )
              : tr('{pontos} pontos', {'pontos': formatInt(score)}),
          style: _bodyStyle,
        ),
        if (onDobrar != null) ...[
          const SizedBox(height: 10),
          if (dobrado)
            Text(
              tr('Estrelas dobradas: +{n}!', {'n': starsGained}),
              style: displayText(16, color: Palette.accent),
            )
          else
            ChunkyButton(
              label: tr('Dobrar: +{n} com vídeo', {'n': starsGained}),
              icon: Icons.smart_display_rounded,
              color: Palette.good,
              textColor: const Color(0xFF0B3D1A),
              onTap: onDobrar,
            ),
        ],
        const SizedBox(height: 18),
        if (replay) ...[
          ChunkyButton(
            label: tr('Jogar de novo'),
            icon: Icons.refresh_rounded,
            big: true,
            onTap: onRetry,
          ),
          TextButton(
            onPressed: onExit,
            child: Text(
              tr('Menu'),
              style: displayText(18, color: Palette.textDim),
            ),
          ),
        ] else ...[
          ChunkyButton(
            label: tr('Próxima fase'),
            icon: Icons.arrow_forward_rounded,
            big: true,
            onTap: onNext,
          ),
          if (onExit != null)
            TextButton(
              onPressed: onExit,
              child: Text(
                tr('Menu'),
                style: displayText(18, color: Palette.textDim),
              ),
            ),
        ],
      ],
    ),
  );
}

/// One of the level's three missions, ticked when done.
class _MissionLine extends StatelessWidget {
  const _MissionLine({
    required this.text,
    required this.done,
    this.isNew = false,
    this.star = false,
  });
  final String text;
  final bool done;
  final bool isNew;

  /// Shows a star instead of a check (before the challenge is won).
  final bool star;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(
          star
              ? (done ? Icons.star_rounded : Icons.star_outline_rounded)
              : done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked,
          size: 20,
          color: done
              ? (star ? Palette.accent : Palette.good)
              : Palette.textDim,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: bodyText(
              15,
              color: done ? Palette.text : Palette.textDim,
              weight: 500,
            ),
          ),
        ),
        if (isNew) _Tag(tr('NOVA'), Palette.accentDeep),
      ],
    ),
  );
}

class _DailyWinCard extends StatelessWidget {
  const _DailyWinCard({
    required this.score,
    required this.starsGained,
    required this.streak,
    required this.onExit,
  });
  final int score;
  final int starsGained;
  final int streak;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => CardPanel(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          color: Palette.accentDeep,
          size: 72,
        ),
        OutlinedTitle(tr('Desafio do dia\nconcluído!'), size: 32),
        const SizedBox(height: 8),
        Text(
          streak > 1
              ? tr('{n} dias seguidos!', {'n': streak})
              : tr('Volte amanhã para outro!'),
          style: displayText(20, color: Palette.accent),
        ),
        const SizedBox(height: 4),
        if (starsGained > 0) ...[
          StarRow(filled: const [true, true, true], size: 34, animate: true),
          const SizedBox(height: 4),
          Text(
            tr('+{n} estrelas · {pontos} pontos', {
              'n': starsGained,
              'pontos': formatInt(score),
            }),
            style: _bodyStyle,
          ),
        ] else
          Text(
            tr('{pontos} pontos', {'pontos': formatInt(score)}),
            style: _bodyStyle,
          ),
        const SizedBox(height: 24),
        ChunkyButton(
          label: tr('Voltar ao menu'),
          icon: Icons.home_rounded,
          big: true,
          onTap: onExit,
        ),
      ],
    ),
  );
}

class _LoseCard extends StatelessWidget {
  const _LoseCard({
    required this.endless,
    required this.starsGained,
    required this.score,
    required this.best,
    required this.newBest,
    required this.canRevive,
    required this.onRevive,
    required this.onRetry,
    required this.onExit,
    this.videoRevive = true,
  });

  final bool endless;

  /// The second chance costs a short video (false: it is simply offered).
  final bool videoRevive;

  /// Endless only: stars this run earned (one per 2,500 points).
  final int starsGained;
  final int score;
  final int best;
  final bool newBest;
  final bool canRevive;
  final VoidCallback onRevive;
  final VoidCallback onRetry;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => CardPanel(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Capi(size: 84, mood: newBest ? CapiMood.cheer : CapiMood.sad),
        OutlinedTitle(
          newBest ? tr('Novo recorde!') : tr('Sem espaço!'),
          size: 36,
          colors: newBest
              ? const [Color(0xFFFFFFFF), Color(0xFFFFD43B)]
              : const [Color(0xFFFFFFFF), Color(0xFFFFB3B3)],
        ),
        const SizedBox(height: 8),
        if (starsGained > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Palette.accent, size: 24),
                const SizedBox(width: 4),
                Text(
                  '+$starsGained',
                  style: displayText(20, color: Palette.accent),
                ),
              ],
            ),
          ),
        Text(
          endless
              ? tr('{pontos} pontos · recorde {recorde}', {
                  'pontos': formatInt(score),
                  'recorde': formatInt(best),
                })
              : tr('Quase lá! Quer mais uma chance?'),
          style: _bodyStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (canRevive) ...[
          ChunkyButton(
            label: tr('Continuar'),
            icon: videoRevive
                ? Icons.smart_display_rounded
                : Icons.play_arrow_rounded,
            color: Palette.good,
            textColor: const Color(0xFF0B3B16),
            big: true,
            onTap: onRevive,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 14),
            child: Text(
              videoRevive
                  ? tr('Assista a um vídeo curto')
                  : tr('Uma chance extra por partida'),
              style: bodyText(13, color: Palette.textDim, weight: 500),
            ),
          ),
        ],
        ChunkyButton(
          label: tr('Jogar de novo'),
          icon: Icons.refresh_rounded,
          color: canRevive ? Palette.panelEdge : Palette.accent,
          textColor: canRevive ? Palette.text : const Color(0xFF3A2200),
          onTap: onRetry,
        ),
        if (onExit != null)
          TextButton(
            onPressed: onExit,
            child: Text(
              tr('Menu'),
              style: displayText(18, color: Palette.textDim),
            ),
          ),
      ],
    ),
  );
}

class _PauseCard extends StatelessWidget {
  const _PauseCard({
    required this.level,
    required this.starBits,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  /// Levels mode: the level, whose missions are listed.
  final int? level;
  final int starBits;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => CardPanel(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedTitle(tr('Pausa'), size: 38),
        if (level case final n?) ...[
          const SizedBox(height: 12),
          Text(
            tr('Desafios da fase'),
            style: displayText(17, color: Palette.accent),
          ),
          const SizedBox(height: 4),
          for (final m in Mission.values)
            _MissionLine(
              text: Missions.text(m, n),
              done: Missions.has(starBits, m),
            ),
        ],
        const SizedBox(height: 24),
        ChunkyButton(
          label: tr('Continuar'),
          icon: Icons.play_arrow_rounded,
          big: true,
          onTap: onResume,
        ),
        const SizedBox(height: 12),
        ChunkyButton(
          label: tr('Reiniciar'),
          icon: Icons.refresh_rounded,
          color: Palette.panelEdge,
          textColor: Palette.text,
          onTap: onRestart,
        ),
        if (onExit != null)
          TextButton(
            onPressed: onExit,
            child: Text(
              tr('Menu'),
              style: displayText(18, color: Palette.textDim),
            ),
          ),
      ],
    ),
  );
}

class _BlitzTimerChip extends StatelessWidget {
  const _BlitzTimerChip({required this.secondsLeft});
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? const Color(0x55FA5252) : const Color(0x442A3356),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent ? const Color(0xFFFA5252) : const Color(0x66FFD43B),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BlitzIcon(size: 20),
          const SizedBox(width: 8),
          Text(
            '${secondsLeft}s',
            style: displayText(
              16,
              color: urgent ? const Color(0xFFFF8787) : Palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _DuelTargetChip extends StatelessWidget {
  const _DuelTargetChip({
    required this.score,
    required this.target,
    required this.rivalName,
    required this.won,
  });
  final int score;
  final int target;
  final String rivalName;
  final bool won;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: won ? const Color(0x4451CF66) : const Color(0x442A3356),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: won ? const Color(0xFF51CF66) : const Color(0x66339AF0),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuelIcon(size: 20),
          const SizedBox(width: 8),
          Text(
            won
                ? tr('SUPEROU {rival}!', {'rival': rivalName.toUpperCase()})
                : tr('Meta do {rival}: {meta}', {
                    'rival': rivalName,
                    'meta': formatInt(target),
                  }),
            style: displayText(
              14,
              color: won ? const Color(0xFF8CE99A) : Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${formatInt(score)}/${formatInt(target)})',
            style: displayText(12, color: Palette.textDim),
          ),
        ],
      ),
    );
  }
}

class _BlitzWinCard extends StatelessWidget {
  const _BlitzWinCard({
    required this.score,
    required this.best,
    required this.newBest,
    required this.starsGained,
    required this.onRetry,
    required this.onExit,
    required this.onShareDuel,
  });

  final int score;
  final int best;
  final bool newBest;
  final int starsGained;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final VoidCallback onShareDuel;

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BlitzIcon(size: 72),
          const SizedBox(height: 8),
          OutlinedTitle(
            newBest ? tr('Novo Recorde Blitz!') : tr('Fim do Blitz!'),
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            tr('{pontos} pontos', {'pontos': formatInt(score)}),
            style: displayText(26, color: Palette.accent),
          ),
          if (newBest) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x33FFD95A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Palette.accent),
              ),
              child: Text(
                tr('MELHOR PLACAR BLITZ!'),
                style: displayText(12, color: Palette.accent),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              tr('Recorde: {pontos} pontos', {'pontos': formatInt(best)}),
              style: bodyText(14, color: Palette.textDim),
            ),
          ],
          if (starsGained > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Palette.accent, size: 22),
                const SizedBox(width: 4),
                Text(
                  tr('+{n} estrelas', {'n': starsGained}),
                  style: displayText(16, color: Palette.accent),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ChunkyButton(
            label: tr('Jogar de novo'),
            icon: Icons.refresh_rounded,
            big: true,
            onTap: onRetry,
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            label: tr('Desafiar Amigo'),
            icon: Icons.share_rounded,
            color: const Color(0xFF339AF0),
            textColor: Colors.white,
            onTap: onShareDuel,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onExit,
            child: Text(
              tr('Menu'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

/// Under the score in a duel started from the menu: there is no one to beat
/// yet, so it says what the match is for.
class _DuelHowChip extends StatelessWidget {
  const _DuelHowChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0x442A3356),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x66339AF0), width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DuelIcon(size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            tr('Faça sua marca e desafie um amigo no fim'),
            style: displayText(13, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

/// The end of a duel started from the menu: the score just set, and the
/// button that sends this board to a friend.
class _DuelMarkCard extends StatelessWidget {
  const _DuelMarkCard({
    required this.score,
    required this.onShareDuel,
    required this.onRetry,
    required this.onExit,
  });

  final int score;
  final VoidCallback onShareDuel;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuelIcon(size: 72),
          const SizedBox(height: 8),
          OutlinedTitle(tr('Sua marca'), size: 30),
          const SizedBox(height: 4),
          Text(
            tr('{pontos} pontos', {'pontos': formatInt(score)}),
            style: displayText(26, color: Palette.accent),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Mande este tabuleiro para um amigo: ele joga as mesmas peças '
              'e tenta passar você.',
            ),
            style: bodyText(15, color: Palette.textDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ChunkyButton(
            label: tr('Desafiar Amigo'),
            icon: Icons.share_rounded,
            big: true,
            color: const Color(0xFF339AF0),
            textColor: Colors.white,
            onTap: onShareDuel,
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            label: tr('Jogar de novo'),
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onExit,
            child: Text(
              tr('Menu'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

/// The end of a friend's challenge: both scores side by side, who won, and
/// the way back at them (send the challenge back, or a rematch on the same
/// board).
class _DuelOutcomeCard extends StatelessWidget {
  const _DuelOutcomeCard({
    required this.won,
    required this.score,
    required this.rivalScore,
    required this.rivalName,
    required this.starsGained,
    required this.onRetry,
    required this.onExit,
    required this.onShareDuel,
  });

  final bool won;
  final int score;
  final int rivalScore;
  final String rivalName;
  final int starsGained;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final VoidCallback onShareDuel;

  Widget _placar(String quem, int pontos, bool vencedor) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: vencedor ? const Color(0x3351CF66) : const Color(0x332A3356),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: vencedor ? const Color(0xFF51CF66) : const Color(0x55FFFFFF),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            quem,
            style: bodyText(13, color: Palette.textDim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            formatInt(pontos),
            style: displayText(
              22,
              color: vencedor ? const Color(0xFF8CE99A) : Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuelIcon(size: 64),
          const SizedBox(height: 8),
          OutlinedTitle(
            won ? tr('Você venceu!') : tr('Quase!'),
            size: 30,
            colors: won
                ? const [Color(0xFFFFFFFF), Color(0xFFFFD43B)]
                : const [Color(0xFFFFFFFF), Color(0xFFFFB3B3)],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _placar(tr('Você'), score, won),
              const SizedBox(width: 8),
              Text('×', style: displayText(20, color: Palette.textDim)),
              const SizedBox(width: 8),
              _placar(rivalName, rivalScore, !won),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            won
                ? tr(
                    'Devolva o desafio: agora é a vez de {rival} passar você.',
                    {'rival': rivalName},
                  )
                : tr(
                    'Faltaram {n} pontos. Mesmo tabuleiro, mais uma tentativa?',
                    {'n': formatInt(rivalScore - score)},
                  ),
            style: bodyText(15, color: Palette.textDim),
            textAlign: TextAlign.center,
          ),
          if (won && starsGained > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Palette.accent, size: 24),
                const SizedBox(width: 4),
                Text(
                  tr('+{n} estrelas', {'n': starsGained}),
                  style: displayText(18, color: Palette.accent),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (won) ...[
            ChunkyButton(
              label: tr('Devolver o Desafio'),
              icon: Icons.share_rounded,
              big: true,
              color: const Color(0xFF339AF0),
              textColor: Colors.white,
              onTap: onShareDuel,
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              label: tr('Jogar de novo'),
              icon: Icons.refresh_rounded,
              onTap: onRetry,
            ),
          ] else ...[
            ChunkyButton(
              label: tr('Revanche'),
              icon: Icons.refresh_rounded,
              big: true,
              onTap: onRetry,
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              label: tr('Desafiar Amigo'),
              icon: Icons.share_rounded,
              color: const Color(0xFF339AF0),
              textColor: Colors.white,
              onTap: onShareDuel,
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: onExit,
            child: Text(
              tr('Menu'),
              style: displayText(16, color: Palette.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

/// The level's three stars at the top: lit as each challenge is met (the
/// "no second chance" one stays lit until the second chance is used). A tap
/// shows what each one asks.
class _StarStrip extends StatelessWidget {
  const _StarStrip({required this.bits, required this.onTap});
  final int bits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tr('Estrelas da fase: {n} de {total}, ver os desafios', {
      'n': Missions.count(bits),
      'total': Mission.values.length,
    }),
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x442A3356),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x66FFD43B), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in Mission.values)
              Icon(
                Missions.has(bits, m)
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 20,
                color: Missions.has(bits, m) ? Palette.accent : Palette.textDim,
              ),
          ],
        ),
      ),
    ),
  );
}
