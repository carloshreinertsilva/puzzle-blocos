import 'package:flutter/material.dart';

import '../l10n/idioma.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../services/jogo_salvo.dart';
import '../services/progress_store.dart';
import 'palette.dart';
import 'typography.dart';
import 'widgets.dart';

/// A saved progress further along than this phone (a new phone, or the
/// game installed again): load it, or keep this one. Nothing when [nuvem]
/// is null.
Future<void> oferecerProgressoDaNuvem(
  BuildContext context,
  ProgressStore store,
  Progresso? nuvem,
) async {
  if (nuvem == null || !context.mounted) return;
  final carregar = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF141938),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.cloud_download_rounded,
            color: Palette.accent,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Progresso encontrado!'),
              style: displayText(22, color: Palette.text),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Seu progresso salvo no Google Play Games:'),
            style: bodyText(15, color: Palette.textDim),
          ),
          const SizedBox(height: 6),
          Text(
            tr('Fase {fase} · {estrelas} estrelas', {
              'fase': nuvem.fase,
              'estrelas': formatInt(nuvem.estrelas),
            }),
            style: displayText(18, color: Palette.accent),
          ),
          const SizedBox(height: 12),
          Text(
            tr('Neste aparelho: fase {fase} · {estrelas} estrelas.', {
              'fase': store.level,
              'estrelas': formatInt(store.starsEarned),
            }),
            style: bodyText(14, color: Palette.textDim),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            tr('Manter este'),
            style: displayText(16, color: Palette.textDim),
          ),
        ),
        ChunkyButton(
          label: tr('Carregar'),
          icon: Icons.cloud_download_rounded,
          onTap: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  if (carregar == true) {
    Analytics.event('jogo_salvo', {'carregou': 1});
    await JogoSalvo.carregar(store, nuvem);
    // Everything on screen came from the old progress: start over.
    App.reinicio.value++;
  } else {
    Analytics.event('jogo_salvo', {'carregou': 0});
    await JogoSalvo.manter(store, nuvem);
  }
}
