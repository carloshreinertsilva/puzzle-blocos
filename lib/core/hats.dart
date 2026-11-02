import '../services/progress_store.dart';

/// The collectible hats that Capi can wear.
enum CapiHat {
  helmet(
    'helmet',
    'Capacete de Obra',
    'O clássico capacete amarelo do Capi construtor.',
  ),
  crown('crown', 'Coroa Real', 'Dourada e nobre, digna de um rei dos blocos.'),
  party('party', 'Chapéu de Festa', 'Colorido com confetes e pompom festivo!'),
  chef(
    'chef',
    'Chapéu de Chef',
    'Para quem cozinha as melhores combinações no tabuleiro.',
  ),
  pirate(
    'pirate',
    'Tricórnio Pirata',
    'Ahoy! À caça de estrelas e tesouros pela ilha.',
  ),
  straw(
    'straw',
    'Chapéu de Palha',
    'Fresco e aconchegante para um dia tranquilo na vila.',
  ),
  wizard(
    'wizard',
    'Chapéu de Mago',
    'Místico e estrelado para quem faz mágicas no tabuleiro.',
  ),
  vip(
    'vip',
    'Cartola VIP',
    'Elegância de quem joga sem interrupções.',
    loja: 'Vem com Remover anúncios',
  ),
  fundador(
    'fundador',
    'Capacete Fundador',
    'Dourado, com estrela: para quem chegou primeiro à vila.',
    loja: 'Vem com o Pacote Inicial',
  );

  const CapiHat(this.id, this.label, this.description, {this.loja});

  final String id;
  final String label;
  final String description;

  /// Shop-only hats say where they come from; the daily chest never gives
  /// them.
  final String? loja;
  bool get exclusivo => loja != null;

  static CapiHat fromId(String id) {
    for (final h in values) {
      if (h.id == id) return h;
    }
    return helmet;
  }

  bool isUnlocked(ProgressStore store) {
    if (this == helmet) return true;
    return store.unlockedHats.contains(id);
  }

  bool isEquipped(ProgressStore store) => store.equippedHat == id;
}
