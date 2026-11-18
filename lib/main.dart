import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'ads/ad_service.dart';
import 'ads/admob.dart';
import 'game/game_controller.dart';
import 'core/convites.dart';
import 'core/wardrobe.dart';
import 'l10n/idioma.dart';
import 'screens/convites_sheet.dart';
import 'screens/game_screen.dart';
import 'screens/root.dart';
import 'services/duelo_link.dart';
import 'services/analytics.dart';
import 'services/avisos.dart';
import 'services/config_remota.dart';
import 'services/feedback.dart';
import 'services/musica.dart';
import 'services/sound/music_player.dart';
import 'services/convites_servidor.dart';
import 'services/duelos_servidor.dart';
import 'services/firebase_config.dart';
import 'services/placares.dart';
import 'services/ranking_servidor.dart';
import 'testing/test_bridge.dart';
import 'services/progress_store.dart';
import 'shop/loja_service.dart';
import 'ui/abertura.dart';
import 'ui/capi_arte.dart';
import 'ui/palette.dart';
import 'ui/typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The phone's language until the saved choice is read (the opening
  // screen shows before that).
  Lingua.atual.value = escolherIdioma('auto');
  if (kTestBridge) {
    // Browser tests find buttons through the accessibility tree.
    SemanticsBinding.instance.ensureSemantics();
    TestBridge.instance.install();
  }
  Placares.ativo =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (ConvitesServidor.ativo) RankingServidor.atual = RankingFirebase();
  if (kTestBridge) RankingServidor.atual = TestBridge.instance.ranking;
  // Duels also on the web: a friend often answers in the browser.
  if (ConvitesServidor.ativo || FirebaseConfig.web != null) {
    DuelosServidor.atual = DuelosFirebase();
  }
  if (kTestBridge) DuelosServidor.atual = TestBridge.instance.duelos;
  CapiArte.ativa = true;
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
  Lingua.atual.value = escolherIdioma(store.idioma);
  if (kTestBridge) {
    TestBridge.instance.wallet = () => store.stars;
    TestBridge.instance.store = store;
  }
  final look = CapiLook.of(store);
  unawaited(
    CapiArte.preparar(look.pelagem, [
      look.hat.id,
      look.rosto,
      look.pescoco,
      look.costas,
    ]),
  );
  final feedback = GameFeedback(
    store,
    // Browser tests run without music (less to load, nothing to wait on).
    musica: Musica(store, player: kTestBridge ? null : MusicPlayer()),
  );
  feedback.preload();
  // AdMob on Android and iOS (test ads in debug); browser tests and web debug get
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

/// The game's language: the one picked in the settings, else the phone's.
/// Browser tests run in Portuguese unless a language was picked (or the
/// address asks for one: `?lang=en`, `?lang=es`).
Idioma escolherIdioma(String salvo) {
  for (final i in Idioma.values) {
    if (i.name == salvo) return i;
  }
  if (kTestBridge) {
    final pedido = Uri.base.queryParameters['lang'];
    return pedido == null ? Idioma.pt : Idioma.doCelular(pedido);
  }
  return Idioma.doCelular(PlatformDispatcher.instance.locale.languageCode);
}

void _depoisDeAbrir(AppServices services) {
  unawaited(services.loja.iniciar());
  unawaited(services.ads.start());
  unawaited(Analytics.start(enabled: services.store.analyticsOn));
  unawaited(Avisos.iniciar(services.store));
  unawaited(ConfigRemota.iniciar());
  unawaited(Placares.iniciar(services.store));
}

/// The route name for a link, as MaterialApp makes it when it opens one.
@visibleForTesting
String rotaDoLink(Uri uri) => Uri.decodeComponent(
  Uri(
    path: uri.path.isEmpty ? '/' : uri.path,
    queryParameters: uri.queryParametersAll.isEmpty
        ? null
        : uri.queryParametersAll,
    fragment: uri.fragment.isEmpty ? null : uri.fragment,
  ).toString(),
);

/// Shows the opening screen ([Abertura]) while the game loads, for at least
/// a moment so it doesn't just flash, then fades into the game.
class Inicio extends StatefulWidget {
  const Inicio({super.key, this.carregar = _iniciar});

  final Future<AppServices> Function() carregar;
  static const tempoMinimo = Duration(milliseconds: 1600);

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> with WidgetsBindingObserver {
  AppServices? _services;
  bool _erro = false;
  final _pronto = ValueNotifier(false);

  /// A link that arrived while the opening screen was still up.
  String? _linkPendente;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pronto.dispose();
    super.dispose();
  }

  /// On the iPhone a challenge link (Universal Link) reaches the app as soon
  /// as the opening screen shows, before the game has a navigator. If nobody
  /// takes it, iOS hands the link to Safari and the challenge is lost; so it
  /// waits here and opens once the game is up. After that, the game's own
  /// navigator (MaterialApp) takes links.
  @override
  Future<bool> didPushRouteInformation(RouteInformation informacao) async {
    if (App.navegador.currentState != null) return false;
    _linkPendente = rotaDoLink(informacao.uri);
    return true;
  }

  void _abrirLinkPendente() {
    final rota = _linkPendente;
    if (rota == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navegador = App.navegador.currentState;
      if (navegador == null || _linkPendente != rota) return;
      _linkPendente = null;
      navegador.pushNamed(rota);
    });
  }

  /// The opening art, decoded before the clock starts, so it always shows
  /// (tests keep the code-drawn Capi and skip it).
  Future<void>? _arte;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arte != null) return;
    _arte = CapiArte.ativa
        ? precacheImage(
            const AssetImage(Abertura.imagem),
            context,
          ).timeout(const Duration(seconds: 3), onTimeout: () {})
        : Future<void>.value();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = false);
    _pronto.value = false;
    try {
      final resultado = await Future.wait([
        widget.carregar(),
        _arte!.then((_) => Future<void>.delayed(Inicio.tempoMinimo)),
      ]);
      final services = resultado.first as AppServices;
      if (!mounted) return;
      // The bar runs to the end while the game fades in.
      _pronto.value = true;
      setState(() => _services = services);
      _abrirLinkPendente();
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
          : Abertura(erro: _erro, onTentarDeNovo: _carregar, pronto: _pronto),
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

  /// Bumped to start the game over from the saved progress (after a cloud
  /// save replaced it).
  static final reinicio = ValueNotifier(0);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Idioma>(
    // A new language rebuilds the whole game in it.
    valueListenable: Lingua.atual,
    builder: (context, idioma, _) => ValueListenableBuilder<int>(
      valueListenable: reinicio,
      builder: (context, n, _) =>
          KeyedSubtree(key: ValueKey('$idioma/$n'), child: _app(context)),
    ),
  );

  /// The app's navigator (the test bridge opens links through it).
  static final navegador = GlobalKey<NavigatorState>();

  Widget _app(BuildContext context) {
    if (kTestBridge) {
      TestBridge.instance.abrirRota = (rota) =>
          navegador.currentState?.pushNamed(rota);
    }
    // A duel notification opens its challenge over wherever the player is.
    Avisos.abrir = (rota) => navegador.currentState?.pushNamed(rota);
    return MaterialApp(
      navigatorKey: navegador,
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
        final endereco = Uri.parse(settings.name ?? '');
        // An invite link (`/convite?c=…`): the welcome gift over the game.
        final codigo = Convites.lerLink(endereco);
        if (codigo != null) return rotaConviteRecebido(services, codigo);
        final convite = DueloConvite.ler(endereco);
        if (convite == null) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => GameScreen(
            services: services,
            mode: convite.blitz ? GameMode.blitz : GameMode.duel,
            duelSeed: convite.semente,
            duelTargetScore: convite.meta,
            duelRivalName: convite.nome ?? tr('Amigo'),
            dueloId: convite.id,
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
