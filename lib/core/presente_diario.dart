import '../services/progress_store.dart';
import 'passe.dart';

/// The daily gift: 7 days in a row, each better than the last. Coming back
/// the next day moves on; missing a day starts again at day 1. Everything
/// is shown in advance (no draw).
abstract final class PresenteDiario {
  static const premios = <Recompensa>[
    Recompensa.estrelas(5),
    Recompensa.ferramenta(CapiTool.hammer, 1),
    Recompensa.estrelas(10),
    Recompensa.ferramenta(CapiTool.shovel, 1),
    Recompensa.estrelas(15),
    Recompensa.ferramenta(CapiTool.reroll, 2),
    Recompensa.estrelas(30),
  ];

  static int _ontem(DateTime agora) =>
      ProgressStore.dayKey(DateTime(agora.year, agora.month, agora.day - 1));

  /// Which day of the 7 (from 0) is today's gift, or the one already taken.
  static int dia(ProgressStore store, DateTime agora) {
    final ultimo = store.giftLastDay;
    if (ultimo == ProgressStore.dayKey(agora)) return store.giftIndex;
    if (ultimo == _ontem(agora)) return (store.giftIndex + 1) % premios.length;
    return 0;
  }

  static bool disponivel(ProgressStore store, DateTime agora) =>
      store.giftLastDay != ProgressStore.dayKey(agora);

  /// Gives today's gift, once a day. Returns it, or null if already taken.
  static Future<Recompensa?> pegar(ProgressStore store, DateTime agora) async {
    if (!disponivel(store, agora)) return null;
    final d = dia(store, agora);
    await store.setGift(ProgressStore.dayKey(agora), d);
    final r = premios[d];
    if (r.ferramenta case final f?) {
      await store.addTool(f, r.quantidade);
    } else {
      await store.addStars(r.quantidade);
    }
    return r;
  }
}
