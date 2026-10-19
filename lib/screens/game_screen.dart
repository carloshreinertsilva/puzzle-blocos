import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../core/game_session.dart';
import '../game/game_controller.dart';
import '../game/puzzle_game.dart';
import '../main.dart';
import '../ui/palette.dart';
import '../ui/widgets.dart';

/// A level or an endless run. The play area stays clean: a slim HUD on top,
/// the board and the tray. No banners; cards only appear between attempts.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.services, required this.endless});
  final AppServices services;
  final bool endless;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller = GameController(
    store: widget.services.store,
    feedback: widget.services.feedback,
    endless: widget.endless,
  );
  PuzzleGame? game;
  bool _busy = false;

  static const hudHeight = 104.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    game ??= PuzzleGame(
      controller: controller,
      topInset: MediaQuery.paddingOf(context).top + hudHeight,
    );
  }

  @override
  void dispose() {
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
                    builder: (context, _) => _Hud(
                      controller: controller,
                      onPause: () => controller.setPaused(true),
                    ),
                  ),
                ),
              ),
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
    if (controller.paused) {
      card = _PauseCard(
        onResume: () => controller.setPaused(false),
        onRestart: () {
          controller.setPaused(false);
          _retry();
        },
        onExit: _exit,
      );
    } else if (controller.showOutcome && s.status == SessionStatus.won) {
      card = _WinCard(
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
        onExit: _exit,
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
              key: ValueKey(card.runtimeType),
              color: const Color(0x99080A20),
              alignment: Alignment.center,
              child: card,
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
              RoundIconButton(icon: Icons.pause_rounded, onTap: onPause),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          level.isEndless
                              ? 'Modo infinito'
                              : 'Fase ${level.number}',
                          style: const TextStyle(
                            color: Palette.textDim,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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
                              style: const TextStyle(
                                color: Palette.textDim,
                                fontWeight: FontWeight.w700,
                              ),
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
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
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
      style: const TextStyle(
        color: Palette.text,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
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
          Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c),
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
            width: 58,
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
              : Text(
                  label,
                  style: const TextStyle(
                    color: Palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ],
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: Palette.text,
  fontSize: 28,
  fontWeight: FontWeight.w900,
);
const _bodyStyle = TextStyle(color: Palette.textDim, fontSize: 16);

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
        const Icon(Icons.emoji_events_rounded, color: Palette.accent, size: 64),
        const SizedBox(height: 8),
        Text(
          'Fase $level concluída!',
          style: _titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
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
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => CardPanel(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(newBest ? 'Novo recorde!' : 'Sem espaço!', style: _titleStyle),
        const SizedBox(height: 6),
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
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 14),
            child: Text(
              'Assista a um vídeo curto',
              style: TextStyle(color: Palette.textDim, fontSize: 13),
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
        TextButton(
          onPressed: onExit,
          child: const Text(
            'Menu',
            style: TextStyle(color: Palette.textDim, fontSize: 16),
          ),
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
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => CardPanel(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Pausa', style: _titleStyle),
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
        TextButton(
          onPressed: onExit,
          child: const Text(
            'Menu',
            style: TextStyle(color: Palette.textDim, fontSize: 16),
          ),
        ),
      ],
    ),
  );
}
