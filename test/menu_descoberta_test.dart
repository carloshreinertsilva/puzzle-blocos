import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/descoberta.dart';
import 'package:puzzle_blocos/core/dica_do_dia.dart';
import 'package:puzzle_blocos/core/fila_abertura.dart';
import 'package:puzzle_blocos/core/menu_estado.dart';
import 'package:puzzle_blocos/game/onboarding.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/ui/menu_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store([Map<String, Object> salvo = const {}]) async {
  SharedPreferences.setMockInitialValues(salvo);
  return ProgressStore.load();
}

final dia = DateTime(2026, 11, 22, 10);
final hoje = ProgressStore.dayKey(dia);

void main() {
  group('fila da abertura', () {
    test('no máximo dois diálogos, pela ordem de importância', () {
      expect(
        FilaAbertura.escolher({
          DialogoAbertura.playGames,
          DialogoAbertura.ofertaBoasVindas,
          DialogoAbertura.presente,
          DialogoAbertura.novidades,
        }),
        [DialogoAbertura.presente, DialogoAbertura.novidades],
      );
      expect(
        FilaAbertura.escolher({
          DialogoAbertura.resultadosDuelo,
          DialogoAbertura.nuvem,
          DialogoAbertura.bonusFundador,
        }),
        [DialogoAbertura.nuvem, DialogoAbertura.resultadosDuelo],
      );
      expect(FilaAbertura.escolher(const []), isEmpty);
    });

    test('a atualização obrigatória nunca fica de fora', () {
      final abrem = FilaAbertura.escolher({
        DialogoAbertura.presente,
        DialogoAbertura.novidades,
        DialogoAbertura.ofertaBoasVindas,
        DialogoAbertura.atualizacao,
      });
      expect(abrem, contains(DialogoAbertura.atualizacao));
      expect(abrem.where((d) => !d.obrigatorio), hasLength(2));
      expect(FilaAbertura.escolher({DialogoAbertura.atualizacao}, limite: 0), [
        DialogoAbertura.atualizacao,
      ]);
    });

    test('passo a passo: conta só o que abriu', () {
      final fila = FilaAbertura();
      expect(fila.cabe(DialogoAbertura.presente), isTrue);
      fila.mostrou(DialogoAbertura.presente);
      fila.mostrou(DialogoAbertura.atualizacao);
      expect(fila.mostrados, 1);
      fila.mostrou(DialogoAbertura.novidades);
      expect(fila.cabe(DialogoAbertura.ofertaBoasVindas), isFalse);
      expect(fila.cabe(DialogoAbertura.atualizacao), isTrue);
      expect(fila.mostrados, FilaAbertura.limitePadrao);
    });

    test('o presente e as novidades vêm antes das ofertas', () {
      final ordem = DialogoAbertura.values;
      expect(
        ordem.indexOf(DialogoAbertura.presente),
        lessThan(ordem.indexOf(DialogoAbertura.ofertaBoasVindas)),
      );
      expect(
        ordem.indexOf(DialogoAbertura.novidades),
        lessThan(ordem.indexOf(DialogoAbertura.ofertaBoasVindas)),
      );
    });
  });

  group('dica do dia', () {
    test('uma por dia, revezando, só entre as disponíveis', () {
      final todas = TemaDica.values.toSet();
      expect(DicaDoDia.escolher(disponiveis: todas, hoje: hoje), todas.first);
      expect(
        DicaDoDia.escolher(
          disponiveis: todas,
          hoje: hoje,
          ultimoDia: hoje - 1,
          ultimo: TemaDica.guardaRoupa,
        ),
        TemaDica.loja,
      );
      // Already one today.
      expect(
        DicaDoDia.escolher(disponiveis: todas, hoje: hoje, ultimoDia: hoje),
        isNull,
      );
      // Wraps around, skipping what is not available.
      expect(
        DicaDoDia.escolher(
          disponiveis: {TemaDica.guardaRoupa, TemaDica.torre},
          hoje: hoje,
          ultimo: TemaDica.torre,
        ),
        TemaDica.guardaRoupa,
      );
      expect(DicaDoDia.escolher(disponiveis: const {}, hoje: hoje), isNull);
    });

    test(
      'nunca aponta o que o jogador já usa nem o que está trancado',
      () async {
        final store = await _store({
          'level': Onboarding.blitzAt,
          'seen_opened_wardrobe': true,
          'seen_opened_loja': true,
          'seen_opened_passe': true,
        });
        final tema = DicaDoDia.paraHoje(store, dia, lojaExiste: true);
        expect(tema, TemaDica.blitz);
        await DicaDoDia.mostrada(store, tema!, dia);
        // Not again today.
        expect(DicaDoDia.paraHoje(store, dia, lojaExiste: true), isNull);
        // Tomorrow, the next one: the Tower is still locked at this level.
        final amanha = dia.add(const Duration(days: 1));
        expect(
          DicaDoDia.paraHoje(store, amanha, lojaExiste: true),
          isNot(tema),
        );
        expect(
          DicaDoDia.liberado(store, TemaDica.torre, dia, lojaExiste: true),
          isFalse,
        );
      },
    );

    test('quem já usava antes da 1.16 também conta como usado', () async {
      final store = await _store({
        'level': 20,
        'unlockedHats': ['helmet', 'touca'],
        'villageItems': ['flores'],
        'rankingNome': 'Ana',
        'blitzBestScore': 300,
        'towerBestHeight': 5,
        'ownedProducts': ['remover_anuncios'],
      });
      for (final t in [
        TemaDica.guardaRoupa,
        TemaDica.vila,
        TemaDica.ranking,
        TemaDica.blitz,
        TemaDica.torre,
        TemaDica.loja,
      ]) {
        expect(DicaDoDia.usado(store, t, dia), isTrue, reason: t.name);
      }
      expect(DicaDoDia.usado(store, TemaDica.duelo, dia), isFalse);
    });

    test(
      'sem loja, a loja não é dica; desafio feito hoje também não',
      () async {
        final store = await _store({'level': Onboarding.dailyAt});
        expect(
          DicaDoDia.liberado(store, TemaDica.loja, dia, lojaExiste: false),
          isFalse,
        );
        expect(
          DicaDoDia.liberado(
            store,
            TemaDica.desafioDiario,
            dia,
            lojaExiste: true,
          ),
          isTrue,
        );
        await store.completeDaily(dia);
        expect(
          DicaDoDia.liberado(
            store,
            TemaDica.desafioDiario,
            dia,
            lojaExiste: true,
          ),
          isFalse,
        );
      },
    );

    test('toda dica tem texto e marca de tela própria', () {
      final marcas = {for (final t in TemaDica.values) t.aberto};
      expect(marcas, hasLength(TemaDica.values.length));
      for (final t in TemaDica.values) {
        expect(t.texto, isNotEmpty);
      }
    });
  });

  group('cartão Modos', () {
    List<EstadoModo> modos({
      int fase = 20,
      Set<Atalho> abertos = const {},
      Set<Atalho> novidade = const {},
      Map<Atalho, String> recordes = const {},
    }) => [
      for (final a in [
        Atalho.infinito,
        Atalho.obras,
        Atalho.blitz,
        Atalho.duelo,
        Atalho.torre,
      ])
        EstadoModo(
          a,
          liberado: fase >= a.liberaNaFase!,
          aberto: abertos.contains(a),
          novidade: novidade.contains(a),
          recorde: recordes[a],
        ),
    ];
    final todos = {
      Atalho.infinito,
      Atalho.obras,
      Atalho.blitz,
      Atalho.duelo,
      Atalho.torre,
    };

    test('resultado de duelo vem primeiro', () {
      expect(
        MenuEstado.modosSubtitulo(modos(), resultadosDuelo: 1),
        'Duelo: resultado novo!',
      );
      expect(
        MenuEstado.modosSubtitulo(modos(), resultadosDuelo: 3),
        'Duelo: 3 resultados novos!',
      );
      // Not before the Duel opens.
      expect(
        MenuEstado.modosSubtitulo(modos(fase: 5), resultadosDuelo: 1),
        isNot(startsWith('Duelo')),
      );
    });

    test('modo liberado e nunca aberto', () {
      expect(MenuEstado.modosSubtitulo(modos(fase: 5)), 'Infinito liberado!');
      expect(
        MenuEstado.modosSubtitulo(modos(fase: 8, abertos: {Atalho.infinito})),
        '3 modos novos',
      );
    });

    test('novidade, próximo modo e recorde', () {
      expect(
        MenuEstado.modosSubtitulo(
          modos(abertos: todos, novidade: {Atalho.torre}),
        ),
        'Torre do Capi: novidade!',
      );
      expect(
        MenuEstado.modosSubtitulo(
          modos(fase: 6, abertos: {Atalho.infinito, Atalho.obras}),
        ),
        '2 modos na fase 8',
      );
      expect(MenuEstado.modosSubtitulo(modos(fase: 4)), 'Infinito na fase 5');
      expect(
        MenuEstado.modosSubtitulo(
          modos(abertos: todos, recordes: {Atalho.torre: '34'}),
        ),
        'Torre do Capi: 34 andares',
      );
      expect(
        MenuEstado.modosSubtitulo(
          modos(abertos: todos, recordes: {Atalho.blitz: '1.200'}),
        ),
        'Blitz 60s: recorde 1.200',
      );
      expect(MenuEstado.modosSubtitulo(modos(abertos: todos)), isNotEmpty);
      // Never the sheet's own title (the browser tests look for it).
      expect(
        MenuEstado.modosSubtitulo(modos(abertos: todos)),
        isNot('Modos de jogo'),
      );
    });

    test('os recordes se revezam por dia', () {
      final m = modos(
        abertos: todos,
        recordes: {Atalho.blitz: '10', Atalho.torre: '3'},
      );
      expect(
        MenuEstado.modosSubtitulo(m, dia: 1),
        isNot(MenuEstado.modosSubtitulo(m, dia: 2)),
      );
    });
  });

  group('marca da Loja', () {
    test('ofertas do dia até abrir a loja hoje', () {
      expect(
        MenuEstado.motivoLoja(
          ofertaNoAr: false,
          cofrinhoCheio: false,
          lojaVistaDia: hoje - 1,
          hoje: hoje,
        ),
        MotivoLoja.ofertasDoDia,
      );
      expect(
        MenuEstado.motivoLoja(
          ofertaNoAr: false,
          cofrinhoCheio: false,
          lojaVistaDia: hoje,
          hoje: hoje,
        ),
        isNull,
      );
    });

    test(
      'oferta e cofrinho cheio ficam marcados; o balão só chama se é novo',
      () {
        final motivo = MenuEstado.motivoLoja(
          ofertaNoAr: true,
          cofrinhoCheio: true,
          lojaVistaDia: hoje,
          hoje: hoje,
        );
        expect(motivo, MotivoLoja.oferta);
        expect(
          MenuEstado.lojaChama(motivo, lojaVistaDia: hoje, hoje: hoje),
          isFalse,
        );
        expect(
          MenuEstado.lojaChama(motivo, lojaVistaDia: hoje - 1, hoje: hoje),
          isTrue,
        );
        expect(
          MenuEstado.motivoLoja(
            ofertaNoAr: false,
            cofrinhoCheio: true,
            lojaVistaDia: hoje,
            hoje: hoje,
          ),
          MotivoLoja.cofrinhoCheio,
        );
        expect(
          MenuEstado.lojaChama(null, lojaVistaDia: 0, hoje: hoje),
          isFalse,
        );
      },
    );

    test('o dia em que a loja foi aberta fica guardado', () async {
      final store = await _store();
      expect(store.lojaVistaDia, 0);
      await store.setLojaVistaDia(hoje);
      expect(store.lojaVistaDia, hoje);
    });
  });

  testWidgets('cartão pequeno mostra a linha de estado sem estourar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 96,
              child: MenuCard(
                compact: true,
                icon: Icons.sports_esports_rounded,
                color: Colors.purple,
                title: 'Modos',
                subtitle: 'Duelo: 12 resultados novos!',
                badge: 'NOVO',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Duelo: 12 resultados novos!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
