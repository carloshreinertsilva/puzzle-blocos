import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/blueprint.dart';
import 'package:puzzle_blocos/core/board.dart';
import 'package:puzzle_blocos/core/village.dart';

/// The solution covers every drawing cell exactly once.
void expectSolved(Blueprint bp) {
  final covered = <int>[];
  for (var i = 0; i < bp.pieces.length; i++) {
    final (r, c) = bp.solution[i];
    for (final (dr, dc) in bp.pieces[i].cells) {
      covered.add((r + dr) * Board.size + c + dc);
    }
  }
  expect(covered.toSet().length, covered.length, reason: '${bp.id} overlap');
  expect(covered.toSet(), bp.cells, reason: bp.id);
}

void main() {
  test('obras: every drawing is cut into pieces that fill it exactly', () {
    for (final (i, item) in Village.items.indexed) {
      final bp = Blueprints.forItem(item.id, item.name, i);
      expectSolved(bp);
      expect(bp.pieces.length, inInclusiveRange(3, 11), reason: item.id);
      expect(bp.pieces.where((s) => s.size == 1).length, lessThan(2));
    }
    for (var n = 1; n <= 36; n++) {
      final bp = Blueprints.level(n);
      expectSolved(bp);
      expect(bp.pieces.length, inInclusiveRange(4, 12), reason: bp.id);
      // Mostly real pieces, not single squares.
      expect(bp.pieces.where((s) => s.size == 1).length, lessThan(2));
    }
  });

  test('obras: the same obra is the same for everyone', () {
    final a = Blueprints.level(5), b = Blueprints.level(5);
    expect([for (final s in a.pieces) s.id], [for (final s in b.pieces) s.id]);
    expect(a.solution, b.solution);
  });

  test('obras: hint finds a move, and notices a dead end', () {
    final bp = Blueprints.level(3);
    final all = List.generate(bp.pieces.length, (i) => i);
    final move = Blueprints.hint(bp, {}, all);
    expect(move, isNotNull);
    final (i, r, c) = move!;
    final filled = {
      for (final (dr, dc) in bp.pieces[i].cells) (r + dr) * Board.size + c + dc,
    };
    expect(Blueprints.hint(bp, filled, [...all]..remove(i)), isNotNull);

    // Some first placement must leave the rest impossible to fill.
    var deadEnds = 0;
    for (var p = 0; p < bp.pieces.length; p++) {
      final s = bp.pieces[p];
      for (var top = 0; top + s.rows <= Board.size; top++) {
        for (var left = 0; left + s.cols <= Board.size; left++) {
          final cells = {
            for (final (dr, dc) in s.cells) (top + dr) * Board.size + left + dc,
          };
          if (!bp.cells.containsAll(cells)) continue;
          if (Blueprints.hint(bp, cells, [...all]..remove(p)) == null) {
            deadEnds++;
          }
        }
      }
    }
    expect(deadEnds, greaterThan(0));
  });

  test('obras: stars for solving without help', () {
    expect(blueprintStars(undos: 0, hints: 0), 3);
    expect(blueprintStars(undos: 2, hints: 0), 2);
    expect(blueprintStars(undos: 0, hints: 1), 2);
    expect(blueprintStars(undos: 2, hints: 1), 1);
  });
}
