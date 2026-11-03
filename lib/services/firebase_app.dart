import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_config.dart';

Future<bool>? _pronto;

/// Starts Firebase once (statistics and messages share it). False on other
/// platforms, without a configuration, or if it fails: the game goes on.
Future<bool> firebasePronto() => _pronto ??= () async {
  if (!Platform.isAndroid || !FirebaseConfig.ready) return false;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: FirebaseConfig.android);
    }
    return true;
  } catch (_) {
    return false;
  }
}();
