import 'package:flutter/services.dart';

import 'musica.dart';
import 'progress_store.dart';
import 'sound/sound_player.dart';

/// Sound effects and vibration, both switchable in settings.
class GameFeedback {
  GameFeedback(this.store, {Musica? musica}) : musica = musica ?? Musica(store);

  final ProgressStore store;

  /// The background music (silent in tests).
  final Musica musica;
  final _sound = SoundPlayer();

  static const _files = [
    'pick.wav',
    'place.wav',
    'clear1.wav',
    'clear2.wav',
    'clear3.wav',
    'clear4.wav',
    'clear5.wav',
    'win.wav',
    'lose.wav',
    'revive.wav',
    'click.wav',
    'praise2.wav',
    'praise3.wav',
    'praise4.wav',
  ];

  Future<void> preload() async {
    try {
      await _sound.loadAll(_files);
    } catch (_) {
      // Audio is a nicety; never block the game on it.
    }
  }

  void _play(String file, {double volume = 0.8}) {
    if (!store.soundOn) return;
    _sound.play(file, volume: volume);
  }

  void pick() {
    _play('pick.wav', volume: 0.5);
    if (store.hapticsOn) HapticFeedback.selectionClick();
  }

  void place() {
    _play('place.wav', volume: 0.6);
    if (store.hapticsOn) HapticFeedback.lightImpact();
  }

  /// Pitch rises with the combo, capped at the fifth note.
  void clear(int combo, int lines) {
    _play('clear${combo.clamp(1, 5)}.wav');
    if (!store.hapticsOn) return;
    lines >= 2 ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();
  }

  /// Extra stinger for big moves (tier 2 and up), on top of the clear sound.
  void praise(int tier) {
    if (tier < 2) return;
    _play('praise${tier.clamp(2, 4)}.wav', volume: 0.7);
    if (store.hapticsOn && tier >= 3) {
      Future.delayed(
        const Duration(milliseconds: 120),
        HapticFeedback.heavyImpact,
      );
    }
  }

  void win() {
    musica.abaixar();
    _play('win.wav');
  }

  void lose() {
    musica.abaixar();
    _play('lose.wav', volume: 0.6);
  }

  void revive() => _play('revive.wav');
  void click() => _play('click.wav', volume: 0.5);
}
