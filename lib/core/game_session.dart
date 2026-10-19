import 'dart:math';

import 'board.dart';
import 'level.dart';
import 'piece_generator.dart';

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
  int _movesSinceClear = 0;
  bool revived = false;
  SessionStatus status = SessionStatus.playing;

  static const comboGrace = 3;
  static const boardClearBonus = 1500;

  int get rocksLeft => board.rockCount;
  int get rocksBroken => rocksAtStart - rocksLeft;

  bool get goalsMet {
    if (level.isEndless) return false;
    if (level.targetScore > 0 && score < level.targetScore) return false;
    if (level.gemsTarget > 0 && gems < level.gemsTarget) return false;
    if (level.hasRockGoal && rocksLeft > 0) return false;
    return true;
  }

  double get difficultyNow {
    if (level.isEndless) {
      return 0.12 + 0.75 * (1 - exp(-score / 7000));
    }
    return (level.difficulty - 0.07 * min(failStreak, 4)).clamp(0.0, 1.0);
  }

  double get _mercy => min(failStreak, 4) * 0.12;

  bool canPlace(int slot, int r, int c) {
    final piece = tray[slot];
    return piece != null && board.canPlace(piece.shape, r, c);
  }

  PlaceResult place(int slot, int r, int c) {
    assert(status == SessionStatus.playing);
    final piece = tray[slot]!;
    final outcome = board.place(piece, r, c);
    tray[slot] = null;

    final lines = outcome.lines;
    if (lines > 0) {
      combo++;
      _movesSinceClear = 0;
    } else if (++_movesSinceClear >= comboGrace) {
      combo = 0;
    }

    var points = piece.shape.size * 5;
    if (lines > 0) points += 50 * lines * (lines + 1) * max(1, combo);
    final boardCleared = lines > 0 && board.isEmpty;
    if (boardCleared) points += boardClearBonus;
    score += points;
    gems += outcome.gems;

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
