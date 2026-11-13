import 'dart:async';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'sound_player.dart';

/// Android: a few players per sound, prepared once in low-latency mode
/// (Android's SoundPool) and reused in turn.
///
/// `FlameAudio.play` made a new player for every sound and never disposed
/// it: each sound waited for several calls to Android before playing, and
/// the players piled up during a game, so sounds came late, cut off or went
/// missing.
class PlatformSoundPlayer implements SoundPlayer {
  /// Enough for the same sound to overlap itself (fast clears, combos).
  static const _porSom = 3;

  /// Game sounds mix with the player's own music instead of pausing it.
  static final _contexto = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  final _players = <String, List<AudioPlayer>>{};
  final _proximo = <String, int>{};

  @override
  Future<void> loadAll(List<String> files) async {
    for (final file in files) {
      final lista = <AudioPlayer>[];
      for (var i = 0; i < _porSom; i++) {
        final player = AudioPlayer()
          ..audioCache = FlameAudio.audioCache
          // Short sounds never need their position. Left on, it asks Android
          // for it on every frame while the player counts as playing, and in
          // low-latency mode Android never says a sound ended.
          ..positionUpdater = null;
        await player.setAudioContext(_contexto);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(file));
        lista.add(player);
      }
      _players[file] = lista;
    }
  }

  /// Tests only: players for [file] without loading real sounds.
  @visibleForTesting
  void debugUsar(String file, List<AudioPlayer> players) =>
      _players[file] = players;

  @override
  void play(String file, {double volume = 1}) {
    final lista = _players[file];
    // Not loaded yet (the first moment after opening): skip it rather than
    // make a throwaway player.
    if (lista == null || lista.isEmpty) return;
    final i = _proximo[file] ?? 0;
    _proximo[file] = (i + 1) % lista.length;
    _tocar(lista[i], volume);
  }

  /// The volume each player was last set to (each sound always uses the same).
  final _volumes = <AudioPlayer, double>{};

  static AudioplayersPlatformInterface get _plataforma =>
      AudioplayersPlatformInterface.instance;

  /// Stop, volume and play go straight to Android, back to back and without
  /// waiting for each answer (a busy moment like a fast Blitz stretched three
  /// waits into an audible delay). Android runs them in the order sent.
  ///
  /// Not through [AudioPlayer.stop] and [AudioPlayer.resume]: sent together,
  /// the player drops the stop (the play right after it wins), so the sound
  /// did not restart, and each play started one more check of the position on
  /// every frame that nothing turned off. Over a game the screen got slower
  /// and slower on Android.
  void _tocar(AudioPlayer player, double volume) {
    final id = player.playerId;
    _semErro(_plataforma.stop(id));
    if (_volumes[player] != volume) {
      _volumes[player] = volume;
      _semErro(_plataforma.setVolume(id, volume));
    }
    _semErro(_plataforma.resume(id));
  }

  /// A sound that fails is just skipped.
  static void _semErro(Future<void> f) =>
      unawaited(f.catchError((Object _) {}));
}
