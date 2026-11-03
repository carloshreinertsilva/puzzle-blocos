import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../main.dart';
import 'palette.dart';
import 'typography.dart';
import 'widgets.dart';
import 'premio.dart';

/// Stars a paid hint costs (obras and levels alike).
const dicaCusto = 5;

/// Asks how to pay for a hint (stars or a video) and charges it. Returns
/// how it was paid ('estrelas' or 'video'), or null when the player gave
/// up or the payment didn't go through.
Future<String?> pagarDica(
  BuildContext context,
  AppServices services,
  RewardPlacement placement, {
  required String motivo,
}) async {
  final store = services.store;
  final ads = services.ads;
  final escolha = await showDialog<String>(
    context: context,
    builder: (_) => _DicaPaga(
      estrelas: store.stars,
      video: ads.hasVideoAds,
      motivo: motivo,
    ),
  );
  if (escolha == null || !context.mounted) return null;
  final bool pago;
  if (escolha == 'video') {
    pago = await ads.rewarded(context, placement);
  } else {
    pago = await store.spendStars(dicaCusto);
  }
  if (!pago) {
    services.feedback.lose();
    return null;
  }
  if (escolha == 'video' && context.mounted) {
    mostrarPremio(
      context,
      'Dica liberada pelo vídeo!',
      icon: Icons.lightbulb_rounded,
    );
  }
  return escolha;
}

/// Asks how to pay for a hint: stars, a video, or not now.
class _DicaPaga extends StatelessWidget {
  const _DicaPaga({
    required this.estrelas,
    required this.video,
    required this.motivo,
  });

  final int estrelas;
  final bool video;
  final String motivo;

  @override
  Widget build(BuildContext context) {
    const custo = dicaCusto;
    final temEstrelas = estrelas >= custo;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: CardPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                container: true,
                header: true,
                child: Text(
                  'Mais uma dica?',
                  style: displayText(22, color: Palette.text),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$motivo As próximas custam '
                '$custo estrelas${video ? ' ou um vídeo' : ''}.\n'
                'Você tem $estrelas ★.',
                textAlign: TextAlign.center,
                style: bodyText(14, color: Palette.textDim),
              ),
              const SizedBox(height: 14),
              ChunkyButton(
                label: 'Usar $custo ★',
                semanticLabel: 'Usar $custo estrelas na dica',
                icon: Icons.star_rounded,
                onTap: temEstrelas
                    ? () => Navigator.of(context).pop('estrelas')
                    : null,
              ),
              if (video) ...[
                const SizedBox(height: 10),
                ChunkyButton(
                  label: 'Ver vídeo',
                  semanticLabel: 'Ver um vídeo pela dica',
                  icon: Icons.play_circle_rounded,
                  onTap: () => Navigator.of(context).pop('video'),
                ),
              ],
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Agora não',
                  style: displayText(16, color: Palette.textDim),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
