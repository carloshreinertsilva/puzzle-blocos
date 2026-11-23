import '../core/hats.dart';
import '../core/ofertas.dart';
import '../core/passe.dart';
import '../core/wardrobe.dart';
import '../l10n/idioma.dart';
import '../services/progress_store.dart';

/// What the shop sells. The ids are the product ids registered in the Play
/// Console (Monetizar → Produtos no app); the prices there win, [precoBase]
/// only shows while the store hasn't answered. See `docs/loja.md`.
enum Produto {
  removerAnuncios(
    'remover_anuncios',
    'Remover anúncios',
    'Sem anúncios entre fases, para sempre. De presente: a Cartola VIP.',
    'R\$ 19,90',
  ),
  pacoteInicial(
    'pacote_inicial',
    'Pacote Inicial',
    'Sem anúncios + 500 estrelas + Capacete Fundador + Cartola VIP + '
        'kit de ferramentas.',
    'R\$ 24,90',
  ),
  estrelas150('estrelas_150', '150 estrelas', '', 'R\$ 4,90', estrelas: 150),
  estrelas400('estrelas_400', '400 estrelas', '', 'R\$ 9,90', estrelas: 400),
  estrelas1000(
    'estrelas_1000',
    '1.000 estrelas',
    '',
    'R\$ 19,90',
    estrelas: 1000,
  ),
  kitFerramentas(
    'kit_ferramentas',
    'Kit de ferramentas',
    '3 martelos, 3 pás e 3 trocas de peças.',
    'R\$ 4,90',
  ),
  cofrinho(
    'cofrinho_capi',
    'Cofrinho do Capi',
    'Quebre o cofrinho e leve todas as estrelas guardadas.',
    'R\$ 4,90',
  ),
  ofertaBoasVindas(
    'oferta_boas_vindas',
    'Oferta de boas-vindas',
    '100 estrelas + 1 martelo, 1 pá e 1 troca de peças. Só uma vez.',
    'R\$ 2,90',
  ),
  passeCapi(
    'passe_capi',
    'Passe do Capi premium',
    'Trilha premium da temporada: itens exclusivos, mais estrelas e '
        'ferramentas, +1 dica grátis por partida e estrelas em dobro no '
        'Desafio diário.',
    'R\$ 9,90',
  ),

  // Legendary items sold in the Mercado do Capi (one a day, see mercado.dart).
  lendarioMascara(
    'lendario_mascara_heroi',
    'Máscara de Herói',
    'Item lendário do Capi.',
    'R\$ 9,90',
    item: 'mascara_heroi',
  ),
  lendarioAsinhas(
    'lendario_asinhas',
    'Asinhas de Anjo',
    'Item lendário do Capi.',
    'R\$ 9,90',
    item: 'asinhas',
  ),
  lendarioArcoIris(
    'lendario_arco_iris',
    'Pelagem Arco-Íris',
    'Item lendário do Capi.',
    'R\$ 9,90',
    item: 'arco_iris',
  ),
  lendarioGalaxia(
    'lendario_galaxia',
    'Pelagem Galáxia',
    'Item lendário do Capi.',
    'R\$ 9,90',
    item: 'galaxia',
  ),
  lendarioColar(
    'lendario_colar_diamante',
    'Colar de Diamante',
    'Item lendário do Capi.',
    'R\$ 9,90',
    item: 'colar_diamante',
  ),
  lendarioJetpack(
    'lendario_jetpack',
    'Mochila a Jato',
    'Item lendário do Capi.',
    'R\$ 9,90',
    item: 'jetpack',
  );

  const Produto(
    this.id,
    this._nome,
    this._descricao,
    this.precoBase, {
    this.estrelas = 0,
    this.item,
  });

  /// The wardrobe item a legendary product gives.
  final String? item;

  static Produto? porItem(String itemId) {
    for (final p in values) {
      if (p.item == itemId) return p;
    }
    return null;
  }

  final String id;
  final String precoBase;

  /// Name and description in Portuguese (the translation keys), shown in
  /// the current language.
  final String _nome;
  final String _descricao;
  String get nome => tr(_nome);
  String get descricao => _descricao.isEmpty ? '' : tr(_descricao);

  /// Stars in a star pack.
  final int estrelas;

  /// Star packs, the tool kit and the pass (once per season) can be bought
  /// again; the rest once, and come back with "Restaurar compras".
  bool get consumivel =>
      estrelas > 0 ||
      this == kitFerramentas ||
      this == passeCapi ||
      this == cofrinho;

