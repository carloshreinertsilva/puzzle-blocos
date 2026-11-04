import 'package:flutter/material.dart';

import '../l10n/idioma.dart';
import '../main.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

Future<void> showStats(BuildContext context, AppServices services) {
  final store = services.store;
  final tiles = [
    (Icons.flag_rounded, tr('Fase atual'), '${store.level}'),
    (Icons.emoji_events_rounded, tr('Recorde'), formatInt(store.bestScore)),
    (
      Icons.check_circle_rounded,
      tr('Fases vencidas'),
      formatInt(store.levelsWon),
    ),
    (
      Icons.sports_esports_rounded,
      tr('Partidas'),
      formatInt(store.gamesPlayed),
    ),
    (
      Icons.view_week_rounded,
      tr('Linhas limpas'),
      formatInt(store.linesCleared),
    ),
    (Icons.bolt_rounded, tr('Maior combo'), 'x${store.bestCombo}'),
    (Icons.diamond_rounded, tr('Gemas'), formatInt(store.gemsCollected)),
    (
      Icons.landscape_rounded,
      tr('Pedras quebradas'),
      formatInt(store.rocksBroken),
    ),
  ];
  return showModalBottomSheet(
    context: context,
    backgroundColor: Palette.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedTitle(tr('Estatísticas'), size: 28),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final (icon, label, value) in tiles)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Palette.emptyCell,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: Palette.accent, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(value, style: displayText(20)),
                              Text(
                                label,
                                style: bodyText(12, color: Palette.textDim),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
