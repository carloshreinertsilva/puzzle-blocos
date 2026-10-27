import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'ads/ad_service.dart';
import 'screens/root.dart';
import 'services/feedback.dart';
import 'services/game_auth_service.dart';
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
  final ads = AdCoordinator(DebugAdService(), store);
  final auth = GameAuthService(store);
  runApp(App(services: AppServices(store, feedback, ads, auth: auth)));
}

class AppServices {
  AppServices(this.store, this.feedback, this.ads, {GameAuthService? auth})
    : auth = auth ?? GameAuthService(store);

  final ProgressStore store;
  final GameFeedback feedback;
  final AdCoordinator ads;
  final GameAuthService auth;
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
