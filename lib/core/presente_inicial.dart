import '../services/analytics.dart';
import '../services/progress_store.dart';
import 'wardrobe.dart';

/// Capi's welcome gift, in the menu's guide (ui/destaque.dart): one item of
/// the wardrobe, free, once in a player's life. It is a cheap common item
/// bought with stars (never one from the shop, the Passe or a collection),
/// on the face so it shows with the yellow helmet, the look players know.
abstract final class PresenteInicial {
  /// The Óculos de Sol: common, 40 stars, part of the Praia collection.
  static const itemId = 'oculos_sol';
  static const _dado = 'presente_inicial';
  static const _vestido = 'presente_inicial_vestido';

  static Cosmetic get item => Wardrobe.byId(itemId)!;

  /// Whether it was given already.
  static bool dado(ProgressStore store) => store.hasSeen(_dado);

  /// Gives the item (once). Returns it when given now; null if it had been
  /// given before. A player who already owns it gets nothing new.
  static Future<Cosmetic?> dar(ProgressStore store) async {
    if (dado(store)) return null;
    await store.markSeen(_dado);
    final c = item;
    if (Wardrobe.owns(store, c)) return null;
    await store.unlockHat(c.id);
    await Wardrobe.awardCollections(store);
    Analytics.event('presente_inicial', {'item': c.id});
    return c;
  }

  /// Puts the gift on Capi (once, and only where he wears nothing else).
  static Future<void> vestir(ProgressStore store) async {
    if (store.hasSeen(_vestido)) return;
    final c = item;
    if (!Wardrobe.owns(store, c)) return;
    await store.markSeen(_vestido);
    if (store.equippedIn(c.slot) != null) return;
    await Wardrobe.equip(store, c);
  }
}
