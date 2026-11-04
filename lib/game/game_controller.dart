import '../core/daily_missions.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/board.dart';
import '../core/game_session.dart';
import '../core/hint.dart';
import '../core/level.dart';
import '../core/missions.dart';
import '../core/shapes.dart';
import '../l10n/idioma.dart';
import '../services/analytics.dart';
import '../services/feedback.dart';
import '../services/progress_store.dart';
import 'tutorial.dart';

enum GameMode { levels, endless, daily, tutorial, blitz, duel }

/// Mechanics explained with a short card the first time they show up.
enum Intro { rocks, toughRocks, gems, pups, doubleGoal }

/// How Capi reacts during a game (a short pop-up beside the tray).
enum CapiReaction { cheer, worried, hint }

/// Connects the rules ([GameSession]) to the scene and the Flutter screens.
class GameController extends ChangeNotifier {
  GameController({
    required this.store,
    required this.feedback,
    required this.mode,
    this.replayLevel,
    this.duelSeed,
    this.duelTargetScore,
    this.duelRivalName,
    DateTime? today,
  }) : today = today ?? DateTime.now() {
    _start();
  }

  final ProgressStore store;
  final GameFeedback feedback;
  final GameMode mode;
  final DateTime today;

  /// Levels mode: an earlier level played again for its missing stars (the
  /// progress does not move on).
  final int? replayLevel;
  final int? duelSeed;
  final int? duelTargetScore;
  final String? duelRivalName;
  bool duelWon = false;

  /// Blitz mode: remaining time in seconds.
  int blitzSecondsLeft = 60;
  Timer? _blitzTimer;

  /// After a win: the missions this attempt completed, what the level had
  /// before, and the stars added to the wallet (levels, daily and endless).
  int starBits = 0;

  /// The level's star challenges as they stand right now: the big move once
  /// done, "no second chance" until it is used, the win once won.
  int get liveStarBits {
    final s = session;
    final bits = Missions.earned(
      level: level.number,
      bestLines: s.bestLines,
      bestCombo: s.bestCombo,
      revived: s.revived,
    );
    return s.status == SessionStatus.won
        ? bits
        : bits & ~Missions.bit(Mission.win);
  }

  int previousStarBits = 0;
  int starsGained = 0;
  int _endlessStarsGiven = 0;

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

  /// Active tool targeting mode (Hammer, Shovel, Rotate).
  CapiTool? activeToolMode;

  /// Scene hooks for tools.
  void Function(CapiTool tool, List<ClearedCell> cleared)? onToolUsed;
  void Function(int slot)? onPieceRotated;
  VoidCallback? onTrayRerolled;

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

  /// Outside the tutorial: Capi's pop-up (reaction and line), bumped by
  /// [capiSeq] so the same reaction twice still shows twice.
  CapiReaction? capiReaction;
  String capiSays = '';
  int capiSeq = 0;
  Timer? _capiTimer;

  /// After this long without a move, Capi suggests one.
  static const idleHintAfter = Duration(seconds: 10);
  Timer? _idleTimer;
  (int, int, int)? _idleHint;

  /// Hints Capi gives on his own in each game; after those, when the player
  /// is stuck he offers a paid hint (or the tools) instead.
  static const freeIdleHints = 1;
  int idleHints = 0;

  /// Capi is offering a paid hint (shown until the player moves).
  bool hintOffer = false;
  bool _warned = false;
  final _rng = Random();

  bool get endless => mode == GameMode.endless;
  bool get isBlitz => mode == GameMode.blitz;
  bool get isDuel => mode == GameMode.duel;

  /// Opened from a friend's challenge link (it has someone to beat).
  bool get isChallenge => duelRivalName != null;

  /// Stars a quick minigame can pay per day (see addStarsCapped).
  static const minigameStarsPerDay = 6;
  static const challengeStars = 3;
  bool get isReplay =>
      mode == GameMode.levels &&
      replayLevel != null &&
      replayLevel! < store.level;
  bool get tutorial => mode == GameMode.tutorial;
  bool get tutorialFinished =>
      tutorial && tutorialStep >= Tutorial.steps.length;
  LevelConfig get level => session.level;
  bool get playing =>
      session.status == SessionStatus.playing &&
      (!isBlitz || blitzSecondsLeft > 0) &&
      !paused &&
      intros.isEmpty &&
      !_tutorialWaiting &&
      !tutorialFinished;

