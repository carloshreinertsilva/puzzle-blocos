import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'music_player.dart';

class PlatformMusicPlayer implements MusicPlayer {
  web.HTMLAudioElement? _audio;

  @override
  Future<void> play(String file, double volume) async {
    _audio?.pause();
    final a = web.HTMLAudioElement()
      // Flutter serves the asset `assets/audio/x` at `assets/assets/audio/x`.
      ..src = 'assets/assets/audio/$file'
      ..loop = true
      ..volume = volume;
    _audio = a;
    await _tocar(a);
  }

  /// Browsers refuse sound before the first tap: try again on the next one.
  Future<void> _tocar(web.HTMLAudioElement a) async {
    try {
      await a.play().toDart;
    } catch (_) {}
  }

  @override
  Future<void> setVolume(double volume) async {
    final a = _audio;
    if (a == null) return;
    a.volume = volume.clamp(0, 1);
    // A tap that changes the music is a chance to unlock it.
    if (a.paused && volume > 0) await _tocar(a);
  }

  @override
  Future<void> pause() async => _audio?.pause();

  @override
  Future<void> resume() async {
    final a = _audio;
    if (a != null) await _tocar(a);
  }

  @override
  Future<void> stop() async {
    _audio?.pause();
    _audio = null;
  }
}
