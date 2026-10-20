import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/onboarding.dart';
import '../main.dart';
import 'game_screen.dart';
import 'home_screen.dart';

/// Picks where the app opens: the tutorial for a new player, then the first
/// levels back to back, and the menu once those are done.
class Root extends StatefulWidget {
  const Root({super.key, required this.services});
  final AppServices services;

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  void _advance() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final store = widget.services.store;
    final Widget child;
    if (!Onboarding.tutorialDone(store)) {
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
