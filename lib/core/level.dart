import 'dart:math';

import 'board.dart';

/// What a level looks like: its goals, its difficulty and the board it
/// starts with. Built deterministically from the level number, so level 37
/// is the same level for every player.
class LevelConfig {
  LevelConfig({
    required this.number,
    required this.difficulty,
    required this.targetScore,
    required this.gemsTarget,
    required this.gemChance,
    required this.initialCells,
    this.isHard = false,
    this.isRelief = false,
  });

  /// Endless mode: no goals; difficulty grows with the score.
  LevelConfig.endless()
    : number = 0,
      difficulty = 0.15,
      targetScore = 0,
      gemsTarget = 0,
      gemChance = 0,
      initialCells = const {},
      isHard = false,
      isRelief = false;

  final int number;
  final double difficulty;
  final int targetScore;
  final int gemsTarget;
  final double gemChance;

  /// Cells filled at the start, keyed by row * 8 + col.
  final Map<int, Cell> initialCells;

  final bool isHard;
  final bool isRelief;

  bool get isEndless => number == 0;
  int get rockCount =>
      initialCells.values.where((c) => c.type == CellType.rock).length;
  bool get hasRockGoal => rockCount > 0;

  Board buildBoard() {
    final board = Board();
    initialCells.forEach((i, cell) {
      board.set(i ~/ Board.size, i % Board.size, cell);
    });
    return board;
  }
}

typedef _Goal = ({bool score, bool rocks, bool gems, int count});

class LevelGenerator {
  /// Difficulty climbs for four levels, peaks on a hard level, then eases
  /// on a relief level ("sawtooth"). The relief is what keeps players going.
  static const _cycle = [0.0, 0.06, 0.12, 0.18, 0.28, -0.05];

  static LevelConfig build(int n) {
    assert(n >= 1);
    final rng = Random(n * 7919 + 17);
    final step = (n - 1) % _cycle.length;
    final isHard = n >= 5 && step == 4;
    final isRelief = n >= 6 && step == 5;

    final global = 1 - exp(-n / 45);
    final d = (0.08 + 0.55 * global + _cycle[step] * min(1.0, n / 12))
        .clamp(0.05, 0.97)
        .toDouble();

    final goal = _goalFor(n);
    // Two goals at once: each one is smaller. Hard levels ask a bit more,
    // relief levels a bit less.
    final share =
        (goal.count > 1 ? 0.6 : 1.0) *
        (isHard
            ? 1.1
            : isRelief
            ? 0.8
            : 1.0);
    final cells = <int, Cell>{};

    var targetScore = 0;
    var gemsTarget = 0;
    var gemChance = 0.0;

    if (goal.score) {
      targetScore = _round50((300 + 70 * n * (0.6 + 0.8 * d)) * share);
    }
    if (goal.rocks) {
      // Rocks sit on a few rows or columns, so each line clear can break
      // several; more lines (and reinforced rocks) as difficulty rises.
      final lines = (1 + 3 * d * share).round().clamp(1, 4);
      final toughShare = ((n - 15) / 80).clamp(0.0, 0.35);
      _rockLines(rng, cells, lines, 2 + (d * 2).round(), toughShare);
    }
    if (goal.gems) {
      gemsTarget = ((4 + 7 * d) * share).round();
      gemChance = 0.28 + 0.1 * (1 - d);
      _scatter(rng, cells, gemsTarget ~/ 2, (_) {
        return Cell.block(rng.nextInt(7), gem: true);
      });
    }
    // Leftover blocks make later boards start crowded.
    if (n > 6) {
      _scatter(rng, cells, (d * 7).round(), (_) => Cell.block(rng.nextInt(7)));
    }

    return LevelConfig(
      number: n,
      difficulty: d,
      targetScore: targetScore,
      gemsTarget: gemsTarget,
      gemChance: gemChance,
      initialCells: cells,
      isHard: isHard,
      isRelief: isRelief,
    );
  }

  static _Goal _goalFor(int n) {
    // The first levels introduce one goal at a time.
    if (n <= 2 || n == 4) {
      return (score: true, rocks: false, gems: false, count: 1);
    }
    if (n == 3) return (score: false, rocks: true, gems: false, count: 1);
    if (n == 5) return (score: false, rocks: false, gems: true, count: 1);
    // Rotate the goal kind so hard and relief levels vary too.
    final kind = (n + (n - 1) ~/ 6) % 3;
    final both = n >= 15 && n % 5 == 0;
    return switch (kind) {
      0 => (score: true, rocks: both, gems: false, count: both ? 2 : 1),
      1 => (score: both, rocks: true, gems: false, count: both ? 2 : 1),
      _ => (score: false, rocks: both, gems: true, count: both ? 2 : 1),
    };
  }

  static void _rockLines(
    Random rng,
    Map<int, Cell> cells,
    int lines,
    int perLine,
    double toughShare,
  ) {
    final rows = rng.nextBool();
    final picked = <int>{};
    while (picked.length < lines) {
      picked.add(1 + rng.nextInt(Board.size - 2));
    }
    for (final line in picked) {
      final spots = List.generate(Board.size, (i) => i)..shuffle(rng);
      for (final k in spots.take(perLine)) {
        final i = rows ? line * Board.size + k : k * Board.size + line;
        cells[i] = Cell.rock(rng.nextDouble() < toughShare ? 2 : 1);
      }
    }
  }

  /// Fills random empty cells, never completing a row or column.
  static void _scatter(
    Random rng,
    Map<int, Cell> cells,
    int count,
    Cell Function(int) make,
  ) {
    var placed = 0;
    for (var tries = 0; placed < count && tries < count * 40; tries++) {
      final i = rng.nextInt(Board.size * Board.size);
      if (cells.containsKey(i)) continue;
      final r = i ~/ Board.size;
      final c = i % Board.size;
      final inRow = cells.keys.where((k) => k ~/ Board.size == r).length;
      final inCol = cells.keys.where((k) => k % Board.size == c).length;
      if (inRow >= Board.size - 2 || inCol >= Board.size - 2) continue;
      cells[i] = make(placed);
      placed++;
    }
  }

  static int _round50(double v) => (v / 50).round() * 50;
}
