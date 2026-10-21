import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/missions.dart';
import 'package:puzzle_blocos/game/game_controller.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('missions: a double clear early on, a combo x3 later, no revive', () {
    expect(
      Missions.earned(level: 3, bestLines: 2, bestCombo: 1, revived: false),
      7,
    );
    expect(
      Missions.count(
        Missions.earned(level: 3, bestLines: 1, bestCombo: 5, revived: true),
      ),
      1,
    );
    expect(
      Missions.has(
        Missions.earned(level: 20, bestLines: 3, bestCombo: 2, revived: false),
        Mission.bigMove,
      ),
      isFalse,
    );
    expect(Missions.forEndless(7400), 2);
    expect(Missions.forEndless(99999), 4);
  });

  test('stars: winning adds only the stars still missing; a replay does '
      'not move the progress on', () async {
    SharedPreferences.setMockInitialValues({'level': 5});
    final store = await ProgressStore.load();
    GameController play(int? replay) => GameController(
      store: store,
      feedback: GameFeedback(store),
      mode: GameMode.levels,
      replayLevel: replay,
    );

    final first = play(null)..debugWin();
    expect(store.level, 6);
    final firstStars = first.starsGained;
    expect(firstStars, greaterThanOrEqualTo(2)); // won, and no revive
    expect(store.stars, firstStars);
    first.dispose();

    // Level 5 again: the same missions add nothing, the level stays at 6.
    final again = play(5)..debugWin();
    expect(again.isReplay, isTrue);
    expect(again.starsGained, 0);
    expect(store.level, 6);
    again.dispose();

    expect(await store.spendStars(store.stars + 1), isFalse);
    expect(await store.spendStars(1), isTrue);
  });
}
