import 'dart:math';

import 'board.dart';
import 'patterns.dart';

enum LevelKind { level, endless, daily }

/// Number of block colors (matches the palette in the UI layer).
const blockColorCount = 7;

/// What a level looks like: its goals, its difficulty and the board it
/// starts with. Built deterministically from the level number (or the date,
/// for the daily challenge), so level 37 is the same level for everyone.
class LevelConfig {
  LevelConfig({
    required this.number,
    required this.difficulty,
    required this.targetScore,
    required this.gemsTarget,
    required this.gemChance,
    required this.initialCells,
    this.kind = LevelKind.level,
    this.isHard = false,
    this.isRelief = false,
    this.pattern,
  });

  /// Endless mode: no goals; difficulty grows with the score.
  LevelConfig.endless()
    : number = 0,
      kind = LevelKind.endless,
      difficulty = 0.15,
      targetScore = 0,
      gemsTarget = 0,
      gemChance = 0,
      initialCells = const {},
      isHard = false,
      isRelief = false,
      pattern = null;

  /// Level number; for the daily challenge, the date as yyyymmdd.
  final int number;
  final LevelKind kind;
  final double difficulty;
  final int targetScore;
  final int gemsTarget;
  final double gemChance;

  /// Cells filled at the start, keyed by row * 8 + col.
  final Map<int, Cell> initialCells;

  final bool isHard;
  final bool isRelief;

  /// Name of the drawing the board starts with, if any.
  final String? pattern;

  bool get isEndless => kind == LevelKind.endless;
  bool get isDaily => kind == LevelKind.daily;
  int get rockCount =>
      initialCells.values.where((c) => c.type == CellType.rock).length;
  bool get hasRockGoal => rockCount > 0;
  bool get hasToughRocks =>
      initialCells.values.any((c) => c.type == CellType.rock && c.hp > 1);
  int get goalCount =>
      [targetScore > 0, gemsTarget > 0, hasRockGoal].where((g) => g).length;

  Board buildBoard() {
    final board = Board();
    initialCells.forEach((i, cell) {
      board.set(i ~/ Board.size, i % Board.size, cell);
    });
    return board;
  }
}

typedef _Goal = ({bool score, bool rocks, bool gems});

class LevelGenerator {
  /// Difficulty climbs for four levels, peaks on a hard level, then eases
  /// on a relief level ("sawtooth"). The relief is what keeps players going.
  static const _cycle = [0.0, 0.06, 0.12, 0.18, 0.28, -0.05];

  static LevelConfig build(int n) {
    assert(n >= 1);
    final step = (n - 1) % _cycle.length;
    final global = 1 - exp(-n / 45);
    final d = (0.08 + 0.55 * global + _cycle[step] * min(1.0, n / 12))
        .clamp(0.05, 0.97)
        .toDouble();

    return _compose(
      rng: Random(n * 7919 + 17),
      number: n,
      level: n,
      difficulty: d,
      goal: _goalFor(n),
      isHard: n >= 5 && step == 4,
      isRelief: n >= 6 && step == 5,
    );
  }

  /// One special level per day, the same for every player: two goals and a
  /// medium difficulty.
  static LevelConfig daily(DateTime day) {
    final key = day.year * 10000 + day.month * 100 + day.day;
    final rng = Random(key);
    const goals = <_Goal>[
      (score: true, rocks: true, gems: false),
      (score: true, rocks: false, gems: true),
      (score: false, rocks: true, gems: true),
    ];
    return _compose(
      rng: rng,
      number: key,
      level: 40,
      difficulty: 0.32 + rng.nextDouble() * 0.12,
      goal: goals[rng.nextInt(goals.length)],
      kind: LevelKind.daily,
    );
  }