  /// Where the hint hand points: (tray slot, row, col), or null. In the
  /// tutorial it is the step's move; otherwise Capi's suggestion when the
  /// player has been still for a while.
  (int, int, int)? get hint {
    if (!playing) return null;
    if (!tutorial) return _idleHint;
    final step = Tutorial.steps[tutorialStep];
    return (1, step.target.$1, step.target.$2);
  }

  void _react(CapiReaction reaction, String line) {
    capiReaction = reaction;
    capiSays = line;
    capiSeq++;
    _capiTimer?.cancel();
    _capiTimer = Timer(const Duration(milliseconds: 2600), () {
      capiReaction = null;
      notifyListeners();
    });
    notifyListeners();
  }

  /// The player touched a piece (or just moved): drop any hint and start
  /// the idle clock again.
  void noteActivity() {
    _idleTimer?.cancel();
    if (_idleHint != null || hintOffer) {
      _idleHint = null;
      hintOffer = false;
      if (capiReaction == CapiReaction.hint) capiReaction = null;
      notifyListeners();
    }
    if (tutorial || session.status != SessionStatus.playing) return;
    _idleTimer = Timer(idleHintAfter, () {
      if (!playing) return noteActivity();
      final move = suggestMove(session.board, session.tray);
      if (move == null) return;
      if (idleHints >= freeIdleHints) {
        hintOffer = true;
        notifyListeners();
        return;
      }
      _showHint(move);
    });
  }

  void _showHint((int, int, int) move) {
    idleHints++;
    hintOffer = false;
    _idleHint = move;
    _react(
      CapiReaction.hint,
      _pick([
        tr('Que tal aqui?'),
        tr('Psiu! Tenta aqui.'),
        tr('Olha esse cantinho!'),
      ]),
    );
  }

  /// The paid hint was paid: Capi shows a move. False when there is none.
  bool showPaidHint() {
    if (!playing) return false;
    final move = suggestMove(session.board, session.tray);
    if (move == null) return false;
    _idleTimer?.cancel();
    _showHint(move);
    return true;
  }

  String _pick(List<String> lines) => lines[_rng.nextInt(lines.length)];

  void _start() {
    final config = switch (mode) {
      GameMode.endless || GameMode.tutorial => LevelConfig.endless(),
      // Every Blitz has a seed, so its "challenge a friend" link replays
      // the same start.
      GameMode.blitz => LevelConfig.blitz(
        seed: duelSeed ?? _rng.nextInt(1000000),
      ),
      GameMode.duel => LevelConfig.duel(
        seed: duelSeed ?? 12345,
        targetScore: duelTargetScore ?? 1000,
        rivalName: duelRivalName ?? tr('Rival'),
      ),
      GameMode.daily => LevelGenerator.daily(today),
      GameMode.levels => LevelGenerator.build(replayLevel ?? store.level),
    };
    session = GameSession(
      config,
      rng: config.seed != null ? Random(config.seed!) : null,
      failStreak: mode == GameMode.levels
          ? store.failStreakFor(config.number)
          : 0,
    );
    bestScore = mode == GameMode.blitz ? store.blitzBestScore : store.bestScore;
    Analytics.event('level_start', {'mode': mode.name, 'level': config.number});
    blitzSecondsLeft = 60;
    _blitzTimer?.cancel();
    if (mode == GameMode.blitz) {
      _startBlitzTimer();
    }
    duelWon = false;
    newBest = false;
    showOutcome = false;
    paused = false;
    _counted = false;
    starBits = 0;
    starsGained = 0;
    _endlessStarsGiven = 0;
    previousStarBits = mode == GameMode.levels
        ? store.levelStars(config.number)
        : 0;
    intros
      ..clear()
      ..addAll(_introsFor(config));
    _warned = false;
    capiReaction = null;
    idleHints = 0;
    hintOffer = false;
    _idleHint = null;
    if (tutorial) _loadTutorialStep(0);
    noteActivity();
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

  /// Capi cheers big moves and gets worried once when the board fills up.
  void _reactTo(PlaceResult result) {
    final lines = result.outcome.lines;
    if (lines >= 2 || (lines > 0 && result.combo >= 3)) {
      _react(
        CapiReaction.cheer,
        _pick([
          tr('Uhul!'),
          tr('Mandou bem!'),
          tr('Que construção!'),
          tr('Isso aí!'),
        ]),
      );
    } else if (!_warned &&
        session.board.filledCount >= Board.size * Board.size * 0.6) {
      _warned = true;
      _react(CapiReaction.worried, tr('Eita, tá enchendo! Limpa uma linha.'));
    }
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
    if (c.hasPupGoal && !store.hasSeen(Intro.pups.name)) Intro.pups,
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
      pups: out.pups,
    );
    if (out.lines > 0) {
      DailyMissionsManager.reportEvent(
        store,
        DailyMissionType.clearLines,
        out.lines,
      );
    }
    if (result.combo >= 2) {
      DailyMissionsManager.reportEvent(store, DailyMissionType.makeCombos, 1);
    }
    onPlaced?.call(result, piece);

    if (isBlitz && out.lines > 0) {
      final bonus = out.lines >= 2 ? 3 : (result.combo >= 2 ? 2 : 1);
      blitzSecondsLeft = min(75, blitzSecondsLeft + bonus);
    }
    if (isChallenge && !duelWon && session.score >= (duelTargetScore ?? 1000)) {
      duelWon = true;
      _react(CapiReaction.cheer, tr('Passou o rival!'));
    }

    if (tutorial) {
      _afterTutorialMove(result);
    } else if (session.status != SessionStatus.playing) {
      _finish();
    } else {
      _reactTo(result);
    }
    noteActivity();
    notifyListeners();
  }