  static Produto? porId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// How long after the first opening the starter pack is offered.
const ofertaPacoteInicial = Duration(days: 3);

abstract final class Entrega {
  /// Gives what [produto] promises. One-time products give their content
  /// only the first time; consumables only once per store purchase
  /// ([compraId]), however often the store reports it.
  static Future<void> aplicar(
    ProgressStore store,
    Produto produto, {
    String? compraId,
    DateTime? agora,
  }) async {
    if (produto.consumivel) {
      if (compraId != null && store.purchaseDelivered(compraId)) return;
      if (produto.estrelas > 0) {
        await store.addBoughtStars(produto.estrelas);
      } else if (produto == Produto.cofrinho) {
        await store.addBoughtStars(Cofrinho.conteudo(store));
        await store.esvaziarCofrinho();
      } else if (produto == Produto.passeCapi) {
        // The premium track of the season it was bought in, and that
        // month's exclusive item at once (worn straight away).
        final quando = agora ?? DateTime.now();
        await store.setPassPremium(PasseDoCapi.temporada(quando));
        if (PasseDoCapi.tema(quando)?.naCompra case final id?) {
          await _vestir(store, id);
        }
      } else {
        await _kit(store);
      }
      if (compraId != null) await store.markPurchaseDelivered(compraId);
      return;
    }
    final primeiraVez = !store.owns(produto.id);
    if (produto.item case final id?) {
      await _vestir(store, id);
      await store.addOwnedProduct(produto.id);
      return;
    }
    if (produto == Produto.ofertaBoasVindas) {
      // Just a start: nothing the starter pack's buyers have.
      if (primeiraVez) {
        await store.addBoughtStars(OfertaBoasVindas.estrelas);
        for (final t in [CapiTool.hammer, CapiTool.shovel, CapiTool.reroll]) {
          await store.addTool(t, OfertaBoasVindas.ferramentas);
        }
      }
      await store.addOwnedProduct(produto.id);
      return;
    }
    await store.setAdsRemoved(true);
    switch (produto) {
      case Produto.removerAnuncios:
        await _vestir(store, CapiHat.vip.id);
      case Produto.pacoteInicial:
        await _vestir(store, CapiHat.vip.id);
        await _vestir(store, CapiHat.fundador.id);
        if (primeiraVez) {
          await store.addBoughtStars(PacoteInicial.estrelas);
          await _kit(store);
          await store.markSeen(PacoteInicial.bonusVisto);
        }
      default:
        break;
    }
    await store.addOwnedProduct(produto.id);
  }

  /// Players who bought the starter pack when it had 300 stars and no VIP
  /// hat or tool kit get the difference once, so they never have less than
  /// a new buyer. Returns whether it was given now.
  static Future<bool> bonusFundador(ProgressStore store) async {
    if (!store.owns(Produto.pacoteInicial.id) ||
        store.hasSeen(PacoteInicial.bonusVisto)) {
      return false;
    }
    await store.markSeen(PacoteInicial.bonusVisto);
    await store.addBoughtStars(PacoteInicial.estrelas - 300);
    await _kit(store);
    if (!store.unlockedHats.contains(CapiHat.vip.id)) {
      await store.unlockHat(CapiHat.vip.id);
    }
    return true;
  }

  /// The starter pack shows for the first days, for players who still see
  /// ads and haven't bought it.
  static bool mostraPacoteInicial(ProgressStore store, DateTime agora) {
    final inicio = store.firstOpenAt;
    return inicio != null &&
        !store.adsRemoved &&
        !store.owns(Produto.pacoteInicial.id) &&
        agora.difference(inicio) < ofertaPacoteInicial;
  }
}

/// What the starter pack gives besides removing ads and the two hats.
abstract final class PacoteInicial {
  static const estrelas = 500;
  static const bonusVisto = 'bonus_fundador_2';
}

Future<void> _kit(ProgressStore store) async {
  await store.addTool(CapiTool.hammer, 3);
  await store.addTool(CapiTool.shovel, 3);
  await store.addTool(CapiTool.reroll, 3);
}

/// A bought item is given and put on at once: the player paid to see Capi
/// wearing it (on the menu, in the village, everywhere).
/// A restored purchase (already owned) keeps what the player wears now.
Future<void> _vestir(ProgressStore store, String id) async {
  if (store.unlockedHats.contains(id)) return;
  await store.unlockHat(id);
  final item = Wardrobe.byId(id);
  if (item != null) await Wardrobe.equip(store, item);
}
