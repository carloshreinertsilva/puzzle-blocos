import 'package:flutter/material.dart';

import '../core/level.dart';
import '../l10n/idioma.dart';
import 'palette.dart';
import 'typography.dart';

/// The rules of a duel in a few short lines: how long it lasts, when it
/// ends and who wins. Shown where the Duel opens from the menu and before a
/// friend's challenge, so nobody is surprised by the end.
class RegrasDuelo extends StatelessWidget {
  const RegrasDuelo({super.key, this.blitz = false, this.rival});

  /// A Blitz duel (timed) instead of the classic one (a fixed number of
  /// pieces).
  final bool blitz;

  /// Who sent the challenge, when there is a name to show.
  final String? rival;

  static List<(IconData, String)> linhas({bool blitz = false, String? rival}) {
    final vence = rival == null
        ? tr('Quem fizer mais pontos vence.')
        : tr('Faça mais pontos que {rival} para vencer.', {'rival': rival});
    if (blitz) {
      return [
        (Icons.timer_rounded, tr('60 segundos no relógio.')),
        (Icons.add_alarm_rounded, tr('Limpar linhas dá segundos a mais.')),
        (Icons.extension_rounded, tr('Começa com as mesmas peças.')),
        (Icons.emoji_events_rounded, vence),
      ];
    }
    return [
      (
        Icons.extension_rounded,
        tr('{n} peças para cada um, começando pelas mesmas.', {
          'n': LevelConfig.duelPieces,
        }),
      ),
      (Icons.construction_rounded, tr('Sem ferramentas: só você e as peças.')),
      (
        Icons.flag_rounded,
        tr('Vai até a última peça, mesmo depois de passar a meta.'),
      ),
      (
        Icons.block_rounded,
        tr('Se nenhuma peça couber, a partida acaba antes.'),
      ),
      (Icons.emoji_events_rounded, vence),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cor = blitz ? const Color(0xFFFFD43B) : const Color(0xFF339AF0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              tr('Como funciona'),
              style: displayText(15, color: Palette.text),
            ),
          ),
          const SizedBox(height: 6),
          for (final (icone, texto) in linhas(blitz: blitz, rival: rival))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icone, color: cor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      texto,
                      style: bodyText(14, color: Palette.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
