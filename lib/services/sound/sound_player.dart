import 'sound_native.dart' if (dart.library.js_interop) 'sound_web.dart';

/// Plays short sound effects from `assets/audio/`.
///
/// In the browser this uses the Web Audio API with sounds decoded once up
/// front: the audio plugin would create a new audio element (and audio
/// context) for every sound, which makes Safari stutter mid-game.
abstract class SoundPlayer {
  factory SoundPlayer() = PlatformSoundPlayer;

  Future<void> loadAll(List<String> files);

  void play(String file, {double volume = 1});
}
