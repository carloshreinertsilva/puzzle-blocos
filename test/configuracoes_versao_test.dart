import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/main.dart';
import 'package:puzzle_blocos/screens/settings_sheet.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Settings show the installed version, not a written one', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'CapiBlocks',
      packageName: 'com.capiblocks.app',
      version: '9.8.7',
      buildNumber: '99',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({'level': 7, 'seen_menu': true});
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
    // The list is built as it scrolls: go down to its end.
    final versao = find.text('CapiBlocks v9.8.7 · CHS TECH');
    await tester.scrollUntilVisible(
      versao,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(versao, findsOneWidget);
    expect(find.textContaining('v1.10.0'), findsNothing);
  });
}
