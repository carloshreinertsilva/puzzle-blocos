// ignore_for_file: avoid_print

// Plays levels with a simple greedy bot to check the difficulty curve.
// Run: dart run tool/simulate.dart [firstLevel] [lastLevel] [attempts]
import 'dart:math';

import 'package:puzzle_blocos/core/board.dart';
import 'package:puzzle_blocos/core/game_session.dart';
import 'package:puzzle_blocos/core/level.dart';

void main(List<String> args) {
  final first = args.isNotEmpty ? int.parse(args[0]) : 1;
  final last = args.length > 1 ? int.parse(args[1]) : 60;
  final attempts = args.length > 2 ? int.parse(args[2]) : 20;
  final rng = Random(1);
  for (var n = first; n <= last; n++) {
    final level = LevelGenerator.build(n);
    var wins = 0, moves = 0, winMoves = 0;
    for (var a = 0; a < attempts; a++) {
      final s = GameSession(level, rng: Random(rng.nextInt(1 << 30)));
      var m = 0;
      while (s.status == SessionStatus.playing && m < 400) {
        final move = _bestMove(s);
        if (move == null) break;
        s.place(move.$1, move.$2, move.$3);
        m++;
      }
      if (s.status == SessionStatus.won) {
        wins++;
        winMoves += m;
      }
      moves += m;
    }
    final kind = [
      if (level.targetScore > 0) 'score${level.targetScore}',
      if (level.hasRockGoal) 'rocks${level.rockCount}',
      if (level.gemsTarget > 0) 'gems${level.gemsTarget}',
      if (level.hasPupGoal) 'pups${level.pupCount}',
    ].join('+');
    final mark = level.isHard ? ' HARD' : (level.isRelief ? ' relief' : '');
    final tag = ' $kind$mark';
    print(
      'level ${n.toString().padLeft(3)} d=${level.difficulty.toStringAsFixed(2)}'
      ' win=${(100 * wins / attempts).round().toString().padLeft(3)}%'
      ' moves=${(moves / attempts).toStringAsFixed(0).padLeft(3)}'
      ' winMoves=${(wins == 0 ? 0 : winMoves / wins).toStringAsFixed(0).padLeft(3)}$tag',
    );
  }
}

(int, int, int)? _bestMove(GameSession s) {
  (int, int, int)? best;
  var bestScore = -1e9;
  for (var slot = 0; slot < 3; slot++) {
    final p = s.tray[slot];
    if (p == null) continue;
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        if (!s.board.canPlace(p.shape, r, c)) continue;
        final b = Board.copy(s.board);
        final out = b.place(p, r, c);
        final score =
            out.lines * 40 +
            out.rocksBroken * 15 +
            out.gems * 15 +
            out.pups * 25 -
            _holes(b) * 3 -
            b.filledCount * 0.5 +
            p.shape.size +
            _rockAim(b);
        if (score > bestScore) {
          bestScore = score;
          best = (slot, r, c);
        }
      }
    }
  }
  return best;
}

/// Empty cells boxed in on all four sides; a rough "bad shape" measure.
int _holes(Board b) {
  var n = 0;
  for (var r = 0; r < Board.size; r++) {
    for (var c = 0; c < Board.size; c++) {
      if (!b.at(r, c).isEmpty) continue;
      bool f(int rr, int cc) =>
          rr < 0 ||
          cc < 0 ||
          rr >= Board.size ||
          cc >= Board.size ||
          b.at(rr, cc).isFilled;
      if (f(r - 1, c) && f(r + 1, c) && f(r, c - 1) && f(r, c + 1)) n++;
    }
  }
  return n;
}

/// Rewards filling rows and columns that still hold rocks or pups, the way
/// a person aims for them.
double _rockAim(Board b) {
  var v = 0.0;
  for (var i = 0; i < Board.size; i++) {
    var rowRock = false, colRock = false, rowFill = 0, colFill = 0;
    for (var j = 0; j < Board.size; j++) {
      final rc = b.at(i, j), cr = b.at(j, i);
      if (rc.type == CellType.rock || rc.pup) rowRock = true;
      if (cr.type == CellType.rock || cr.pup) colRock = true;
      if (rc.isFilled) rowFill++;
      if (cr.isFilled) colFill++;
    }
    if (rowRock) v += rowFill * rowFill * 0.25;
    if (colRock) v += colFill * colFill * 0.25;
  }
  return v;
}
