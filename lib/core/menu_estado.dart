import '../l10n/idioma.dart';
import 'descoberta.dart';

/// How one game mode of the Modos sheet stands for the player.
class EstadoModo {
  const EstadoModo(
    this.modo, {
    required this.liberado,
    this.aberto = false,
    this.novidade = false,
    this.recorde,
  });

  final Atalho modo;
  final bool liberado;

  /// Opened at least once.
  final bool aberto;

  /// News about it (core/novidades.dart) the player has not opened.
  final bool novidade;

  /// The player's record, already written for the screen ("12.345"), or
  /// null before the first one.
  final String? recorde;
}

/// Why the shop button calls the player.
enum MotivoLoja {
  /// The starter pack or the welcome offer is on.
  oferta,

  /// The piggy bank is full.
  cofrinhoCheio,

  /// Today's Mercado offers were not seen yet.
  ofertasDoDia;

  /// What Capi's balloon by the button says.
  String get fala => switch (this) {
    MotivoLoja.oferta => tr('Tem oferta na loja!'),
    MotivoLoja.cofrinhoCheio => tr('Seu cofrinho encheu!'),
    MotivoLoja.ofertasDoDia => tr('Ofertas novas hoje!'),
  };
}

/// What the menu's cards say, so they show what is going on in the game.
abstract final class MenuEstado {
  /// The most useful line for the "Modos" card right now: a duel result,
  /// a mode just opened, news, the next mode to open, or a record (a
  /// different one each [dia]).
  static String modosSubtitulo(
    List<EstadoModo> modos, {
    int resultadosDuelo = 0,
    int dia = 0,
  }) {
    final duelo = modos.where((m) => m.modo == Atalho.duelo).firstOrNull;
    if (resultadosDuelo > 0 && (duelo?.liberado ?? false)) {
      return trN(
        resultadosDuelo,
        'Duelo: resultado novo!',
        'Duelo: {n} resultados novos!',
      );
    }
    final novos = [
      for (final m in modos)
        if (m.liberado && !m.aberto) m,
    ];
    if (novos.length == 1) {
      return tr('{modo} liberado!', {'modo': novos.first.modo.nome});
    }
    if (novos.length > 1) return tr('{n} modos novos', {'n': novos.length});
    for (final m in modos) {
      if (m.liberado && m.novidade) {
        return tr('{modo}: novidade!', {'modo': m.modo.nome});
      }
    }
    final trancados = [
      for (final m in modos)
        if (!m.liberado && m.modo.liberaNaFase != null) m,
    ]..sort((a, b) => a.modo.liberaNaFase!.compareTo(b.modo.liberaNaFase!));
    if (trancados.isNotEmpty) {
      final fase = trancados.first.modo.liberaNaFase!;
      final juntos = trancados.where((m) => m.modo.liberaNaFase == fase);
      return juntos.length > 1
          ? tr('{n} modos na fase {fase}', {'n': juntos.length, 'fase': fase})
          : tr('{modo} na fase {fase}', {
              'modo': trancados.first.modo.nome,
              'fase': fase,
            });
    }
    final recordes = [
      for (final m in modos)
        if (m.recorde != null) m,
    ];
    if (recordes.isNotEmpty) {
      final m = recordes[dia.abs() % recordes.length];
      return m.modo == Atalho.torre
          ? tr('{modo}: {n} andares', {'modo': m.modo.nome, 'n': m.recorde!})
          : tr('{modo}: recorde {n}', {'modo': m.modo.nome, 'n': m.recorde!});
    }
    return tr('Mais jeitos de jogar');
  }

  /// Why the shop button shows its mark, or null: an offer on, the piggy
  /// bank full, or today's offers not seen yet ([lojaVistaDia] is the day
  /// the shop was last opened, [hoje] today, both as dayKeys).
  static MotivoLoja? motivoLoja({
    required bool ofertaNoAr,
    required bool cofrinhoCheio,
    required int lojaVistaDia,
    required int hoje,
  }) {
    if (ofertaNoAr) return MotivoLoja.oferta;
    if (cofrinhoCheio) return MotivoLoja.cofrinhoCheio;
    if (lojaVistaDia != hoje) return MotivoLoja.ofertasDoDia;
    return null;
  }

  /// Whether Capi's balloon by the shop button should call: only while
  /// there is something the player has not seen today.
  static bool lojaChama(
    MotivoLoja? motivo, {
    required int lojaVistaDia,
    required int hoje,
  }) => motivo != null && lojaVistaDia != hoje;
}
