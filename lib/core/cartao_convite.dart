import 'dart:math';

import '../services/progress_store.dart';
import 'convites.dart';

/// The pictures of the invite card, shown in turn: one argument each.
enum ArteConvite {
  /// What whoever invites gets ([Convites.metas]).
  premios,

  /// The friend's welcome gift ([Convites.presenteEstrelas] and
  /// [Convites.itemPresente]).
  presente,

  /// Help Capi's village grow.
  vila,
}

/// What the menu knows about the player before a match, to tell after it
/// whether it ended well (a level won or a new record).
class MarcaPartida {
  const MarcaPartida(this.vencidas, this.recorde);
  MarcaPartida.of(ProgressStore store)
    : vencidas = store.levelsWon,
      recorde = store.bestScore;
  final int vencidas;
  final int recorde;
}

/// Now and then, back on the menu after a good match, Capi asks the player
/// to bring friends (screens/cartao_convite_dialog.dart). Never after a
/// loss, never often, and never again once the player said no enough times
/// or already has every reward.
abstract final class CartaoConvite {
  /// At least this long between two cards.
  static const intervalo = Duration(days: 3);

  /// After this many "Agora não", never again.
  static const maxRecusas = 3;

  /// Not right after a full-screen ad.
  static const depoisDeAnuncio = Duration(minutes: 3);

  /// With this many friends every reward is given: nothing left to ask.
  static int get amigosBastam =>
      Convites.metas.map((m) => m.amigos).reduce(max);

  /// Whether the match the menu just came back from ended well: a level
  /// won or a new record.
  static bool momentoBom(MarcaPartida antes, ProgressStore store) =>
      store.levelsWon > antes.vencidas || store.bestScore > antes.recorde;

  /// Whether to show the card now, back on the menu; [momentoBom] says
  /// whether the match that just ended was won or set a record.
  static bool deveMostrar(
    ProgressStore store,
    DateTime agora, {
    required bool momentoBom,
  }) {
    if (!momentoBom) return false;
    if (store.level < Convites.faseQueConta) return false;
    if (store.conviteCartaoRecusas >= maxRecusas) return false;
    if (store.conviteAmigos >= amigosBastam) return false;
    final ultimo = store.conviteCartaoEm;
    if (ultimo != null && agora.difference(ultimo) < intervalo) return false;
    final anuncio = store.lastFullscreenAt;
    if (anuncio != null && agora.difference(anuncio) < depoisDeAnuncio) {
      return false;
    }
    return true;
  }

  /// The picture that comes next.
  static ArteConvite proxima(ProgressStore store) {
    final n = ArteConvite.values.length;
    return ArteConvite.values[(store.conviteCartaoArte + 1) % n];
  }

  /// The card is shown now: remembers when and with which picture, and
  /// returns that picture.
  static Future<ArteConvite> mostrado(
    ProgressStore store,
    DateTime agora,
  ) async {
    final arte = proxima(store);
    await store.setConviteCartaoEm(agora);
    await store.setConviteCartaoArte(arte.index);
    return arte;
  }

  /// The player closed it without inviting.
  static Future<void> recusado(ProgressStore store) =>
      store.addConviteCartaoRecusa();
}
