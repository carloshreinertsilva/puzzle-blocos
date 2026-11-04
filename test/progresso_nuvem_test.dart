import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/main.dart';
import 'package:puzzle_blocos/screens/settings_sheet.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/placares.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => Placares.ativo = false);

  testWidgets('Cloud save in Settings always answers, above the sheet', (
    tester,
  ) async {
    // No Play Games here (no plugin): signing in fails, and the player must
    // see it rather than a message hidden behind the sheet.
    Placares.ativo = true;
    SharedPreferences.setMockInitialValues({
      'level': 7,
      'pgsConvites': 2,
      'seen_menu': true,
    });
    final store = await ProgressStore.load();
    final services = AppServices(
      store,
      GameFeedback(store),
      AdCoordinator(DebugAdService(), store),
    );
    await tester.pumpWidget(App(services: services));
    await tester.pump(const Duration(seconds: 1));

    unawaited(
      showSettings(tester.element(find.byType(Scaffold).first), services),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final tile = find.text('Progresso na nuvem');
    await tester.ensureVisible(tile);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(tile);
    // The plugin answers on a real platform channel: let real time pass.
    await tester.pump();
    expect(find.text('Falando com o Google Play Games…'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(
      find.text('Não deu para entrar no Play Games agora.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
