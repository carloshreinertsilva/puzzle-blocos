<<<<<<< HEAD
import 'dart:async';

=======
>>>>>>> fba42f5 (v1.0.1: sem anúncios de teste nem nuvem simulada na versão publicada (#18))
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'ads/ad_service.dart';
import 'ads/admob.dart';
import 'screens/root.dart';
import 'services/analytics.dart';
import 'services/feedback.dart';
import 'testing/test_bridge.dart';
import 'services/progress_store.dart';
import 'ui/palette.dart';
import 'ui/typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kTestBridge) {
    // Browser tests find buttons through the accessibility tree.
    SemanticsBinding.instance.ensureSemantics();
    TestBridge.instance.install();
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = await ProgressStore.load();
  if (kTestBridge) {
    TestBridge.instance.wallet = () => store.stars;
    TestBridge.instance.store = store;
  }
  final feedback = GameFeedback(store);
  feedback.preload();
<<<<<<< HEAD
  // AdMob on Android (test ads in debug); browser tests and web debug get
  // the placeholder; anything else shows no ads at all.
  final ads = AdCoordinator(
    kTestBridge
        ? DebugAdService()
        : createAdMobService() ??
              (kDebugMode ? DebugAdService() : NoAdService()),
    store,
  );
  runApp(App(services: AppServices(store, feedback, ads)));
  unawaited(ads.start());
  unawaited(Analytics.start(enabled: store.analyticsOn));
=======
  // No real ad network yet: release builds show no ads (never the test
  // placeholder).
  final ads = AdCoordinator(
    kDebugMode || kTestBridge ? DebugAdService() : NoAdService(),
    store,
  );
  runApp(App(services: AppServices(store, feedback, ads)));
>>>>>>> fba42f5 (v1.0.1: sem anúncios de teste nem nuvem simulada na versão publicada (#18))
}

class AppServices {
  AppServices(this.store, this.feedback, this.ads);

  final ProgressStore store;
  final GameFeedback feedback;
  final AdCoordinator ads;
}

class App extends StatelessWidget {
  const App({super.key, required this.services});
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Palette.bgTop,
        fontFamily: Fonts.body,
        useMaterial3: true,
      ),
      home: Root(services: services),
    );
  }
}
