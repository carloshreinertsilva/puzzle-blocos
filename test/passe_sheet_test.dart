import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/core/passe.dart';
import 'package:puzzle_blocos/main.dart';
import 'package:puzzle_blocos/screens/passe_sheet.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/shop/loja_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The game's real fonts, so text measures as on a phone.
Future<void> _fontes() async {
  for (final (familia, arquivo) in const [
    ('Lilita', 'assets/fonts/LilitaOne-Regular.ttf'),
    ('Fredoka', 'assets/fonts/Fredoka-Variable.ttf'),
  ]) {
    final bytes = File(arquivo).readAsBytesSync();
    await (FontLoader(
      familia,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

void main() {
  setUpAll(_fontes);

  for (final tela in const [Size(360, 640), Size(375, 667)]) {
    testWidgets('the Passe fits a small phone (${tela.width.toInt()}x'
        '${tela.height.toInt()}): level 1 and the purchase on screen', (
      tester,
    ) async {
      tester.view.physicalSize = tela;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      final agora = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'level': 12,
        // Level 2 of the season, as if earned by playing.
        'passPoints_${PasseDoCapi.temporada(agora)}':
            PasseDoCapi.pontosPorNivel * 2 + 5,
      });
      final store = await ProgressStore.load();
      final services = AppServices(
        store,
        GameFeedback(store),
        AdCoordinator(NoAdService(), store),
        loja: LojaSimulada(store),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => unawaited(showPasse(context, services)),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.text('Nível 2 de 30'), findsOneWidget);
      final comprar = find.bySemanticsLabel(
        RegExp(r'^Liberar a trilha premium do Passe'),
      );
      final nivel1 = find.bySemanticsLabel('Nível 1 grátis: 3 estrelas, pegar');
      for (final f in [comprar, nivel1]) {
        expect(f, findsOneWidget);
        final r = tester.getRect(f);
        expect(r.bottom, lessThanOrEqualTo(tela.height - 8), reason: '$f');
      }
      // The track shows what buying gives at once.
      expect(find.textContaining('na hora:'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Nível 1 premium: .*, bloqueado$')),
        findsOneWidget,
      );
      // Every level is built (the browser tests look them up).
      expect(
        find.bySemanticsLabel(RegExp(r'^Nível 30 grátis: ')),
        findsOneWidget,
      );
      semantics.dispose();
    });
  }
}
