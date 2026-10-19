import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/main.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home shows the level road, daily challenge and endless mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'level': 7, 'bestScore': 12345});
    final store = await ProgressStore.load();
    final services = AppServices(
      store,
      GameFeedback(store),
      AdCoordinator(DebugAdService(), store),
    );
    await tester.pumpWidget(App(services: services));
    expect(find.text('Jogar · Fase 7'), findsOneWidget);
    expect(find.text('Desafio diário'), findsOneWidget);
    expect(find.text('Recorde 12.345'), findsOneWidget);
    // The level road shows the current level and the next ones.
    expect(find.text('7'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });
}
