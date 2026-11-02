import 'package:firebase_core/firebase_core.dart';

/// The Firebase project for usage statistics (Android app
/// `com.capiblocks.app`). Values come from the Firebase console, in the
/// app's `google-services.json`; while they are empty, statistics are off.
/// These are identifiers, not secrets: they ship inside every app.
abstract final class FirebaseConfig {
  static const _apiKey = 'AIzaSyB7HOQ_WL6Lv66YooFWmX2ls2jNhpZLe7M';
  static const _appId = '1:731810631964:android:64bfa0dded5ad8eb4e6ad9';
  static const _messagingSenderId = '731810631964';
  static const _projectId = 'capiblocks';

  static bool get ready =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static const android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
  );
}
