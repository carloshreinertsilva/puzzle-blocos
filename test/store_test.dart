import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'daily streak grows on consecutive days and resets after a gap',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();
      final d1 = DateTime(2026, 10, 18);
      final d2 = DateTime(2026, 10, 19);
      final d4 = DateTime(2026, 10, 21);

      expect(store.dailyStreak(d1), 0);
      await store.completeDaily(d1);
      expect(store.dailyDone(d1), isTrue);
      expect(store.dailyStreak(d1), 1);

      await store.completeDaily(d2);
      await store.completeDaily(d2); // twice on one day counts once
      expect(store.dailyStreak(d2), 2);

      expect(store.dailyStreak(d4), 0); // a day was skipped
      await store.completeDaily(d4);
      expect(store.dailyStreak(d4), 1);
    },
  );

  test('stats add up', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await store.recordMove(lines: 2, combo: 3, gems: 1, rocks: 0);
    await store.recordMove(lines: 1, combo: 1, gems: 0, rocks: 2);
    await store.recordGame(levelWon: true);
    expect(store.linesCleared, 3);
    expect(store.bestCombo, 3);
    expect(store.gemsCollected, 1);
    expect(store.rocksBroken, 2);
    expect(store.gamesPlayed, 1);
    expect(store.levelsWon, 1);
  });
}
