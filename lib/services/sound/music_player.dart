import 'music_native.dart' if (dart.library.js_interop) 'music_web.dart';

/// One looping background track at a time, from `assets/audio/`.
///
/// On the phone a media player streams the file; in the browser an audio
/// element does (decoding a whole song into Web Audio would take tens of
/// megabytes).
abstract class MusicPlayer {
  factory MusicPlayer() = PlatformMusicPlayer;

  /// Loads [file] and starts it looping at [volume].
  Future<void> play(String file, double volume);

  Future<void> setVolume(double volume);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();
}
