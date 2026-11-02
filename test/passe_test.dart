import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/passe.dart';
import 'package:puzzle_blocos/core/wardrobe.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/shop/produtos.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return ProgressStore.load();
}

void main() {
  test('seasons last 30 days from the start', () {
    expect(PasseDoCapi.temporada(DateTime(2026, 11, 1)), 1);
    expect(PasseDoCapi.temporada(DateTime(2026, 11, 30, 23)), 1);
    expect(PasseDoCapi.temporada(DateTime(2026, 12, 1)), 2);
    expect(PasseDoCapi.temporada(DateTime(2025, 1, 1)), 1);
    expect(PasseDoCapi.diasRestantes(DateTime(2026, 11, 30, 12)), 1);
  });

  test('the track has 30 levels and the pass-only items', () {
    expect(PasseDoCapi.niveis, 30);
    final itens = [for (final n in PasseDoCapi.trilha) ?n.premium.item];
    final doPasse = [
      for (final c in Wardrobe.catalog)
        if (c.fonte is Passe) c.id,
    ];
    expect(itens..sort(), doPasse..sort());
    for (final n in PasseDoCapi.trilha) {
      expect(n.gratis.item, isNull, reason: 'free track gives no item');
    }
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
    final store = await _store();
    final agora = DateTime.now();
    await store.addStars(PasseDoCapi.pontosPorNivel * 10);
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
    await Entrega.aplicar(store, Produto.passeCapi, compraId: 'gpa.1');
    await Entrega.aplicar(store, Produto.passeCapi, compraId: 'gpa.1');
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
}
