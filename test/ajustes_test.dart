import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/core/game_session.dart';
import 'package:puzzle_blocos/core/level.dart';
import 'package:puzzle_blocos/game/game_controller.dart';
import 'package:puzzle_blocos/services/ajustes.dart';
import 'package:puzzle_blocos/services/analytics.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Recorder implements AnalyticsBackend {
  final events = <(String, Map<String, Object>)>[];

  @override
  void log(String name, Map<String, Object> params) =>
      events.add((name, params));

  @override
  Future<void> setEnabled(bool on) async {}
}

void main() {
  tearDown(() {
    Ajustes.atuais = const Ajustes();
    Analytics.use(null);
  });

  test('os ajustes de fábrica são os da política de anúncios', () {
    final a = Ajustes.de(const {});
    expect(a.anuncios.minInterval, const Duration(minutes: 6));
    expect(a.anuncios.firstLevel, 6);
    expect(a.anuncios.sessionGrace, const Duration(minutes: 5));
    expect(a.dobrarPorDia, 10);
  });

  test('um valor errado no console nunca enche o jogo de anúncios', () {
    final a = Ajustes.de(const {
      Ajustes.chaveIntervalo: 0,
      Ajustes.chaveFaseInicial: -4,
      Ajustes.chaveCarencia: 0,
      Ajustes.chaveDobrar: 999,
    });
    expect(a.intervaloAnunciosMin, 3);
    expect(a.faseDoPrimeiroAnuncio, 3);
    expect(a.carenciaSessaoMin, 2);
    expect(a.dobrarPorDia, 20);
  });

  test('o coordenador segue os ajustes atuais', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final ads = AdCoordinator(NoAdService(), store);
    expect(ads.policy.minInterval, const Duration(minutes: 6));
    Ajustes.atuais = Ajustes.de(const {Ajustes.chaveIntervalo: 4});
    expect(ads.policy.minInterval, const Duration(minutes: 4));
  });

  test('a oferta de vídeo só conta onde existe vídeo', () async {
    final recorder = _Recorder();
    Analytics.use(recorder);
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    AdCoordinator(NoAdService(), store).offered(RewardPlacement.revive);
    expect(recorder.events, isEmpty);
    AdCoordinator(
      DebugAdService(),
      store,
    ).offered(RewardPlacement.revive, {'progress': 80});
    final (nome, dados) = recorder.events.single;
    expect(nome, 'ad_offer');
    expect(dados, {'placement': 'revive', 'progress': 80});
  });

  test('a sessão conta as jogadas e o progresso da meta', () {
    final s = GameSession(LevelGenerator.build(1));
    expect(s.moves, 0);
    expect(s.goalPercent, 0);
    s.score = s.level.targetScore ~/ 2;
    expect(s.goalPercent, inInclusiveRange(1, 99));
    s.score = s.level.targetScore * 3;
    expect(s.goalPercent, lessThanOrEqualTo(100));
  });

  test('o fim de fase leva progresso, jogadas, tempo e tentativa', () async {
    final recorder = _Recorder();
    Analytics.use(recorder);
    SharedPreferences.setMockInitialValues({'level': 4});
    final store = await ProgressStore.load();
    await store.setFailStreak(4, 2);
    final game = GameController(
      store: store,
      feedback: GameFeedback(store),
      mode: GameMode.levels,
    );
    game.debugWin();
    final fim = recorder.events.firstWhere((e) => e.$1 == 'level_end').$2;
    expect(fim['attempt'], 3);
    expect(fim['moves'], isA<int>());
    expect(fim['seconds'], isA<int>());
    expect(fim['progress'], inInclusiveRange(0, 100));
    game.dispose();
  });

  testWidgets('sem política própria, vale o intervalo ajustado', (t) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    Ajustes.atuais = Ajustes.de(const {Ajustes.chaveFaseInicial: 30});
    final ads = AdCoordinator(DebugAdService(), store);
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    await ads.betweenLevels(t.element(find.byType(SizedBox)), 10);
    await t.pump();
    expect(find.textContaining('Anúncio'), findsNothing);
  });
}
