import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/main.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home shows the current level and endless mode', (tester) async {
    SharedPreferences.setMockInitialValues({'level': 7, 'bestScore': 12345});
    final store = await ProgressStore.load();
    final services = AppServices(
      store,
      GameFeedback(store),
      AdCoordinator(DebugAdService(), store),
    );
    await tester.pumpWidget(App(services: services));
    expect(find.text('Fase 7'), findsOneWidget);
    expect(find.text('Modo infinito'), findsOneWidget);
    expect(find.text('Recorde: 12.345'), findsOneWidget);
  });
}
