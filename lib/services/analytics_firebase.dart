import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import 'analytics.dart';
import 'firebase_config.dart';

Future<AnalyticsBackend?> createFirebaseBackend() async {
  if (!Platform.isAndroid || !FirebaseConfig.ready) return null;
  try {
    await Firebase.initializeApp(options: FirebaseConfig.android);
    final analytics = FirebaseAnalytics.instance;
    // Statistics only: nothing feeds ad personalization.
    await analytics.setAnalyticsCollectionEnabled(false);
    await analytics.setConsent(
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
      analyticsStorageConsentGranted: true,
    );
    return _FirebaseBackend(analytics);
  } catch (_) {
    // A broken setup must never stop the game.
    return null;
  }
}

class _FirebaseBackend implements AnalyticsBackend {
  _FirebaseBackend(this._analytics);
  final FirebaseAnalytics _analytics;

  @override
  void log(String name, Map<String, Object> params) {
    _analytics.logEvent(name: name, parameters: params).ignore();
  }

  @override
  Future<void> setEnabled(bool on) =>
      _analytics.setAnalyticsCollectionEnabled(on);
}
