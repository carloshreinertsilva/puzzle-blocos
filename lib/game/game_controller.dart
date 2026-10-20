import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/board.dart';
import '../core/game_session.dart';
import '../core/level.dart';
import '../core/shapes.dart';
import '../services/feedback.dart';
import '../services/progress_store.dart';
import 'tutorial.dart';

enum GameMode { levels, endless, daily, tutorial }

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

  /// Tutorial only: the current step (== steps.length once finished), what
  /// Capi says, and whether a step change is on its way.
  int tutorialStep = 0;
  String capiLine = '';
  bool capiCheer = false;
  bool _tutorialWaiting = false;
  Timer? _tutorialTimer;

  bool get endless => mode == GameMode.endless;
  bool get tutorial => mode == GameMode.tutorial;
  bool get tutorialFinished =>
      tutorial && tutorialStep >= Tutorial.steps.length;
  LevelConfig get level => session.level;
  bool get playing =>
      session.status == SessionStatus.playing &&
      !paused &&
      intros.isEmpty &&
      !_tutorialWaiting &&
      !tutorialFinished;

  /// Where the hint hand points: (tray slot, row, col), or null.
  (int, int, int)? get tutorialHint {
    if (!tutorial || !playing) return null;
    final step = Tutorial.steps[tutorialStep];
    return (1, step.target.$1, step.target.$2);
  }

  void _start() {
    final config = switch (mode) {
      GameMode.endless || GameMode.tutorial => LevelConfig.endless(),
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
    if (tutorial) _loadTutorialStep(0);
  }

  void _loadTutorialStep(int index, {String? say}) {
    tutorialStep = index;
    _tutorialWaiting = false;
    capiCheer = tutorialFinished;
    if (tutorialFinished) {
      capiLine = Tutorial.done;
      store.markSeen('tutorial');
      for (var r = 0; r < Board.size; r++) {
        for (var c = 0; c < Board.size; c++) {
          session.board.set(r, c, const Cell.empty());
        }
      }
      session.tray = [null, null, null];
      onRestarted?.call();
      return;
    }
    final step = Tutorial.steps[index];
    capiLine = say ?? step.say;
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        final ch = step.board[r][c];
        session.board.set(
          r,
          c,
          ch == '.' ? const Cell.empty() : Cell.block(int.parse(ch)),
        );
      }
    }
    final shape = allShapes.firstWhere((s) => s.id == step.piece);
    session.tray = [null, Piece(shape), null];
    session.refreshStatus();
    onRestarted?.call();
  }

  void _afterTutorialMove(PlaceResult result) {
    final step = Tutorial.steps[tutorialStep];
    final ok = result.outcome.lines >= step.needLines;
    _tutorialWaiting = true;
    capiCheer = ok;
    _tutorialTimer?.cancel();
    _tutorialTimer = Timer(Duration(milliseconds: ok ? 1100 : 700), () {
      ok
          ? _loadTutorialStep(tutorialStep + 1)
          : _loadTutorialStep(tutorialStep, say: Tutorial.retry);
      notifyListeners();
    });
  }

  /// Ends the tutorial right away (the "Pular" button).
  void skipTutorial() {
    if (!tutorial) return;
    _tutorialTimer?.cancel();
    _loadTutorialStep(Tutorial.steps.length);
    notifyListeners();
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
    // The tutorial deals its own pieces, step by step.
    if (tutorial) session.tray = [null, null, null];

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

    if (tutorial) {
      _afterTutorialMove(result);
    } else if (session.status != SessionStatus.playing) {
      _finish();
    }
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
      case GameMode.daily || GameMode.tutorial:
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

  /// Test scenarios only: wins the attempt as if the goals were met.
  void debugWin() {
    if (tutorial || session.status != SessionStatus.playing) return;
    session.status = SessionStatus.won;
    _finish();
    notifyListeners();
  }

  /// Test scenarios only: replaces the board and/or the tray, then checks
  /// for a win or loss as if a move had just been made.
  void debugLoad({List<String>? board, List<Shape?>? tray}) {
    if (board != null) {
      for (var r = 0; r < Board.size; r++) {
        for (var c = 0; c < Board.size; c++) {
          session.board.set(r, c, switch (board[r][c]) {
            'b' => const Cell.block(0),
            'g' => const Cell.block(0, gem: true),
            'r' => const Cell.rock(1),
            'R' => const Cell.rock(2),
            _ => const Cell.empty(),
          });
        }
      }
    }
    if (tray != null) {
      session.tray = [for (final s in tray) s == null ? null : Piece(s)];
    }
    session.refreshStatus();
    if (session.status != SessionStatus.playing) _finish();
    notifyListeners();
  }

  void setPaused(bool v) {
    paused = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _outcomeTimer?.cancel();
    _tutorialTimer?.cancel();
    super.dispose();
  }
}
