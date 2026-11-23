import 'dart:math';

/// The bonus wheel on the Tower's end card: a needle sweeps back and forth
/// over a half circle of five sectors, and where it stops when the player
/// taps "Continuar" is how much the top block grows after the video.
///
/// Pure and deterministic: everything follows from the seconds [t] since
/// the needle started moving, so tests (and the browser bridge) can tell
/// exactly what a tap at a given moment gives.
abstract final class Roleta {
  /// The sectors, left to right on the half circle.
  static const multiplicadores = [1.0, 1.2, 3.0, 1.5, 1.0];

  /// How much of the half circle each sector takes (they add up to 1). The
  /// 3x in the middle is the narrow one.
  static const larguras = [0.23, 0.23, 0.08, 0.23, 0.23];

  /// Seconds for the needle to go from the left end to the right end and
  /// back again.
  static const periodo = 2.0;

  /// Where the needle is at [t], from 0 (left end) to 1 (right end). It
  /// eases at the ends and is fastest in the middle, over the 3x.
  static double fracao(double t) {
    if (t <= 0) return 0;
    return (1 - cos(2 * pi * t / periodo)) / 2;
  }

  /// The needle's angle at [t], in radians: 0 points left, pi/2 straight
  /// up and pi right.
  static double angulo(double t) => fracao(t) * pi;

  /// The sector under the position [f] (0 to 1).
  static int setorEm(double f) {
    var acc = 0.0;
    for (var i = 0; i < larguras.length; i++) {
      acc += larguras[i];
      if (f < acc) return i;
    }
    return larguras.length - 1;
  }

  /// Where the sector [i] starts and ends (0 to 1).
  static (double, double) limites(int i) {
    var start = 0.0;
    for (var k = 0; k < i; k++) {
      start += larguras[k];
    }
    return (start, start + larguras[i]);
  }

  /// The bonus a tap at [t] gives.
  static double multiplicadorEm(double t) =>
      multiplicadores[setorEm(fracao(t))];

  /// "1,2x" (or "1.2x" with [virgula] false, in English).
  static String rotulo(double m, {bool virgula = true}) {
    final s = m == m.roundToDouble()
        ? m.toStringAsFixed(0)
        : m.toStringAsFixed(1);
    return '${virgula ? s.replaceAll('.', ',') : s}x';
  }

  /// The block [lado] long grown by [fator], never past [maximo] (the base
  /// block) and never smaller than it was.
  static double crescer(double lado, double fator, double maximo) =>
      max(lado, min(maximo, lado * fator));
}
