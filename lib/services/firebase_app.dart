import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_config.dart';

Future<bool>? _pronto;

/// Starts Firebase once (statistics and messages share it). False on other
/// platforms, without a configuration, or if it fails: the game goes on.
Future<bool> firebasePronto() => _pronto ??= () async {
  final options = FirebaseConfig.atual;
  // Only on a real phone (flutter test says "android" too).
  if (options == null || !(Platform.isAndroid || Platform.isIOS)) {
    return false;
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
    return true;
  } catch (_) {
    return false;
  }
}();
