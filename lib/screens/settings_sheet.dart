import 'package:flutter/material.dart';

import '../main.dart';
import '../services/web_url.dart';
import '../ui/palette.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';

Future<void> showSettings(BuildContext context, AppServices services) {
  return showModalBottomSheet(
    context: context,
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
    openExternalUrl('/privacidade/');
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OutlinedTitle('Configurações', size: 28),
            const SizedBox(height: 8),
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
            const Divider(color: Color(0x22FFFFFF), height: 16),
            Semantics(
              button: true,
              label: 'Política de Privacidade',
              child: ListTile(
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
            ),
            const SizedBox(height: 8),
            Text(
              'CapiBlocks v1.0.0 · CHS CONSULTORIA LTDA',
              style: bodyText(12, color: Palette.textDim),
            ),
          ],
        ),
      ),
    );
  }
}
