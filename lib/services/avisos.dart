import 'package:flutter/widgets.dart';

import 'avisos_stub.dart' if (dart.library.io) 'avisos_android.dart' as impl;
import 'progress_store.dart';

/// Notifications:
/// - reminders scheduled on the phone (opt-in, no server), on Android and
///   iPhone: what the player has waiting (core/lembretes.dart);
///
/// and on Android only (the iPhone would need push from Apple's servers):
/// - messages sent from the Firebase console (news, a new version), free;
/// - duels: a friend answered a challenge or challenged back
///   (services/duelo_aviso.dart);
/// - Google Play's "update available" offer inside the game.
abstract final class Avisos {
  /// Whether this platform has the daily reminders (Android and iPhone).
  static bool get lembretesSuportados => impl.lembretesSuportados;

  /// Whether this platform has the rest: Firebase messages, duels'
  /// notifications and the in-game update (Android only).
  static bool get mensagensSuportadas => impl.mensagensSuportadas;

  /// Starts messages and, if the player wants them, re-schedules the
  /// reminders from tomorrow (opening the game today pushes them on; so
  /// does leaving it, with the texts of what is waiting by then).
  static Future<void> iniciar(ProgressStore store) => impl.iniciar(store);

  /// Asks for permission (Android 13+, iPhone) and turns reminders on or
  /// off.
  /// Returns whether reminders are on.
  static Future<bool> lembretes(ProgressStore store, bool ligar) =>
      impl.lembretes(store, ligar);

  /// Asks Android for permission (13+) to show notifications, when the
  /// player starts or answers a duel: the friend's answer comes as one.
  static Future<void> pedirParaDuelos() => impl.pedirParaDuelos();

  /// Opens a game route (`/duelo?…`) from a tapped notification. Set by
  /// the app, which owns the navigator.
  static void Function(String rota)? abrir;

  /// Offers a new version from Google Play each time the game opens; a
  /// version below the minimum set in Firebase must be updated to play.
  static Future<void> verificarAtualizacao(
    BuildContext context,
    ProgressStore store,
  ) => impl.verificarAtualizacao(context, store);
}
