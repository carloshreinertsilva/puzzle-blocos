import 'package:flutter/material.dart';

import '../core/ranking.dart';
import '../l10n/idioma.dart';
import '../services/progress_store.dart';
import '../services/ranking_resumo.dart';
import 'palette.dart';
import 'typography.dart';

/// "Faltam 230 pontos para subir de posição!"
String textoFaltam(Quadro q, int n) {
  final args = {'n': formatInt(n)};
  return switch (q) {
    Quadro.torre => trN(
      n,
      'Falta {n} andar para subir de posição!',
      'Faltam {n} andares para subir de posição!',
      args,
    ),
    Quadro.fases => trN(
      n,
      'Falta {n} fase para subir de posição!',
      'Faltam {n} fases para subir de posição!',
      args,
    ),
    _ => trN(
      n,
      'Falta {n} ponto para subir de posição!',
      'Faltam {n} pontos para subir de posição!',
      args,
    ),
  };
}

/// At the end of a match: the player's place on this week's board and how
/// much is missing to go up one. Takes no room until (and unless) the
/// answer comes.
class PosicaoNoRanking extends StatefulWidget {
  const PosicaoNoRanking({
    super.key,
    required this.store,
    required this.quadro,
  });
  final ProgressStore store;
  final Quadro quadro;

  @override
  State<PosicaoNoRanking> createState() => _PosicaoNoRankingState();
}

class _PosicaoNoRankingState extends State<PosicaoNoRanking> {
  late final _posicao = RankingResumo.ler(widget.store, widget.quadro);

  @override
  Widget build(BuildContext context) => FutureBuilder<PosicaoRanking?>(
    future: _posicao,
    builder: (context, r) {
      final p = r.data;
      if (p == null) return const SizedBox.shrink();
      final lugar = tr('Você está em {n}º no ranking da semana.', {
        'n': p.posicao,
      });
      final resto = p.faltam == null
          ? tr('Você lidera a semana!')
          : textoFaltam(p.quadro, p.faltam!);
      return Semantics(
        label: '$lugar $resto',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Palette.accent,
                size: 20,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$lugar\n$resto',
                  style: bodyText(13, color: Palette.textDim),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
