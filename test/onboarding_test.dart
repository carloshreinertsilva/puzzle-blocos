import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/game/game_controller.dart';
import 'package:puzzle_blocos/game/onboarding.dart';
import 'package:puzzle_blocos/game/tutorial.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a new player gets the tutorial, then the first levels, then the '
      'menu; modes unlock as levels go up', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await ProgressStore.load();
    expect(Onboarding.tutorialDone(s), isFalse);
    expect(Onboarding.menuUnlocked(s), isFalse);

    await s.markSeen('tutorial');
    expect(Onboarding.tutorialDone(s), isTrue);
    expect(Onboarding.menuUnlocked(s), isFalse);

    await s.setLevel(Onboarding.railLevels + 1);
    expect(Onboarding.menuUnlocked(s), isTrue);
    expect(Onboarding.pendingNews(s), [MenuNews.welcome, MenuNews.village]);
    expect(Onboarding.endlessUnlocked(s), isFalse);

    await s.setLevel(Onboarding.dailyAt);
    expect(Onboarding.pendingNews(s), [
      MenuNews.welcome,
      MenuNews.village,
      MenuNews.endless,
      MenuNews.daily,
    ]);
    await s.markSeen(MenuNews.welcome.key);
    await s.markSeen(MenuNews.village.key);
    expect(Onboarding.pendingNews(s).first, MenuNews.endless);
  });

  test('players who already played skip the tutorial', () async {
    SharedPreferences.setMockInitialValues({'level': 2});
    expect(Onboarding.tutorialDone(await ProgressStore.load()), isTrue);
  });

  testWidgets('tutorial steps: a miss repeats the step, a hit moves on', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final c = GameController(
      store: store,
      feedback: GameFeedback(store),
      mode: GameMode.tutorial,
    );
    addTearDown(c.dispose);

    // Step 1: any placement counts.
    expect(c.hint, (1, 3, 3));
    c.place(1, 0, 0);
    expect(c.playing, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(c.tutorialStep, 1);

    // Step 2 needs a line: dropping the piece elsewhere repeats the step.
    c.place(1, 0, 0);
    await tester.pump(const Duration(seconds: 2));
    expect(c.tutorialStep, 1);
    expect(c.capiLine, Tutorial.retry);
    final (_, r, col) = c.hint!;
    c.place(1, r, col);
    await tester.pump(const Duration(seconds: 2));
    expect(c.tutorialStep, 2);

    // Step 3: two lines at once, then the tutorial is over.
    final (_, r2, col2) = c.hint!;
    c.place(1, r2, col2);
    await tester.pump(const Duration(seconds: 2));
    expect(c.tutorialFinished, isTrue);
    expect(c.capiLine, Tutorial.done);
    expect(store.hasSeen('tutorial'), isTrue);
  });

  testWidgets('Capi suggests a move after a while without playing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final c = GameController(
      store: store,
      feedback: GameFeedback(store),
      mode: GameMode.endless,
    );

    expect(c.hint, isNull);
    await tester.pump(GameController.idleHintAfter);
    final hint = c.hint;
    expect(hint, isNotNull);
    expect(c.capiReaction, CapiReaction.hint);
    final (slot, row, col) = hint!;
    expect(c.session.canPlace(slot, row, col), isTrue);

    // Touching a piece takes the hint away.
    c.noteActivity();
    expect(c.hint, isNull);
    c.dispose(); // stops the idle clock before the test ends
  });
}
