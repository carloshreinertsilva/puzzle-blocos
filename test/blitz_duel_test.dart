import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/board.dart';
import 'package:puzzle_blocos/core/game_session.dart';
import 'package:puzzle_blocos/core/level.dart';
import 'package:puzzle_blocos/game/game_controller.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Seed determinism for Duels', () {
    test('sessions with same seed produce identical tray deals', () {
      final config1 = LevelConfig.duel(seed: 4242, targetScore: 1000);
      final session1 = GameSession(config1, rng: Random(4242));

      final config2 = LevelConfig.duel(seed: 4242, targetScore: 1000);
      final session2 = GameSession(config2, rng: Random(4242));

      expect(session1.tray.length, session2.tray.length);
      for (var i = 0; i < 3; i++) {
        expect(session1.tray[i]?.shape.id, session2.tray[i]?.shape.id);
      }
    });

    test('sessions with different seeds produce different deals', () {
      final config1 = LevelConfig.duel(seed: 111, targetScore: 1000);
      final session1 = GameSession(config1, rng: Random(111));

      final config2 = LevelConfig.duel(seed: 99999, targetScore: 1000);
      final session2 = GameSession(config2, rng: Random(99999));

      final ids1 = session1.tray.map((p) => p?.shape.id).join(',');
      final ids2 = session2.tray.map((p) => p?.shape.id).join(',');
      expect(ids1, isNot(equals(ids2)));
    });
  });

  group('ProgressStore Blitz & Duel', () {
    test('records blitz best score only when higher', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();

      expect(store.blitzBestScore, 0);

      final ok1 = await store.recordBlitzScore(850);
      expect(ok1, isTrue);
      expect(store.blitzBestScore, 850);

      final ok2 = await store.recordBlitzScore(600); // lower
      expect(ok2, isFalse);
      expect(store.blitzBestScore, 850);

      final ok3 = await store.recordBlitzScore(1450); // higher
      expect(ok3, isTrue);
      expect(store.blitzBestScore, 1450);
    });

    test('records duel wins counter', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();

      expect(store.duelsWon, 0);
      await store.recordDuelWin();
      expect(store.duelsWon, 1);
      await store.recordDuelWin();
      expect(store.duelsWon, 2);
    });
  });

  group('GameController Blitz mode', () {
    test('initializes with 60 seconds and finishes on timeout', () async {
      SharedPreferences.setMockInitialValues({'level': 10});
      final store = await ProgressStore.load();
      final feedback = GameFeedback(store);

      final controller = GameController(
        store: store,
        feedback: feedback,
        mode: GameMode.blitz,
      );

      expect(controller.isBlitz, isTrue);
      expect(controller.blitzSecondsLeft, 60);
      expect(controller.playing, isTrue);

      // Advance score
      controller.session.score = 2500;

      // Simulate time expiration directly
      controller.blitzSecondsLeft = 0;
      expect(controller.playing, isFalse);

      controller.session.status = SessionStatus.won;
      expect(controller.session.status, SessionStatus.won);

      controller.dispose();
    });

    test('line clears add bonus seconds in Blitz mode', () async {
      SharedPreferences.setMockInitialValues({'level': 10});
      final store = await ProgressStore.load();
      final feedback = GameFeedback(store);

      final controller = GameController(
        store: store,
        feedback: feedback,
        mode: GameMode.blitz,
      );

      controller.blitzSecondsLeft = 40;

      // Fill row 0 completely except cell (0, 0)
      for (var c = 1; c < Board.size; c++) {
        controller.session.board.set(0, c, const Cell.block(1));
      }

      // Slot 0 has a single dot piece
      final dot = allShapes.firstWhere((s) => s.id == 'dot0');
      controller.session.tray[0] = Piece(dot);

      controller.place(0, 0, 0);

      // Should have cleared row 0 and added bonus time
      expect(controller.blitzSecondsLeft, greaterThan(40));

      controller.dispose();
    });
  });

  group('GameController Duel mode', () {
    test('detects rival score passed and awards win and stars', () async {
      SharedPreferences.setMockInitialValues({'level': 10, 'stars': 10});
      final store = await ProgressStore.load();
      final feedback = GameFeedback(store);

      final controller = GameController(
        store: store,
        feedback: feedback,
        mode: GameMode.duel,
        duelSeed: 12345,
        duelTargetScore: 500,
        duelRivalName: 'Amigo',
      );

      expect(controller.isDuel, isTrue);
      expect(controller.duelTargetScore, 500);
      expect(controller.duelRivalName, 'Amigo');
      expect(controller.duelWon, isFalse);

      // Fill row 0 completely except cell (0, 0)
      for (var c = 1; c < Board.size; c++) {
        controller.session.board.set(0, c, const Cell.block(1));
      }

      final dot = allShapes.firstWhere((s) => s.id == 'dot0');
      controller.session.tray[0] = Piece(dot);

      controller.place(0, 0, 0);

      // Simulates high score passing rival target
      controller.session.score = 600;

      // Win the duel attempt
      controller.debugWin();

      expect(controller.duelWon, isTrue);
      expect(store.duelsWon, 1);
      expect(store.stars, 13); // +3 stars for winning duel

      controller.dispose();
    });
  });
}
