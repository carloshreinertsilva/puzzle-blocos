import 'package:flutter/material.dart';

import '../core/novidades.dart';
import '../l10n/idioma.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

IconData iconeDaNovidade(DestinoNovidade d) => switch (d) {
  DestinoNovidade.ranking => Icons.emoji_events_rounded,
  DestinoNovidade.torre => Icons.layers_rounded,
  DestinoNovidade.missoes => Icons.assignment_turned_in_rounded,
  DestinoNovidade.guardaRoupa => Icons.checkroom_rounded,
  DestinoNovidade.passe => Icons.military_tech_rounded,
  DestinoNovidade.loja => Icons.storefront_rounded,
  DestinoNovidade.blitz => Icons.bolt_rounded,
};

/// "O que há de novo": what changed in this version, each with a button
/// that goes straight to it. Returns where the player chose to go, or null.
Future<DestinoNovidade?> mostrarNovidades(
  BuildContext context,
  List<Novidade> novidades,
) => showDialog<DestinoNovidade>(
  context: context,
  builder: (context) => Center(
    child: SingleChildScrollView(
      child: Material(
        type: MaterialType.transparency,
        child: CardPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: OutlinedTitle(tr('O que há de novo'), size: 26),
              ),
              const SizedBox(height: 14),
              for (final n in novidades) _Item(n),
              const SizedBox(height: 4),
              ChunkyButton(
                label: tr('Fechar'),
                color: Palette.panelEdge,
                textColor: Palette.text,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

class _Item extends StatelessWidget {
  const _Item(this.novidade);
  final Novidade novidade;

  @override
  Widget build(BuildContext context) {
    final titulo = tr(novidade.titulo);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconeDaNovidade(novidade.destino),
            color: Palette.accent,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: displayText(17, color: Palette.text)),
                const SizedBox(height: 2),
                Text(
                  tr(novidade.texto),
                  style: bodyText(14, color: Palette.textDim),
                ),
                const SizedBox(height: 6),
                Semantics(
                  button: true,
                  label: tr('Ver agora: {titulo}', {'titulo': titulo}),
                  excludeSemantics: true,
                  child: Material(
                    color: Palette.accent,
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(novidade.destino),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Text(
                          tr('Ver agora'),
                          style: displayText(
                            14,
                            color: const Color(0xFF3A2200),
                          ),
                        ),
                      ),
                    ),
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
