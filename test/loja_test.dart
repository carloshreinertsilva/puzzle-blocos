import 'package:puzzle_blocos/core/wardrobe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/daily_missions.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/shop/loja_service.dart';
import 'package:puzzle_blocos/shop/produtos.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store([Map<String, Object> salvo = const {}]) async {
  SharedPreferences.setMockInitialValues({...salvo});
  return ProgressStore.load();
}

void main() {
  test('product ids are unique and match the Play Console list', () {
    final ids = Produto.values.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, [
      'remover_anuncios',
      'pacote_inicial',
      'estrelas_150',
      'estrelas_400',
      'estrelas_1000',
      'kit_ferramentas',
      'passe_capi',
    ]);
  });

  test('removing ads also gives the VIP top hat, only once', () async {
    final store = await _store();
    await Entrega.aplicar(store, Produto.removerAnuncios, compraId: 'a');
    await Entrega.aplicar(store, Produto.removerAnuncios, compraId: 'b');
    expect(store.adsRemoved, isTrue);
    expect(store.unlockedHats.where((h) => h == 'vip'), hasLength(1));
    expect(store.owns('remover_anuncios'), isTrue);
  });

  test(
    'the starter pack pays its 300 stars once, even when restored',
    () async {
      final store = await _store({'stars': 10});
      await Entrega.aplicar(store, Produto.pacoteInicial, compraId: 'x');
      // "Restaurar compras" brings it back.
      await Entrega.aplicar(store, Produto.pacoteInicial, compraId: 'x');
      expect(store.stars, 310);
      expect(store.adsRemoved, isTrue);
      expect(store.unlockedHats, contains('fundador'));
    },
  );

  test(
    'a star pack pays once per purchase, however often it arrives',
    () async {
      final store = await _store();
      await Entrega.aplicar(store, Produto.estrelas400, compraId: 'p1');
      await Entrega.aplicar(store, Produto.estrelas400, compraId: 'p1');
      await Entrega.aplicar(store, Produto.estrelas400, compraId: 'p2');
      expect(store.stars, 800);
      // Bought stars are not "earned" stars.
      expect(store.starsEarned, 0);
    },
  );

  test('the tool kit adds 3 hammers, shovels and swaps', () async {
    final store = await _store();
    final antes = {for (final t in CapiTool.values) t: store.toolCount(t)};
    await Entrega.aplicar(store, Produto.kitFerramentas, compraId: 'k');
    expect(store.toolCount(CapiTool.hammer), antes[CapiTool.hammer]! + 3);
    expect(store.toolCount(CapiTool.shovel), antes[CapiTool.shovel]! + 3);
    expect(store.toolCount(CapiTool.reroll), antes[CapiTool.reroll]! + 3);
    expect(store.toolCount(CapiTool.rotate), antes[CapiTool.rotate]!);
  });

  test(
    'the starter pack shows only in the first 3 days, without ads',
    () async {
      final store = await _store();
      final inicio = DateTime(2026, 11, 1, 10);
      await store.noteFirstOpen(inicio);
      await store.noteFirstOpen(inicio.add(const Duration(days: 9)));
      expect(store.firstOpenAt, inicio);
      expect(Entrega.mostraPacoteInicial(store, inicio), isTrue);
      expect(
        Entrega.mostraPacoteInicial(store, inicio.add(const Duration(days: 4))),
        isFalse,
      );
      await Entrega.aplicar(store, Produto.removerAnuncios);
      expect(Entrega.mostraPacoteInicial(store, inicio), isFalse);
    },
  );

  test('the daily chest never gives a shop-only hat', () async {
    final store = await _store();
    for (final c in Wardrobe.chestPool(store)) {
      await store.unlockHat(c.id);
    }
    // Every chest item is owned: nothing left to give.
    final day = DateTime(2026, 11, 2);
    for (final m in DailyMissionsManager.missionsFor(store, day)) {
      await store.setDailyMissionProgress(day, m.index, 999);
    }
    final hat = await DailyMissionsManager.claimChest(store, day);
    expect(hat, isNull);
    expect(store.unlockedHats, isNot(contains('vip')));
    expect(store.unlockedHats, isNot(contains('fundador')));
  });

  test('the simulated shop delivers at once', () async {
    final store = await _store();
    final loja = LojaSimulada(store);
    expect(loja.disponivel, isTrue);
    expect(await loja.comprar(Produto.estrelas150), ResultadoCompra.ok);
    expect(store.stars, 150);
    expect(SemLoja(store).disponivel, isFalse);
  });
}
