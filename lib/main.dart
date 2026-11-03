import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'ads/ad_service.dart';
import 'ads/admob.dart';
import 'game/game_controller.dart';
import 'screens/game_screen.dart';
import 'screens/root.dart';
import 'services/duelo_link.dart';
import 'services/analytics.dart';
import 'services/avisos.dart';
import 'services/feedback.dart';
import 'testing/test_bridge.dart';
import 'services/progress_store.dart';
import 'shop/loja_service.dart';
import 'ui/abertura.dart';
import 'ui/palette.dart';
import 'ui/typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kTestBridge) {
    // Browser tests find buttons through the accessibility tree.
    SemanticsBinding.instance.ensureSemantics();
    TestBridge.instance.install();
  }
  if (kIsWeb) {
    // The page's own loading screen (web/index.html) covers the start.
    final services = await _iniciar();
    runApp(App(services: services));
    _depoisDeAbrir(services);
  } else {
    // On the phone the opening screen shows at once and covers the loading,
    // and a failure there becomes a message instead of a frozen screen.
    runApp(const Inicio());
  }
}

/// Loads the saved progress and sets up sounds and ads.
Future<AppServices> _iniciar() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // Edge to edge on every Android, not only 15+ (where it is the default):
    // what the Play Console recommends. Every screen keeps its content in
    // the safe area (SafeArea).
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  final store = await ProgressStore.load();
  if (kTestBridge) {
    TestBridge.instance.wallet = () => store.stars;
    TestBridge.instance.store = store;
  }
  final feedback = GameFeedback(store);
  feedback.preload();
  // AdMob on Android (test ads in debug); browser tests and web debug get
  // the placeholder; anything else shows no ads at all.
  final ads = AdCoordinator(
    kTestBridge
        ? DebugAdService()
        : createAdMobService() ??
              (kDebugMode ? DebugAdService() : NoAdService()),
    store,
  );
  await store.noteFirstOpen(DateTime.now());
  final loja = kTestBridge
      ? LojaSimulada(store)
      : LojaService.play(store) ??
            (kDebugMode ? LojaSimulada(store) : SemLoja(store));
  return AppServices(store, feedback, ads, loja: loja);
}

void _depoisDeAbrir(AppServices services) {
  unawaited(services.loja.iniciar());
  unawaited(services.ads.start());
  unawaited(Analytics.start(enabled: services.store.analyticsOn));
  unawaited(Avisos.iniciar(services.store));
}

/// Shows the opening screen ([Abertura]) while the game loads, for at least
/// a moment so it doesn't just flash, then fades into the game.
class Inicio extends StatefulWidget {
  const Inicio({super.key, this.carregar = _iniciar});

  final Future<AppServices> Function() carregar;
  static const tempoMinimo = Duration(milliseconds: 900);

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  AppServices? _services;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = false);
    try {
      final resultado = await Future.wait([
        widget.carregar(),
        Future<void>.delayed(Inicio.tempoMinimo),
      ]);
      final services = resultado.first as AppServices;
      if (!mounted) return;
      setState(() => _services = services);
      _depoisDeAbrir(services);
    } catch (e, pilha) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: pilha, library: 'abertura'),
      );
      if (mounted) setState(() => _erro = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: services != null
          ? App(services: services)
          : Abertura(erro: _erro, onTentarDeNovo: _carregar),
    );
  }
}

class AppServices {
  AppServices(this.store, this.feedback, this.ads, {LojaService? loja})
    : loja = loja ?? SemLoja(store);

  final ProgressStore store;
  final GameFeedback feedback;
  final AdCoordinator ads;
  final LojaService loja;
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
      // Android App Links: a challenge link (`/duelo?s=…&p=…`) arrives as a
      // route, at start or while the game is open, and opens the match on
      // top of wherever the player is.
      onGenerateRoute: (settings) {
        final convite = DueloConvite.ler(Uri.parse(settings.name ?? ''));
        if (convite == null) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => GameScreen(
            services: services,
            mode: convite.blitz ? GameMode.blitz : GameMode.duel,
            duelSeed: convite.semente,
            duelTargetScore: convite.meta,
            duelRivalName: 'Amigo',
          ),
        );
      },
      // Any other address: just the game.
      onUnknownRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Root(services: services),
      ),
    );
  }
}
