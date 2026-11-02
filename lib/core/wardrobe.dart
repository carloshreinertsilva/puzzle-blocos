import 'dart:ui';

import '../services/progress_store.dart';
import 'hats.dart';

/// Where an item sits on Capi.
enum Slot {
  cabeca('Cabeça'),
  rosto('Rosto'),
  pescoco('Pescoço'),
  costas('Costas'),
  pelagem('Pelagem');

  const Slot(this.label);
  final String label;
}

/// How rare an item is: sets its frame color and how it is earned.
enum Raridade {
  comum('Comum', Color(0xFF94A3B8)),
  raro('Raro', Color(0xFF4DABF7)),
  epico('Épico', Color(0xFFB57CF7)),
  lendario('Lendário', Color(0xFFFFC94D));

  const Raridade(this.label, this.color);
  final String label;
  final Color color;
}

/// How an item is earned. Nothing is ever a paid random draw (ECA Digital,
/// Lei 15.211/2025): items are bought directly, earned by playing, by
/// completing a collection, or in the Passe do Capi.
sealed class Fonte {
  const Fonte();
}

/// Free from the start.
class Gratis extends Fonte {
  const Gratis();
}

/// Bought with stars (also one of the possible free daily chest prizes).
class Estrelas extends Fonte {
  const Estrelas(this.preco);
  final int preco;
}

/// The prize for completing a collection.
class PremioColecao extends Fonte {
  const PremioColecao(this.colecao);
  final String colecao;
}

/// Comes with a purchase in the shop (Remover anúncios, Pacote Inicial).
class Loja extends Fonte {
  const Loja(this.texto);
  final String texto;
}

/// A reward on the Passe do Capi's track.
class Passe extends Fonte {
  const Passe();
}

/// An item Capi can wear. [id]s are saved on the player's phone, so they
/// never change (the hats keep their old ids).
class Cosmetic {
  const Cosmetic(
    this.id,
    this.label,
    this.slot,
    this.raridade,
    this.fonte, {
    this.descricao = '',
  });

  final String id;
  final String label;
  final Slot slot;
  final Raridade raridade;
  final Fonte fonte;
  final String descricao;

  int? get preco => switch (fonte) {
    Estrelas(:final preco) => preco,
    _ => null,
  };

  /// How to get it, for a locked item.
  String get comoGanhar => switch (fonte) {
    Gratis() => 'Grátis',
    Estrelas(:final preco) => '$preco estrelas',
    PremioColecao(:final colecao) => 'Complete a coleção $colecao',
    Loja(:final texto) => texto,
    Passe() => 'Trilha premium do Passe do Capi',
  };

  /// The hat this item is, for the head slot.
  CapiHat? get hat => slot == Slot.cabeca ? CapiHat.fromIdOrNull(id) : null;
}

/// A themed set: owning every item gives the prize.
class Colecao {
  const Colecao(this.nome, this.itens, this.premio);
  final String nome;
  final List<String> itens;
  final String premio;
}

/// What Capi is wearing, one item id per slot (null: nothing there).
class CapiLook {
  const CapiLook({
    this.hat = CapiHat.helmet,
    this.rosto,
    this.pescoco,
    this.costas,
    this.pelagem = Wardrobe.pelagemPadrao,
  });

  final CapiHat hat;
  final String? rosto;
  final String? pescoco;
  final String? costas;
  final String pelagem;

  static CapiLook of(ProgressStore store) => CapiLook(
    hat: CapiHat.fromId(store.equippedHat),
    rosto: store.equippedIn(Slot.rosto),
    pescoco: store.equippedIn(Slot.pescoco),
    costas: store.equippedIn(Slot.costas),
    pelagem: store.equippedIn(Slot.pelagem) ?? Wardrobe.pelagemPadrao,
  );

  /// This look with [item] on (a preview, nothing is saved).
  CapiLook wearing(Cosmetic item) => switch (item.slot) {
    Slot.cabeca => _copy(hat: item.hat ?? hat),
    Slot.rosto => _copy(rosto: item.id),
    Slot.pescoco => _copy(pescoco: item.id),
    Slot.costas => _copy(costas: item.id),
    Slot.pelagem => _copy(pelagem: item.id),
  };

  CapiLook _copy({
    CapiHat? hat,
    String? rosto,
    String? pescoco,
    String? costas,
    String? pelagem,
  }) => CapiLook(
    hat: hat ?? this.hat,
    rosto: rosto ?? this.rosto,
    pescoco: pescoco ?? this.pescoco,
    costas: costas ?? this.costas,
    pelagem: pelagem ?? this.pelagem,
  );

  @override
  bool operator ==(Object other) =>
      other is CapiLook &&
      other.hat == hat &&
      other.rosto == rosto &&
      other.pescoco == pescoco &&
      other.costas == costas &&
      other.pelagem == pelagem;

