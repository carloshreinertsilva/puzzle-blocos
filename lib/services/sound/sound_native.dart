import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

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
        final player = AudioPlayer()..audioCache = FlameAudio.audioCache;
        await player.setAudioContext(_contexto);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(file));
        lista.add(player);
      }
      _players[file] = lista;
    }
  }

  @override
  void play(String file, {double volume = 1}) {
    final lista = _players[file];
    // Not loaded yet (the first moment after opening): skip it rather than
    // make a throwaway player.
    if (lista == null || lista.isEmpty) return;
    final i = _proximo[file] ?? 0;
    _proximo[file] = (i + 1) % lista.length;
    unawaited(_tocar(lista[i], volume));
  }

  Future<void> _tocar(AudioPlayer player, double volume) async {
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.resume();
    } catch (_) {
      // A sound that fails is just skipped.
    }
  }
}
