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

  test('Erro total provoca Game Over e grava novo recorde', () async {
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
    await pumpEventQueue();
    expect(c.starsGained, greaterThan(0));
    expect(store.stars, greaterThan(0));
  });

  test('Corte que deixa pouco bloco é "por um fio" e treme a tela', () {
    final c = TowerController(store: store, feedback: feedback);
    c.debugPlace(perfect: false, offset: 0.6);
    expect(c.fx.last.kind, TowerFxKind.cut);
    // O segundo bloco vem pelo outro eixo (3.0 de lado): sobra 1/3 dele.
    c.debugPlace(perfect: false, offset: 2.0);
    expect(c.fx.last.kind, TowerFxKind.closeCall);
    expect(c.shake, 1);
    expect(c.blocks.last.dy, closeTo(1.0, 0.01));
    expect(c.tense, isTrue);
  });

  test('O bloco cortado fica onde caiu, e a fatia cai do lado certo', () {
    final c = TowerController(store: store, feedback: feedback);
    final base = c.blocks.first;
    c.debugPlace(perfect: false, offset: -0.5);
    // Passou para a esquerda: o bloco fica alinhado à base e a sobra, antes.
    expect(c.blocks.last.x, closeTo(base.x, 0.001));
    expect(c.fallingSlices.single.x, closeTo(base.x - 0.5, 0.001));
    expect(c.fallingSlices.single.vx, lessThan(0));
  });

  test('Zonas: a cada marco o céu muda e o Capi comemora', () {
    final c = TowerController(store: store, feedback: feedback);
    expect(c.zone.name, 'Vila do Capi');
    expect(c.nextZone!.floor, 10);
    for (var i = 0; i < 10; i++) {
      c.debugPlace(perfect: true);
    }
    expect(c.floors, 10);
    expect(c.zone.name, 'Nuvens');
    expect(
      c.fx.where((e) => e.kind == TowerFxKind.zone).single.zone!.floor,
      10,
    );
    expect(c.fever, isTrue);
    expect(TowerController.zoneAt(61).name, 'Lua');
  });

  test('Passar do recorde comemora na hora, uma vez só', () async {
    await store.recordTowerHeight(3);
    final c = TowerController(store: store, feedback: feedback);
    expect(c.recordToBeat, 3);
    for (var i = 0; i < 3; i++) {
      c.debugPlace(perfect: true);
    }
    expect(c.recordBeaten, isFalse, reason: 'empatou, ainda não passou');
    c.debugPlace(perfect: true);
    c.debugPlace(perfect: true);
    expect(c.recordBeaten, isTrue);
    expect(c.fx.where((e) => e.kind == TowerFxKind.record).length, 1);
  });

  test(
    'Continuar: uma vez por subida, e as estrelas não contam em dobro',
    () async {
      final c = TowerController(store: store, feedback: feedback);
      for (var i = 0; i < 4; i++) {
        c.debugPlace(perfect: true);
      }
      c.debugPlace(perfect: false, offset: 8.0);
      expect(c.canContinue, isFalse, reason: 'só a partir de 5 andares');

      c.reset();
      for (var i = 0; i < 5; i++) {
        c.debugPlace(perfect: true);
      }
      c.debugPlace(perfect: false, offset: 8.0);
      await pumpEventQueue();
      expect(c.canContinue, isTrue);
      expect(c.starsGained, 1);
      final jogos = store.towerGamesPlayed;

      expect(c.continueClimb(), isTrue);
      expect(c.gameOver, isFalse);
      expect(c.floors, 5);
      expect(c.fallingSlices, isEmpty);
      for (var i = 0; i < 5; i++) {
        c.debugPlace(perfect: true);
      }
      c.debugPlace(perfect: false, offset: 8.0);
      await pumpEventQueue();
      expect(c.floors, 10);
      // 10 andares valem 3 estrelas no total: 1 já tinha sido dada.
      expect(c.starsGained, 3);
      expect(store.stars, 3);
      expect(store.towerGamesPlayed, jogos, reason: 'a mesma subida');
      expect(store.towerBestHeight, 10);
      expect(c.canContinue, isFalse, reason: 'só uma vez');
      expect(c.continueClimb(), isFalse);
    },
  );

  test('Desbloqueio no Onboarding ocorre na fase 9', () async {
    await store.setLevel(8);
    expect(Onboarding.towerUnlocked(store), isFalse);

    await store.setLevel(9);
    expect(Onboarding.towerUnlocked(store), isTrue);
  });
}