  @override
  int get hashCode => Object.hash(hat, rosto, pescoco, costas, pelagem);
}

/// The catalog. Prices are a first proposal: an active player earns about
/// 15 to 25 stars a day, so a common item is one or two days of play and a
/// rare one about a week.
abstract final class Wardrobe {
  static const precoComum = 25;
  static const precoRaro = 75;
  static const pelagemPadrao = 'caramelo';

  static const catalog = <Cosmetic>[
    // Head: the hats keep their old ids.
    Cosmetic(
      'helmet',
      'Capacete de Obra',
      Slot.cabeca,
      Raridade.comum,
      Gratis(),
      descricao: 'O clássico capacete amarelo do Capi construtor.',
    ),
    Cosmetic(
      'straw',
      'Chapéu de Palha',
      Slot.cabeca,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'Fresco e aconchegante para um dia na praia.',
    ),
    Cosmetic(
      'party',
      'Chapéu de Festa',
      Slot.cabeca,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'Colorido, com confetes e pompom.',
    ),
    Cosmetic(
      'touca',
      'Touca de Inverno',
      Slot.cabeca,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'Quentinha, com pompom.',
    ),
    Cosmetic(
      'chef',
      'Chapéu de Chef',
      Slot.cabeca,
      Raridade.raro,
      Estrelas(precoRaro),
      descricao: 'Para quem cozinha as melhores combinações.',
    ),
    Cosmetic(
      'pirate',
      'Tricórnio Pirata',
      Slot.cabeca,
      Raridade.raro,
      Estrelas(precoRaro),
      descricao: 'À caça de estrelas e tesouros pela ilha.',
    ),
    Cosmetic(
      'junino',
      'Chapéu Caipira',
      Slot.cabeca,
      Raridade.raro,
      Estrelas(precoRaro),
      descricao: 'Palha com remendo e fita xadrez: é arraiá!',
    ),
    Cosmetic(
      'wizard',
      'Chapéu de Mago',
      Slot.cabeca,
      Raridade.epico,
      PremioColecao('Arraiá'),
      descricao: 'Místico e estrelado.',
    ),
    Cosmetic(
      'crown',
      'Coroa Real',
      Slot.cabeca,
      Raridade.epico,
      PremioColecao('Aventura'),
      descricao: 'Dourada e nobre, digna de um rei dos blocos.',
    ),
    Cosmetic(
      'vip',
      'Cartola VIP',
      Slot.cabeca,
      Raridade.lendario,
      Loja('Vem com Remover anúncios'),
      descricao: 'Elegância de quem joga sem interrupções.',
    ),
    Cosmetic(
      'fundador',
      'Capacete Fundador',
      Slot.cabeca,
      Raridade.lendario,
      Loja('Vem com o Pacote Inicial'),
      descricao: 'Dourado, com estrela: para quem chegou primeiro.',
    ),
    Cosmetic(
      'coroa_estrelas',
      'Coroa de Estrelas',
      Slot.cabeca,
      Raridade.lendario,
      Passe(),
      descricao: 'Brilha como o céu da vila à noite.',
    ),

    // Face.
    Cosmetic(
      'oculos_sol',
      'Óculos de Sol',
      Slot.rosto,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'Estilo de praia.',
    ),
    Cosmetic(
      'bigode',
      'Bigodão',
      Slot.rosto,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'Bigode de quadrilha, bem enrolado.',
    ),
    Cosmetic(
      'oculos_coracao',
      'Óculos de Coração',
      Slot.rosto,
      Raridade.raro,
      Estrelas(precoRaro),
      descricao: 'Para quem ama montar blocos.',
    ),
    Cosmetic(
      'monoculo',
      'Monóculo',
      Slot.rosto,
      Raridade.raro,
      Estrelas(precoRaro),
      descricao: 'Muito chique, com correntinha dourada.',
    ),
    Cosmetic(
      'mascara_heroi',
      'Máscara de Herói',
      Slot.rosto,
      Raridade.lendario,
      Passe(),
      descricao: 'O protetor secreto da vila.',
    ),

    // Neck.
    Cosmetic(
      'cachecol',
      'Cachecol Listrado',
      Slot.pescoco,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'Vermelho e branco, para os dias frios.',
    ),
    Cosmetic(
      'gravata',
      'Gravata-Borboleta',
      Slot.pescoco,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'Pronto para a festa de gala.',
    ),
    Cosmetic(
      'lenco',
      'Lenço Xadrez',
      Slot.pescoco,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'O lenço da quadrilha.',
    ),
    Cosmetic(
      'colar_flores',
      'Colar de Flores',
      Slot.pescoco,
      Raridade.raro,
      Estrelas(precoRaro),
      descricao: 'Aloha! Direto da praia.',
    ),

    // Back.
    Cosmetic(
      'mochila',
      'Mochila de Trilha',
      Slot.costas,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'Cabe um lanche e muitos blocos.',
    ),
    Cosmetic(
      'boia',
      'Boia de Patinho',
      Slot.costas,
      Raridade.raro,
      Estrelas(precoRaro),
      descricao: 'Para nadar no lago da vila.',
    ),
    Cosmetic(
      'capa_real',
      'Capa Real',
      Slot.costas,
      Raridade.epico,
      PremioColecao('Gala'),
      descricao: 'Vermelha, com gola de arminho.',
    ),
    Cosmetic(
      'asinhas',
      'Asinhas de Anjo',
      Slot.costas,
      Raridade.lendario,
      Passe(),
      descricao: 'Batem de leve quando o Capi fica feliz.',
    ),

    // Fur.
    Cosmetic(
      'caramelo',
      'Caramelo',
      Slot.pelagem,
      Raridade.comum,
      Gratis(),
      descricao: 'A cor de sempre do Capi.',
    ),
    Cosmetic(
      'chocolate',
      'Chocolate',
      Slot.pelagem,
      Raridade.comum,
      Estrelas(precoComum),
      descricao: 'Pelo marrom escuro e macio.',
    ),
    Cosmetic(
      'neve',
      'Neve',
      Slot.pelagem,
      Raridade.epico,
      PremioColecao('Inverno'),
      descricao: 'Branquinho como a neve.',
    ),
    Cosmetic(
      'dourado',
      'Dourado',
      Slot.pelagem,
      Raridade.epico,
      PremioColecao('Praia'),
      descricao: 'Brilha ao sol.',
    ),
    Cosmetic(
      'arco_iris',
      'Arco-Íris',
      Slot.pelagem,
      Raridade.lendario,
      Passe(),
      descricao: 'Todas as cores dos blocos.',
    ),
  ];

