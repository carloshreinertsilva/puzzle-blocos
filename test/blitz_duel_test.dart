import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/board.dart';
import 'package:puzzle_blocos/core/game_session.dart';
import 'package:puzzle_blocos/core/level.dart';
import 'package:puzzle_blocos/game/game_controller.dart';
import 'package:puzzle_blocos/core/shapes.dart';
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
    testWidgets('the clock really runs down and ends the run', (tester) async {
      SharedPreferences.setMockInitialValues({'level': 10});
      final store = await ProgressStore.load();
      final controller = GameController(
        store: store,
        feedback: GameFeedback(store),
        mode: GameMode.blitz,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(controller.blitzSecondsLeft, 55);

      // A move (which resets the idle hint clock) must not stop it.
      controller.noteActivity();
      await tester.pump(const Duration(seconds: 5));
      expect(controller.blitzSecondsLeft, 50);

      await tester.pump(const Duration(seconds: 51));
      expect(controller.blitzSecondsLeft, 0);
      expect(controller.session.status, SessionStatus.won);
      controller.dispose();
      await tester.pump(const Duration(seconds: 5));
    });

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

  group('Blitz extra time', () {
    test('bigger clears add more seconds', () {
      int b(int lines, [int combo = 1]) =>
          GameController.blitzTimeBonus(lines: lines, combo: combo);
      expect(b(0), 0);
      expect(b(1), 1);
      expect(b(2), 3);
      expect(b(3), 5);
      expect(b(4), 5);
      expect(b(1, 2), 2, reason: 'combo seguido vale +1');
      expect(b(2, 3), 4);
    });

    test('the clock never goes past 90 seconds', () async {
      SharedPreferences.setMockInitialValues({'level': 10});
      final store = await ProgressStore.load();
      final controller = GameController(
        store: store,
        feedback: GameFeedback(store),
        mode: GameMode.blitz,
      );
      controller.blitzSecondsLeft = 89;
      for (var c = 1; c < Board.size; c++) {
        controller.session.board.set(0, c, const Cell.block(1));
      }
      controller.session.tray[0] = Piece(
        allShapes.firstWhere((s) => s.id == 'dot0'),
      );
      final tick = controller.blitzBonusTick;
      controller.place(0, 0, 0);
      expect(controller.blitzSecondsLeft, GameController.blitzMaxSeconds);
      expect(controller.blitzLastBonus, 1);
      expect(controller.blitzBonusTick, tick + 1);
      controller.dispose();
    });

    testWidgets('a video adds 10 seconds once, and stars are not paid twice', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'level': 10, 'stars': 0});
      final store = await ProgressStore.load();
      final controller = GameController(
        store: store,
        feedback: GameFeedback(store),
        mode: GameMode.blitz,
      );
      expect(controller.canBlitzExtraTime, isFalse, reason: 'ainda jogando');

      controller.session.score = 3000; // 2 stars
      controller.blitzSecondsLeft = 1;
      await tester.pump(const Duration(seconds: 2));
      expect(controller.session.status, SessionStatus.won);
      expect(controller.canBlitzExtraTime, isTrue);
      await tester.pump();
      expect(store.stars, 2);

      controller.addBlitzExtraTime();
      expect(controller.session.status, SessionStatus.playing);
      expect(controller.blitzSecondsLeft, GameController.blitzExtraSeconds);
      expect(controller.showOutcome, isFalse);
      expect(controller.playing, isTrue);

      controller.session.score = 4600; // 3 stars: only 1 more is due
      await tester.pump(const Duration(seconds: 11));
      expect(controller.blitzSecondsLeft, 0);
      expect(controller.session.status, SessionStatus.won);
      await tester.pump();
      expect(store.stars, 3);
      expect(store.blitzBestScore, 4600, reason: 'o recorde conta');
      expect(controller.canBlitzExtraTime, isFalse, reason: 'só uma vez');

      controller.dispose();
      await tester.pump(const Duration(seconds: 3));
    });

    test('a duel against a friend never offers extra time', () async {
      SharedPreferences.setMockInitialValues({'level': 10});
      final store = await ProgressStore.load();
      final controller = GameController(
        store: store,
        feedback: GameFeedback(store),
        mode: GameMode.blitz,
        duelSeed: 99,
        duelTargetScore: 500,
        duelRivalName: 'Amigo',
      );
      controller.blitzSecondsLeft = 0;
      controller.session.status = SessionStatus.won;
      expect(controller.canBlitzExtraTime, isFalse);
      controller.addBlitzExtraTime();
      expect(controller.session.status, SessionStatus.won);
      controller.dispose();
    });
  });

  group('Stars from quick modes', () {
    test('a challenge pays once per seed; menu duels pay nothing', () async {
      SharedPreferences.setMockInitialValues({'level': 10, 'stars': 0});
      final store = await ProgressStore.load();
      GameController duel({String? rival}) => GameController(
        store: store,
        feedback: GameFeedback(store),
        mode: GameMode.duel,
        duelSeed: 777,
        duelTargetScore: 100,
        duelRivalName: rival,
      );

      final practice = duel()..session.score = 500;
      practice.debugWin();
      expect(store.stars, 0, reason: 'duelo do menu é treino');
      practice.dispose();

      final first = duel(rival: 'Amigo')..session.score = 500;
      first.debugWin();
      expect(store.stars, GameController.challengeStars);
      first.dispose();

      final again = duel(rival: 'Amigo')..session.score = 500;
      again.debugWin();
      expect(store.stars, GameController.challengeStars, reason: 'só 1 vez');
      again.dispose();
    });

    test('minigame stars stop at the daily cap', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();
      final day = DateTime(2026, 10, 23);
      expect(await store.addStarsCapped('blitz', 3, 6, day), 3);
      expect(await store.addStarsCapped('blitz', 3, 6, day), 3);
      expect(await store.addStarsCapped('blitz', 3, 6, day), 0);
      expect(await store.addStarsCapped('tower', 2, 6, day), 2);
      final tomorrow = day.add(const Duration(days: 1));
      expect(await store.addStarsCapped('blitz', 3, 6, tomorrow), 3);
      expect(store.stars, 11);
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

  test('Blitz goes on after the first piece (it has no goal, only time)', () {
    final session = GameSession(LevelConfig.blitz(seed: 7), rng: Random(7));
    var placed = 0;
    for (var slot = 0; slot < 3 && placed < 3; slot++) {
      final p = session.tray[slot];
      if (p == null) continue;
      search:
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (session.board.canPlace(p.shape, r, c)) {
            session.place(slot, r, c);
            placed++;
            break search;
          }
        }
      }
      expect(session.status, SessionStatus.playing, reason: 'after $placed');
    }
    expect(placed, greaterThan(1));
  });
}
