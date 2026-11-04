import 'package:flutter/material.dart';

import '../main.dart';
import '../services/analytics.dart';
import '../services/avisos.dart';
import '../services/web_url.dart';
import '../ui/palette.dart';
import '../ui/privacy_dialog.dart';
import '../ui/typography.dart';
import '../ui/widgets.dart';
import 'stats_sheet.dart';
import '../l10n/idioma.dart';

Future<void> showSettings(BuildContext context, AppServices services) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => _Settings(
      services: services,
      // Statistics replace the settings, so only one sheet is open.
      onStats: () {
        Navigator.of(sheet).pop();
        showStats(context, services);
      },
    ),
  );
}

class _Settings extends StatefulWidget {
  const _Settings({required this.services, required this.onStats});
  final AppServices services;
  final VoidCallback onStats;

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  static String _nomeIdioma(String code) => code == 'auto'
      ? tr('Automático')
      : Idioma.values.firstWhere((i) => i.name == code).nome;

  Future<void> _escolherIdioma() async {
    widget.services.feedback.click();
    final store = widget.services.store;
    final escolha = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: Palette.panel,
        title: Text(tr('Idioma'), style: displayText(20, color: Palette.text)),
        children: [
          for (final code in ['auto', ...Idioma.values.map((i) => i.name)])
            Semantics(
              button: true,
              label: code == 'auto'
                  ? tr('Automático (idioma do celular)')
                  : _nomeIdioma(code),
              excludeSemantics: true,
              child: SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(code),
                child: Row(
                  children: [
                    Icon(
                      store.idioma == code
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: Palette.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        code == 'auto'
                            ? tr('Automático (idioma do celular)')
                            : _nomeIdioma(code),
                        style: bodyText(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (escolha == null || escolha == store.idioma) return;
    await store.setIdioma(escolha);
    if (!mounted) return;
    // The whole game rebuilds in the new language.
    Navigator.of(context).pop();
    Lingua.atual.value = escolherIdioma(escolha);
  }

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
              OutlinedTitle(tr('Configurações'), size: 28),
              const SizedBox(height: 12),

              // Audio & Haptics
              SwitchListTile(
                title: Text(tr('Sons'), style: bodyText(17)),
                secondary: const Icon(Icons.volume_up_rounded),
                value: store.soundOn,
                onChanged: (v) async {
                  await store.setSoundOn(v);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: Text(tr('Vibração'), style: bodyText(17)),
                secondary: const Icon(Icons.vibration_rounded),
                value: store.hapticsOn,
                onChanged: (v) async {
                  await store.setHapticsOn(v);
                  setState(() {});
                },
              ),
              // Daily reminders (Android, opt-in).
              if (Avisos.suportado)
                SwitchListTile(
                  title: Text(tr('Lembretes diários'), style: bodyText(17)),
                  subtitle: Text(
                    tr('O presente do dia e as missões, às 19h'),
                    style: bodyText(12, color: Palette.textDim),
                  ),
                  secondary: const Icon(Icons.notifications_rounded),
                  value: store.remindersOn,
                  onChanged: (v) async {
                    await store.setRemindersAsked();
                    await Avisos.lembretes(store, v);
                    setState(() {});
                  },
                ),
              // Anonymous usage statistics (Firebase on Android).
              if (Analytics.active)
                SwitchListTile(
                  title: Text(tr('Estatísticas de uso'), style: bodyText(17)),
                  subtitle: Text(
                    tr('Anônimas, para melhorar o jogo'),
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

              // AdMob consent: in regions whose law requires it, players
              // can change their choice at any time.
              if (widget.services.ads.privacyOptionsRequired)
                ListTile(
                  leading: const Icon(
                    Icons.tune_rounded,
                    color: Palette.accent,
                  ),
                  title: Text(
                    tr('Privacidade dos anúncios'),
                    style: bodyText(16),
                  ),
                  onTap: () {
                    widget.services.feedback.click();
                    widget.services.ads.showPrivacyOptions();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

              if (widget.services.loja.disponivel)
                ListTile(
                  leading: const Icon(
                    Icons.bar_chart_rounded,
                    color: Palette.accent,
                  ),
                  title: Text(tr('Estatísticas'), style: bodyText(16)),
                  onTap: () {
                    widget.services.feedback.click();
                    widget.onStats();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

              // Language
              ListTile(
                leading: const Icon(
                  Icons.translate_rounded,
                  color: Palette.accent,
                ),
                title: Text(tr('Idioma'), style: bodyText(16)),
                trailing: Text(
                  _nomeIdioma(widget.services.store.idioma),
                  style: bodyText(14, color: Palette.textDim),
                ),
                onTap: _escolherIdioma,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              // Privacy Policy
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip_rounded,
                  color: Palette.accent,
                ),
                title: Text(tr('Política de Privacidade'), style: bodyText(16)),
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
                'CapiBlocks v1.5.0 · CHS TECH',
                style: bodyText(12, color: Palette.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
