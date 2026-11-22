import '../l10n/idioma.dart';
import '../services/progress_store.dart';
import 'passe.dart';
import 'presente_diario.dart';
import 'village.dart';

/// The days of absence that get a reminder, at [lembretesHora] local time:
/// two right away (the gift and the streaks are lost after one day), then
/// spaced out, and none after a week. At most one a day; opening the game
/// moves them all on again from tomorrow.
const lembretesDias = [1, 2, 4, 7];

/// The hour the reminders ring (local time).
const lembretesHora = 19;

/// What the player has waiting, read from the [ProgressStore] when the
/// reminders are scheduled (so [escolherLembretes] needs no plugin or
/// storage, and can be tested as is).
class EstadoLembretes {
  const EstadoLembretes({
    required this.agora,
    this.presentePegoHoje = false,
    this.presenteDia = 0,
    this.desafioFeitoHoje = false,
    this.sequenciaDesafio = 0,
    this.passeProntos = 0,
    this.passeFaltam,
    this.passePremio = '',
    this.vilaItem,
  });

  factory EstadoLembretes.doStore(ProgressStore store, DateTime agora) {
    final nivel = PasseDoCapi.nivel(store, agora);
    final temNivel = nivel < PasseDoCapi.niveis;
    final pontos = PasseDoCapi.pontos(store, agora);
    final sugestao = Village.suggestion(store.villageItems);
    return EstadoLembretes(
      agora: agora,
      presentePegoHoje: !PresenteDiario.disponivel(store, agora),
      presenteDia: PresenteDiario.dia(store, agora),
      desafioFeitoHoje: store.dailyDone(agora),
      sequenciaDesafio: store.dailyStreak(agora),
      passeProntos: PasseDoCapi.prontas(store, agora),
      passeFaltam: temNivel
          ? PasseDoCapi.pontosPorNivel - pontos % PasseDoCapi.pontosPorNivel
          : null,
      passePremio: temNivel
          ? PasseDoCapi.trilha(agora)[nivel].gratis.texto
          : '',
      vilaItem: sugestao != null && store.stars >= sugestao.cost
          ? sugestao.nameInline
          : null,
    );
  }

  /// When the reminders are scheduled (the game was just opened or left).
  final DateTime agora;

  /// Whether today's daily gift was taken, and which day of the 7 (from 0)
  /// today's gift is.
  final bool presentePegoHoje;
  final int presenteDia;

  /// The Daily challenge: done today, and the days in a row.
  final bool desafioFeitoHoje;
  final int sequenciaDesafio;

  /// Passe do Capi rewards ready to claim; the points still missing for the
  /// next level (null when the track is done) and that level's free reward.
  final int passeProntos;
  final int? passeFaltam;
  final String passePremio;

  /// A village item the player's stars already pay for (its name inside a
  /// sentence), or null.
  final String? vilaItem;
}

/// One reminder: how many days after [EstadoLembretes.agora] it rings, its
/// texts, and what it is about (for statistics and tests).
class Lembrete {
  const Lembrete(this.dias, this.tipo, this.titulo, this.texto);
  final int dias;
  final String tipo;
  final String titulo;
  final String texto;

  @override
  String toString() => 'Lembrete($dias, $tipo: $titulo / $texto)';
}

/// The moment a reminder [dias] days after [agora] rings.
DateTime quandoLembrete(DateTime agora, int dias) =>
    DateTime(agora.year, agora.month, agora.day + dias, lembretesHora);

/// The reminders for [lembretesDias], each with the most concrete thing the
/// player has to lose or to win on that day if they haven't come back by
/// then. Each subject (the gift, the challenge, the Passe, the village)
/// is used once at most; with nothing left, a friendly generic text.
List<Lembrete> escolherLembretes(EstadoLembretes e) {
  final usados = <String>{};
  final out = <Lembrete>[];
  for (var i = 0; i < lembretesDias.length; i++) {
    final dias = lembretesDias[i];
    final quando = quandoLembrete(e.agora, dias);
    Lembrete? escolhido;
    for (final (assunto, fazer) in _candidatos(e, dias, quando)) {
      if (usados.contains(assunto)) continue;
      final l = fazer();
      if (l == null) continue;
      usados.add(assunto);
      escolhido = l;
      break;
    }
    out.add(escolhido ?? _generico(dias, i));
  }
  return out;
}

