import 'dart:convert';

import '../core/board.dart';
import '../core/shapes.dart';
import '../game/game_controller.dart';
import '../game/puzzle_game.dart';
import 'bridge_stub.dart' if (dart.library.js_interop) 'bridge_web.dart';

/// Build with --dart-define=TEST_BRIDGE=true to expose the game to browser
/// tests (Playwright) as `window.__bb`. Off in normal builds.
const kTestBridge = bool.fromEnvironment('TEST_BRIDGE');

/// What the browser tests can see and do. Buttons are found through the
/// accessibility tree; this covers what the canvas hides: the board, the
/// tray, where things are on screen, and which praise words appeared.
class TestBridge {
  TestBridge._();
  static final instance = TestBridge._();

  String screen = 'home';
  GameController? controller;
  PuzzleGame? game;
  final praises = <String>[];

  void install() => installJsBridge(this);

  String stateJson() => jsonEncode(state());

  Map<String, Object?> state() {
    final c = controller;
    final g = game;
    if (c == null) return {'screen': screen};
    final s = c.session;
    final level = s.level;
    return {
      'screen': screen,
      'mode': c.mode.name,
      'level': level.number,
      'kind': level.kind.name,
      'isHard': level.isHard,
      'pattern': level.pattern,
      'status': s.status.name,
      'showOutcome': c.showOutcome,
      'paused': c.paused,
      'intros': [for (final i in c.intros) i.name],
      'score': s.score,
      'combo': s.combo,
      'revived': s.revived,
      'goals': {
        'targetScore': level.targetScore,
        'gemsTarget': level.gemsTarget,
        'gems': s.gems,
        'rocksLeft': s.rocksLeft,
      },
      'board': [
        for (var r = 0; r < Board.size; r++)
          [for (var col = 0; col < Board.size; col++) _cell(s.board.at(r, col))]
              .join(),
      ],
      'tray': [
        for (final p in s.tray)
          p == null
              ? null
              : {
                  'id': p.shape.id,
                  'rows': p.shape.rows,
                  'cols': p.shape.cols,
                  'cells': [
                    for (final (r, col) in p.shape.cells) [r, col],
                  ],
                },
      ],
      'praises': praises,
      if (c.tutorial) 'tutorialStep': c.tutorialStep,
      if (c.tutorial) 'capi': c.capiLine,
      if (c.hint case final h?) 'hint': [h.$1, h.$2, h.$3],
      if (g != null && g.cellSize > 1) 'geometry': g.testGeometry(),
    };
  }

  static String _cell(Cell c) => switch (c.type) {
    CellType.empty => '.',
    CellType.rock => c.hp > 1 ? 'R' : 'r',
    CellType.block => c.gem ? 'g' : 'b',
  };

  /// Pointer path (in page pixels) that drags tray [slot] onto (row, col).
  Map<String, Object?>? dragPath(int slot, int row, int col) {
    final g = game;
    final p = controller?.session.tray[slot];
    if (g == null || p == null) return null;
    return g.dragPath(slot, p.shape, row, col);
  }

  /// Wins the current attempt (to reach later screens quickly).
  bool win() {
    final c = controller;
    if (c == null) return false;
    c.debugWin();
    return true;
  }

  /// Sets up a scenario: [board] as 8 strings ('.', 'b', 'g', 'r', 'R') and
  /// the tray as shape ids (null for an empty slot).
  bool load(String json) {
    final c = controller;
    if (c == null) return false;
    final data = jsonDecode(json) as Map<String, dynamic>;
    final rows = (data['board'] as List?)?.cast<String>();
    final tray = (data['tray'] as List?)?.cast<String?>();
    c.debugLoad(
      board: rows,
      tray: tray
          ?.map(
            (id) => id == null ? null : allShapes.firstWhere((s) => s.id == id),
          )
          .toList(),
    );
    return true;
  }
}
