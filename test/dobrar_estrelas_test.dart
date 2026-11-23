import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/main.dart';
import 'package:puzzle_blocos/screens/tower_screen.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/testing/test_bridge.dart';
import 'package:puzzle_blocos/tower/roleta.dart';
import 'package:puzzle_blocos/tower/tower_controller.dart';
import 'package:puzzle_blocos/ui/dobrar_estrelas.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rewarded videos that exist, and that the player watches to the end (or
/// not, with [assiste] false).
class _VideoDeTeste implements AdService {
  bool assiste = true;
  final pedidos = <RewardPlacement>[];

  @override
  bool get hasVideoAds => true;
  @override
  bool get privacyOptionsRequired => false;
  @override
  Future<void> start() async {}
  @override
  Future<void> showPrivacyOptions() async {}
  @override
  Future<bool> showRewarded(BuildContext context, RewardPlacement p) async {
    pedidos.add(p);
    return assiste;
  }

  @override
  Future<bool> showInterstitial(BuildContext context) async => false;
}

void main() {
  late ProgressStore store;
  late _VideoDeTeste video;
  late AppServices services;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'level': 12, 'seen_menu': true});
    store = await ProgressStore.load();
    video = _VideoDeTeste();
    services = AppServices(
      store,
      GameFeedback(store),
      AdCoordinator(video, store),
    );
  });

  testWidgets('dobrar: só com vídeo, estrelas ganhas e dentro do limite', (
    tester,
  ) async {
    expect(DobrarEstrelas.pode(services, 2), isTrue);
    expect(DobrarEstrelas.pode(services, 0), isFalse);
    final semVideo = AppServices(
      store,
      GameFeedback(store),
      AdCoordinator(NoAdService(), store),
    );
    expect(DobrarEstrelas.pode(semVideo, 2), isFalse);
    for (var i = 0; i < 10; i++) {
      await store.addVideoToday(DobrarEstrelas.chave, DateTime.now());
    }
    expect(DobrarEstrelas.pode(services, 2), isFalse, reason: 'limite do dia');
  });

  testWidgets('dobrar dá as estrelas de novo só com o vídeo até o fim', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    video.assiste = false;
    expect(await DobrarEstrelas.dobrar(ctx, services, 3, modo: 'blitz'), false);
    expect(store.stars, 0);
    expect(store.videosToday(DobrarEstrelas.chave, DateTime.now()), 0);

    video.assiste = true;
    expect(await DobrarEstrelas.dobrar(ctx, services, 3, modo: 'blitz'), true);
    expect(store.stars, 3);
    expect(store.videosToday(DobrarEstrelas.chave, DateTime.now()), 1);
    expect(video.pedidos, everyElement(RewardPlacement.doubleStars));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('o botão de dobrar vira o aviso das estrelas dobradas', (
    tester,
  ) async {
    Widget tela(BotaoDobrar b) => MaterialApp(home: Scaffold(body: b));
    await tester.pumpWidget(tela(const BotaoDobrar(estrelas: 2)));
    expect(find.byType(Text), findsNothing);
    await tester.pumpWidget(tela(BotaoDobrar(estrelas: 2, onDobrar: () {})));
    expect(find.text('Dobrar: +2 com vídeo'), findsOneWidget);
    await tester.pumpWidget(tela(const BotaoDobrar(estrelas: 2, dobradas: 2)));
    expect(find.text('Estrelas dobradas: +2!'), findsOneWidget);
  });

  group('Torre: roleta do bônus no fim da subida', () {
    Future<void> abrirECair(WidgetTester tester, {int andares = 6}) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: TowerScreen(services: services)),
      );
      await tester.pump();
      final t = TestBridge.instance.tower!;
      for (var i = 0; i < andares; i++) {
        t.debugPlace(perfect: true);
      }
      t.debugPlace(perfect: false, offset: 9);
      // The card waits for the camera (2.1 s of the tower's clock).
      for (var i = 0; i < 70; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('roleta, Continuar, Subir de Novo e Menu cabem na tela', (
      tester,
    ) async {
      await abrirECair(tester);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Roleta do bônus do vídeo'), findsOneWidget);
      for (final nome in [
        'Continuar a subida vendo um vídeo',
        'Subir de Novo',
        'Voltar ao Menu',
        'Dobrar: +1 com vídeo',
      ]) {
        final f = find.bySemanticsLabel(nome);
        expect(f, findsOneWidget, reason: nome);
        final r = tester.getRect(f);
        expect(r.top, greaterThanOrEqualTo(0), reason: nome);
        expect(r.bottom, lessThanOrEqualTo(640), reason: nome);
        expect(r.height, greaterThanOrEqualTo(44), reason: '$nome: toque');
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('sem o vídeo até o fim, nada acontece e a seta volta a andar', (
      tester,
    ) async {
      await abrirECair(tester);
      final t = TestBridge.instance.tower!;
      video.assiste = false;
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(t.gameOver, isTrue);
      expect(t.continued, isFalse);
      expect(t.wheelStoppedAt, isNull, reason: 'a roleta pode ser usada');
      expect(t.blocks.last.dx, TowerController.baseSize);
    });

    testWidgets('com o vídeo, a subida continua com o bônus em que parou', (
      tester,
    ) async {
      await abrirECair(tester);
      final t = TestBridge.instance.tower!;
      final esperado = t.wheelFactor;
      video.assiste = true;
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(t.gameOver, isFalse);
      expect(t.continueFactor, esperado);
      expect(video.pedidos, [RewardPlacement.revive]);
      expect(Roleta.multiplicadores, contains(t.continueFactor));
      // The top block was already as big as the base: it stays at most that.
      expect(t.blocks.last.dx, lessThanOrEqualTo(TowerController.baseSize));
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
