import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../core/missions.dart';
import '../game/onboarding.dart';
import '../main.dart';
import '../ui/capi.dart';
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
  /// What Capi says over the menu (news first, then any hint), if anything.
  late List<MenuNews> _news = Onboarding.pendingNews(widget.services.store);
  String? _hint;

  String? get _capiLine => _news.isNotEmpty ? _news.first.text : _hint;

  void _dismissCapi() {
    widget.services.feedback.click();
    setState(() {
      if (_news.isNotEmpty) {
        widget.services.store.markSeen(_news.removeAt(0).key);
      } else {
        _hint = null;
      }
    });
  }

  static const _tips = [
    'Dica: guarde espaço para as peças grandes, como o quadradão 3x3.',
    'Limpar duas linhas de uma vez vale muito mais pontos!',
    'Limpando linhas em seguida você faz combo e multiplica os pontos.',
    'Gemas só contam quando a linha ou a coluna delas some.',
    'Ficou parado? Eu dou uma dica de onde encaixar a peça.',
  ];
  int _tipIndex = 0;

  void _tip() {
    widget.services.feedback.click();
    setState(() => _hint = _tips[_tipIndex++ % _tips.length]);
  }

  void _locked(String mode, int level) {
    widget.services.feedback.click();
    setState(
      () => _hint = 'Chegue na fase $level que eu libero o $mode pra você!',
    );
  }

  Future<void> _open(GameMode mode, {int? replayLevel}) async {
    widget.services.feedback.click();
    if (mode == GameMode.endless) {
      widget.services.store.markSeen('opened_endless');
    }
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => GameScreen(
          services: widget.services,
          mode: mode,
          replayLevel: replayLevel,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    // Level, record and streak may have changed, and modes may unlock.
    setState(() => _news = Onboarding.pendingNews(widget.services.store));
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final today = DateTime.now();
    final dailyDone = store.dailyDone(today);
    final streak = store.dailyStreak(today);
    final dailyOpen = Onboarding.dailyUnlocked(store);
    final endlessOpen = Onboarding.endlessUnlocked(store);
    final capiLine = _capiLine;

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
                          icon: Icons.star_rounded,
                          color: Palette.accent,
                          value: formatInt(store.stars),
                        ),
                        const SizedBox(width: 8),
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
                    Logo(onCapiTap: _tip),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: LevelPath(
                          current: store.level,
                          onPlay: () => _open(GameMode.levels),
                          starsFor: (n) => Missions.count(store.levelStars(n)),
                          onReplay: (n) =>
                              _open(GameMode.levels, replayLevel: n),
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
                          child: dailyOpen
                              ? MenuCard(
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
                                )
                              : MenuCard(
                                  icon: Icons.lock_rounded,
                                  color: Palette.panelEdge,
                                  title: 'Desafio diário',
                                  subtitle:
                                      'Libera na fase ${Onboarding.dailyAt}',
                                  onTap: () => _locked(
                                    'Desafio diário',
                                    Onboarding.dailyAt,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: endlessOpen
                              ? MenuCard(
                                  icon: Icons.all_inclusive_rounded,
                                  color: Palette.blocks[5],
                                  title: 'Infinito',
                                  subtitle: store.bestScore > 0
                                      ? 'Recorde ${formatInt(store.bestScore)}'
                                      : 'Sem metas, sem fim',
                                  badge: store.hasSeen('opened_endless')
                                      ? null
                                      : 'NOVO',
                                  onTap: () => _open(GameMode.endless),
                                )
                              : MenuCard(
                                  icon: Icons.lock_rounded,
                                  color: Palette.panelEdge,
                                  title: 'Infinito',
                                  subtitle:
                                      'Libera na fase ${Onboarding.endlessAt}',
                                  onTap: () =>
                                      _locked('Infinito', Onboarding.endlessAt),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (capiLine != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _dismissCapi,
                  child: const ColoredBox(color: Color(0x88080A20)),
                ),
              ),
            if (capiLine != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24 + MediaQuery.paddingOf(context).bottom,
                child: CapiSays(
                  text: capiLine,
                  capiSize: 96,
                  action: _news.isNotEmpty ? 'Bora!' : 'Beleza!',
                  onAction: _dismissCapi,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
