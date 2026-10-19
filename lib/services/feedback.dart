import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import 'progress_store.dart';

/// Sound effects and vibration, both switchable in settings.
class GameFeedback {
  GameFeedback(this.store);

  final ProgressStore store;

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
  ];

  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll(_files);
    } catch (_) {
      // Audio is a nicety; never block the game on it.
    }
  }

  void _play(String file, {double volume = 0.8}) {
    if (!store.soundOn) return;
    FlameAudio.play(file, volume: volume).catchError((_) => AudioPlayer());
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

  void win() => _play('win.wav');
  void lose() => _play('lose.wav', volume: 0.6);
  void revive() => _play('revive.wav');
  void click() => _play('click.wav', volume: 0.5);
}
