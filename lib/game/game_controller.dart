import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/board.dart';
import '../core/game_session.dart';
import '../core/level.dart';
import '../services/feedback.dart';
import '../services/progress_store.dart';

enum GameMode { levels, endless, daily }

/// Mechanics explained with a short card the first time they show up.
enum Intro { rocks, toughRocks, gems, doubleGoal }

/// Connects the rules ([GameSession]) to the scene and the Flutter screens.
class GameController extends ChangeNotifier {
  GameController({
    required this.store,
    required this.feedback,
    required this.mode,
    DateTime? today,
  }) : today = today ?? DateTime.now() {
    _start();
  }

  final ProgressStore store;
  final GameFeedback feedback;
  final GameMode mode;
  final DateTime today;

  late GameSession session;

  /// True once the end-of-level card should show (after effects play out).
  bool showOutcome = false;
  bool paused = false;
  int bestScore = 0;
  bool newBest = false;

  /// Cards still to show before play starts.
  final List<Intro> intros = [];

  /// Scene hooks, set by the game.
  void Function(PlaceResult result, Piece piece)? onPlaced;
  void Function(List<ClearedCell> cleared)? onRevived;
  VoidCallback? onRestarted;

  /// Called when the attempt is ready to play (after any intro cards).
  VoidCallback? onReady;

  Timer? _outcomeTimer;
  bool _counted = false;

  bool get endless => mode == GameMode.endless;
  LevelConfig get level => session.level;
  bool get playing =>
      session.status == SessionStatus.playing && !paused && intros.isEmpty;

  void _start() {
    final config = switch (mode) {
      GameMode.endless => LevelConfig.endless(),
      GameMode.daily => LevelGenerator.daily(today),
      GameMode.levels => LevelGenerator.build(store.level),
    };
    session = GameSession(
      config,
      failStreak: mode == GameMode.levels
          ? store.failStreakFor(config.number)
          : 0,
    );
    bestScore = store.bestScore;
    newBest = false;
    showOutcome = false;
    paused = false;
    _counted = false;
    intros
      ..clear()
      ..addAll(_introsFor(config));
  }

  List<Intro> _introsFor(LevelConfig c) => [
    if (c.hasRockGoal && !store.hasSeen(Intro.rocks.name)) Intro.rocks,
    if (c.hasToughRocks && !store.hasSeen(Intro.toughRocks.name))
      Intro.toughRocks,
    if (c.gemsTarget > 0 && !store.hasSeen(Intro.gems.name)) Intro.gems,
    if (c.goalCount > 1 && !store.hasSeen(Intro.doubleGoal.name))
      Intro.doubleGoal,
  ];

  void dismissIntro() {
    if (intros.isEmpty) return;
    store.markSeen(intros.removeAt(0).name);
    if (intros.isEmpty) onReady?.call();
    notifyListeners();
  }

  void place(int slot, int r, int c) {
    if (!playing || !session.canPlace(slot, r, c)) return;
    final piece = session.tray[slot]!;
    final result = session.place(slot, r, c);

    final out = result.outcome;
    if (out.lines > 0) {
      feedback.clear(result.combo, out.lines);
    } else {
      feedback.place();
    }
    store.recordMove(
      lines: out.lines,
      combo: result.combo,
      gems: out.gems,
      rocks: out.rocksBroken,
    );
    onPlaced?.call(result, piece);

    if (session.status != SessionStatus.playing) _finish();
    notifyListeners();
  }

  void _finish() {
    final won = session.status == SessionStatus.won;
    if (!_counted) {
      _counted = true;
      store.recordGame(levelWon: won);
    }
    switch (mode) {
      case GameMode.levels when won:
        store.setLevel(level.number + 1);
        store.setFailStreak(level.number, 0);
      case GameMode.levels:
        store.setFailStreak(
          level.number,
          store.failStreakFor(level.number) + 1,
        );
      case GameMode.daily when won:
        store.completeDaily(today);
      case GameMode.daily:
        break;
      case GameMode.endless:
        if (session.score > store.bestScore) {
          newBest = true;
          bestScore = session.score;
          store.setBestScore(session.score);
        }
    }
    _outcomeTimer?.cancel();
    _outcomeTimer = Timer(Duration(milliseconds: won ? 1300 : 700), () {
      won ? feedback.win() : feedback.lose();
      showOutcome = true;
      notifyListeners();
    });
  }

  bool get canRevive =>
      session.status == SessionStatus.lost && !session.revived;

  void revive() {
    if (!canRevive) return;
    final cleared = session.revive();
    if (mode == GameMode.levels) {
      // The loss did not stick, so undo its effect on the next attempt.
      store.setFailStreak(
        level.number,
        (store.failStreakFor(level.number) - 1).clamp(0, 99),
      );
    }
    feedback.revive();
    showOutcome = false;
    onRevived?.call(cleared);
    if (session.status != SessionStatus.playing) _finish();
    notifyListeners();
  }

  /// Retry this level, or move on to the next one after a win.
  void restart() {
    _outcomeTimer?.cancel();
    _start();
    onRestarted?.call();
    if (intros.isEmpty) onReady?.call();
    notifyListeners();
  }

  void setPaused(bool v) {
    paused = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _outcomeTimer?.cancel();
    super.dispose();
  }
}
