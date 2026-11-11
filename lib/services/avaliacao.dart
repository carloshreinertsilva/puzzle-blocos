import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'analytics.dart';
import 'progress_store.dart';

/// Asking for a rating in the store, with the store's own window (the
/// player stays in the game). Only at a happy moment, after a level won, and
/// rarely: the stores also limit how often the window really shows.
abstract final class Avaliacao {
  /// Not before the player has won this many levels.
  static const faseMinima = 12;

  /// At least this long between two asks, and at most [maxPedidos] ever.
  static const intervalo = Duration(days: 60);
  static const maxPedidos = 3;

  /// Not right after a full-screen ad.
  static const depoisDeAnuncio = Duration(minutes: 3);

  /// Whether to ask now, after level [fase] was won.
  static bool devePedir(ProgressStore store, int fase, DateTime agora) {
    if (fase < faseMinima || store.levelsWon < faseMinima) return false;
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
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await store.setAvaliacaoPedida(agora);
      // No interstitial right after the window.
      await store.setLastFullscreenAt(agora);
      Analytics.event('avaliacao_pedida', {'level': fase});
      await review.requestReview();
    } catch (e) {
      debugPrint('Avaliação: $e');
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
