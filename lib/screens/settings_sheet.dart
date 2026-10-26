import 'package:flutter/material.dart';

import '../main.dart';
import '../services/web_url.dart';
import '../ui/palette.dart';
import '../ui/privacy_dialog.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

Future<void> showSettings(BuildContext context, AppServices services) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _Settings(services: services),
  );
}

class _Settings extends StatefulWidget {
  const _Settings({required this.services});
  final AppServices services;

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  void _openPrivacy() {
    widget.services.feedback.click();
    showPrivacyDialog(
      context,
      onOpenWeb: () => openExternalUrl('https://capiblocks.vercel.app/privacidade/'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final auth = widget.services.auth;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OutlinedTitle('Configurações', size: 28),
              const SizedBox(height: 12),

              // Audio & Haptics
              SwitchListTile(
                title: Text('Sons', style: bodyText(17)),
                secondary: const Icon(Icons.volume_up_rounded),
                value: store.soundOn,
                onChanged: (v) async {
                  await store.setSoundOn(v);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: Text('Vibração', style: bodyText(17)),
                secondary: const Icon(Icons.vibration_rounded),
                value: store.hapticsOn,
                onChanged: (v) async {
                  await store.setHapticsOn(v);
                  setState(() {});
                },
              ),

              const Divider(color: Color(0x22FFFFFF), height: 20),

              // Cloud Sync Section (Google Play Games / Apple Game Center - Opcional)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Palette.bgTop.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Palette.panelEdge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.cloud_sync_rounded,
                          color: Palette.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text('Nuvem & Conquistas', style: displayText(16)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      auth.isSignedIn
                          ? 'Conectado como ${auth.gamerTag ?? "Jogador"}'
                          : 'Opcional: conecte ao Google Play Games ou Apple Game Center para sincronizar o progresso em nuvem.',
                      style: bodyText(13, color: Palette.textDim),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (!auth.isSignedIn) ...[
                          Expanded(
                            child: ChunkyButton(
                              label: 'Conectar Conta',
                              color: Palette.accent,
                              textColor: const Color(0xFF231800),
                              onTap: () async {
                                widget.services.feedback.click();
                                final ok = await auth.signIn();
                                if (mounted) {
                                  setState(() {});
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Conta conectada com sucesso!'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ChunkyButton(
                              label: 'Sincronizar Agora',
                              color: Palette.good,
                              textColor: const Color(0xFF0B3B16),
                              onTap: () async {
                                widget.services.feedback.click();
                                await auth.syncNow();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Progresso salvo na nuvem!'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Palette.danger,
                            ),
                            tooltip: 'Desconectar',
                            onPressed: () async {
                              widget.services.feedback.click();
                              await auth.signOut();
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0x22FFFFFF), height: 20),

              // Privacy Policy
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip_rounded,
                  color: Palette.accent,
                ),
                title: Text('Política de Privacidade', style: bodyText(16)),
                trailing: const Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: Palette.textDim,
                ),
                onTap: _openPrivacy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CapiBlocks v1.0.0 · CHS CONSULTORIA LTDA',
                style: bodyText(12, color: Palette.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
