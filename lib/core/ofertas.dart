import '../services/progress_store.dart';

/// Capi's piggy bank: for every star the player earns by playing, Capi
/// keeps one more in the piggy bank (bought stars don't count). Once it has
/// [minimo] stars it can be broken open in the shop, for a fixed price,
/// giving everything inside. It stops filling at [capacidade].
abstract final class Cofrinho {
  /// Breaking it open is worth it from here: as much as the smallest star
  /// pack, for the same price.
  static const minimo = 150;

  /// Full: as much as the 400 pack, for the price of the 150 one.
  static const capacidade = 400;

  static bool podeQuebrar(ProgressStore store) => store.cofrinho >= minimo;
  static bool cheio(ProgressStore store) => store.cofrinho >= capacidade;

  /// What breaking it gives now (never less than [minimo]: a payment
  /// approved later still gives at least what was promised).
  static int conteudo(ProgressStore store) =>
      store.cofrinho < minimo ? minimo : store.cofrinho;
}

/// A cheap first purchase for players who never bought anything: offered
/// once, for [duracao], after the starter pack's days are over.
abstract final class OfertaBoasVindas {
  /// Players who got this far like the game.
  static const nivelMinimo = 8;
  static const duracao = Duration(hours: 48);
  static const estrelas = 200;

  /// Whether the offer may start now (it starts once, and then runs for
  /// [duracao]).
  static bool podeComecar(
    ProgressStore store,
    DateTime agora, {
    required bool pacoteInicialNoAr,
  }) =>
      store.ofertaBoasVindasInicio == null &&
      !pacoteInicialNoAr &&
      store.level >= nivelMinimo &&
      !store.jaComprou;

  /// Whether the offer is on now.
  static bool noAr(ProgressStore store, DateTime agora) {
    final inicio = store.ofertaBoasVindasInicio;
    return inicio != null &&
        !store.jaComprou &&
        agora.difference(inicio) < duracao &&
        !agora.isBefore(inicio);
  }

  static Duration restante(ProgressStore store, DateTime agora) {
    final inicio = store.ofertaBoasVindasInicio ?? agora;
    final falta = inicio.add(duracao).difference(agora);
    return falta.isNegative ? Duration.zero : falta;
  }
}
