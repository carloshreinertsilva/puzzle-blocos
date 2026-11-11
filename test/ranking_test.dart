import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/ranking.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/services/ranking_servidor.dart';
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
}
