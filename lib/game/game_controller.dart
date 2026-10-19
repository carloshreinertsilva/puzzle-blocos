import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/board.dart';
import '../core/game_session.dart';
import '../core/level.dart';
import '../services/feedback.dart';
import '../services/progress_store.dart';

/// Connects the rules ([GameSession]) to the scene and the Flutter screens.
class GameController extends ChangeNotifier {
  GameController({
    required this.store,
    required this.feedback,
    required this.endless,
  }) {
    _start();
  }

  final ProgressStore store;
  final GameFeedback feedback;
  final bool endless;

  late GameSession session;

  /// True once the end-of-level card should show (after effects play out).
  bool showOutcome = false;
  bool paused = false;
  int bestScore = 0;
  bool newBest = false;

  /// Scene hooks, set by the game.
  void Function(PlaceResult result, Piece piece)? onPlaced;
  void Function(List<ClearedCell> cleared)? onRevived;
  VoidCallback? onRestarted;

  Timer? _outcomeTimer;

  LevelConfig get level => session.level;
  bool get playing => session.status == SessionStatus.playing && !paused;

  void _start() {
    final config = endless
        ? LevelConfig.endless()
        : LevelGenerator.build(store.level);
    session = GameSession(
      config,
      failStreak: endless ? 0 : store.failStreakFor(config.number),
    );
    bestScore = store.bestScore;
    newBest = false;
    showOutcome = false;
    paused = false;
  }

  void place(int slot, int r, int c) {
    if (!playing || !session.canPlace(slot, r, c)) return;
    final piece = session.tray[slot]!;
    final result = session.place(slot, r, c);

    if (result.outcome.lines > 0) {
      feedback.clear(result.combo, result.outcome.lines);
    } else {
      feedback.place();
    }
    onPlaced?.call(result, piece);

    if (session.status != SessionStatus.playing) _finish();
    notifyListeners();
  }

  void _finish() {
    final won = session.status == SessionStatus.won;
    if (won) {
      store.setLevel(level.number + 1);
      store.setFailStreak(level.number, 0);
    } else if (endless) {
      if (session.score > store.bestScore) {
        newBest = true;
        bestScore = session.score;
        store.setBestScore(session.score);
      }
    } else {
      store.setFailStreak(level.number, store.failStreakFor(level.number) + 1);
    }
    _outcomeTimer?.cancel();
    _outcomeTimer = Timer(Duration(milliseconds: won ? 900 : 700), () {
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
    if (!endless) {
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
