import 'dart:math';

import 'board.dart';
import 'level.dart';
import 'piece_generator.dart';
import 'shapes.dart';

enum SessionStatus { playing, won, lost }

class PlaceResult {
  PlaceResult({
    required this.outcome,
    required this.points,
    required this.combo,
    required this.boardCleared,
    required this.newTray,
  });

  final PlaceOutcome outcome;
  final int points;

  /// Combo level after this move (0 = no combo running).
  final int combo;
  final bool boardCleared;
  final bool newTray;
}

/// One attempt at a level (or an endless run). Pure game rules, no UI.
class GameSession {
  GameSession(this.level, {Random? rng, this.failStreak = 0})
    : rng = rng ?? Random(),
      board = level.buildBoard() {
    generator = PieceGenerator(this.rng);
    rocksAtStart = board.rockCount;
    _deal(extraMercy: level.isRelief ? 0.15 : 0);
  }

  final LevelConfig level;
  final Random rng;
  final Board board;

  /// Consecutive losses on this level before this attempt; eases the deal.
  final int failStreak;
  late final PieceGenerator generator;
  late final int rocksAtStart;

  late List<Piece?> tray;
  int score = 0;
  int combo = 0;
  int gems = 0;
  int pupsSaved = 0;
  int _movesSinceClear = 0;
  bool revived = false;

  /// Pieces placed in this attempt.
  int moves = 0;

  /// Best single move of this attempt (for the level's missions).
  int bestLines = 0;
  int bestCombo = 0;
  SessionStatus status = SessionStatus.playing;

  static const comboGrace = 3;
  static const boardClearBonus = 1500;

  int get rocksLeft => board.rockCount;
  int get rocksBroken => rocksAtStart - rocksLeft;
  int get pupsLeft => board.pupCount;

  bool get goalsMet {
    // Endless and Blitz have no goal: they end when the pieces (or, in
    // Blitz, the time) run out.
    if (level.isEndless || level.isBlitz) return false;
    if (level.targetScore > 0 && score < level.targetScore) return false;
    if (level.gemsTarget > 0 && gems < level.gemsTarget) return false;
    if (level.hasRockGoal && rocksLeft > 0) return false;
    if (level.hasPupGoal && pupsLeft > 0) return false;
    return true;
  }

  /// How much of the level's goals is done, 0 to 100 (the average of its
  /// goals). Endless and Blitz have no goal: always 0.
  int get goalPercent {
    final partes = <double>[
      if (level.targetScore > 0) score / level.targetScore,
      if (level.gemsTarget > 0) gems / level.gemsTarget,
      if (level.hasRockGoal && rocksAtStart > 0) rocksBroken / rocksAtStart,
      if (level.hasPupGoal && pupsSaved + pupsLeft > 0)
        pupsSaved / (pupsSaved + pupsLeft),
    ];
    if (level.isEndless || level.isBlitz || partes.isEmpty) return 0;
    final soma = partes.fold(0.0, (a, b) => a + b.clamp(0.0, 1.0));
    return (100 * soma / partes.length).floor();
  }

  double get difficultyNow {
    if (level.isEndless) {
      return 0.12 + 0.75 * (1 - exp(-score / 7000));
    }
    // Pieces lag the goal difficulty a little: longer levels need room to
    // breathe. The first levels are a warm-up.
    final warmUp = _isWarmUp ? 0.1 : 0.0;
    return (level.difficulty * 0.75 - warmUp - 0.07 * min(failStreak, 4)).clamp(
      0.0,
      1.0,
    );
  }

  bool get _isWarmUp => level.kind == LevelKind.level && level.number <= 3;

  double get _mercy => min(failStreak, 4) * 0.12 + (_isWarmUp ? 0.25 : 0);

  bool canPlace(int slot, int r, int c) {
    final piece = tray[slot];
    return piece != null && board.canPlace(piece.shape, r, c);
  }