/// The subjects in order of importance for that day, each making its
/// reminder (or null when it has nothing to say).
List<(String, Lembrete? Function())> _candidatos(
  EstadoLembretes e,
  int dias,
  DateTime quando,
) {
  final mesmaTemporada =
      PasseDoCapi.temporada(quando) == PasseDoCapi.temporada(e.agora);
  // Tomorrow the gift streak goes on only if today's gift was taken;
  // after that (or without today's) it starts again at day 1.
  final proximoDia = dias == 1 && e.presentePegoHoje
      ? (e.presenteDia + 1) % PresenteDiario.premios.length
      : 0;
  final premio = PresenteDiario.premios[proximoDia].texto;
  return [
    (
      'presente',
      () {
        if (proximoDia == 0) return null;
        final dia = proximoDia + 1;
        return Lembrete(
          dias,
          'presente_sequencia',
          dia == PresenteDiario.premios.length
              ? tr('Dia 7: o maior presente 🎁')
              : tr('Dia {dia} do presente 🎁', {'dia': dia}),
          tr('Hoje tem {premio} esperando. Se faltar, volta ao dia 1.', {
            'premio': premio,
          }),
        );
      },
    ),
    (
      'desafio',
      () {
        final n = e.sequenciaDesafio;
        if (dias != 1 || !e.desafioFeitoHoje || n < 2) return null;
        return Lembrete(
          dias,
          'desafio_sequencia',
          trN(
            n,
            'Sequência de {n} dia em risco 🔥',
            'Sequência de {n} dias em risco 🔥',
          ),
          tr('Jogue o Desafio diário hoje para não perder a sequência.'),
        );
      },
    ),
    (
      'passe',
      () {
        if (!mesmaTemporada) return null;
        final n = e.passeProntos;
        if (n > 0) {
          final restam = PasseDoCapi.diasRestantes(quando);
          return Lembrete(
            dias,
            'passe_pronto',
            trN(
              n,
              '{n} prêmio do Passe esperando ⭐',
              '{n} prêmios do Passe esperando ⭐',
            ),
            restam <= 3
                ? trN(
                    restam,
                    'A temporada acaba em {n} dia. Pegue antes!',
                    'A temporada acaba em {n} dias. Pegue antes!',
                  )
                : tr('Abra o Passe do Capi e pegue tudo.'),
          );
        }
        final f = e.passeFaltam;
        if (f == null || f > 10 || e.passePremio.isEmpty) return null;
        return Lembrete(
          dias,
          'passe_perto',
          tr('Quase lá no Passe ⭐'),
          trN(
            f,
            'Falta {n} ponto para {premio}. Uma partida resolve!',
            'Faltam {n} pontos para {premio}. Uma partida resolve!',
            {'premio': e.passePremio},
          ),
        );
      },
    ),
    (
      'vila',
      () {
        final item = e.vilaItem;
        if (item == null) return null;
        return Lembrete(
          dias,
          'vila',
          tr('A vila pode crescer 🏡'),
          tr('Você já tem estrelas para construir {item}.', {'item': item}),
        );
      },
    ),
    (
      'presente',
      () => Lembrete(
        dias,
        'presente',
        tr('Presente do Capi 🎁'),
        tr('Seu presente de hoje: {premio}. Vem pegar!', {'premio': premio}),
      ),
    ),
  ];
}

/// Nothing special left to say on that day.
Lembrete _generico(int dias, int i) {
  // (The first day always has the gift to talk about.)
  final (titulo, texto) = switch (i) {
    0 || 2 => (
      tr('O Capi sentiu sua falta 🐹'),
      tr('As missões de hoje já chegaram.'),
    ),
    1 => (
      tr('A vila espera por você'),
      tr('Volte e continue construindo a vila do Capi!'),
    ),
    _ => (
      tr('Faz uma semana! 🐹'),
      tr('O Capi guardou um presente para você. Vem jogar uma partida!'),
    ),
  };
  return Lembrete(dias, 'generico', titulo, texto);
}