  void _finish() {
    final won = session.status == SessionStatus.won;
    Analytics.event('level_end', {
      'mode': mode.name,
      'level': level.number,
      'success': won ? 1 : 0,
      'score': session.score,
      'revived': session.revived ? 1 : 0,
    });
    if (!_counted) {
      _counted = true;
      store.recordGame(levelWon: won);
    }
    switch (mode) {
      case GameMode.levels when won:
        if (!isReplay) store.setLevel(level.number + 1);
        store.setFailStreak(level.number, 0);
        _awardLevelStars();
        DailyMissionsManager.reportEvent(store, DailyMissionType.playLevels, 1);
      case GameMode.levels:
        store.setFailStreak(
          level.number,
          store.failStreakFor(level.number) + 1,
        );
      case GameMode.daily when won:
        if (!store.dailyDone(today)) {
          starsGained = Missions.daily;
          store.addStars(starsGained);
        }
        store.completeDaily(today);
      case GameMode.blitz:
        _blitzTimer?.cancel();
        DailyMissionsManager.reportEvent(store, DailyMissionType.playBlitz, 1);
        _payChallenge();
        // One star per 1,500 points, up to 3 a run and a few a day.
        final dueBlitz = min(3, session.score ~/ 1500);
        store
            .addStarsCapped('blitz', dueBlitz, minigameStarsPerDay, today)
            .then((n) {
              starsGained += n;
              if (!_disposed) notifyListeners();
            });
        if (session.score > store.blitzBestScore) {
          newBest = true;
          bestScore = session.score;
          store.recordBlitzScore(session.score);
        }
      case GameMode.duel:
        _payChallenge();
      case GameMode.daily || GameMode.tutorial:
        break;
      case GameMode.endless:
        DailyMissionsManager.reportEvent(
          store,
          DailyMissionType.playEndless,
          session.score,
        );
        // A revived run pays only the stars its extra points add.
        final due = Missions.forEndless(session.score);
        starsGained = due - _endlessStarsGiven;
        _endlessStarsGiven = due;
        store.addStars(starsGained);
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

  void _awardLevelStars() {
    starBits = Missions.earned(
      level: level.number,
      bestLines: session.bestLines,
      bestCombo: session.bestCombo,
      revived: session.revived,
    );
    final all = previousStarBits | starBits;
    starsGained = Missions.count(all) - Missions.count(previousStarBits);
    store.setLevelStars(level.number, all);
    store.addStars(starsGained);
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
    Analytics.event('revive', {'mode': mode.name, 'level': level.number});
    showOutcome = false;
    noteActivity();
    onRevived?.call(cleared);
    if (session.status != SessionStatus.playing) _finish();
    notifyListeners();
  }

  // --- Capi Tools (Step 2) ---

  void cancelToolMode() {
    activeToolMode = null;
    notifyListeners();
  }

  Future<bool> selectTool(CapiTool tool) async {
    if (!playing || store.toolCount(tool) <= 0) return false;
    Analytics.event('tool_use', {'tool': tool.name});
    if (tool == CapiTool.reroll) {
      final ok = await store.useTool(CapiTool.reroll);
      if (!ok) return false;
      session.useReroll();
      feedback.pick();
      _react(CapiReaction.cheer, tr('Peças novinhas na mão!'));
      onTrayRerolled?.call();
      noteActivity();
      notifyListeners();
      return true;
    }
    activeToolMode = tool;
    _react(CapiReaction.hint, tool.actionPrompt);
    notifyListeners();
    return true;
  }

  Future<bool> executeHammer(int r, int c) async {
    if (!playing ||
        activeToolMode != CapiTool.hammer ||
        !session.canBreakCell(r, c)) {
      return false;
    }
    final ok = await store.useTool(CapiTool.hammer);
    if (!ok) return false;
    activeToolMode = null;
    final cleared = session.useHammer(r, c);
    if (cleared == null) return false;
    feedback.clear(0, 1);
    _react(CapiReaction.cheer, tr('Quebrou!'));
    onToolUsed?.call(CapiTool.hammer, [cleared]);
    if (session.status != SessionStatus.playing) {
      _finish();
    }
    noteActivity();
    notifyListeners();
    return true;
  }

  Future<bool> executeShovel(int r, int c) async {
    if (!playing || activeToolMode != CapiTool.shovel) return false;
    final ok = await store.useTool(CapiTool.shovel);
    if (!ok) return false;
    activeToolMode = null;
    final cleared = session.useShovel(r, c);
    feedback.clear(1, 2);
    _react(CapiReaction.cheer, tr('Limpou geral!'));
    onToolUsed?.call(CapiTool.shovel, cleared);
    if (session.status != SessionStatus.playing) {
      _finish();
    }
    noteActivity();
    notifyListeners();
    return true;
  }

  Future<bool> executeRotate(int slot) async {
    if (!playing ||
        activeToolMode != CapiTool.rotate ||
        !session.canRotatePiece(slot)) {
      return false;
    }
    final ok = await store.useTool(CapiTool.rotate);
    if (!ok) return false;
    activeToolMode = null;
    final piece = session.useRotate(slot);
    if (piece == null) return false;
    feedback.pick();
    _react(CapiReaction.cheer, tr('Girou!'));
    onPieceRotated?.call(slot);
    if (session.status != SessionStatus.playing) {
      _finish();
    }
    noteActivity();
    notifyListeners();
    return true;
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
    if (isChallenge) {
      final target = duelTargetScore ?? 1000;
      if (session.score < target) {
        session.score = target + 50;
      }
      duelWon = true;
    }
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
            'p' => const Cell.block(0, pup: true),
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

  /// A friend's challenge beaten for the first time pays its stars. Duels
  /// started from the menu have no one to beat: they set the score to send.
  void _payChallenge() {
    if (!isChallenge) return;
    final target = duelTargetScore ?? 1000;
    if (session.score < target) return;
    duelWon = true;
    final seed = level.seed;
    if (!isChallenge || seed == null || store.duelSeedWon(seed)) return;
    store
      ..recordDuelWin()
      ..markDuelSeedWon(seed);
    starsGained += challengeStars;
    store.addStars(challengeStars);
  }

  void _startBlitzTimer() {
    _blitzTimer?.cancel();
    _blitzTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (paused || !playing) return;
      if (blitzSecondsLeft > 0) {
        blitzSecondsLeft--;
        if (blitzSecondsLeft == 10) {
          feedback.click();
          _react(CapiReaction.worried, tr('10 segundos!'));
        } else if (blitzSecondsLeft <= 3 && blitzSecondsLeft > 0) {
          feedback.click();
        } else if (blitzSecondsLeft == 0) {
          timer.cancel();
          _finishBlitz();
        }
        notifyListeners();
      }
    });
  }

  void _finishBlitz() {
    _blitzTimer?.cancel();
    session.status = SessionStatus.won;
    _finish();
    notifyListeners();
  }

  void setPaused(bool v) {
    paused = v;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _outcomeTimer?.cancel();
    _tutorialTimer?.cancel();
    _capiTimer?.cancel();
    _idleTimer?.cancel();
    _blitzTimer?.cancel();
    super.dispose();
  }
}
