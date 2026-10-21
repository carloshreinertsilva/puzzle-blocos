import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../core/game_session.dart';
import '../game/game_controller.dart';
import '../game/onboarding.dart';
import '../game/puzzle_game.dart';
import '../main.dart';
import '../testing/test_bridge.dart';
import '../ui/level_text.dart';
import '../ui/capi.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// A level, the daily challenge or an endless run. The play area stays
/// clean: a slim HUD on top, the board and the tray. No banners; cards only
/// appear before or after an attempt.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.services,
    required this.mode,
    this.onDone,
  });
  final AppServices services;
  final GameMode mode;

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
    );
  }

  @override
  void initState() {
    super.initState();
    if (kTestBridge) {
      TestBridge.instance
        ..screen = 'game'
        ..controller = controller
        ..praises.clear();
    }
  }

  @override
  void dispose() {
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

  Future<void> _next() => _guard(() async {
    widget.services.feedback.click();
    await widget.services.ads.betweenLevels(context, controller.level.number);
    if (_onboarding && controller.level.number >= Onboarding.railLevels) {
      // The first levels are done: on to the menu.
      await widget.services.store.markSeen('menu');
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
    if (ok) controller.revive();
  });

  void _retry() {
    widget.services.feedback.click();
    controller.restart();
  }

  void _exit() {
    widget.services.feedback.click();
    Navigator.of(context).pop();
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
            action: 'Bora!',
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
        onResume: () => controller.setPaused(false),
        onRestart: () {
          controller.setPaused(false);
          _retry();
        },
        onExit: _onboarding ? null : _exit,
      );
    } else if (controller.showOutcome && s.status == SessionStatus.won) {
      card = controller.level.isDaily
          ? _DailyWinCard(
              score: s.score,
              streak: widget.services.store.dailyStreak(controller.today),
              onExit: _exit,
            )
          : _WinCard(
              level: controller.level.number,
              score: s.score,
              onNext: _next,
            );
    } else if (controller.showOutcome && s.status == SessionStatus.lost) {
      card = _LoseCard(
        endless: controller.endless,
        score: s.score,
        best: controller.bestScore,
        newBest: controller.newBest,
        canRevive: controller.canRevive,
        onRevive: _revive,
        onRetry: _retry,
        onExit: _onboarding ? null : _exit,
      );
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
                      label: 'Pular tutorial',
                      excludeSemantics: true,
                      onTap: onSkip,
                      child: GestureDetector(
                        onTap: onSkip,
                        child: Text(
                          'Pular',
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
  const _Hud({required this.controller, required this.onPause});
  final GameController controller;
  final VoidCallback onPause;

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
                label: 'Pausar',
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
                          const _Tag('DIFÍCIL', Palette.danger),
                        ],
                      ],
                    ),
                    _AnimatedScore(score: s.score),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                child: level.isEndless
                    ? Column(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Palette.accent,
                            size: 20,
                          ),
                          FittedBox(
                            child: Text(
                              formatInt(controller.bestScore),
                              style: displayText(14, color: Palette.textDim),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!level.isEndless) _Goals(session: s),
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
  const _Goals({required this.session});
  final GameSession session;

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
        'Pedras',
        'Complete a linha ou a coluna de uma pedra para quebrá-la. '
            'Quebre todas para vencer a fase.',
      ),
      Intro.toughRocks => (
        const MiniGlyph(MiniIcon.toughRock, size: 56),
        'Pedras reforçadas',
        'As pedras com rebites precisam de duas limpezas: '
            'a primeira só racha.',
      ),
      Intro.gems => (
        const MiniGlyph(MiniIcon.gem, size: 56),
        'Gemas',
        'Algumas peças trazem gemas. Limpe a linha onde elas estão '
            'para coletar.',
      ),
      Intro.doubleGoal => (
        const Icon(Icons.flag_rounded, color: Palette.accent, size: 56),
        'Duas metas',
        'Agora algumas fases pedem duas coisas ao mesmo tempo. '
            'Fique de olho nas metas no topo da tela.',
      ),
    };
    return CardPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('NOVIDADE!', style: displayText(16, color: Palette.accent)),
          const SizedBox(height: 12),
          icon,
          const SizedBox(height: 12),
          OutlinedTitle(title, size: 30),
          const SizedBox(height: 10),
          Text(text, style: _bodyStyle, textAlign: TextAlign.center),
          const SizedBox(height: 22),
          ChunkyButton(label: 'Entendi!', big: true, onTap: onOk),
        ],
      ),
    );
  }
}

