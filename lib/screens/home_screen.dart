import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../main.dart';
import '../ui/menu_widgets.dart';
import '../ui/palette.dart';
import '../ui/widgets.dart';
import 'game_screen.dart';
import 'settings_sheet.dart';
import 'stats_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(GameMode mode) async {
    widget.services.feedback.click();
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) =>
            GameScreen(services: widget.services, mode: mode),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    setState(() {}); // level, record and streak may have changed
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final today = DateTime.now();
    final dailyDone = store.dailyDone(today);
    final streak = store.dailyStreak(today);

    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGradient,
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBlocks()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatChip(
                          icon: Icons.emoji_events_rounded,
                          color: Palette.accent,
                          value: formatInt(store.bestScore),
                        ),
                        const SizedBox(width: 8),
                        StatChip(
                          icon: Icons.local_fire_department_rounded,
                          color: Palette.accentDeep,
                          value: '$streak',
                        ),
                        const Spacer(),
                        RoundIconButton(
                          icon: Icons.bar_chart_rounded,
                          label: 'Estatísticas',
                          onTap: () => showStats(context, widget.services),
                        ),
                        const SizedBox(width: 8),
                        RoundIconButton(
                          icon: Icons.settings_rounded,
                          label: 'Configurações',
                          onTap: () => showSettings(context, widget.services),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Logo(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: LevelPath(
                          current: store.level,
                          onPlay: () => _open(GameMode.levels),
                        ),
                      ),
                    ),
                    ChunkyButton(
                      big: true,
                      icon: Icons.play_arrow_rounded,
                      label: 'Jogar · Fase ${store.level}',
                      onTap: () => _open(GameMode.levels),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: MenuCard(
                            icon: dailyDone
                                ? Icons.check_circle_rounded
                                : Icons.calendar_today_rounded,
                            color: Palette.blocks[0],
                            title: 'Desafio diário',
                            subtitle: dailyDone
                                ? 'Feito! Volte amanhã'
                                : streak > 0
                                ? 'Sequência: $streak dias'
                                : 'Um novo a cada dia',
                            badge: dailyDone ? null : 'NOVO',
                            onTap: () => _open(GameMode.daily),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MenuCard(
                            icon: Icons.all_inclusive_rounded,
                            color: Palette.blocks[5],
                            title: 'Infinito',
                            subtitle: store.bestScore > 0
                                ? 'Recorde ${formatInt(store.bestScore)}'
                                : 'Sem metas, sem fim',
                            onTap: () => _open(GameMode.endless),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
