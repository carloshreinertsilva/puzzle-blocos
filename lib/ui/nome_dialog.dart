import 'package:flutter/material.dart';

import '../core/nome_filtro.dart';
import '../l10n/idioma.dart';
import 'palette.dart';
import 'typography.dart';
import 'widgets.dart';

/// Asks for the player's name (the ranking's, also shown to friends in
/// duels). Returns the clean name, or null for "Agora não".
class NomeDialog extends StatefulWidget {
  const NomeDialog({super.key, this.atual, this.titulo, this.texto});
  final String? atual;

  /// Defaults: the ranking's title and warning.
  final String? titulo;
  final String? texto;

  @override
  State<NomeDialog> createState() => _NomeDialogState();
}

class _NomeDialogState extends State<NomeDialog> {
  late final _campo = TextEditingController(text: widget.atual ?? '');
  String? _erro;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _salvar() {
    final recusa = NomeFiltro.recusar(_campo.text);
    if (recusa == null) {
      Navigator.pop(context, NomeFiltro.limpar(_campo.text));
      return;
    }
    setState(() {
      _erro = switch (recusa) {
        NomeRecusado.curto => tr('O nome precisa de pelo menos 3 letras.'),
        NomeRecusado.longo => tr('O nome pode ter até 16 letras.'),
        NomeRecusado.caracteres => tr(
          'Use só letras, números, espaço, ponto, traço ou _.',
        ),
        NomeRecusado.improprio => tr(
          'Esse nome não pode. Escolha outro, por favor.',
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    child: SingleChildScrollView(
      child: CardPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedTitle(widget.titulo ?? tr('Seu nome no ranking'), size: 22),
            const SizedBox(height: 8),
            Text(
              widget.texto ??
                  tr(
                    'Todo mundo vê esse nome nas listas. Pode ser um apelido: '
                    'não use nome completo nem dados pessoais.',
                  ),
              textAlign: TextAlign.center,
              style: bodyText(14, color: Palette.textDim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _campo,
              autofocus: true,
              maxLength: NomeFiltro.maximo,
              textCapitalization: TextCapitalization.words,
              style: displayText(18, color: Palette.text),
              decoration: InputDecoration(
                counterText: '',
                labelText: tr('Nome no ranking'),
                labelStyle: bodyText(13, color: Palette.textDim),
                filled: true,
                fillColor: const Color(0x22FFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _salvar(),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: bodyText(13, color: const Color(0xFFFF8A8A)),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ChunkyButton(
              label: tr('Salvar'),
              semanticLabel: tr('Salvar meu nome no ranking'),
              icon: Icons.check_rounded,
              onTap: _salvar,
            ),
            const SizedBox(height: 8),
            ChunkyButton(
              label: tr('Agora não'),
              color: Palette.panelEdge,
              textColor: Colors.white,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}
