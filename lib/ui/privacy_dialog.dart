import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';
import 'widgets.dart';

/// Shows the in-app Privacy Policy dialog.
/// Works offline on any mobile device, ensuring full transparency and compliance
/// for Google Play and App Store reviewers and players.
Future<void> showPrivacyDialog(
  BuildContext context, {
  VoidCallback? onOpenWeb,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _PrivacySheet(onOpenWeb: onOpenWeb),
  );
}

class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet({this.onOpenWeb});
  final VoidCallback? onOpenWeb;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag bar indicator
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Palette.textDim.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const OutlinedTitle('Privacidade', size: 26),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Palette.textDim,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Palette.bgTop.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Palette.panelEdge),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CapiBlocks: Blocos e Capivaras',
                          style: displayText(18, color: Palette.accent),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Desenvolvido por CHS CONSULTORIA LTDA (CHS TECH)\nÚltima atualização: Outubro de 2026',
                          style: bodyText(12, color: Palette.textDim),
                        ),
                        const SizedBox(height: 14),
                        _section(
                          '1. Compromisso e Jogo Offline',
                          'O CapiBlocks foi desenvolvido com o compromisso absoluto de respeitar sua privacidade. O jogo funciona sem internet, não exige cadastro, criação de conta nem senhas.',
                        ),
                        _section(
                          '2. Dados Pessoais',
                          'Não coletamos, não vendemos e não transmitimos nenhum dado pessoal identificável (como nome, CPF, e-mail ou localização física) para servidores próprios.',
                        ),
                        _section(
                          '3. Armazenamento Local no Aparelho',
                          'Todo o seu progresso no jogo (fases concluídas, estrelas conquistadas, itens construídos na Vila do Capi, recordes e preferências de som/vibração) é armazenado exclusivamente no armazenamento interno do seu dispositivo.',
                        ),
                        _section(
                          '4. Serviços Opcionais',
<<<<<<< HEAD
                          '• Anúncios: no Android, os anúncios do Google AdMob podem usar identificadores de publicidade e dados de diagnóstico, conforme as políticas do Google.\n• Estatísticas de uso: no Android, o Google Firebase Analytics registra de forma anônima como o jogo é usado (fases, modos, ferramentas), para sabermos o que melhorar. Dá para desligar em Configurações → Estatísticas de uso.',
=======
                          '• Anúncios: Se anúncios estiverem ativados, os identificadores anônimos de publicidade e diagnóstico são tratados em estrita conformidade com as políticas do Google AdMob.',
>>>>>>> fba42f5 (v1.0.1: sem anúncios de teste nem nuvem simulada na versão publicada (#18))
                        ),
                        _section(
                          '5. Seus Direitos e Exclusão (LGPD)',
                          'Como todos os dados ficam no seu próprio celular, você tem controle total. Para apagar completamente todos os registros do jogo a qualquer momento, basta limpar os dados do aplicativo nas configurações do aparelho ou simplesmente desinstalar o jogo.',
                        ),
                        _section(
                          '6. Contato e Suporte Oficial',
                          'Em caso de dúvidas sobre privacidade, suporte ou conformidade legal, entre em contato conosco:\n• E-mail: contato@chstech.dev.br\n• Website: https://www.chstech.dev.br',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (onOpenWeb != null) ...[
                    Expanded(
                      child: ChunkyButton(
                        label: 'Ver na Web',
                        color: Palette.panelEdge,
                        textColor: Palette.text,
                        onTap: onOpenWeb,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ChunkyButton(
                      label: 'Entendido',
                      color: Palette.good,
                      textColor: const Color(0xFF0B3B16),
                      onTap: () => Navigator.of(context).pop(),
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

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: displayText(15, color: Palette.text)),
          const SizedBox(height: 4),
          Text(
            content,
            style: bodyText(13, color: Palette.textDim, weight: 400),
          ),
        ],
      ),
    );
  }
}
