import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// The Firebase project `capiblocks` (statistics and messages), one app per
/// platform. Values come from the Firebase console: `google-services.json`
/// for Android, `GoogleService-Info.plist` for iOS (API_KEY and
/// GOOGLE_APP_ID). While a platform's are empty, Firebase is off there.
/// These are identifiers, not secrets: they ship inside every app.
abstract final class FirebaseConfig {
  static const _messagingSenderId = '731810631964';
  static const _projectId = 'capiblocks';

  static const _androidApiKey = 'AIzaSyB7HOQ_WL6Lv66YooFWmX2ls2jNhpZLe7M';
  static const _androidAppId = '1:731810631964:android:64bfa0dded5ad8eb4e6ad9';

  static const _iosApiKey = 'AIzaSyApIIYuMQPDxJLcnqcBZCMH4Vcoi5kGi4E';
  static const _iosAppId = '1:731810631964:ios:289078f5983e2ad44e6ad9';
  static const _iosBundleId = 'com.capiblocks.app';

  static const android = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: _androidAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
  );

  static const ios = FirebaseOptions(
    apiKey: _iosApiKey,
    appId: _iosAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    iosBundleId: _iosBundleId,
  );

  /// This platform's app, or null where Firebase is off (web, desktop, or
  /// a platform not configured yet).
  static FirebaseOptions? get atual {
    if (kIsWeb) return null;
    final opcoes = switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
    if (opcoes == null || opcoes.apiKey.isEmpty || opcoes.appId.isEmpty) {
      return null;
    }
    return opcoes;
  }
}
