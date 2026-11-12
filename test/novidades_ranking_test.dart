import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/novidades.dart';
import 'package:puzzle_blocos/core/ranking.dart';
import 'package:puzzle_blocos/l10n/en.dart';
import 'package:puzzle_blocos/l10n/es.dart';
import 'package:puzzle_blocos/l10n/idioma.dart';
import 'package:puzzle_blocos/screens/novidades_dialog.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/services/ranking_resumo.dart';
import 'package:puzzle_blocos/services/ranking_servidor.dart';
import 'package:puzzle_blocos/ui/posicao_ranking.dart';
import 'package:shared_preferences/shared_preferences.dart';

final quarta = DateTime.utc(2026, 11, 11, 12);

Future<ProgressStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return ProgressStore.load();
}

void main() {
  group('novidades', () {
    test('quem já viu tudo não recebe nada; o resto vem do mais novo', () {
      expect(Novidades.pendentes(Novidades.atual), isEmpty);
      final todas = Novidades.pendentes(-1);
      expect(todas, isNotEmpty);
      expect(todas.length, lessThanOrEqualTo(Novidades.porVez));
      expect(todas.first, Novidades.edicoes[Novidades.atual]!.first);
    });

    test('quem viu a edição 1 recebe só o Blitz da 1.12.0', () {
      final novas = Novidades.pendentes(1);
      expect(novas.map((n) => n.destino), [DestinoNovidade.blitz]);
      expect(iconeDaNovidade(DestinoNovidade.blitz), Icons.bolt_rounded);
    });

    test('toda novidade tem tradução em inglês e espanhol', () {
      for (final lista in Novidades.edicoes.values) {
        for (final n in lista) {
          for (final texto in [n.titulo, n.texto]) {
            expect(en.containsKey(texto), isTrue, reason: 'inglês: $texto');
            expect(es.containsKey(texto), isTrue, reason: 'espanhol: $texto');
          }
        }
      }
    });

    test('o que foi mostrado fica pendente até ser aberto', () async {
      final store = await _store();
      expect(store.novidadesVistas, -1);
      await store.setNovidadesVistas(Novidades.atual);
      await store.setNovidadesPendentes(['ranking', 'torre']);
      expect(store.novidadesVistas, Novidades.atual);
      expect(store.novidadesPendentes, ['ranking', 'torre']);
    });

    for (final largura in [320.0, 375.0]) {
      for (final idioma in Idioma.values) {
        testWidgets('o cartão cabe em $largura px (${idioma.name})', (t) async {
          Lingua.atual.value = idioma;
          addTearDown(() => Lingua.atual.value = Idioma.pt);
          t.view.physicalSize = Size(largura, 640);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          DestinoNovidade? escolhido;
          await t.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => TextButton(
                  onPressed: () async => escolhido = await mostrarNovidades(
                    context,
                    Novidades.pendentes(-1),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          );
          await t.tap(find.text('abrir'));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(find.text(tr('O que há de novo')), findsWidgets);
          await t.tap(find.text(tr('Ver agora')).first);
          await t.pumpAndSettle();
          expect(escolhido, Novidades.pendentes(-1).first.destino);
        });
      }
    }
  });

  group('posição no ranking', () {
    late RankingDeTeste servidor;
    late String id;

    setUp(() {
      RankingResumo.limpar();
      servidor = RankingDeTeste();
      RankingServidor.atual = servidor;
      id = Ranking.id(Quadro.infinito, Periodo.semana, quarta);
      for (final (uid, pontos) in [('a', 9000), ('b', 5000), ('c', 1200)]) {
        servidor.quadros.putIfAbsent(id, () => {})[uid] = EntradaRanking(
          uid: uid,
          nome: uid,
          pontos: pontos,
        );
      }
    });
    tearDown(() => RankingServidor.atual = null);

    test('sem nome ou sem pontos na semana, não há posição', () async {
      final store = await _store();
      expect(await RankingResumo.ler(store, Quadro.infinito), isNull);
      await store.setRankingNome('Ana');
      expect(
        await RankingResumo.ler(store, Quadro.infinito, quando: quarta),
        isNull,
      );
    });

    test('diz o lugar e quanto falta para subir', () async {
      final store = await _store();
      await store.setRankingNome('Ana');
      await Ranking.marcar(store, Quadro.infinito, 4770, quarta);
      final p = await RankingResumo.ler(store, Quadro.infinito, quando: quarta);
      expect(p!.posicao, 3);
      expect(p.faltam, 230);
      expect(p.anterior, isNull);
      expect(p.caiu, isFalse);
      expect(textoFaltam(Quadro.infinito, p.faltam!), contains('230'));
    });

    test('no topo não falta nada', () async {
      final store = await _store();
      await store.setRankingNome('Ana');
      await Ranking.marcar(store, Quadro.infinito, 9500, quarta);
      final p = await RankingResumo.ler(store, Quadro.infinito, quando: quarta);
      expect(p!.posicao, 1);
      expect(p.faltam, isNull);
    });

    test('a resposta fica guardada por alguns minutos', () async {
      final store = await _store();
      await store.setRankingNome('Ana');
      await Ranking.marcar(store, Quadro.infinito, 4770, quarta);
      await RankingResumo.ler(store, Quadro.infinito, quando: quarta);
      servidor.quadros[id]!['d'] = const EntradaRanking(
        uid: 'd',
        nome: 'd',
        pontos: 4800,
      );
      final logo = quarta.add(const Duration(minutes: 1));
      final mesma = await RankingResumo.ler(
        store,
        Quadro.infinito,
        quando: logo,
      );
      expect(mesma!.posicao, 3);
      final depois = quarta.add(RankingResumo.validade);
      final nova = await RankingResumo.ler(
        store,
        Quadro.infinito,
        quando: depois,
      );
      expect(nova!.posicao, 4);
      expect(nova.faltam, 30);
    });

    test('a seta compara com a última vez que o ranking foi aberto', () async {
      final store = await _store();
      await store.setRankingNome('Ana');
      await Ranking.marcar(store, Quadro.infinito, 4770, quarta);
      await RankingResumo.visto(store, quando: quarta);
      expect(store.rankingVisto(Quadro.infinito.id, Ranking.semana(quarta)), 3);
      // Alguém passou na frente.
      servidor.quadros[id]!['d'] = const EntradaRanking(
        uid: 'd',
        nome: 'd',
        pontos: 4800,
      );
      final depois = quarta.add(RankingResumo.validade);
      final caiu = await RankingResumo.ler(
        store,
        Quadro.infinito,
        quando: depois,
      );
      expect(caiu!.caiu, isTrue);
      expect(caiu.subiu, isFalse);
      // Uma partida melhor: sobe.
      await Ranking.marcar(store, Quadro.infinito, 6000, depois);
      final subiu = await RankingResumo.ler(
        store,
        Quadro.infinito,
        quando: depois,
      );
      expect(subiu!.posicao, 2);
      expect(subiu.subiu, isTrue);
      // Na semana seguinte a comparação recomeça.
      final proxima = quarta.add(const Duration(days: 7));
      expect(
        store.rankingVisto(Quadro.infinito.id, Ranking.semana(proxima)),
        isNull,
      );
    });

    test('o menu mostra o quadro em que o jogador está melhor', () async {
      final store = await _store();
      await store.setRankingNome('Ana');
      await Ranking.marcar(store, Quadro.infinito, 4770, quarta);
      await Ranking.marcar(store, Quadro.torre, 12, quarta);
      final p = await RankingResumo.melhor(store, quando: quarta);
      expect(p!.quadro, Quadro.torre);
      expect(p.posicao, 1);
    });
  });
}
