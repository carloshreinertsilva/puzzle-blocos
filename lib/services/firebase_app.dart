import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_config.dart';

Future<bool>? _pronto;

/// Starts Firebase once (statistics, messages, ranking, duels share it).
/// False on other platforms, without a configuration, or if it fails: the
/// game goes on. On the web only duels use it.
Future<bool> firebasePronto() => _pronto ??= () async {
  final options = FirebaseConfig.atual;
  if (options == null) return false;
  // Only on a real phone or in the browser (flutter test says "android"
  // too).
  if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) return false;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
    return true;
  } catch (_) {
    return false;
  }
}();
