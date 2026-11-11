import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'ajustes.dart';
import 'firebase_app.dart';

/// The oldest build allowed to play (0: none is required).
const chaveVersaoMinima = 'versao_minima';

Future<FirebaseRemoteConfig?>? _config;

/// Remote Config, set up once with every default. Null without Firebase.
Future<FirebaseRemoteConfig?> configRemota() => _config ??= () async {
  try {
    if (!await firebasePronto()) return null;
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await rc.setDefaults(const {...Ajustes.padroes, chaveVersaoMinima: 0});
    return rc;
  } catch (_) {
    // A broken setup must never stop the game.
    return null;
  }
}();

Future<Map<String, int>?> lerAjustes() async {
  final rc = await configRemota();
  if (rc == null) return null;
  try {
    await rc.activate();
    // For the next time the app opens: values stay put during a session.
    unawaited(rc.fetch().catchError((_) {}));
    return {for (final chave in Ajustes.padroes.keys) chave: rc.getInt(chave)};
  } catch (_) {
    return null;
  }
}
