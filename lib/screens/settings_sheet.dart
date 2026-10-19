import 'package:flutter/material.dart';

import '../main.dart';
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
  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
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
          ],
        ),
      ),
    );
  }
}