  PlaceResult place(int slot, int r, int c) {
    assert(status == SessionStatus.playing);
    final piece = tray[slot]!;
    final outcome = board.place(piece, r, c);
    tray[slot] = null;
    moves++;

    final lines = outcome.lines;
    if (lines > 0) {
      combo++;
      _movesSinceClear = 0;
    } else if (++_movesSinceClear >= comboGrace) {
      combo = 0;
    }

    bestLines = max(bestLines, lines);
    bestCombo = max(bestCombo, combo);

    var points = piece.shape.size * 5;
    if (lines > 0) points += 50 * lines * (lines + 1) * max(1, combo);
    final boardCleared = lines > 0 && board.isEmpty;
    if (boardCleared) points += boardClearBonus;
    score += points;
    gems += outcome.gems;
    pupsSaved += outcome.pups;

    var newTray = false;
    if (tray.every((p) => p == null)) {
      _deal();
      newTray = true;
    }
    _updateStatus();

    return PlaceResult(
      outcome: outcome,
      points: points,
      combo: combo,
      boardCleared: boardCleared,
      newTray: newTray,
    );
  }

  /// Second chance (after a rewarded ad): clears the three most crowded
  /// rows and deals a gentle tray. Once per attempt.
  List<ClearedCell> revive() {
    assert(status == SessionStatus.lost && !revived);
    revived = true;
    final masks = board.rowMasks;
    final rows = List.generate(Board.size, (r) => r)
      ..sort((a, b) => _bits(masks[b]).compareTo(_bits(masks[a])));
    final cleared = <ClearedCell>[];
    for (final r in rows.take(3)) {
      for (var c = 0; c < Board.size; c++) {
        final before = board.at(r, c);
        if (before.isEmpty) continue;
        final after = before.type == CellType.rock && before.hp > 1
            ? Cell.rock(before.hp - 1)
            : const Cell.empty();
        board.set(r, c, after);
        if (before.pup) pupsSaved++;
        cleared.add(ClearedCell(r, c, before, after));
      }
    }
    combo = 0;
    _movesSinceClear = 0;
    status = SessionStatus.playing;
    _deal(extraMercy: 0.8);
    _updateStatus();
    return cleared;
  }

  // --- Capi Tools (Step 2) ---

  bool canBreakCell(int r, int c) =>
      r >= 0 &&
      r < Board.size &&
      c >= 0 &&
      c < Board.size &&
      board.at(r, c).isFilled;

  ClearedCell? useHammer(int r, int c) {
    if (!canBreakCell(r, c)) return null;
    final cleared = board.breakCell(r, c);
    if (cleared == null) return null;
    if (cleared.before.gem) gems++;
    if (cleared.before.pup) pupsSaved++;
    _updateStatus();
    return cleared;
  }

  List<ClearedCell> useShovel(int centerR, int centerC) {
    final cleared = board.breakArea3x3(centerR, centerC);
    for (final c in cleared) {
      if (c.before.gem) gems++;
      if (c.before.pup) pupsSaved++;
    }
    _updateStatus();
    return cleared;
  }

  bool canRotatePiece(int slot) =>
      slot >= 0 && slot < tray.length && tray[slot] != null;

  Piece? useRotate(int slot) {
    if (!canRotatePiece(slot)) return null;
    final p = tray[slot]!;
    final rotated = rotateShape(p.shape);
    final gemIdx = p.gemCell >= 0
        ? p.gemCell.clamp(0, rotated.cells.length - 1)
        : -1;
    final newPiece = Piece(rotated, color: p.color, gemCell: gemIdx);
    tray[slot] = newPiece;
    _updateStatus();
    return newPiece;
  }

  void useReroll() {
    _deal(extraMercy: 0.25);
    _updateStatus();
  }

  void _deal({double extraMercy = 0}) {
    final gemChance = level.gemsTarget > gems ? level.gemChance : 0.0;
    tray = List<Piece?>.of(
      generator.deal(
        board,
        difficulty: difficultyNow,
        mercy: min(1.0, _mercy + extraMercy),
        gemChance: gemChance,
      ),
    );
  }

  /// Re-evaluates win/loss after the board or tray was changed from outside
  /// (test scenarios).
  void refreshStatus() => _updateStatus();

  void _updateStatus() {
    if (goalsMet) {
      status = SessionStatus.won;
    } else if (!tray.any((p) => p != null && board.fitsAnywhere(p.shape))) {
      status = SessionStatus.lost;
    } else {
      status = SessionStatus.playing;
    }
  }

  static int _bits(int v) {
    var n = 0;
    while (v != 0) {
      n += v & 1;
      v >>= 1;
    }
    return n;
  }
}
