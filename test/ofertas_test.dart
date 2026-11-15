import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/ofertas.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/shop/produtos.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store([Map<String, Object> salvo = const {}]) async {
  SharedPreferences.setMockInitialValues({...salvo});
  return ProgressStore.load();
}

void main() {
  group('Cofrinho do Capi', () {
    test('fills with earned stars, not bought ones, up to the top', () async {
      final store = await _store();
      await store.addStars(40);
      expect(store.cofrinho, 40);
      await store.addBoughtStars(500);
      expect(store.cofrinho, 40);
      await store.addStars(1000);
      expect(store.cofrinho, Cofrinho.capacidade);
      expect(Cofrinho.cheio(store), isTrue);
    });

    test(
      'breaking it gives what is inside and empties it, once per purchase',
      () async {
        final store = await _store({'cofrinho': 230, 'stars': 10});
        expect(Cofrinho.podeQuebrar(store), isTrue);
        await Entrega.aplicar(store, Produto.cofrinho, compraId: 'c1');
        await Entrega.aplicar(store, Produto.cofrinho, compraId: 'c1');
        expect(store.stars, 240);
        expect(store.cofrinho, 0);
      },
    );

    test('a payment approved later still gives at least the minimum', () async {
      final store = await _store({'cofrinho': 20});
      expect(Cofrinho.podeQuebrar(store), isFalse);
      await Entrega.aplicar(store, Produto.cofrinho, compraId: 'c2');
      expect(store.stars, Cofrinho.minimo);
    });
  });

  group('Oferta de boas-vindas', () {
    final agora = DateTime(2026, 11, 20, 10);

    test('starts once for players into the game who never bought', () async {
      final novato = await _store({'level': 3});
      expect(
        OfertaBoasVindas.podeComecar(novato, agora, pacoteInicialNoAr: false),
        isFalse,
      );
      final store = await _store({'level': 12});
      expect(
        OfertaBoasVindas.podeComecar(store, agora, pacoteInicialNoAr: true),
        isFalse,
      );
      expect(
        OfertaBoasVindas.podeComecar(store, agora, pacoteInicialNoAr: false),
        isTrue,
      );
      await store.comecarOfertaBoasVindas(agora);
      expect(
        OfertaBoasVindas.podeComecar(store, agora, pacoteInicialNoAr: false),
        isFalse,
      );
      expect(OfertaBoasVindas.noAr(store, agora), isTrue);
      expect(
        OfertaBoasVindas.noAr(store, agora.add(const Duration(hours: 49))),
        isFalse,
      );
    });

    test('whoever bought anything does not get it', () async {
      final store = await _store({
        'level': 12,
        'ownedProducts': ['remover_anuncios'],
      });
      expect(
        OfertaBoasVindas.podeComecar(store, agora, pacoteInicialNoAr: false),
        isFalse,
      );
    });

    test('gives a few stars and tools once, nothing exclusive', () async {
      final store = await _store({'level': 12});
      await store.comecarOfertaBoasVindas(agora);
      await Entrega.aplicar(store, Produto.ofertaBoasVindas, compraId: 'o');
      await Entrega.aplicar(store, Produto.ofertaBoasVindas, compraId: 'o');
      expect(store.stars, OfertaBoasVindas.estrelas);
      expect(
        store.toolCount(CapiTool.hammer),
        2 + OfertaBoasVindas.ferramentas,
      );
      expect(store.unlockedHats, isNot(contains('fundador')));
      expect(store.adsRemoved, isFalse);
      expect(OfertaBoasVindas.noAr(store, agora), isFalse);
    });
  });
}
