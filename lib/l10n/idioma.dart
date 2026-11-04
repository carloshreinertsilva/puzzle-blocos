import 'package:flutter/foundation.dart';

import 'en.dart';
import 'es.dart';

/// The languages the game speaks. Portuguese is the original: every text in
/// the code is written in it and is also its own translation key.
enum Idioma {
  pt('Português'),
  en('English'),
  es('Español');

  const Idioma(this.nome);

  /// The language's name in itself (for the settings).
  final String nome;

  /// The phone's language, or English for one the game doesn't speak.
  static Idioma doCelular(String languageCode) => switch (languageCode) {
    'pt' => Idioma.pt,
    'es' => Idioma.es,
    _ => Idioma.en,
  };
}

abstract final class Lingua {
  /// The language the game is showing. Tests and pure-Dart code start in
  /// Portuguese; `main` sets it from the settings or the phone.
  static final atual = ValueNotifier<Idioma>(Idioma.pt);

  static Idioma get idioma => atual.value;
}

/// The text [pt] (written in Portuguese, as in the code) in the current
/// language. `{name}` placeholders take the [args]. A text still missing a
/// translation falls back to English, then to the Portuguese original.
String tr(String pt, [Map<String, Object?> args = const {}]) {
  var s = switch (Lingua.idioma) {
    Idioma.pt => pt,
    Idioma.en => en[pt] ?? pt,
    Idioma.es => es[pt] ?? en[pt] ?? pt,
  };
  for (final a in args.entries) {
    s = s.replaceAll('{${a.key}}', '${a.value}');
  }
  return s;
}

/// Picks the singular or plural form of a Portuguese text by [n] (both are
/// translated as their own keys).
String trN(
  int n,
  String um,
  String varios, [
  Map<String, Object?> args = const {},
]) => tr(n == 1 ? um : varios, {'n': n, ...args});
