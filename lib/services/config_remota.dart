import 'ajustes.dart';
import 'config_remota_stub.dart'
    if (dart.library.io) 'config_remota_firebase.dart'
    as impl;

/// Firebase Remote Config: the numbers in [Ajustes], changed (or A/B
/// tested) from the Firebase console without a new version. Without
/// Firebase the game keeps the values it ships with.
abstract final class ConfigRemota {
  /// Applies the values fetched the last time the app was open, then
  /// fetches new ones for the next time.
  static Future<void> iniciar() async {
    final valores = await impl.lerAjustes();
    if (valores != null) Ajustes.atuais = Ajustes.de(valores);
  }
}
