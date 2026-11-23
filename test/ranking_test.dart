import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/fila_abertura.dart';
import 'package:puzzle_blocos/core/ranking.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/services/ranking_servidor.dart';
import 'package:puzzle_blocos/ui/nome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store([Map<String, Object> salvo = const {}]) async {
  SharedPreferences.setMockInitialValues(salvo);
  return ProgressStore.load();
}

void main() {
  // Uma quarta-feira; a semana vai de segunda 9/11 a domingo 15/11 (UTC).
  final quarta = DateTime.utc(2026, 11, 11, 15);

  test('a semana começa na segunda-feira, 00:00 UTC', () {
    final s = Ranking.semana(quarta);
    expect(Ranking.semana(DateTime.utc(2026, 11, 9)), s);
    expect(Ranking.semana(DateTime.utc(2026, 11, 15, 23, 59)), s);
    expect(Ranking.semana(DateTime.utc(2026, 11, 8, 23, 59)), s - 1);
    expect(Ranking.semana(DateTime.utc(2026, 11, 16)), s + 1);
    expect(Ranking.fimDaSemana(quarta), DateTime.utc(2026, 11, 16));
    expect(Ranking.id(Quadro.torre, Periodo.geral, quarta), 'torre_geral');
    expect(Ranking.id(Quadro.blitz, Periodo.semana, quarta), 'blitz_s$s');
  });

  test(
    'a marca da semana é a melhor partida; nas fases, quantas venceu',
    () async {
      final store = await _store();
      await Ranking.marcar(store, Quadro.torre, 8, quarta);
      await Ranking.marcar(store, Quadro.torre, 5, quarta);
      expect(Ranking.pontos(store, Quadro.torre, Periodo.semana, quarta), 8);
      for (var i = 0; i < 3; i++) {
        await Ranking.marcar(store, Quadro.fases, 1, quarta);
      }
      expect(Ranking.pontos(store, Quadro.fases, Periodo.semana, quarta), 3);
      // Na semana seguinte começa do zero.
      final depois = quarta.add(const Duration(days: 7));
      expect(Ranking.pontos(store, Quadro.torre, Periodo.semana, depois), 0);
      await Ranking.marcar(store, Quadro.torre, 2, depois);
      expect(Ranking.pontos(store, Quadro.torre, Periodo.semana, depois), 2);
    },
  );

  test('o placar de sempre vem dos recordes do jogador', () async {
    final store = await _store({
      'towerBestHeight': 31,
      'bestScore': 4200,
      'blitzBestScore': 1500,
      'level': 12,
    });
    int geral(Quadro q) => Ranking.pontos(store, q, Periodo.geral, quarta);
    expect(geral(Quadro.torre), 31);
    expect(geral(Quadro.infinito), 4200);
    expect(geral(Quadro.blitz), 1500);
    expect(geral(Quadro.fases), 11, reason: 'fases concluídas');
  });

  test('sem nome nada é enviado; com nome, só o que mudou', () async {
    final store = await _store({'towerBestHeight': 9});
    final servidor = RankingDeTeste();
    RankingServidor.atual = servidor;
    addTearDown(() => RankingServidor.atual = null);

    await RankingSync.enviar(store, quarta);
    expect(servidor.quadros, isEmpty);

    await store.setRankingNome('Ana');
    await Ranking.marcar(store, Quadro.torre, 9, quarta);
    await RankingSync.enviar(store, quarta);
    final s = Ranking.semana(quarta);
    expect(servidor.quadros.keys, {'torre_geral', 'torre_s$s'});
    expect(servidor.quadros['torre_geral']!['eu']!.nome, 'Ana');
    expect(servidor.quadros['torre_geral']!['eu']!.pontos, 9);

    // Nada mudou: nada vai de novo.
    servidor.quadros.clear();
    await RankingSync.enviar(store, quarta);
    expect(servidor.quadros, isEmpty);

    // Nome novo: as linhas vão de novo, com ele.
    await store.setRankingNome('Aninha');
    await RankingSync.enviar(store, quarta);
    expect(servidor.quadros['torre_s$s']!['eu']!.nome, 'Aninha');
  });

  test('a pontuação enviada não passa do teto do placar', () async {
    final store = await _store({'towerBestHeight': 9999});
    await store.setRankingNome('Ana');
    final e = Ranking.minha(store, 'eu', Quadro.torre, Periodo.geral, quarta);
    expect(e!.pontos, Quadro.torre.maximo);
  });

  test('uma linha lida do servidor: campos a menos não quebram', () {
    final e = EntradaRanking.ler('x', {'nome': 'Bia', 'pontos': 7});
    expect(e!.chapeu, 'helmet');
    expect(e.embaixador, isFalse);
    expect(EntradaRanking.ler('x', {'nome': 'Bia'}), isNull);
    expect(EntradaRanking.ler('x', {'pontos': 3}), isNull);
  });

  test('dois envios ao mesmo tempo mandam cada linha uma vez só', () async {
    final store = await _store({'towerBestHeight': 9, 'rankingNome': 'Ana'});
    final servidor = _Contador();
    RankingServidor.atual = servidor;
    addTearDown(() => RankingServidor.atual = null);
    // O fim da partida e a volta ao menu, juntos.
    await Future.wait([
      RankingSync.enviar(store, quarta),
      RankingSync.enviar(store, quarta),
    ]);
    expect(servidor.envios, 1, reason: 'só torre_geral tem pontos');
    expect(servidor.quadros['torre_geral']!['eu']!.nome, 'Ana');
  });

  group('nome obrigatório', () {
    test('a janela do nome vem logo depois do convite e não conta no '
        'limite de janelas', () {
      final ordem = DialogoAbertura.values;
      expect(ordem.indexOf(DialogoAbertura.nomeRanking), 1);
      expect(ordem.first, DialogoAbertura.conviteRecebido);
      expect(DialogoAbertura.nomeRanking.obrigatorio, isTrue);
      expect(
        FilaAbertura.escolher({
          DialogoAbertura.novidades,
          DialogoAbertura.nomeRanking,
          DialogoAbertura.presente,
          DialogoAbertura.ofertaBoasVindas,
        }),
        [
          DialogoAbertura.nomeRanking,
          DialogoAbertura.presente,
          DialogoAbertura.novidades,
        ],
      );
      final fila = FilaAbertura(limite: 0);
      expect(fila.cabe(DialogoAbertura.nomeRanking), isTrue);
      fila.mostrou(DialogoAbertura.nomeRanking);
      expect(fila.mostrados, 0);
    });

    Future<String? Function()> abrir(
      WidgetTester t, {
      bool obrigatorio = true,
    }) async {
      String? nome = 'nada';
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => nome = obrigatorio
                  ? await pedirNomeObrigatorio(context)
                  : await showDialog<String>(
                      context: context,
                      builder: (_) => const NomeDialog(),
                    ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      return () => nome;
    }

    testWidgets('sem "Agora não", não fecha no voltar nem fora; só com um '
        'nome válido', (t) async {
      final nome = await abrir(t);
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.text('Seu nome no ranking'), findsWidgets);
      expect(find.text('Agora não'), findsNothing);
      // O campo vem vazio.
      expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '');

      // Voltar (botão do Android) e tocar fora não fecham a janela.
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await t.tapAt(const Offset(5, 5));
      await t.pumpAndSettle();
      expect(find.text('Seu nome no ranking'), findsWidgets);

      // Nome curto não passa; um bom passa e fecha.
      await t.enterText(find.byType(TextField), 'Zé');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.text('Seu nome no ranking'), findsWidgets);
      await t.enterText(find.byType(TextField), 'Carlos');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.text('Seu nome no ranking'), findsNothing);
      expect(nome(), 'Carlos');
    });

    testWidgets('fora do obrigatório, "Agora não" continua', (t) async {
      final nome = await abrir(t, obrigatorio: false);
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Agora não'));
      await t.pumpAndSettle();
      expect(find.text('Seu nome no ranking'), findsNothing);
      expect(nome(), isNull);
    });
  });
}

/// Counts what reaches the server.
class _Contador extends RankingDeTeste {
  int envios = 0;

  @override
  Future<void> enviar(String id, EntradaRanking entrada) async {
    envios++;
    // Some time on the network, so the two sends could overlap.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await super.enviar(id, entrada);
  }
}
