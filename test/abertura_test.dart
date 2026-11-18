import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/main.dart';
import 'package:puzzle_blocos/screens/game_screen.dart';
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

  testWidgets('a challenge link that arrives during the opening opens after '
      'it (iPhone)', (tester) async {
    final services = await _servicos();
    await tester.pumpWidget(Inicio(carregar: () async => services));
    expect(find.byType(Abertura), findsOneWidget);
    // iOS sends the Universal Link as soon as the first frame shows; if the
    // app answers "not handled", iOS opens it in Safari instead.
    bool? tratado;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(
        const MethodCall('pushRouteInformation', {
          'location': 'https://capiblocks.vercel.app/duelo?s=42&p=1500&n=Ana',
        }),
      ),
      (resposta) =>
          tratado = const JSONMethodCodec().decodeEnvelope(resposta!) as bool,
    );
    await tester.pump();
    expect(tratado, isTrue);
    await tester.pump(Inicio.tempoMinimo);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    final jogo = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(jogo.duelSeed, 42);
    expect(jogo.duelTargetScore, 1500);
    expect(jogo.duelRivalName, 'Ana');
  });

  test('a link becomes the route MaterialApp would open', () {
    expect(
      rotaDoLink(Uri.parse('https://capiblocks.vercel.app/duelo?s=7&p=900')),
      '/duelo?s=7&p=900',
    );
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

  testWidgets('the loading bar waits near the end, then fills when ready', (
    tester,
  ) async {
    final pronto = ValueNotifier(false);
    await tester.pumpWidget(Abertura(pronto: pronto));
    expect(find.text('Carregando'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('90%'), findsOneWidget);
    pronto.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('100%'), findsOneWidget);
  });
}
