import 'dart:ui';

import '../l10n/idioma.dart';
import '../services/progress_store.dart';
import 'hats.dart';

/// Where an item sits on Capi.
enum Slot {
  cabeca('Cabeça'),
  rosto('Rosto'),
  pescoco('Pescoço'),
  costas('Costas'),
  pelagem('Pelagem');

  const Slot(this._label);
  final String _label;
  String get label => tr(_label);
}

/// How rare an item is: sets its frame color and how it is earned.
enum Raridade {
  comum('Comum', Color(0xFF94A3B8)),
  raro('Raro', Color(0xFF4DABF7)),
  epico('Épico', Color(0xFFB57CF7)),
  lendario('Lendário', Color(0xFFFFC94D));

  const Raridade(this._label, this.color);
  final String _label;
  final Color color;
  String get label => tr(_label);
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

  /// The collection's name in Portuguese, as in [Colecao] (not translated).
  final String colecao;
}

/// Comes with a purchase in the shop (Remover anúncios, Pacote Inicial).
class Loja extends Fonte {
  const Loja(this._texto);
  final String _texto;
  String get texto => tr(_texto);
}

/// From the Passe do Capi of one month's season (exclusive to it): on the
/// track, or ([naCompra]) given the moment the premium track is bought.
/// Outside that month it is not on offer (and hidden from players who don't
/// have it); it comes back with the same month's season a year later.
class Passe extends Fonte {
  const Passe(this.mes, {this.naCompra = false});

  /// The month (1 to 12) of the season it belongs to.
  final int mes;
  final bool naCompra;
}

/// From inviting friends (see core/convites.dart): [amigos] friends who came
/// in with the player's code, or 0 for the gift of whoever comes in with a
/// friend's code.
class Amizade extends Fonte {
  const Amizade(this.amigos);
  final int amigos;
}

/// Sold now and then in the Mercado do Capi (see [Mercado]).
class NoMercado extends Fonte {
  const NoMercado();
}

/// An item Capi can wear. [id]s are saved on the player's phone, so they
/// never change (the hats keep their old ids).
class Cosmetic {
  const Cosmetic(
    this.id,
    this._label,
    this.slot,
    this.raridade,
    this.fonte, {
    this._descricao = '',
  });

  final String id;
  final Slot slot;
  final Raridade raridade;
  final Fonte fonte;

  /// Kept in Portuguese (the translation keys), shown in the current
  /// language.
  final String _label;
  final String _descricao;
  String get label => tr(_label);
  String get descricao => _descricao.isEmpty ? '' : tr(_descricao);

  int? get preco => switch (fonte) {
    Estrelas(:final preco) => preco,
    _ => null,
  };

  /// How to get it, for a locked item.
  String get comoGanhar => switch (fonte) {
    Gratis() => tr('Grátis'),
    Estrelas(:final preco) => tr('{n} estrelas', {'n': preco}),
    PremioColecao(:final colecao) => tr('Complete a coleção {colecao}', {
      'colecao': tr(colecao),
    }),
    Loja(:final texto) => texto,
    Passe(:final mes, :final naCompra) =>
      DateTime.now().month == mes
          ? (naCompra
                ? tr('Vem com o premium do Passe deste mês')
                : tr('Trilha do Passe do Capi deste mês'))
          : tr('Volta no Passe de {mes}', {'mes': nomeDoMes(mes)}),
    NoMercado() => tr('Aparece nas Ofertas do dia, na Loja'),
    Amizade(amigos: 0) => tr('Presente de quem entra pelo convite de um amigo'),
    Amizade(:final amigos) => trN(
      amigos,
      'Convide {n} amigo para jogar',
      'Convide {n} amigos para jogar',
    ),
  };

  /// The hat this item is, for the head slot.
  CapiHat? get hat => slot == Slot.cabeca ? CapiHat.fromIdOrNull(id) : null;
}

/// A themed set: owning every item gives the prize.
class Colecao {
  const Colecao(this._nome, this.itens, this.premio);

  /// The name in Portuguese (also what [PremioColecao] refers to).
  final String _nome;
  final List<String> itens;
  final String premio;
  String get nome => tr(_nome);
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

/// The catalog. Prices (agreed with the owner, see docs/economia.md): a
/// regular player earns about 35 to 60 stars a day, so a common item is
/// about a day of play and a rare one about a week, or 5 videos.
abstract final class Wardrobe {
  static const precoComum = 40;
  static const precoRaro = 150;

  /// A rare item can also be earned with this many videos, at most
  /// [videosPorDia] wardrobe videos a day.
  static const videosRaro = 5;
  static const videosPorDia = 5;
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
      Passe(11),
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
      NoMercado(),
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
      NoMercado(),
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
      NoMercado(),
      descricao: 'Todas as cores dos blocos.',
    ),
    Cosmetic(
      'galaxia',
      'Galáxia',
      Slot.pelagem,
      Raridade.lendario,
      NoMercado(),
      descricao: 'Pelo azul-noite, cheio de estrelinhas.',
    ),

