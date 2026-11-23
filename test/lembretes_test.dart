import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/lembretes.dart';
import 'package:puzzle_blocos/core/passe.dart';
import 'package:puzzle_blocos/core/presente_diario.dart';
import 'package:puzzle_blocos/core/village.dart';
import 'package:puzzle_blocos/l10n/idioma.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => Lingua.atual.value = Idioma.pt);

  // Mid-season (November 2026 is season 1), in the evening.
  final agora = DateTime(2026, 11, 10, 21);

  List<String> tipos(List<Lembrete> l) => [for (final x in l) x.tipo];

  test('cadence: days 1, 2, 4 and 7 of absence, at 19h, one a day', () {
    final l = escolherLembretes(EstadoLembretes(agora: agora));
    expect([for (final x in l) x.dias], [1, 2, 4, 7]);
    expect(quandoLembrete(agora, 1), DateTime(2026, 11, 11, 19));
    // Across the end of the month.
    expect(
      quandoLembrete(DateTime(2026, 11, 28, 10), 4),
      DateTime(2026, 12, 2, 19),
    );
  });

  test('nothing special: the gift once, then friendly generic texts', () {
    final l = escolherLembretes(EstadoLembretes(agora: agora));
    expect(tipos(l), ['presente', 'generico', 'generico', 'generico']);
    expect(l[0].texto, 'Seu presente de hoje: 5 estrelas. Vem pegar!');
    expect(l[3].titulo, 'Faz uma semana! 🐹');
    // No two reminders say the same thing.
    expect({for (final x in l) x.texto}.length, l.length);
  });

  test('gift taken today: tomorrow the streak is at risk, with its prize', () {
    final l = escolherLembretes(
      EstadoLembretes(agora: agora, presentePegoHoje: true, presenteDia: 2),
    );
    expect(l[0].tipo, 'presente_sequencia');
    expect(l[0].titulo, 'Dia 4 do presente 🎁');
    expect(l[0].texto, contains('1 pá'));
    expect(l[0].texto, contains('volta ao dia 1'));
    // The gift is not brought up again.
    expect(tipos(l).skip(1), everyElement('generico'));
  });

  test('day 7 of the gift: the 30 stars', () {
    final l = escolherLembretes(
      EstadoLembretes(agora: agora, presentePegoHoje: true, presenteDia: 5),
    );
    expect(l[0].titulo, 'Dia 7: o maior presente 🎁');
    expect(l[0].texto, contains('30 estrelas'));
  });

  test('after day 7 the gift starts over: nothing to lose', () {
    final l = escolherLembretes(
      EstadoLembretes(agora: agora, presentePegoHoje: true, presenteDia: 6),
    );
    expect(l[0].tipo, 'presente');
    expect(l[0].texto, contains('5 estrelas'));
  });

  test('daily challenge streak at risk, after the gift', () {
    final l = escolherLembretes(
      EstadoLembretes(
        agora: agora,
        presentePegoHoje: true,
        presenteDia: 0,
        desafioFeitoHoje: true,
        sequenciaDesafio: 5,
      ),
    );
    expect(tipos(l).take(2), ['presente_sequencia', 'generico']);
    // Without the gift's streak, the challenge's comes first.
    final s = escolherLembretes(
      EstadoLembretes(
        agora: agora,
        desafioFeitoHoje: true,
        sequenciaDesafio: 5,
      ),
    );
    expect(s[0].tipo, 'desafio_sequencia');
    expect(s[0].titulo, 'Sequência de 5 dias em risco 🔥');
    expect(s[1].tipo, 'presente');
    // A streak of one day, or a challenge not done today: nothing at risk.
    for (final e in [
      EstadoLembretes(
        agora: agora,
        desafioFeitoHoje: true,
        sequenciaDesafio: 1,
      ),
      EstadoLembretes(agora: agora, sequenciaDesafio: 5),
    ]) {
      expect(tipos(escolherLembretes(e)), isNot(contains('desafio_sequencia')));
    }
  });

  test('Passe rewards ready, and the season ending soon', () {
    final l = escolherLembretes(EstadoLembretes(agora: agora, passeProntos: 2));
    expect(l[0].tipo, 'passe_pronto');
    expect(l[0].titulo, '2 prêmios do Passe esperando ⭐');
    expect(l[0].texto, 'Abra o Passe do Capi e pegue tudo.');
    expect(l[1].tipo, 'presente');

    final fim = escolherLembretes(
      EstadoLembretes(agora: DateTime(2026, 11, 27, 12), passeProntos: 1),
    );
    expect(fim[0].tipo, 'passe_pronto');
    expect(fim[0].texto, 'A temporada acaba em 3 dias. Pegue antes!');

    // A reminder in the next season would talk about rewards already gone.
    final virou = escolherLembretes(
      EstadoLembretes(agora: DateTime(2026, 11, 30, 12), passeProntos: 1),
    );
    expect(tipos(virou), isNot(contains('passe_pronto')));
  });

  test('Passe close to a reward', () {
    final l = escolherLembretes(
      EstadoLembretes(agora: agora, passeFaltam: 4, passePremio: '3 estrelas'),
    );
    expect(l[0].tipo, 'passe_perto');
    expect(l[0].texto, 'Faltam 4 pontos para 3 estrelas. Uma partida resolve!');
    // Far from it: not worth a reminder.
    final longe = escolherLembretes(
      EstadoLembretes(agora: agora, passeFaltam: 25, passePremio: '3 estrelas'),
    );
    expect(tipos(longe), isNot(contains('passe_perto')));
  });

  test('village: something the stars already pay for', () {
    final l = escolherLembretes(
      EstadoLembretes(agora: agora, vilaItem: 'o banquinho'),
    );
    expect(l[0].tipo, 'vila');
    expect(l[0].texto, 'Você já tem estrelas para construir o banquinho.');
  });

  test('everything at once: each subject once, by importance', () {
    final l = escolherLembretes(
      EstadoLembretes(
        agora: agora,
        presentePegoHoje: true,
        presenteDia: 1,
        desafioFeitoHoje: true,
        sequenciaDesafio: 3,
        passeProntos: 1,
        vilaItem: 'o banquinho',
      ),
    );
    // The streaks are only at risk tomorrow; then the Passe and the
    // village. The gift's streak is gone by day 2: not brought up again.
    expect(tipos(l), [
      'presente_sequencia',
      'passe_pronto',
      'vila',
      'generico',
    ]);
  });

  test('read from the store', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    var e = EstadoLembretes.doStore(store, agora);
    expect(e.presentePegoHoje, isFalse);
    expect(e.vilaItem, isNull);
    expect(e.passeProntos, 0);
    expect(e.passeFaltam, PasseDoCapi.pontosPorNivel);

    await PresenteDiario.pegar(store, agora);
    await store.completeDaily(agora.subtract(const Duration(days: 1)));
    await store.completeDaily(agora);
    final barato = Village.suggestion(const [])!;
    await store.addStars(barato.cost);
    e = EstadoLembretes.doStore(store, agora);
    expect(e.presentePegoHoje, isTrue);
    expect(e.presenteDia, 0);
    expect(e.desafioFeitoHoje, isTrue);
    expect(e.sequenciaDesafio, 2);
    expect(e.vilaItem, barato.nameInline);
    // Both streaks end tomorrow: the gift's, with its prize, is told.
    final l = escolherLembretes(e);
    expect(l.first.tipo, 'presente_sequencia');
    expect(l.first.titulo, 'Dia 2 do presente 🎁');
    expect(tipos(l), contains('vila'));
  });

  test('the texts follow the language', () {
    Lingua.atual.value = Idioma.en;
    final l = escolherLembretes(EstadoLembretes(agora: agora, passeProntos: 1));
    expect(l[0].titulo, '1 Pass reward waiting ⭐');
    Lingua.atual.value = Idioma.pt;
  });
}
