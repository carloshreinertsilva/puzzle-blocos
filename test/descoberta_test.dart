import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/descoberta.dart';
import 'package:puzzle_blocos/core/ofertas.dart';
import 'package:puzzle_blocos/core/passe.dart';
import 'package:puzzle_blocos/game/onboarding.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store([Map<String, Object> salvo = const {}]) async {
  SharedPreferences.setMockInitialValues(salvo);
  return ProgressStore.load();
}

final novembro = DateTime(2026, 11, 15);

void main() {
  test('vencer a fase anterior à do modo mostra o modo liberado', () {
    expect(Descoberta.liberadosAoVencer(Onboarding.endlessAt - 1), [
      Atalho.infinito,
    ]);
    expect(Descoberta.liberadosAoVencer(Onboarding.obrasAt - 1), [
      Atalho.obras,
    ]);
    expect(Descoberta.liberadosAoVencer(Onboarding.dailyAt - 1), [
      Atalho.desafioDiario,
    ]);
    // Blitz and Duelo open together.
    expect(Descoberta.liberadosAoVencer(Onboarding.blitzAt - 1), [
      Atalho.blitz,
      Atalho.duelo,
    ]);
    expect(Descoberta.liberadosAoVencer(Onboarding.towerAt - 1), [
      Atalho.torre,
    ]);
  });

  test('nas outras fases nada é anunciado, e Passe e Loja nunca são modos', () {
    for (final fase in [1, 2, 3, Onboarding.towerAt, 20, 90]) {
      expect(Descoberta.liberadosAoVencer(fase), isEmpty, reason: '$fase');
    }
    for (var fase = 0; fase < 100; fase++) {
      final l = Descoberta.liberadosAoVencer(fase);
      expect(l, isNot(contains(Atalho.passe)));
      expect(l, isNot(contains(Atalho.loja)));
    }
  });

  test('o Passe diz quanto falta para o próximo prêmio grátis', () async {
    final store = await _store();
    final linha = Descoberta.passe(store, novembro)!;
    expect(linha.prontas, 0);
    expect(linha.faltam, PasseDoCapi.pontosPorNivel);
    expect(linha.premio, PasseDoCapi.trilha(novembro).first.gratis.texto);
    expect(linha.texto, contains('${PasseDoCapi.pontosPorNivel}'));

    // 12 stars earned by playing: 12 points.
    await store.addStars(12);
    expect(
      Descoberta.passe(store, novembro)!.faltam,
      PasseDoCapi.pontosPorNivel - 12,
    );
  });

  test('com prêmio pronto no Passe, a linha fala dele', () async {
    final store = await _store();
    await store.addStars(PasseDoCapi.pontosPorNivel + 5);
    final linha = Descoberta.passe(store, novembro)!;
    expect(linha.prontas, 1);
    expect(linha.texto, 'Passe: 1 prêmio pronto!');

    await PasseDoCapi.pegar(store, novembro, 1, trilhaPremium: false);
    final depois = Descoberta.passe(store, novembro)!;
    expect(depois.prontas, 0);
    expect(depois.faltam, PasseDoCapi.pontosPorNivel - 5);
    expect(depois.premio, PasseDoCapi.trilha(novembro)[1].gratis.texto);
  });

  test('Passe completo e todo pego: a linha some', () async {
    final store = await _store();
    await store.addStars(PasseDoCapi.pontosPorNivel * PasseDoCapi.niveis);
    for (var n = 1; n <= PasseDoCapi.niveis; n++) {
      await PasseDoCapi.pegar(store, novembro, n, trilhaPremium: false);
    }
    expect(Descoberta.passe(store, novembro), isNull);
  });

  test('o Cofrinho só aparece quando já vale quebrar', () async {
    final store = await _store();
    expect(Descoberta.cofrinho(store), isNull);
    await store.addStars(Cofrinho.minimo - 1);
    expect(Descoberta.cofrinho(store), isNull);
    await store.addStars(1);
    expect(
      Descoberta.cofrinho(store),
      'Cofrinho: ${Cofrinho.minimo} estrelas guardadas',
    );
    await store.addStars(Cofrinho.capacidade);
    expect(
      Descoberta.cofrinho(store),
      'Cofrinho cheio: ${Cofrinho.capacidade} estrelas!',
    );
  });
}