    // Exclusive to the Passe do Capi (rare, on the premium track).
    Cosmetic(
      'oculos_estrelados',
      'Óculos Estrelados',
      Slot.rosto,
      Raridade.raro,
      Passe(11),
      descricao: 'Do Passe do Capi de novembro.',
    ),
    Cosmetic(
      'medalha',
      'Medalha da Temporada',
      Slot.pescoco,
      Raridade.raro,
      Passe(11),
      descricao: 'Do Passe do Capi de novembro.',
    ),

    // The Christmas season (December's Passe do Capi).
    Cosmetic(
      'gorro_natal',
      'Gorro de Papai Noel',
      Slot.cabeca,
      Raridade.lendario,
      Passe(12, naCompra: true),
      descricao: 'Ho-ho-ho! Vem na hora com o Passe de Natal.',
    ),
    Cosmetic(
      'chifres_rena',
      'Chifres de Rena',
      Slot.cabeca,
      Raridade.epico,
      Passe(12),
      descricao: 'Para puxar o trenó dos blocos.',
    ),
    Cosmetic(
      'cachecol_natal',
      'Cachecol Natalino',
      Slot.pescoco,
      Raridade.raro,
      Passe(12),
      descricao: 'Listrado de vermelho e verde, quentinho.',
    ),
    Cosmetic(
      'sininho',
      'Sininho de Natal',
      Slot.pescoco,
      Raridade.comum,
      Passe(12),
      descricao: 'Plim-plim a cada linha limpa.',
    ),

    // From inviting friends.
    Cosmetic(
      'laco_amizade',
      'Laço da Amizade',
      Slot.pescoco,
      Raridade.raro,
      Amizade(0),
      descricao: 'Presente para quem chega pelo convite de um amigo.',
    ),
    Cosmetic(
      'faixa_embaixador',
      'Faixa de Embaixador',
      Slot.pescoco,
      Raridade.epico,
      Amizade(3),
      descricao: 'Para o Capi Embaixador, que trouxe 3 amigos.',
    ),
    Cosmetic(
      'coroa_amizade',
      'Coroa de Amizade',
      Slot.cabeca,
      Raridade.lendario,
      Amizade(5),
      descricao: 'Corações dourados: 5 amigos na Vila do Capi.',
    ),

    // The summer season (January's Passe do Capi).
    Cosmetic(
      'chapeu_melancia',
      'Chapéu de Melancia',
      Slot.cabeca,
      Raridade.lendario,
      Passe(1, naCompra: true),
      descricao: 'Refrescante: vem na hora com o Passe de Verão.',
    ),
    Cosmetic(
      'mascara_mergulho',
      'Máscara de Mergulho',
      Slot.rosto,
      Raridade.raro,
      Passe(1),
      descricao: 'Com snorkel, para mergulhar nos combos.',
    ),
    Cosmetic(
      'prancha_surfe',
      'Prancha de Surfe',
      Slot.costas,
      Raridade.epico,
      Passe(1),
      descricao: 'Pegando a onda das linhas limpas.',
    ),
    Cosmetic(
      'colar_conchas',
      'Colar de Conchas',
      Slot.pescoco,
      Raridade.comum,
      Passe(1),
      descricao: 'Achadinhos da praia, com uma estrela-do-mar.',
    ),

    // More legendaries for the Mercado.
    Cosmetic(
      'colar_diamante',
      'Colar de Diamante',
      Slot.pescoco,
      Raridade.lendario,
      NoMercado(),
      descricao: 'Brilha a cada combo.',
    ),
    Cosmetic(
      'jetpack',
      'Mochila a Jato',
      Slot.costas,
      Raridade.lendario,
      NoMercado(),
      descricao: 'Para chegar mais rápido à próxima fase.',
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

  /// Whether [c] shows in the wardrobe: a season's item only in its month,
  /// or for whoever already has it (theirs to wear forever).
  static bool visivel(ProgressStore store, Cosmetic c, DateTime agora) =>
      switch (c.fonte) {
        Passe(:final mes) => mes == agora.month || owns(store, c),
        _ => true,
      };

  /// What shows in [slot] now (see [visivel]).
  static List<Cosmetic> visiveis(
    ProgressStore store,
    Slot slot,
    DateTime agora,
  ) => [
    for (final c in inSlot(slot))
      if (visivel(store, c, agora)) c,
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

  /// Videos watched toward [item] (a rare one), and whether one more can
  /// be watched today.
  static int videos(ProgressStore store, Cosmetic item) =>
      store.itemVideos(item.id);

  static bool podeVerVideo(ProgressStore store, Cosmetic item, DateTime dia) =>
      item.raridade == Raridade.raro &&
      item.fonte is Estrelas &&
      !owns(store, item) &&
      store.videosToday('guardaRoupa', dia) < videosPorDia;

  /// Counts one watched video toward [item]; the [videosRaro]th gives it.
  /// Returns true when the item is now the player's.
  static Future<bool> videoVisto(
    ProgressStore store,
    Cosmetic item,
    DateTime dia,
  ) async {
    if (!podeVerVideo(store, item, dia)) return false;
    await store.addVideoToday('guardaRoupa', dia);
    await store.addItemVideo(item.id);
    if (store.itemVideos(item.id) < videosRaro) return false;
    await store.unlockHat(item.id);
    await awardCollections(store);
    return true;
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

/// A month's name (1 to 12), in the current language.
String nomeDoMes(int mes) => tr(
  const [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ][mes - 1],
);