  static const colecoes = <Colecao>[
    Colecao('Inverno', ['touca', 'cachecol', 'mochila'], 'neve'),
    Colecao('Praia', [
      'straw',
      'oculos_sol',
      'colar_flores',
      'boia',
    ], 'dourado'),
    Colecao('Arraiá', ['junino', 'bigode', 'lenco'], 'wizard'),
    Colecao('Gala', ['gravata', 'monoculo', 'oculos_coracao'], 'capa_real'),
    Colecao('Aventura', ['pirate', 'chef', 'party', 'chocolate'], 'crown'),
  ];

  static Cosmetic? byId(String id) {
    for (final c in catalog) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<Cosmetic> inSlot(Slot slot) => [
    for (final c in catalog)
      if (c.slot == slot) c,
  ];

  static bool owns(ProgressStore store, Cosmetic item) =>
      item.fonte is Gratis || store.unlockedHats.contains(item.id);

  /// How many items of [c] the player owns.
  static int progress(ProgressStore store, Colecao c) =>
      c.itens.where((id) => store.unlockedHats.contains(id)).length;

  /// Gives the prize of every collection just completed. Returns the prizes
  /// given now (empty if none).
  static Future<List<Cosmetic>> awardCollections(ProgressStore store) async {
    final given = <Cosmetic>[];
    for (final c in colecoes) {
      if (progress(store, c) == c.itens.length &&
          !store.unlockedHats.contains(c.premio)) {
        await store.unlockHat(c.premio);
        given.add(byId(c.premio)!);
      }
    }
    return given;
  }

  /// Buys [item] with stars. False if it can't be bought or there aren't
  /// enough stars.
  static Future<bool> buy(ProgressStore store, Cosmetic item) async {
    final preco = item.preco;
    if (preco == null || owns(store, item) || store.stars < preco) {
      return false;
    }
    await store.spendStars(preco);
    await store.unlockHat(item.id);
    return true;
  }

  static Future<void> equip(ProgressStore store, Cosmetic item) async {
    if (!owns(store, item)) return;
    if (item.slot == Slot.cabeca) {
      await store.equipHat(item.id);
    } else {
      await store.equipIn(item.slot, item.id);
    }
  }

  /// Takes the item off (not for the head or fur, which always have one).
  static Future<void> takeOff(ProgressStore store, Slot slot) async {
    if (slot == Slot.cabeca || slot == Slot.pelagem) return;
    await store.equipIn(slot, null);
  }

  /// What the free daily chest can give: common and rare items bought with
  /// stars that the player doesn't own yet. The list is shown before the
  /// chest opens.
  static List<Cosmetic> chestPool(ProgressStore store) => [
    for (final c in catalog)
      if (c.fonte is Estrelas &&
          c.raridade.index <= Raridade.raro.index &&
          !owns(store, c))
        c,
  ];
}