  static LevelConfig _compose({
    required Random rng,
    required int number,
    required int level,
    required double difficulty,
    required _Goal goal,
    LevelKind kind = LevelKind.level,
    bool isHard = false,
    bool isRelief = false,
  }) {
    final d = difficulty;
    final n = level;
    final goals = [goal.score, goal.rocks, goal.gems].where((g) => g).length;
    // Two goals at once: each one is smaller. Hard levels ask a bit more,
    // relief levels a bit less.
    final share =
        (goals > 1 ? 0.55 : 1.0) *
        (isHard
            ? 1.1
            : isRelief
            ? 0.8
            : 1.0);
    final cells = <int, Cell>{};

    // Most boards start with a drawing (not rock boards, which bring their
    // own layout), so the very first moves already clear lines.
    String? pattern;
    if (!goal.rocks && (goal.score || rng.nextDouble() < 0.6)) {
      // Lighter drawings first; heavier ones join as difficulty rises.
      final names = boardPatterns.keys.toList()
        ..sort(
          (a, b) =>
              _weight(boardPatterns[a]!).compareTo(_weight(boardPatterns[b]!)),
        );
      final reach = (4 + d * (names.length - 4)).round().clamp(4, names.length);
      pattern = names[(n * 5 + rng.nextInt(3)) % reach];
      final offset = rng.nextInt(blockColorCount);
      for (final (r, c) in patternCells(boardPatterns[pattern]!, rng)) {
        cells[r * Board.size + c] = Cell.block((r + offset) % blockColorCount);
      }
    }

    var targetScore = 0;
    var gemsTarget = 0;
    var gemChance = 0.0;

    if (goal.score) {
      targetScore = _round50((2200 + 90 * n) * (0.6 + 0.8 * d) * share);
    }
    if (goal.rocks) {
      // Rocks sit on a few rows or columns, so each line clear can break
      // several; more lines (and reinforced rocks) as difficulty rises.
      final lines = (2 + 3 * d * share).round().clamp(1, 5);
      final toughShare = ((n - 15) / 80).clamp(0.0, 0.35);
      _rockLines(rng, cells, lines, 2 + (d * 2).round(), toughShare);
    }
    if (goal.gems) {
      gemsTarget = ((6 + 7 * d) * share).round();
      gemChance = 0.2 + 0.08 * (1 - d);
      // Some gems start on the board, inside the drawing when there is one.
      final drawing = cells.keys
          .where((i) => cells[i]!.type == CellType.block)
          .toList();
      drawing.shuffle(rng);
      for (final i in drawing.take(gemsTarget ~/ 3)) {
        cells[i] = Cell.block(cells[i]!.color, gem: true);
      }
      if (drawing.isEmpty) {
        _scatter(rng, cells, gemsTarget ~/ 3, (_) {
          return Cell.block(rng.nextInt(blockColorCount), gem: true);
        });
      }
    }
    // Leftover blocks make later boards without a drawing start crowded.
    if (pattern == null && n > 6) {
      _scatter(
        rng,
        cells,
        (d * 7).round(),
        (_) => Cell.block(rng.nextInt(blockColorCount)),
      );
    }

    return LevelConfig(
      number: number,
      kind: kind,
      difficulty: d,
      targetScore: targetScore,
      gemsTarget: gemsTarget,
      gemChance: gemChance,
      initialCells: cells,
      isHard: isHard,
      isRelief: isRelief,
      pattern: pattern,
    );
  }

  static _Goal _goalFor(int n) {
    // The first levels introduce one goal at a time.
    if (n <= 2 || n == 4) return (score: true, rocks: false, gems: false);
    if (n == 3) return (score: false, rocks: true, gems: false);
    if (n == 5) return (score: false, rocks: false, gems: true);
    // Rotate the goal kind so hard and relief levels vary too.
    final kind = (n + (n - 1) ~/ 6) % 3;
    final both = n >= 10 && n % 5 == 0;
    return switch (kind) {
      0 => (score: true, rocks: both, gems: false),
      1 => (score: both, rocks: true, gems: false),
      _ => (score: false, rocks: both, gems: true),
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

  static int _weight(List<String> art) =>
      art.fold(0, (sum, row) => sum + '#'.allMatches(row).length);

  static int _round50(double v) => (v / 50).round() * 50;
}
