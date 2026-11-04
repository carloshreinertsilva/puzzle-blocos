import 'package:flutter/foundation.dart';

import '../core/blueprint.dart';
import '../core/board.dart';
import '../l10n/idioma.dart';

/// One attempt at a construction puzzle: which pieces sit where, how much
/// help was used, and whether the drawing is complete.
class ObraController extends ChangeNotifier {
  ObraController(this.blueprint)
    : placed = List.filled(blueprint.pieces.length, null);

  final Blueprint blueprint;

  /// Where each piece sits (top-left), or null while it is in the tray.
  final List<(int, int)?> placed;
  int undos = 0;
  int hints = 0;

  /// The current hint: piece index and spot, until that piece moves.
  (int, int, int)? hint;

  /// Capi's line under the board.
  String line = tr(
    'Arraste as peças para dentro do desenho. Tem que caber '
    'todas, sem sobrar buraco!',
  );

  bool get solved => placed.every((p) => p != null);
  int get stars => blueprintStars(undos: undos, hints: hints);

  List<int> get unplaced => [
    for (var i = 0; i < placed.length; i++)
      if (placed[i] == null) i,
  ];

  Set<int> cellsOf(int piece, int r, int c) => {
    for (final (dr, dc) in blueprint.pieces[piece].cells)
      (r + dr) * Board.size + c + dc,
  };

  Set<int> get filled => {
    for (var i = 0; i < placed.length; i++)
      if (placed[i] case (final r, final c)) ...cellsOf(i, r, c),
  };

  /// Which placed piece covers [cell], or null.
  int? pieceAt(int cell) {
    for (var i = 0; i < placed.length; i++) {
      if (placed[i] case (final r, final c)) {
        if (cellsOf(i, r, c).contains(cell)) return i;
      }
    }
    return null;
  }

  bool canPlace(int piece, int r, int c) {
    final s = blueprint.pieces[piece];
    if (r < 0 || c < 0 || r + s.rows > Board.size || c + s.cols > Board.size) {
      return false;
    }
    final cells = cellsOf(piece, r, c);
    return blueprint.cells.containsAll(cells) &&
        cells.intersection(filled).isEmpty;
  }

  bool place(int piece, int r, int c) {
    if (solved || placed[piece] != null || !canPlace(piece, r, c)) {
      return false;
    }
    placed[piece] = (r, c);
    if (hint?.$1 == piece) hint = null;
    if (solved) {
      line = tr('Obra pronta! Ficou perfeita!');
    } else if (Blueprints.hint(blueprint, filled, unplaced) == null) {
      line = tr('Hmm, assim não fecha... Toque numa peça para tirá-la.');
    } else {
      line = [
        tr('Isso! Segue o desenho.'),
        tr('Encaixou direitinho!'),
        tr('Boa, falta pouco!'),
      ][unplaced.length % 3];
    }
    notifyListeners();
    return true;
  }

  /// Takes a placed piece back to the tray (counts as undoing).
  void remove(int piece) {
    if (solved || placed[piece] == null) return;
    placed[piece] = null;
    undos++;
    line = tr('Sem problema, tenta de outro jeito.');
    notifyListeners();
  }

  /// Hints given free in each obra; the next ones are paid (stars or video).
  static const freeHints = 1;

  /// Whether pressing "Dica" now costs something: a new piece would be shown
  /// and the free hints are used up. Repeating the hint on screen, or Capi
  /// saying the board can't be finished, is always free.
  bool get nextHintPaid =>
      !solved &&
      hint == null &&
      hints >= freeHints &&
      Blueprints.hint(blueprint, filled, unplaced) != null;

  /// Capi shows where one piece goes; if the board can't be finished from
  /// here, he says so instead (that one doesn't count as a hint).
  void showHint() {
    if (solved) return;
    if (hint != null) {
      line = tr('Essa peça vai aqui, ó!');
      notifyListeners();
      return;
    }
    final move = Blueprints.hint(blueprint, filled, unplaced);
    if (move == null) {
      line = tr('Do jeito que está, não fecha. Tire uma peça e eu te mostro!');
    } else {
      hints++;
      hint = move;
      line = tr('Essa peça vai aqui, ó!');
    }
    notifyListeners();
  }

  /// Clears the drawing; every piece taken back counts as an undo.
  void restart() {
    undos += placed.where((p) => p != null).length;
    for (var i = 0; i < placed.length; i++) {
      placed[i] = null;
    }
    hint = null;
    line = tr('Do zero! Arraste as peças para o desenho.');
    notifyListeners();
  }

  /// Test scenarios only: finishes the drawing with the solution.
  void debugSolve() {
    for (var i = 0; i < placed.length; i++) {
      placed[i] = blueprint.solution[i];
    }
    line = tr('Obra pronta! Ficou perfeita!');
    notifyListeners();
  }
}
