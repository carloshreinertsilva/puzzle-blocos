import '../ads/ad_policy.dart';

/// Numbers that can change without a new version: they come from Firebase
/// Remote Config (`config_remota.dart`, `docs/ajustes-remotos.md`), which
/// also runs A/B tests on them. Every value is clamped to a safe range, so
/// a typo in the console can never flood players with ads.
class Ajustes {
  const Ajustes({
    this.intervaloAnunciosMin = 6,
    this.faseDoPrimeiroAnuncio = 6,
    this.carenciaSessaoMin = 5,
    this.dobrarPorDia = 10,
  });

  /// From Remote Config values (by key, see [padroes]); a missing or
  /// out-of-range value falls back to the nearest allowed one.
  factory Ajustes.de(Map<String, int> v) {
    int ler(String chave, int minimo, int maximo) =>
        (v[chave] ?? padroes[chave]!).clamp(minimo, maximo);
    return Ajustes(
      intervaloAnunciosMin: ler(chaveIntervalo, 3, 30),
      faseDoPrimeiroAnuncio: ler(chaveFaseInicial, 3, 50),
      carenciaSessaoMin: ler(chaveCarencia, 2, 30),
      dobrarPorDia: ler(chaveDobrar, 0, 20),
    );
  }

  static const chaveIntervalo = 'anuncio_intervalo_min';
  static const chaveFaseInicial = 'anuncio_fase_inicial';
  static const chaveCarencia = 'anuncio_carencia_min';
  static const chaveDobrar = 'dobrar_por_dia';

  /// The values the game ships with, by Remote Config key.
  static const padroes = <String, int>{
    chaveIntervalo: 6,
    chaveFaseInicial: 6,
    chaveCarencia: 5,
    chaveDobrar: 10,
  };

  /// What the game uses now. Read once when the app opens, so a value
  /// never changes in the middle of a session.
  static Ajustes atuais = const Ajustes();

  /// Minutes between full-screen ads.
  final int intervaloAnunciosMin;

  /// No ad between levels before this level has been completed.
  final int faseDoPrimeiroAnuncio;

  /// Minutes after the app opens without any ad between levels.
  final int carenciaSessaoMin;

  /// How many wins a day can have their stars doubled with a video.
  final int dobrarPorDia;

  AdPolicy get anuncios => AdPolicy(
    minInterval: Duration(minutes: intervaloAnunciosMin),
    firstLevel: faseDoPrimeiroAnuncio,
    sessionGrace: Duration(minutes: carenciaSessaoMin),
  );
}
