import 'analytics_stub.dart'
    if (dart.library.io) 'analytics_firebase.dart'
    as impl;

/// Where usage statistics go.
abstract interface class AnalyticsBackend {
  void log(String name, Map<String, Object> params);
  Future<void> setEnabled(bool on);
}

/// Usage statistics: which modes people play, where they give up, how often
/// they come back. Firebase Analytics on Android once it is configured (see
/// `firebase_config.dart`); elsewhere, and while the player has statistics
/// turned off, events go nowhere. Never anything personal: no name, no
/// e-mail, no location.
abstract final class Analytics {
  static AnalyticsBackend? _backend;

  /// Events from before [start] is done: the first screen (the tutorial,
  /// on a first open) shows while Firebase is still starting.
  static List<(String, Map<String, Object>)>? _espera = [];
  static const maxEspera = 50;

  /// Firebase on Android when configured, otherwise nothing. The events
  /// that waited go out once statistics are on (and are dropped when the
  /// player turned them off).
  static Future<void> start({
    required bool enabled,
    Future<AnalyticsBackend?> Function() criar = impl.createFirebaseBackend,
  }) async {
    final backend = await criar();
    if (backend != null) {
      await backend.setEnabled(enabled);
      use(backend);
    }
    final fila = _espera ?? const [];
    _espera = null;
    if (!enabled) return;
    for (final (nome, dados) in fila) {
      _backend?.log(nome, dados);
    }
  }

  /// Back to the first open (for tests).
  static void reiniciarEspera() => _espera = [];

  static void use(AnalyticsBackend? backend) => _backend = backend;

  /// Whether statistics go anywhere (the settings only offer the switch
  /// then).
  static bool get active => _backend != null;

  static Future<void> setEnabled(bool on) async => _backend?.setEnabled(on);

  static void event(String name, [Map<String, Object> params = const {}]) {
    final backend = _backend;
    if (backend != null) {
      backend.log(name, params);
      return;
    }
    final fila = _espera;
    if (fila != null && fila.length < maxEspera) fila.add((name, params));
  }
}
