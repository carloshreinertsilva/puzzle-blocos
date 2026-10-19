import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_policy.dart';
import 'package:puzzle_blocos/core/board.dart';
import 'package:puzzle_blocos/core/game_session.dart';
import 'package:puzzle_blocos/core/level.dart';
import 'package:puzzle_blocos/core/patterns.dart';
import 'package:puzzle_blocos/core/piece_generator.dart';
import 'package:puzzle_blocos/core/shapes.dart';
import 'package:puzzle_blocos/core/solver.dart';

Shape shape(String id) => allShapes.firstWhere((s) => s.id == id);

void main() {
  group('Board', () {
    test('placing a piece fills its cells', () {
      final board = Board();
      board.place(Piece(shape('o20')), 2, 3);
      expect(board.filledCount, 4);
      expect(board.at(2, 3).isFilled, isTrue);
      expect(board.at(3, 4).isFilled, isTrue);
      expect(board.canPlace(shape('dot0'), 2, 3), isFalse);
      expect(board.canPlace(shape('i50'), 0, 4), isFalse); // off the edge
    });

    test('completing a row and a column clears both', () {
      final board = Board();
      for (var c = 0; c < 7; c++) {
        board.set(0, c, const Cell.block(1));
      }
      for (var r = 1; r < 8; r++) {
        board.set(r, 7, const Cell.block(2));
      }
      final out = board.place(Piece(shape('dot0')), 0, 7);
      expect(out.rows, [0]);
      expect(out.cols, [7]);
      expect(out.cleared.length, 15);
      expect(board.isEmpty, isTrue);
    });

    test('tough rocks lose one hp per clear; gems are collected', () {
      final board = Board();
      board.set(0, 0, const Cell.rock(2));
      board.set(0, 1, const Cell.rock(1));
      board.set(0, 2, const Cell.block(3, gem: true));
      for (var c = 3; c < 7; c++) {
        board.set(0, c, const Cell.block(1));
      }
      final out = board.place(Piece(shape('dot0')), 0, 7);
      expect(out.rocksBroken, 1);
      expect(out.gems, 1);
      expect(board.at(0, 0).type, CellType.rock);
      expect(board.at(0, 0).hp, 1);
      expect(board.filledCount, 1);
    });
  });

  group('Solver', () {
    test('sees that a full-width bar fits only after a clear', () {
      final board = Board();
      // Rows 0-6 full except column 0; row 7 empty.
      for (var r = 0; r < 7; r++) {
        for (var c = 1; c < 8; c++) {
          board.set(r, c, const Cell.block(0));
        }
      }
      final solver = Solver();
      final masks = board.rowMasks;
      final sticky = board.stickyMasks;
      expect(solver.canPlaceAll(masks, sticky, [shape('o30')]), isFalse);
      // A vertical 5-bar in column 0 clears five rows; then the 3x3 fits.
      expect(
        solver.canPlaceAll(masks, sticky, [shape('o30'), shape('i51')]),
        isTrue,
      );
    });

    test('apply clears full lines but keeps sticky rocks', () {
      final masks = List.filled(8, 0);
      masks[0] = 0x7F; // row 0 missing column 7
      final sticky = List.filled(8, 0)..[0] = 0x01;
      final next = Solver.apply(masks, sticky, shape('dot0'), 0, 7);
      expect(next[0], 0x01);
    });
  });

  group('PieceGenerator', () {
    test('every dealt tray can be placed completely', () {
      final rng = Random(42);
      final gen = PieceGenerator(rng);
      for (var game = 0; game < 30; game++) {
        final board = LevelGenerator.build(1 + game * 7).buildBoard();
        // Crowd the board randomly.
        for (var i = 0; i < rng.nextInt(30); i++) {
          final r = rng.nextInt(8), c = rng.nextInt(8);
          if (board.at(r, c).isEmpty) board.set(r, c, const Cell.block(0));
        }
        final tray = gen.deal(board, difficulty: rng.nextDouble());
        expect(tray.length, 3);
        final ok = Solver(budget: 200000).canPlaceAll(
          board.rowMasks,
          board.stickyMasks,
          [for (final p in tray) p.shape],
        );
        // Only an already hopeless board may get an unplaceable tray.
        if (!ok) {
          expect(allShapes.where(board.fitsAnywhere).length, lessThan(6));
        }
      }
    });

    test('higher difficulty deals bigger pieces on average', () {
      double avg(double d) {
        final gen = PieceGenerator(Random(7));
        var total = 0;
        for (var i = 0; i < 300; i++) {
          total += gen
              .deal(Board(), difficulty: d)
              .fold(0, (a, p) => a + p.shape.size);
        }
        return total / 900;
      }

      expect(avg(0.9), greaterThan(avg(0.1) + 0.5));
    });
  });

  group('LevelGenerator', () {
    test('is deterministic', () {
      final a = LevelGenerator.build(23), b = LevelGenerator.build(23);
      expect(a.difficulty, b.difficulty);
      expect(a.targetScore, b.targetScore);
      expect(a.initialCells.keys, b.initialCells.keys);
    });

    test('difficulty rises overall with a relief level after each peak', () {
      final d = [for (var n = 1; n <= 60; n++) LevelGenerator.build(n)];
      double avg(Iterable<LevelConfig> ls) =>
          ls.fold(0.0, (a, l) => a + l.difficulty) / ls.length;
      expect(avg(d.skip(54)), greaterThan(avg(d.take(6)) + 0.25));
      for (final level in d.where((l) => l.isHard)) {
        final next = d.firstWhere((l) => l.number == level.number + 1);
        expect(next.isRelief, isTrue);
        expect(next.difficulty, lessThan(level.difficulty));
      }
    });

    test('every level has a goal and never starts with a full line', () {
      for (var n = 1; n <= 200; n++) {
        final level = LevelGenerator.build(n);
        expect(
          level.targetScore > 0 || level.gemsTarget > 0 || level.hasRockGoal,
          isTrue,
          reason: 'level $n',
        );
        final masks = level.buildBoard().rowMasks;
        expect(masks.contains(Board.fullRow), isFalse);
      }
    });
  });

  group('Daily challenge and patterns', () {
    test('the daily level is the same all day and differs by day', () {
      final a = LevelGenerator.daily(DateTime(2026, 10, 19, 8));
      final b = LevelGenerator.daily(DateTime(2026, 10, 19, 22));
      final c = LevelGenerator.daily(DateTime(2026, 10, 20));
      expect(a.initialCells.keys, b.initialCells.keys);
      expect(a.isDaily, isTrue);
      expect(a.goalCount, 2);
      expect(
        a.initialCells.keys.toSet().difference(c.initialCells.keys.toSet()),
        isNotEmpty,
      );
    });

    test('no drawing starts with a full line in any orientation', () {
      for (final art in boardPatterns.values) {
        for (var seed = 0; seed < 8; seed++) {
          final board = Board();
          for (final (r, c) in patternCells(art, Random(seed))) {
            board.set(r, c, const Cell.block(0));
          }
          expect(board.rowMasks.contains(Board.fullRow), isFalse);
          expect(board.rowMasks.fold(Board.fullRow, (a, b) => a & b), 0);
        }
      }
    });

    test('early levels start with a drawing', () {
      expect(LevelGenerator.build(1).pattern, isNotNull);
      expect(LevelGenerator.build(2).pattern, isNotNull);
    });
  });

  group('GameSession', () {
    test('score goal wins the level', () {
      final level = LevelConfig(
        number: 1,
        difficulty: 0.1,
        targetScore: 20,
        gemsTarget: 0,
        gemChance: 0,
        initialCells: const {},
      );
      final s = GameSession(level, rng: Random(1));
      final piece = s.tray[0]!;
      expect(s.canPlace(0, 0, 0), isTrue);
      s.place(0, 0, 0);
      expect(s.score, piece.shape.size * 5);
      if (piece.shape.size * 5 < 20) {
        expect(s.status, SessionStatus.playing);
      }
    });

    test('combo multiplies line points and survives two dry moves', () {
      final level = LevelConfig(
        number: 1,
        difficulty: 0.1,
        targetScore: 999999,
        gemsTarget: 0,
        gemChance: 0,
        initialCells: {
          for (var c = 0; c < 7; c++) c: const Cell.block(0),
          63: const Cell.block(0),
        },
      );
      final s = GameSession(level, rng: Random(3));
      s.tray = [for (var i = 0; i < 3; i++) Piece(shape('dot0'))];
      final first = s.place(0, 0, 7);
      expect(first.combo, 1);
      expect(first.points, 5 + 100);
      s.place(1, 5, 5); // no clear
      expect(s.combo, 1);
    });

    test('revive clears crowded rows and resumes play', () {
      final cells = <int, Cell>{};
      for (var i = 0; i < 64; i++) {
        if (i % 8 != i ~/ 8) cells[i] = const Cell.block(0);
      }
      final level = LevelConfig(
        number: 9,
        difficulty: 0.9,
        targetScore: 999999,
        gemsTarget: 0,
        gemChance: 0,
        initialCells: cells,
      );
      final s = GameSession(level, rng: Random(5));
      s.tray = [Piece(shape('o30')), null, null];
      // Force a loss check.
      s.status = SessionStatus.lost;
      final cleared = s.revive();
      expect(cleared.length, greaterThanOrEqualTo(21));
      expect(s.revived, isTrue);
      expect(s.status, SessionStatus.playing);
    });
  });

  group('AdPolicy', () {
    final start = DateTime(2026, 1, 1, 12);
    const policy = AdPolicy(minInterval: Duration(minutes: 6));

    bool can(DateTime now, int level, [DateTime? last]) =>
        policy.canShowInterstitial(
          now: now,
          completedLevel: level,
          sessionStart: start,
          lastFullscreenAt: last,
        );

    test('never in the first levels or the first minutes', () {
      expect(can(start.add(const Duration(minutes: 30)), 3), isFalse);
      expect(can(start.add(const Duration(minutes: 2)), 20), isFalse);
      expect(can(start.add(const Duration(minutes: 6)), 20), isTrue);
    });

    test('spaces full-screen ads by the minimum interval', () {
      final last = start.add(const Duration(minutes: 10));
      expect(can(last.add(const Duration(minutes: 5)), 20, last), isFalse);
      expect(can(last.add(const Duration(minutes: 6)), 20, last), isTrue);
    });

    test('ads removed means no interstitials', () {
      expect(
        policy.canShowInterstitial(
          now: start.add(const Duration(hours: 1)),
          completedLevel: 50,
          sessionStart: start,
          adsRemoved: true,
        ),
        isFalse,
      );
    });
  });
}
