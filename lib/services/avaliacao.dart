import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'analytics.dart';
import 'progress_store.dart';

/// Asking for a rating in the store, with the store's own window (the
/// player stays in the game). Only at a happy moment (after a level won, or
/// back on the menu once the player has really played) and rarely: the stores
/// also limit how often the window really shows.
abstract final class Avaliacao {
  /// Not before the player has won this many levels.
  static const faseMinima = 6;

  /// At least this long between two asks, and at most [maxPedidos] ever.
  static const intervalo = Duration(days: 60);
  static const maxPedidos = 3;

  /// Back on the menu, sooner: this much time in the matches and this many
  /// levels won are enough.
  static const tempoNoMenu = Duration(minutes: 5);
  static const fasesNoMenu = 3;

  /// Not right after a full-screen ad.
  static const depoisDeAnuncio = Duration(minutes: 3);

  /// Whether to ask now, after level [fase] was won.
  static bool devePedir(ProgressStore store, int fase, DateTime agora) {
    if (fase < faseMinima || store.levelsWon < faseMinima) return false;
    return _livre(store, agora);
  }

  /// Whether to ask now, as the player comes back to the menu from a match.
  static bool devePedirNoMenu(ProgressStore store, DateTime agora) {
    if (store.levelsWon < fasesNoMenu) return false;
    if (store.tempoDeJogo < tempoNoMenu) return false;
    return _livre(store, agora);
  }

  /// Neither asked too often nor right after a full-screen ad.
  static bool _livre(ProgressStore store, DateTime agora) {
    if (store.avaliacaoPedidos >= maxPedidos) return false;
    final ultimo = store.avaliacaoPedidaEm;
    if (ultimo != null && agora.difference(ultimo) < intervalo) return false;
    final anuncio = store.lastFullscreenAt;
    if (anuncio != null && agora.difference(anuncio) < depoisDeAnuncio) {
      return false;
    }
    return true;
  }

  static bool get _celular =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// After level [fase] was won: asks, when [devePedir] says so.
  static Future<void> talvezPedir(ProgressStore store, int fase) async {
    final agora = DateTime.now();
    if (!_celular || !devePedir(store, fase, agora)) return;
    await _pedir(store, agora, {'level': fase, 'origem': 'fase'});
  }

  /// Back on the menu from a match: asks, when [devePedirNoMenu] says so.
  /// True when the window was asked for.
  static Future<bool> talvezPedirNoMenu(ProgressStore store) async {
    final agora = DateTime.now();
    if (!_celular || !devePedirNoMenu(store, agora)) return false;
    return _pedir(store, agora, {'level': store.level, 'origem': 'menu'});
  }

  static Future<bool> _pedir(
    ProgressStore store,
    DateTime agora,
    Map<String, Object> dados,
  ) async {
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return false;
      await store.setAvaliacaoPedida(agora);
      // No interstitial right after the window.
      await store.setLastFullscreenAt(agora);
      Analytics.event('avaliacao_pedida', dados);
      await review.requestReview();
      return true;
    } catch (e) {
      debugPrint('Avaliação: $e');
      return false;
    }
  }

  /// The game's page in the Play Store, from the settings (Android only:
  /// on the iPhone, Apple wants only the window above).
  static bool get temPaginaDaLoja =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> abrirPaginaDaLoja() async {
    try {
      Analytics.event('avaliacao_configuracoes');
      await InAppReview.instance.openStoreListing();
    } catch (e) {
      debugPrint('Avaliação: $e');
    }
  }
}