class _WinCard extends StatelessWidget {
  const _WinCard({
    required this.level,
    required this.score,
    required this.onNext,
  });
  final int level;
  final int score;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => CardPanel(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Capi(size: 96, mood: CapiMood.cheer),
        const SizedBox(height: 4),
        OutlinedTitle('Fase $level\nconcluída!', size: 34),
        const SizedBox(height: 8),
        Text('${formatInt(score)} pontos', style: _bodyStyle),
        const SizedBox(height: 24),
        ChunkyButton(
          label: 'Próxima fase',
          icon: Icons.arrow_forward_rounded,
          big: true,
          onTap: onNext,
        ),
      ],
    ),
  );
}

class _DailyWinCard extends StatelessWidget {
  const _DailyWinCard({
    required this.score,
    required this.streak,
    required this.onExit,
  });
  final int score;
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
        const OutlinedTitle('Desafio do dia\nconcluído!', size: 32),
        const SizedBox(height: 8),
        Text(
          streak > 1 ? '$streak dias seguidos!' : 'Volte amanhã para outro!',
          style: displayText(20, color: Palette.accent),
        ),
        const SizedBox(height: 4),
        Text('${formatInt(score)} pontos', style: _bodyStyle),
        const SizedBox(height: 24),
        ChunkyButton(
          label: 'Voltar ao menu',
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
    required this.score,
    required this.best,
    required this.newBest,
    required this.canRevive,
    required this.onRevive,
    required this.onRetry,
    required this.onExit,
  });

  final bool endless;
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
          newBest ? 'Novo recorde!' : 'Sem espaço!',
          size: 36,
          colors: newBest
              ? const [Color(0xFFFFFFFF), Color(0xFFFFD43B)]
              : const [Color(0xFFFFFFFF), Color(0xFFFFB3B3)],
        ),
        const SizedBox(height: 8),
        Text(
          endless
              ? '${formatInt(score)} pontos · recorde ${formatInt(best)}'
              : 'Quase lá! Quer mais uma chance?',
          style: _bodyStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (canRevive) ...[
          ChunkyButton(
            label: 'Continuar',
            icon: Icons.smart_display_rounded,
            color: Palette.good,
            textColor: const Color(0xFF0B3B16),
            big: true,
            onTap: onRevive,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 14),
            child: Text(
              'Assista a um vídeo curto',
              style: bodyText(13, color: Palette.textDim, weight: 500),
            ),
          ),
        ],
        ChunkyButton(
          label: 'Jogar de novo',
          icon: Icons.refresh_rounded,
          color: canRevive ? Palette.panelEdge : Palette.accent,
          textColor: canRevive ? Palette.text : const Color(0xFF3A2200),
          onTap: onRetry,
        ),
        if (onExit != null)
          TextButton(
            onPressed: onExit,
            child: Text('Menu', style: displayText(18, color: Palette.textDim)),
          ),
      ],
    ),
  );
}

class _PauseCard extends StatelessWidget {
  const _PauseCard({
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => CardPanel(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const OutlinedTitle('Pausa', size: 38),
        const SizedBox(height: 24),
        ChunkyButton(
          label: 'Continuar',
          icon: Icons.play_arrow_rounded,
          big: true,
          onTap: onResume,
        ),
        const SizedBox(height: 12),
        ChunkyButton(
          label: 'Reiniciar',
          icon: Icons.refresh_rounded,
          color: Palette.panelEdge,
          textColor: Palette.text,
          onTap: onRestart,
        ),
        if (onExit != null)
          TextButton(
            onPressed: onExit,
            child: Text('Menu', style: displayText(18, color: Palette.textDim)),
          ),
      ],
    ),
  );
}
