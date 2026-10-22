import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/board.dart';
import 'package:puzzle_blocos/core/game_session.dart';
import 'package:puzzle_blocos/core/level.dart';
import 'package:puzzle_blocos/core/shapes.dart';
import 'package:puzzle_blocos/game/game_controller.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('rotateShape', () {
    test('cycles variants for shapes with multiple rotations', () {
      final dot = allShapes.firstWhere((s) => s.id == 'dot0');
      expect(rotateShape(dot).id, 'dot0');

      final i2 = allShapes.firstWhere((s) => s.id == 'i20');
      final i2Next = rotateShape(i2);
      expect(i2Next.id, 'i21');
      expect(rotateShape(i2Next).id, 'i20');

      final t4 = allShapes.firstWhere((s) => s.id == 't40');
      expect(rotateShape(t4).id, 't41');
      expect(rotateShape(rotateShape(t4)).id, 't42');
    });
  });

  group('Board tools methods', () {
    test('breakCell removes a single cell and returns before/after', () {
      final board = Board();
      board.set(2, 3, const Cell.block(1, gem: true));

      expect(board.breakCell(0, 0), isNull); // empty cell

      final cleared = board.breakCell(2, 3);
      expect(cleared, isNotNull);
      expect(cleared!.row, 2);
      expect(cleared.col, 3);
      expect(cleared.before.isFilled, isTrue);
      expect(cleared.before.gem, isTrue);
      expect(cleared.after.isEmpty, isTrue);
      expect(board.at(2, 3).isEmpty, isTrue);
    });

    test('breakArea3x3 clears surrounding 3x3 area clamped to bounds', () {
      final board = Board();
      // Place blocks at (0, 0), (0, 1), (1, 0), (1, 1)
      board.set(0, 0, const Cell.block(1));
      board.set(0, 1, const Cell.block(2));
      board.set(1, 0, const Cell.block(3));
      board.set(1, 1, const Cell.block(4));

      // Shovel centered at corner (0, 0)
      final cleared = board.breakArea3x3(0, 0);
      expect(cleared.length, 4);
      expect(board.at(0, 0).isEmpty, isTrue);
      expect(board.at(1, 1).isEmpty, isTrue);
    });
  });

  group('GameSession tools', () {
    test('useHammer breaks cell and collects gem / pup', () {
      final session = GameSession(LevelConfig.endless());
      session.board.set(3, 4, const Cell.block(0, gem: true, pup: true));

      expect(session.canBreakCell(3, 4), isTrue);
      expect(session.canBreakCell(0, 0), isFalse);

      final cleared = session.useHammer(3, 4);
      expect(cleared, isNotNull);
      expect(session.gems, 1);
      expect(session.pupsSaved, 1);
      expect(session.board.at(3, 4).isEmpty, isTrue);
    });

    test('useShovel clears 3x3 area and collects multiple items', () {
      final session = GameSession(LevelConfig.endless());
      session.board.set(2, 2, const Cell.block(1, gem: true));
      session.board.set(2, 3, const Cell.block(2, gem: true));
      session.board.set(3, 2, const Cell.block(3, pup: true));

      final cleared = session.useShovel(2, 2);
      expect(cleared.length, 3);
      expect(session.gems, 2);
      expect(session.pupsSaved, 1);
    });

    test('useRotate rotates tray piece and preserves properties', () {
      final session = GameSession(LevelConfig.endless());
      final i20 = allShapes.firstWhere((s) => s.id == 'i20');
      session.tray[0] = Piece(i20, color: 4, gemCell: 1);

      expect(session.canRotatePiece(0), isTrue);
      expect(session.canRotatePiece(5), isFalse);

      final rotated = session.useRotate(0);
      expect(rotated, isNotNull);
      expect(rotated!.shape.id, 'i21');
      expect(rotated.color, 4);
      expect(rotated.gemCell, 1);
    });

    test('useReroll refreshes tray pieces', () {
      final session = GameSession(LevelConfig.endless());
      session.useReroll();
      expect(session.tray.length, 3);
      expect(session.tray.any((p) => p != null), isTrue);
    });
  });

  group('ProgressStore tools', () {
    test('default counts and operations', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();

      expect(store.toolCount(CapiTool.hammer), 2);
      expect(store.toolCount(CapiTool.rotate), 2);
      expect(store.toolCount(CapiTool.reroll), 2);
      expect(store.toolCount(CapiTool.shovel), 1);

      await store.addTool(CapiTool.hammer, 3);
      expect(store.toolCount(CapiTool.hammer), 5);

      final ok = await store.useTool(CapiTool.hammer);
      expect(ok, isTrue);
      expect(store.toolCount(CapiTool.hammer), 4);
    });

    test('buyToolWithStars checks balance', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();

      // Not enough stars
      expect(await store.buyToolWithStars(CapiTool.hammer), isFalse);

      // Add stars and buy
      await store.addStars(10);
      expect(await store.buyToolWithStars(CapiTool.hammer), isTrue); // cost: 5
      expect(store.stars, 5);
      expect(store.toolCount(CapiTool.hammer), 3);
    });
  });

  group('GameController tools integration', () {
    test('selectTool and execution flow', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();
      final feedback = GameFeedback(store);
      final controller = GameController(
        store: store,
        feedback: feedback,
        mode: GameMode.endless,
      );
      while (controller.intros.isNotEmpty) {
        controller.dismissIntro();
      }

      expect(controller.playing, isTrue);

      // Test Reroll: executes immediately
      final okReroll = await controller.selectTool(CapiTool.reroll);
      expect(okReroll, isTrue);
      expect(store.toolCount(CapiTool.reroll), 1);
      expect(controller.activeToolMode, isNull);

      // Test Hammer: sets mode, then breaks block
      controller.session.board.set(4, 4, const Cell.block(1));
      final okSelect = await controller.selectTool(CapiTool.hammer);
      expect(okSelect, isTrue);
      expect(controller.activeToolMode, CapiTool.hammer);

      final okHammer = await controller.executeHammer(4, 4);
      expect(okHammer, isTrue);
      expect(store.toolCount(CapiTool.hammer), 1);
      expect(controller.activeToolMode, isNull);
      expect(controller.session.board.at(4, 4).isEmpty, isTrue);

      // Test Rotate
      final i20 = allShapes.firstWhere((s) => s.id == 'i20');
      controller.session.tray[0] = Piece(i20);
      await controller.selectTool(CapiTool.rotate);
      expect(controller.activeToolMode, CapiTool.rotate);
      final okRotate = await controller.executeRotate(0);
      expect(okRotate, isTrue);
      expect(controller.session.tray[0]?.shape.id, 'i21');
      expect(controller.activeToolMode, isNull);
      expect(store.toolCount(CapiTool.rotate), 1);

      // Test Shovel
      controller.session.board.set(2, 2, const Cell.block(1));
      await controller.selectTool(CapiTool.shovel);
      expect(controller.activeToolMode, CapiTool.shovel);
      final okShovel = await controller.executeShovel(2, 2);
      expect(okShovel, isTrue);
      expect(controller.activeToolMode, isNull);
      expect(store.toolCount(CapiTool.shovel), 0);

      // Test Cancel tool mode
      await store.addTool(CapiTool.shovel, 1);
      await controller.selectTool(CapiTool.shovel);
      expect(controller.activeToolMode, CapiTool.shovel);
      controller.cancelToolMode();
      expect(controller.activeToolMode, isNull);
      expect(store.toolCount(CapiTool.shovel), 1); // no shovel spent
    });
  });
}
