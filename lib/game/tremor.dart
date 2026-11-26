import 'dart:math';
import 'dart:ui';

/// Screen shake from a "trauma" value that decays over time.
///
/// Hits add trauma (they don't restart the shake) and the stage moves by
/// trauma squared, so a small hit barely moves it and a big one punches.
/// The path is two sines at unrelated rates: smooth, never the per-frame
/// random jump that reads as static. The offset is exactly zero once the
/// trauma is gone.
class Tremor {
  Tremor({this.queda = 2.4, this.ritmo = 34});

  /// Trauma lost per second.
  final double queda;

  /// How fast the stage swings.
  final double ritmo;

  double _trauma = 0;
  double _relogio = 0;

  double get trauma => _trauma;
  bool get parado => _trauma <= 0;

  /// Adds [quanto] (0–1) to the shake, up to 1.
  void somar(double quanto) => _trauma = min(1, _trauma + max(0, quanto));

  void parar() => _trauma = 0;

  /// Advances [dt] seconds and returns where the stage sits, at most
  /// [alcance] pixels from rest sideways (a little less up and down).
  Offset avancar(double dt, double alcance) {
    if (_trauma <= 0) return Offset.zero;
    _trauma = max(0, _trauma - queda * dt);
    if (_trauma <= 0) return Offset.zero;
    _relogio += dt * ritmo;
    final forca = _trauma * _trauma * alcance;
    return Offset(
      forca * sin(_relogio * 1.7),
      forca * 0.7 * sin(_relogio * 2.3 + 1.3),
    );
  }
}
