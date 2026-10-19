import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/ad_service.dart';
import 'screens/home_screen.dart';
import 'services/feedback.dart';
import 'services/progress_store.dart';
import 'ui/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = await ProgressStore.load();
  final feedback = GameFeedback(store);
  feedback.preload();
  final ads = AdCoordinator(DebugAdService(), store);
  runApp(App(services: AppServices(store, feedback, ads)));
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
        useMaterial3: true,
      ),
      home: HomeScreen(services: services),
    );
  }
}
