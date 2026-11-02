import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/main.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/ui/abertura.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppServices> _servicos() async {
  SharedPreferences.setMockInitialValues({'level': 7, 'seen_menu': true});
  final store = await ProgressStore.load();
  return AppServices(
    store,
    GameFeedback(store),
    AdCoordinator(NoAdService(), store),
  );
}

void main() {
  testWidgets('the opening screen shows while loading, then the game', (
    tester,
  ) async {
    final services = await _servicos();
    await tester.pumpWidget(Inicio(carregar: () async => services));
    expect(find.byType(Abertura), findsOneWidget);
    expect(find.text('CapiBlocks'), findsOneWidget);
    // Stays at least a moment, even when loading is instant.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(App), findsNothing);
    await tester.pump(Inicio.tempoMinimo);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(App), findsOneWidget);
    expect(find.byType(Abertura), findsNothing);
  });

  testWidgets('a loading failure offers to try again instead of hanging', (
    tester,
  ) async {
    final services = await _servicos();
    var tentativas = 0;
    await tester.pumpWidget(
      Inicio(
        carregar: () async {
          tentativas++;
          if (tentativas == 1) throw StateError('falhou');
          return services;
        },
      ),
    );
    await tester.pump(Inicio.tempoMinimo);
    await tester.pump();
    expect(tester.takeException(), isA<StateError>());
    expect(find.text('Ops! O jogo não conseguiu abrir.'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    await tester.pump(Inicio.tempoMinimo);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tentativas, 2);
    expect(find.byType(App), findsOneWidget);
  });
}
