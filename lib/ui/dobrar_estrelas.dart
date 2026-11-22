import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../l10n/idioma.dart';
import '../main.dart';
import '../services/ajustes.dart';
import '../services/analytics.dart';
import 'palette.dart';
import 'premio.dart';
import 'typography.dart';
import 'widgets.dart';

/// "Double the stars with a video" on the result cards (levels, daily
/// challenge, Endless, Blitz, Tower): one rule for all of them, within one
/// daily limit ([Ajustes.dobrarPorDia]).
abstract final class DobrarEstrelas {
  /// What the store counts the day's doubling videos under.
  static const chave = 'dobrar';

  /// Whether [ganhas] stars just earned can still be doubled today.
  static bool pode(AppServices services, int ganhas) =>
      services.ads.hasVideoAds &&
      ganhas > 0 &&
      services.store.videosToday(chave, DateTime.now()) <
          Ajustes.atuais.dobrarPorDia;

  /// The offer is on screen (`ad_offer`).
  static void oferecer(AppServices services, Map<String, Object> dados) =>
      services.ads.offered(RewardPlacement.doubleStars, dados);

  /// Shows the video and, once it was watched to the end, gives [ganhas]
  /// stars again. Returns whether it did.
  static Future<bool> dobrar(
    BuildContext context,
    AppServices services,
    int ganhas, {
    required String modo,
  }) async {
    if (ganhas <= 0) return false;
    final ok = await services.ads.rewarded(
      context,
      RewardPlacement.doubleStars,
    );
    if (!ok) return false;
    // Watched to the end: the stars are the player's, screen or not.
    await services.store.addVideoToday(chave, DateTime.now());
    await services.store.addStars(ganhas);
    Analytics.event('double_stars', {'mode': modo, 'stars': ganhas});
    services.feedback.praise(3);
    if (context.mounted) {
      mostrarPremio(
        context,
        tr('+{n} ★ pelo vídeo!', {'n': ganhas}),
        icon: Icons.star_rounded,
      );
    }
    return true;
  }
}

/// The doubling offer on a result card: the button, or once it was used,
/// how many stars it gave. Nothing when neither applies.
class BotaoDobrar extends StatelessWidget {
  const BotaoDobrar({
    super.key,
    required this.estrelas,
    this.dobradas,
    this.onDobrar,
    this.espaco = 10,
  });

  /// The stars a video would give again.
  final int estrelas;

  /// Stars this result already got from the video (null: not doubled).
  final int? dobradas;
  final VoidCallback? onDobrar;

  /// The gap above it.
  final double espaco;

  @override
  Widget build(BuildContext context) {
    final feitas = dobradas;
    if (feitas == null && onDobrar == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: espaco),
      child: feitas != null
          ? Text(
              tr('Estrelas dobradas: +{n}!', {'n': feitas}),
              textAlign: TextAlign.center,
              style: displayText(16, color: Palette.accent),
            )
          : ChunkyButton(
              label: tr('Dobrar: +{n} com vídeo', {'n': estrelas}),
              icon: Icons.smart_display_rounded,
              color: Palette.good,
              textColor: const Color(0xFF0B3D1A),
              onTap: onDobrar,
            ),
    );
  }
}

/// A result card that shrinks a little, instead of spilling over, when the
/// screen is too short for it (iPhone SE, small Android phones): every
/// button stays on screen and tappable.
class CabeNaAltura extends StatelessWidget {
  const CabeNaAltura({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (!box.hasBoundedHeight || !box.hasBoundedWidth) return child;
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: box.maxWidth,
          child: Center(child: child),
        ),
      );
    },
  );
}
