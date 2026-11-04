import 'package:flame_audio/flame_audio.dart';

import 'music_player.dart';

class PlatformMusicPlayer implements MusicPlayer {
  /// The music mixes with whatever else is playing instead of stopping it;
  /// the player turns it off in Settings → Música.
  static final _contexto = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  AudioPlayer? _player;

  Future<AudioPlayer> _pronto() async {
    final atual = _player;
    if (atual != null) return atual;
    final novo = AudioPlayer()..audioCache = FlameAudio.audioCache;
    await novo.setAudioContext(_contexto);
    await novo.setReleaseMode(ReleaseMode.loop);
    return _player = novo;
  }

  @override
  Future<void> play(String file, double volume) async {
    final p = await _pronto();
    await p.stop();
    await p.setVolume(volume);
    await p.play(AssetSource(file), volume: volume);
  }

  @override
  Future<void> setVolume(double volume) async => _player?.setVolume(volume);

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> resume() async => _player?.resume();

  @override
  Future<void> stop() async => _player?.stop();
}
