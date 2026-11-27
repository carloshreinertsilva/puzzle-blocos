import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/core/presente_inicial.dart';
import 'package:puzzle_blocos/core/wardrobe.dart';
import 'package:puzzle_blocos/game/onboarding.dart';
import 'package:puzzle_blocos/main.dart';
import 'package:puzzle_blocos/screens/game_screen.dart';
import 'package:puzzle_blocos/screens/home_screen.dart';
import 'package:puzzle_blocos/services/analytics.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/ui/destaque.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Recorder implements AnalyticsBackend {
  final events = <(String, Map<String, Object>)>[];

  @override
  void log(String name, Map<String, Object> params) =>
      events.add((name, params));

  @override
  Future<void> setEnabled(bool on) async {}
}

Future<AppServices> _servicos(Map<String, Object> salvo) async {
  SharedPreferences.setMockInitialValues(salvo);
  final store = await ProgressStore.load();
  return AppServices(
    store,
    GameFeedback(store),
    AdCoordinator(NoAdService(), store),
  );
}

/// A few frames: the menu has endless animations (no pumpAndSettle).
Future<void> _passa(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _vila = 'Com as estrelas das fases você constrói a minha vila!';

void main() {
  late _Recorder analytics;
  setUp(() => Analytics.use(analytics = _Recorder()));
  tearDown(() => Analytics.use(null));

  List<String> eventos(String nome) => [
    for (final (n, p) in analytics.events)
      if (n == nome) '$p',
  ];

  testWidgets('o tutorial leva direto ao menu, com o guia (sem as fases '
      'emendadas)', (tester) async {
    final services = await _servicos({});
    await tester.pumpWidget(App(services: services));
    await _passa(tester);
    expect(find.byType(GameScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Pular tutorial'));
    await _passa(tester);
    await tester.tap(find.text('Bora!'));
    await _passa(tester);

    expect(find.byType(GameScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(Destaque), findsOneWidget);
    expect(find.text(_vila), findsOneWidget);
    expect(eventos('tutorial_complete'), hasLength(1));
    expect(services.store.hasSeen('menu'), isTrue);
  });

  testWidgets('guia: três passos, presente uma vez, e nunca mais', (
    tester,
  ) async {
    final services = await _servicos({'seen_tutorial': true});
    final store = services.store;
    await tester.pumpWidget(App(services: services));
    await _passa(tester);

    // Step 1: the village.
    expect(find.text(_vila), findsOneWidget);
    expect(store.hasSeen(Onboarding.guiaVisto), isTrue);
    expect(store.unlockedHats, contains(PresenteInicial.itemId));
    expect(eventos('presente_inicial'), ['{item: oculos_sol}']);

    // Step 2: the wardrobe, with the gift on Capi.
    await tester.tap(find.text('Continuar'));
    await _passa(tester);
    expect(
      find.text(
        'Um presente pra você: Óculos de Sol! No Guarda-Roupa você me veste '
        'do seu jeito.',
      ),
      findsOneWidget,
    );
    expect(store.equippedIn(Slot.rosto), PresenteInicial.itemId);

    // Step 3: the level button. A tap anywhere ends the guide.
    await tester.tap(find.text('Continuar'));
    await _passa(tester);
    expect(find.text('Vamos para a fase 1?'), findsOneWidget);
    await tester.tapAt(const Offset(20, 300));
    await _passa(tester);
    expect(find.byType(Destaque), findsNothing);

    expect(eventos('guia_menu_passo'), [
      '{passo: 1}',
      '{passo: 2}',
      '{passo: 3}',
    ]);
    expect(eventos('guia_menu_fim'), hasLength(1));
    expect(eventos('guia_menu_pulado'), isEmpty);

    // The next time the menu opens there is no guide and no second gift.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(App(services: services));
    await _passa(tester);
    expect(find.byType(Destaque), findsNothing);
    expect(await PresenteInicial.dar(store), isNull);
    expect(eventos('presente_inicial'), hasLength(1));
  });

  testWidgets('pular no primeiro passo: o presente vem assim mesmo', (
    tester,
  ) async {
    final services = await _servicos({'seen_tutorial': true});
    final store = services.store;
    await tester.pumpWidget(App(services: services));
    await _passa(tester);
    expect(find.text(_vila), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Pular'));
    await _passa(tester);
    expect(find.byType(Destaque), findsNothing);
    expect(eventos('guia_menu_pulado'), ['{passo: 1}']);
    expect(eventos('guia_menu_fim'), isEmpty);
    expect(store.unlockedHats, contains(PresenteInicial.itemId));
    expect(store.equippedIn(Slot.rosto), PresenteInicial.itemId);
    expect(Onboarding.guiaPendente(store), isFalse);
    // Let the gift's card leave.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('quem já conhecia o menu não vê o guia', (tester) async {
    final services = await _servicos({
      'seen_tutorial': true,
      'seen_menu': true,
      'seen_news_welcome': true,
      'level': 4,
    });
    await tester.pumpWidget(App(services: services));
    await _passa(tester);
    expect(find.byType(Destaque), findsNothing);
    expect(eventos('guia_menu_passo'), isEmpty);
    expect(services.store.unlockedHats, isNot(contains('oculos_sol')));
  });

  test('o presente é um item comum de estrelas, nunca pago nem do Passe', () {
    final c = PresenteInicial.item;
    expect(c.fonte, isA<Estrelas>());
    expect(c.raridade, Raridade.comum);
  });

  test('o presente não troca o que o Capi já usa no rosto', () async {
    SharedPreferences.setMockInitialValues({
      'unlockedHats': ['bigode'],
    });
    final store = await ProgressStore.load();
    await Wardrobe.equip(store, Wardrobe.byId('bigode')!);
    expect(await PresenteInicial.dar(store), isNotNull);
    await PresenteInicial.vestir(store);
    expect(store.equippedIn(Slot.rosto), 'bigode');
    expect(await PresenteInicial.dar(store), isNull);
  });
}
