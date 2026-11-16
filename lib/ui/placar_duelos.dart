import 'package:flutter/material.dart';

import '../core/duelos.dart';
import '../l10n/idioma.dart';
import '../services/progress_store.dart';
import 'blitz_duel_painter.dart';
import 'palette.dart';
import 'typography.dart';
import 'widgets.dart';

const _verde = Color(0xFF8CE99A);
const _vermelho = Color(0xFFFFB3B3);

/// "Você 3 × 2 Ana" in one line.
String textoPlacar(PlacarAmigo p) => tr('Você {v} × {d} {rival}', {
  'v': p.vitorias,
  'd': p.derrotas,
  'rival': p.nome,
});

/// On the end card of a friend's challenge: the result went back to them,
/// and the score with them so far.
class PlacarDoAmigo extends StatelessWidget {
  const PlacarDoAmigo({super.key, required this.aviso, this.placar});
  final String aviso;
  final PlacarAmigo? placar;

  @override
  Widget build(BuildContext context) {
    final p = placar;
    return Semantics(
      container: true,
      label: [aviso, if (p != null) textoPlacar(p)].join(' '),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_email_read_rounded,
                    color: _verde,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      aviso,
                      textAlign: TextAlign.center,
                      style: bodyText(13, color: Palette.textDim),
                    ),
                  ),
                ],
              ),
              if (p != null) ...[
                const SizedBox(height: 4),
                Text(
                  tr('Placar: {placar}', {'placar': textoPlacar(p)}),
                  textAlign: TextAlign.center,
                  style: displayText(15, color: Palette.text),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The scores with each friend, in the Duel dialog.
class ListaPlacarDuelos extends StatelessWidget {
  const ListaPlacarDuelos({super.key, required this.store, this.limite = 5});
  final ProgressStore store;
  final int limite;

  @override
  Widget build(BuildContext context) {
    final linhas = Duelos.placar(store).take(limite).toList();
    if (linhas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('Placar dos duelos'), style: displayText(16)),
        const SizedBox(height: 6),
        for (final p in linhas)
          Semantics(
            label: textoPlacar(p),
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bodyText(15, color: Palette.text),
                      ),
                    ),
                    Text(
                      '${p.vitorias}',
                      style: displayText(
                        16,
                        color: p.vitorias >= p.derrotas ? _verde : Colors.white,
                      ),
                    ),
                    Text(
                      '  ×  ',
                      style: displayText(14, color: Palette.textDim),
                    ),
                    Text(
                      '${p.derrotas}',
                      style: displayText(
                        16,
                        color: p.derrotas > p.vitorias
                            ? _vermelho
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Friends answered the player's challenges: who beat whom, and the score
/// with each of them now. A friend who beat the player gets a "Revanche":
/// the chosen result comes back, to play that board again.
Future<ResultadoDuelo?> mostrarResultadosDuelo(
  BuildContext context,
  ProgressStore store,
  List<ResultadoDuelo> novos,
) => showDialog<ResultadoDuelo>(
  context: context,
  builder: (ctx) => AlertDialog(
    backgroundColor: const Color(0xFF141938),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0x33FFFFFF)),
    ),
    title: Column(
      children: [
        const DuelIcon(size: 56),
        const SizedBox(height: 6),
        Text(
          tr('Resultado do duelo'),
          style: displayText(22),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in novos.take(4)) ...[
            _LinhaResultado(
              r: r,
              placar: Duelos.contra(store, r.rival),
              onRevanche: r.perdi ? () => Navigator.of(ctx).pop(r) : null,
            ),
            const SizedBox(height: 10),
          ],
          if (novos.length > 4)
            Text(
              trN(novos.length - 4, 'E mais {n} duelo.', 'E mais {n} duelos.'),
              style: bodyText(14, color: Palette.textDim),
            ),
        ],
      ),
    ),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      ChunkyButton(
        label: tr('Legal!'),
        icon: Icons.check_rounded,
        onTap: () => Navigator.of(ctx).pop(),
      ),
    ],
  ),
);

class _LinhaResultado extends StatelessWidget {
  const _LinhaResultado({required this.r, this.placar, this.onRevanche});
  final ResultadoDuelo r;
  final PlacarAmigo? placar;
  final VoidCallback? onRevanche;

  @override
  Widget build(BuildContext context) {
    final titulo = r.venci
        ? tr('{rival} não passou você: {ele} × {eu}.', {
            'rival': r.nome,
            'ele': formatInt(r.ele),
            'eu': formatInt(r.eu),
          })
        : r.perdi
        ? tr('{rival} passou você: {ele} × {eu}.', {
            'rival': r.nome,
            'ele': formatInt(r.ele),
            'eu': formatInt(r.eu),
          })
        : tr('{rival} empatou com você: {eu} pontos.', {
            'rival': r.nome,
            'eu': formatInt(r.eu),
          });
    final p = placar;
    final linha = Semantics(
      container: true,
      label: [titulo, if (p != null) textoPlacar(p)].join(' '),
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: r.venci ? const Color(0x3351CF66) : const Color(0x332A3356),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: r.venci
                  ? const Color(0xFF51CF66)
                  : const Color(0x55FFFFFF),
            ),
          ),
          child: Column(
            children: [
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: bodyText(15, color: Palette.text),
              ),
              if (p != null) ...[
                const SizedBox(height: 4),
                Text(
                  tr('Placar: {placar}', {'placar': textoPlacar(p)}),
                  textAlign: TextAlign.center,
                  style: displayText(
                    15,
                    color: r.venci ? _verde : Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final revanche = onRevanche;
    if (revanche == null) return linha;
    return Column(
      children: [
        linha,
        const SizedBox(height: 8),
        ChunkyButton(
          label: tr('Revanche contra {rival}', {'rival': r.nome}),
          icon: Icons.refresh_rounded,
          onTap: revanche,
        ),
      ],
    );
  }
}
