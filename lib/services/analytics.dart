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

  /// Firebase on Android when configured, otherwise nothing.
  static Future<void> start({required bool enabled}) async {
    final backend = await impl.createFirebaseBackend();
    if (backend != null) use(backend);
    await _backend?.setEnabled(enabled);
  }

  static void use(AnalyticsBackend? backend) => _backend = backend;

  /// Whether statistics go anywhere (the settings only offer the switch
  /// then).
  static bool get active => _backend != null;

  static Future<void> setEnabled(bool on) async => _backend?.setEnabled(on);

  static void event(String name, [Map<String, Object> params = const {}]) =>
      _backend?.log(name, params);
}
