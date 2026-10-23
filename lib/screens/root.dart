import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/onboarding.dart';
import '../main.dart';
import '../services/web_url.dart';
import '../ui/palette.dart';
import 'game_screen.dart';
import 'home_screen.dart';

/// Picks where the app opens: the tutorial for a new player, then the first
/// levels back to back, and the menu once those are done. A challenge link
/// (`?duelo=<seed>&p=<points>[&m=blitz]`) opens that match on top, once;
/// leaving it goes back to wherever the player would normally be.
class Root extends StatefulWidget {
  const Root({super.key, required this.services});
  final AppServices services;

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  void _advance() => setState(() {});

  /// While a challenge from a link is open, nothing runs underneath it.
  bool _challengeOpen = false;

  @override
  void initState() {
    super.initState();
    final query = Uri.base.queryParameters;
    final seed = int.tryParse(query['duelo'] ?? '');
    if (seed == null) return;
    final target = int.tryParse(query['p'] ?? '') ?? 1000;
    final mode = query['m'] == 'blitz' ? GameMode.blitz : GameMode.duel;
    clearUrlQuery();
    _challengeOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            services: widget.services,
            mode: mode,
            duelSeed: seed,
            duelTargetScore: target,
            duelRivalName: 'Amigo',
          ),
        ),
      );
      if (mounted) setState(() => _challengeOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final Widget child;
    if (_challengeOpen) {
      child = const DecoratedBox(
        key: ValueKey('challenge'),
        decoration: backgroundGradient,
        child: SizedBox.expand(),
      );
    } else if (!Onboarding.tutorialDone(store)) {
      child = GameScreen(
        key: const ValueKey('tutorial'),
        services: widget.services,
        mode: GameMode.tutorial,
        onDone: _advance,
      );
    } else if (!Onboarding.menuUnlocked(store)) {
      child = GameScreen(
        key: const ValueKey('first-levels'),
        services: widget.services,
        mode: GameMode.levels,
        onDone: _advance,
      );
    } else {
      child = HomeScreen(
        key: const ValueKey('home'),
        services: widget.services,
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: child,
    );
  }
}
