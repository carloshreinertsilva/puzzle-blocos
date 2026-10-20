import 'package:flame_audio/flame_audio.dart';

import 'sound_player.dart';

class PlatformSoundPlayer implements SoundPlayer {
  @override
  Future<void> loadAll(List<String> files) =>
      FlameAudio.audioCache.loadAll(files);

  @override
  void play(String file, {double volume = 1}) {
    FlameAudio.play(file, volume: volume).ignore();
  }
}
