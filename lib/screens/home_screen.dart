import 'package:flutter/material.dart';

import '../main.dart';
import '../ui/palette.dart';
import '../ui/widgets.dart';
import 'game_screen.dart';
import 'settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open({required bool endless}) async {
    widget.services.feedback.click();
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) =>
            GameScreen(services: widget.services, endless: endless),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    setState(() {}); // level / best score may have changed
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RoundIconButton(
                      icon: Icons.settings_rounded,
                      onTap: () => showSettings(context, widget.services),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                const Logo(),
                const Spacer(flex: 3),
                ChunkyButton(
                  big: true,
                  icon: Icons.play_arrow_rounded,
                  label: 'Fase ${store.level}',
                  onTap: () => _open(endless: false),
                ),
                const SizedBox(height: 16),
                ChunkyButton(
                  label: 'Modo infinito',
                  icon: Icons.all_inclusive_rounded,
                  color: Palette.blocks[5],
                  textColor: Colors.white,
                  onTap: () => _open(endless: true),
                ),
                const SizedBox(height: 12),
                Text(
                  store.bestScore > 0
                      ? 'Recorde: ${formatInt(store.bestScore)}'
                      : ' ',
                  style: const TextStyle(color: Palette.textDim, fontSize: 15),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
