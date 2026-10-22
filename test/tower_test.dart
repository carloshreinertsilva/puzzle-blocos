import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/game/onboarding.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/tower/tower_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProgressStore store;
  late GameFeedback feedback;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await ProgressStore.load();
    feedback = GameFeedback(store);
  });

  test('Torre inicia com o andar base colocado', () {
    final c = TowerController(store: store, feedback: feedback);
    expect(c.blocks.length, 1);
    expect(c.blocks.first.dx, TowerController.baseSize);
    expect(c.blocks.first.dy, TowerController.baseSize);
    expect(c.height, 1);
    expect(c.gameOver, isFalse);
    expect(c.playing, isTrue);
  });

  test('Acertos perfeitos acumulam combo e expandem largura cortada', () {
    final c = TowerController(store: store, feedback: feedback);

    // Primeiro andar perfeito
    c.debugPlace(perfect: true);
    expect(c.blocks.length, 2);
    expect(c.combo, 1);
    expect(c.fallingSlices.length, 0);

    // Segundo andar perfeito
    c.debugPlace(perfect: true);
    expect(c.blocks.length, 3);
    expect(c.combo, 2);

    // Terceiro andar perfeito
    c.debugPlace(perfect: true);
    expect(c.blocks.length, 4);
    expect(c.combo, 3);
  });

  test('Corte de fatia reduz tamanho da base e gera fatia caindo', () {
    final c = TowerController(store: store, feedback: feedback);

    // Coloca com offset de 0.6 tiles (parcial)
    c.debugPlace(perfect: false, offset: 0.6);
    expect(c.blocks.length, 2);
    expect(c.blocks.last.dx, closeTo(TowerController.baseSize - 0.6, 0.01));
    expect(c.combo, 0);
    expect(c.fallingSlices.length, 1);
    expect(c.fallingSlices.first.dx, closeTo(0.6, 0.01));
  });

  test('Erro total provoca Game Over e grava novo recorde', () {
    final c = TowerController(store: store, feedback: feedback);

    // Faz 5 andares perfeitos
    for (var i = 0; i < 5; i++) {
      c.debugPlace(perfect: true);
    }
    expect(c.blocks.length, 6); // base + 5 andares

    // Erra completamente o 6º andar
    c.debugPlace(perfect: false, offset: 8.0);
    expect(c.gameOver, isTrue);
    expect(c.playing, isFalse);
    expect(c.isNewBest, isTrue);
    expect(store.towerBestHeight, 5);
    expect(store.towerGamesPlayed, 1);
    expect(c.starsGained, greaterThan(0));
    expect(store.stars, greaterThan(0));
  });

  test('Desbloqueio no Onboarding ocorre na fase 9', () async {
    await store.setLevel(8);
    expect(Onboarding.towerUnlocked(store), isFalse);

    await store.setLevel(9);
    expect(Onboarding.towerUnlocked(store), isTrue);
  });
}
