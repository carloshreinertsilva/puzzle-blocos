import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/passe.dart';
import 'package:puzzle_blocos/core/wardrobe.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/shop/produtos.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store([Map<String, Object> salvo = const {}]) async {
  SharedPreferences.setMockInitialValues(salvo);
  return ProgressStore.load();
}

// Fixed days, so the tests don't depend on the month they run in.
final novembro = DateTime(2026, 11, 15);
final dezembro = DateTime(2026, 12, 10);
final janeiro = DateTime(2027, 1, 10);

void main() {
  test('each calendar month is a season', () {
    expect(PasseDoCapi.temporada(DateTime(2026, 11, 1)), 1);
    expect(PasseDoCapi.temporada(DateTime(2026, 11, 30, 23)), 1);
    expect(PasseDoCapi.temporada(DateTime(2026, 12, 1)), 2);
    expect(PasseDoCapi.temporada(DateTime(2026, 12, 31, 23)), 2);
    expect(PasseDoCapi.temporada(DateTime(2027, 1, 1)), 3);
    expect(PasseDoCapi.temporada(DateTime(2025, 1, 1)), 1);
    expect(PasseDoCapi.fim(2), DateTime(2027, 1, 1));
    expect(PasseDoCapi.diasRestantes(DateTime(2026, 11, 30, 12)), 1);
    expect(PasseDoCapi.diasRestantes(DateTime(2026, 12, 1)), 31);
  });

  test('every season item is on its month\'s track, once', () {
    final daTemporada = <String>[
      for (final t in PasseDoCapi.temas.values) ...t.itens,
    ];
    final doPasse = [
      for (final c in Wardrobe.catalog)
        if (c.fonte is Passe) c.id,
    ];
    expect(daTemporada.toSet().length, daTemporada.length, reason: 'repeated');
    expect(daTemporada.toSet(), doPasse.toSet());
    for (final MapEntry(key: mes, value: t) in PasseDoCapi.temas.entries) {
      for (final id in t.itens) {
        final fonte = Wardrobe.byId(id)!.fonte as Passe;
        expect(fonte.mes, mes, reason: id);
        expect(fonte.naCompra, id == t.naCompra, reason: id);
      }
    }
  });

  test('the track: 30 levels, items only where the theme puts them', () {
    expect(PasseDoCapi.niveis, 30);
    for (final agora in [novembro, dezembro, janeiro]) {
      final trilha = PasseDoCapi.trilha(agora);
      expect(trilha.length, 30);
      final tema = PasseDoCapi.tema(agora);
      for (var n = 1; n <= 30; n++) {
        expect(trilha[n - 1].gratis.item, tema?.gratis[n]);
        expect(trilha[n - 1].premium.item, tema?.premium[n]);
      }
    }
    expect(PasseDoCapi.trilha(novembro)[9].premium.item, 'oculos_estrelados');
    expect(PasseDoCapi.trilha(dezembro)[9].premium.item, 'cachecol_natal');
    expect(PasseDoCapi.trilha(dezembro)[24].gratis.item, 'sininho');
    expect(PasseDoCapi.tema(janeiro)!.naCompra, 'chapeu_melancia');
    expect(PasseDoCapi.trilha(janeiro)[19].premium.item, 'prancha_surfe');
    // A month without a theme: stars and tools only.
    final semTema = DateTime(2027, 3, 10);
    expect(PasseDoCapi.tema(semTema), isNull);
    expect([
      for (final n in PasseDoCapi.trilha(semTema)) ...[
        ?n.gratis.item,
        ?n.premium.item,
      ],
    ], isEmpty);
  });

  test(
    'stars earned by playing are pass points; bought ones are not',
    () async {
      final store = await _store();
      final agora = DateTime.now();
      await store.addStars(65);
      await store.addBoughtStars(400);
      expect(PasseDoCapi.pontos(store, agora), 65);
      expect(PasseDoCapi.nivel(store, agora), 2);
    },
  );

  test('free rewards once; premium only with the pass', () async {
    final store = await _store({
      'passPoints_1': PasseDoCapi.pontosPorNivel * 10,
    });
    final agora = novembro;
    final antes = store.stars;

    expect(
      await PasseDoCapi.pegar(store, agora, 1, trilhaPremium: false),
      isTrue,
    );
    expect(store.stars, antes + 3);
    expect(
      await PasseDoCapi.pegar(store, agora, 1, trilhaPremium: false),
      isFalse,
    );
    expect(
      await PasseDoCapi.pegar(store, agora, 11, trilhaPremium: false),
      isFalse,
      reason: 'level not reached',
    );
    expect(
      await PasseDoCapi.pegar(store, agora, 10, trilhaPremium: true),
      isFalse,
      reason: 'no premium',
    );

    // Bought (the store may report the same purchase twice).
    await Entrega.aplicar(
      store,
      Produto.passeCapi,
      compraId: 'gpa.1',
      agora: agora,
    );
    await Entrega.aplicar(
      store,
      Produto.passeCapi,
      compraId: 'gpa.1',
      agora: agora,
    );
    expect(PasseDoCapi.premium(store, agora), isTrue);
    expect(store.adsRemoved, isFalse, reason: 'the pass does not remove ads');

    expect(
      await PasseDoCapi.pegar(store, agora, 10, trilhaPremium: true),
      isTrue,
    );
    expect(store.unlockedHats, contains('oculos_estrelados'));
    // Claimed reward stars don't add pass points.
    expect(PasseDoCapi.pontos(store, agora), PasseDoCapi.pontosPorNivel * 10);
    expect(PasseDoCapi.prontas(store, agora), 18);
  });

  test(
    'Christmas: the Santa hat comes at once with the premium track',
    () async {
      final store = await _store();
      expect(store.unlockedHats, isNot(contains('gorro_natal')));
      await Entrega.aplicar(
        store,
        Produto.passeCapi,
        compraId: 'gpa.natal',
        agora: dezembro,
      );
      expect(PasseDoCapi.premium(store, dezembro), isTrue);
      expect(store.unlockedHats, contains('gorro_natal'));
      expect(store.equippedHat, 'gorro_natal', reason: 'worn straight away');

      // November's pass gives no item on purchase.
      final outra = await _store();
      await Entrega.aplicar(
        outra,
        Produto.passeCapi,
        compraId: 'gpa.nov',
        agora: novembro,
      );
      expect(PasseDoCapi.premium(outra, novembro), isTrue);
      expect(outra.equippedHat, 'helmet');
    },
  );

  test('a season\'s items show in its month, or for who has them', () async {
    final store = await _store();
    final gorro = Wardrobe.byId('gorro_natal')!;
    final coroa = Wardrobe.byId('coroa_estrelas')!;
    expect(Wardrobe.visivel(store, gorro, dezembro), isTrue);
    expect(Wardrobe.visivel(store, gorro, janeiro), isFalse);
    final melancia = Wardrobe.byId('chapeu_melancia')!;
    expect(Wardrobe.visivel(store, melancia, janeiro), isTrue);
    expect(Wardrobe.visivel(store, melancia, dezembro), isFalse);
    expect(Wardrobe.visivel(store, coroa, novembro), isTrue);
    expect(Wardrobe.visivel(store, coroa, dezembro), isFalse);
    // Bought or earned: the player's to wear, any month.
    await store.unlockHat('coroa_estrelas');
    expect(Wardrobe.visivel(store, coroa, dezembro), isTrue);
    // Items outside the pass always show.
    expect(Wardrobe.visivel(store, Wardrobe.byId('touca')!, janeiro), isTrue);
    expect(
      Wardrobe.visiveis(store, Slot.cabeca, janeiro).map((c) => c.id),
      isNot(contains('gorro_natal')),
    );
  });
}
