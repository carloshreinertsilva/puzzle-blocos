import 'package:flutter/material.dart';

import '../core/passe.dart';
import '../core/presente_diario.dart';
import '../main.dart';
import '../services/analytics.dart';
import '../services/avisos.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

/// The daily gift: the 7 days, today's highlighted, and a button to take it.
Future<void> showPresente(BuildContext context, AppServices services) {
  Analytics.event('screen_open', {'screen': 'presente'});
  return showDialog(
    context: context,
    builder: (_) => _Presente(services: services),
  );
}

class _Presente extends StatefulWidget {
  const _Presente({required this.services});
  final AppServices services;

  @override
  State<_Presente> createState() => _PresenteState();
}

class _PresenteState extends State<_Presente> {
  Recompensa? _ganhou;

  Future<void> _pegar() async {
    final r = await PresenteDiario.pegar(widget.services.store, DateTime.now());
    if (r == null || !mounted) return;
    widget.services.feedback.praise(3);
    Analytics.event('presente_diario', {
      'dia': PresenteDiario.dia(widget.services.store, DateTime.now()) + 1,
    });
    setState(() => _ganhou = r);
    await _perguntarLembretes();
  }

  /// Once, after the first gift: would the player like a reminder?
  Future<void> _perguntarLembretes() async {
    final store = widget.services.store;
    if (!Avisos.suportado || store.remindersAsked || store.remindersOn) return;
    await store.setRemindersAsked();
    if (!mounted) return;
    final sim = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.panel,
        title: Text(
          'Quer um lembrete?',
          style: displayText(20, color: Palette.text),
        ),
        content: Text(
          'O Capi te avisa uma vez por dia, às 19h, quando o próximo '
          'presente estiver pronto. Dá para desligar nas Configurações.',
          style: bodyText(14, color: Palette.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Agora não', style: bodyText(15)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Quero!',
              style: displayText(15, color: Palette.accent),
            ),
          ),
        ],
      ),
    );
    if (sim == true) await Avisos.lembretes(store, true);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final agora = DateTime.now();
    final hoje = PresenteDiario.dia(store, agora);
    final pegou = !PresenteDiario.disponivel(store, agora);
    final amanha = (hoje + 1) % PresenteDiario.premios.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: CardPanel(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  container: true,
                  header: true,
                  child: Text(
                    'Presente do dia',
                    style: displayText(22, color: Palette.text),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Volte todo dia: o presente melhora até o dia 7. '
                  'Se pular um dia, começa de novo.',
                  textAlign: TextAlign.center,
                  style: bodyText(12, color: Palette.textDim),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < PresenteDiario.premios.length; i++)
                      _Dia(
                        numero: i + 1,
                        premio: PresenteDiario.premios[i],
                        hoje: i == hoje,
                        feito: i < hoje || (i == hoje && pegou),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_ganhou != null)
                  Semantics(
                    container: true,
                    liveRegion: true,
                    label:
                        'Você ganhou ${_ganhou!.texto}! Amanhã: '
                        '${PresenteDiario.premios[amanha].texto}.',
                    excludeSemantics: true,
                    child: Text(
                      'Você ganhou ${_ganhou!.texto}!\n'
                      'Amanhã: ${PresenteDiario.premios[amanha].texto}.',
                      textAlign: TextAlign.center,
                      style: displayText(15, color: Palette.accent),
                    ),
                  )
                else if (!pegou)
                  ChunkyButton(
                    label: 'Pegar presente',
                    semanticLabel:
                        'Pegar o presente do dia ${hoje + 1}: '
                        '${PresenteDiario.premios[hoje].texto}',
                    icon: Icons.card_giftcard_rounded,
                    onTap: _pegar,
                  )
                else
                  Text(
                    'Presente de hoje já pego. Volte amanhã!',
                    style: bodyText(14, color: Palette.textDim),
                  ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _ganhou != null || pegou ? 'Fechar' : 'Depois',
                    style: displayText(16, color: Palette.textDim),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.numero,
    required this.premio,
    required this.hoje,
    required this.feito,
  });

  final int numero;
  final Recompensa premio;
  final bool hoje;
  final bool feito;

  @override
  Widget build(BuildContext context) => Container(
    width: 80,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    decoration: BoxDecoration(
      color: hoje
          ? Palette.accent.withValues(alpha: 0.22)
          : const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: hoje ? Palette.accent : const Color(0x33FFFFFF),
        width: hoje ? 2 : 1,
      ),
    ),
    child: Column(
      children: [
        Text(
          'Dia $numero',
          style: displayText(12, color: hoje ? Palette.accent : Palette.text),
        ),
        const SizedBox(height: 4),
        Icon(
          feito
              ? Icons.check_circle_rounded
              : premio.ferramenta != null
              ? Icons.handyman_rounded
              : Icons.star_rounded,
          color: feito ? Palette.good : Palette.accent,
          size: numero == 7 ? 30 : 24,
        ),
        const SizedBox(height: 2),
        Text(
          premio.texto,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: bodyText(11, color: Palette.text),
        ),
      ],
    ),
  );
}
