import 'package:flutter/widgets.dart';

import 'avisos_stub.dart' if (dart.library.io) 'avisos_android.dart' as impl;
import 'progress_store.dart';

/// Notifications, all on Android only:
/// - daily reminders scheduled on the phone (opt-in, no server): the gift,
///   the missions, the village;
/// - messages sent from the Firebase console (news, a new version), free;
/// - Google Play's "update available" offer inside the game.
abstract final class Avisos {
  /// Whether this platform can show notifications at all.
  static bool get suportado => impl.suportado;

  /// Starts messages and, if the player wants them, re-schedules the
  /// reminders from tomorrow (opening the game today pushes them on).
  static Future<void> iniciar(ProgressStore store) => impl.iniciar(store);

  /// Asks Android for permission (13+) and turns reminders on or off.
  /// Returns whether reminders are on.
  static Future<bool> lembretes(ProgressStore store, bool ligar) =>
      impl.lembretes(store, ligar);

  /// Offers a new version from Google Play each time the game opens; a
  /// version below the minimum set in Firebase must be updated to play.
  static Future<void> verificarAtualizacao(
    BuildContext context,
    ProgressStore store,
  ) => impl.verificarAtualizacao(context, store);
}

/// The reminder texts, one per day of absence (then they stop).
const lembretesTextos = [
  ('Presente do Capi 🎁', 'Seu presente de hoje está esperando. Vem pegar!'),
  ('O Capi sentiu sua falta 🐹', 'As missões de hoje já chegaram.'),
  ('A vila espera por você', 'Volte e continue construindo a vila do Capi!'),
];
