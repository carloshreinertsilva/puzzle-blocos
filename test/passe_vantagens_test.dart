import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/missions.dart';
import 'package:puzzle_blocos/core/passe.dart';
import 'package:puzzle_blocos/game/game_controller.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store({bool premium = false}) async {
  SharedPreferences.setMockInitialValues({'level': 12});
  final store = await ProgressStore.load();
  if (premium) {
    await store.setPassPremium(PasseDoCapi.temporada(DateTime.now()));
  }
  return store;
}

GameController _jogo(ProgressStore store, GameMode mode) =>
    GameController(store: store, feedback: GameFeedback(store), mode: mode);

void main() {
  for (final premium in [false, true]) {
    test('daily challenge, premium $premium: '
        '${premium ? 'double' : 'normal'} stars', () async {
      final store = await _store(premium: premium);
      final pontos = PasseDoCapi.pontos(store, DateTime.now());
      final c = _jogo(store, GameMode.daily);
      c.debugWin();
      await Future<void>.delayed(Duration.zero);
      final esperado =
          Missions.daily * (premium ? PasseDoCapi.multiplicadorDesafio : 1);
      expect(c.starsGained, esperado);
      expect(store.stars, esperado);
      // Only the challenge's own stars are pass points and fill the piggy
      // bank; the premium extra ones are like bought stars.
      expect(
        PasseDoCapi.pontos(store, DateTime.now()),
        pontos + Missions.daily,
      );
      expect(store.cofrinho, Missions.daily);
      expect(store.starsEarned, Missions.daily);
      c.dispose();
    });
  }

  testWidgets('premium gives one more free hint per game', (tester) async {
    final store = await _store(premium: true);
    final c = _jogo(store, GameMode.endless);
    expect(c.freeHints, GameController.freeIdleHints + PasseDoCapi.dicasExtras);
    for (var i = 0; i < c.freeHints; i++) {
      expect(c.showFreeHint(), isTrue, reason: 'free hint ${i + 1}');
      c.noteActivity();
    }
    expect(c.showFreeHint(), isFalse, reason: 'the next one is paid');
    c.dispose();
    await tester.pump(GameController.hintOfferAfter);
  });

  testWidgets('without premium, one free hint per game', (tester) async {
    final store = await _store();
    final c = _jogo(store, GameMode.endless);
    expect(c.freeHints, GameController.freeIdleHints);
    expect(c.showFreeHint(), isTrue);
    c.noteActivity();
    expect(c.showFreeHint(), isFalse);
    c.dispose();
    await tester.pump(GameController.hintOfferAfter);
  });
}
