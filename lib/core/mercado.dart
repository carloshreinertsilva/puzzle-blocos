import '../services/progress_store.dart';
import '../shop/produtos.dart';
import 'wardrobe.dart';

/// The Mercado do Capi: three offers that change every day at midnight, the
/// same for everyone and in a fixed order (no draw): one legendary item for
/// money, and a common and a rare one for stars with a discount.
abstract final class Mercado {
  /// Star offers cost this share of the usual price.
  static const desconto = 0.8;

  static final _inicio = DateTime(2026, 11, 1);

  static int _dia(DateTime d) =>
      DateTime(d.year, d.month, d.day).difference(_inicio).inDays.abs();

  static List<Cosmetic> get lendarios => [
    for (final c in Wardrobe.catalog)
      if (c.fonte is NoMercado) c,
  ];

  static List<Cosmetic> _comPreco(Raridade r) => [
    for (final c in Wardrobe.catalog)
      if (c.fonte is Estrelas && c.raridade == r) c,
  ];

  static Cosmetic lendarioDoDia(DateTime dia) {
    final l = lendarios;
    return l[_dia(dia) % l.length];
  }

  static Cosmetic comumDoDia(DateTime dia) {
    final l = _comPreco(Raridade.comum);
    return l[(_dia(dia) * 4 + 1) % l.length];
  }

  static Cosmetic raroDoDia(DateTime dia) {
    final l = _comPreco(Raridade.raro);
    return l[(_dia(dia) * 3 + 2) % l.length];
  }

  static int precoComDesconto(Cosmetic item) =>
      (item.preco! * desconto).round();

  static Produto produtoDe(Cosmetic lendario) => Produto.porItem(lendario.id)!;

  /// Buys today's common or rare offer with stars, at the discount.
  static Future<bool> comprarComEstrelas(
    ProgressStore store,
    Cosmetic item,
    DateTime dia,
  ) async {
    final hoje = item.id == comumDoDia(dia).id || item.id == raroDoDia(dia).id;
    final preco = precoComDesconto(item);
    if (!hoje || Wardrobe.owns(store, item) || store.stars < preco) {
      return false;
    }
    await store.spendStars(preco);
    await store.unlockHat(item.id);
    await Wardrobe.awardCollections(store);
    return true;
  }

  /// Time left until the offers change.
  static Duration ateTrocar(DateTime agora) =>
      DateTime(agora.year, agora.month, agora.day + 1).difference(agora);
}
