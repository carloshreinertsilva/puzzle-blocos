import 'package:flutter/material.dart';

import '../main.dart';
import '../services/analytics.dart';
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
      onOpenWeb: () =>
          openExternalUrl('https://capiblocks.vercel.app/privacidade/'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;

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
              // Anonymous usage statistics (Firebase on Android).
              if (Analytics.active)
                SwitchListTile(
                  title: Text('Estatísticas de uso', style: bodyText(17)),
                  subtitle: Text(
                    'Anônimas, para melhorar o jogo',
                    style: bodyText(12, color: Palette.textDim),
                  ),
                  secondary: const Icon(Icons.insights_rounded),
                  value: store.analyticsOn,
                  onChanged: (v) async {
                    await store.setAnalyticsOn(v);
                    await Analytics.setEnabled(v);
                    setState(() {});
                  },
                ),

              const Divider(color: Color(0x22FFFFFF), height: 20),

<<<<<<< HEAD
              // AdMob consent: in regions whose law requires it, players
              // can change their choice at any time.
              if (widget.services.ads.privacyOptionsRequired)
                ListTile(
                  leading: const Icon(
                    Icons.tune_rounded,
                    color: Palette.accent,
                  ),
                  title: Text('Privacidade dos anúncios', style: bodyText(16)),
                  onTap: () {
                    widget.services.feedback.click();
                    widget.services.ads.showPrivacyOptions();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
=======
              const Divider(color: Color(0x22FFFFFF), height: 20),
>>>>>>> fba42f5 (v1.0.1: sem anúncios de teste nem nuvem simulada na versão publicada (#18))

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
<<<<<<< HEAD
                'CapiBlocks v1.1.0 · CHS CONSULTORIA LTDA',
=======
                'CapiBlocks v1.0.1 · CHS CONSULTORIA LTDA',
>>>>>>> fba42f5 (v1.0.1: sem anúncios de teste nem nuvem simulada na versão publicada (#18))
                style: bodyText(12, color: Palette.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
