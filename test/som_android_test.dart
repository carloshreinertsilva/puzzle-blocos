import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:puzzle_blocos/services/sound/sound_native.dart';

/// Records what reaches Android's audio plugin.
class _Plataforma extends Fake
    with MockPlatformInterfaceMixin
    implements AudioplayersPlatformInterface {
  final chamadas = <String>[];
  int posicoes = 0;

  @override
  Future<void> create(String playerId) async {}

  @override
  Stream<AudioEvent> getEventStream(String playerId) => const Stream.empty();

  @override
  Future<void> stop(String playerId) async => chamadas.add('stop');

  @override
  Future<void> resume(String playerId) async => chamadas.add('resume');

  @override
  Future<void> setVolume(String playerId, double volume) async =>
      chamadas.add('volume');

  @override
  Future<int?> getCurrentPosition(String playerId) async {
    posicoes++;
    return null;
  }
}

class _Global extends Fake
    with MockPlatformInterfaceMixin
    implements GlobalAudioplayersPlatformInterface {
  @override
  Future<void> init() async {}

  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

void main() {
  late _Plataforma plataforma;

  setUp(() {
    plataforma = _Plataforma();
    AudioplayersPlatformInterface.instance = plataforma;
    GlobalAudioplayersPlatformInterface.instance = _Global();
  });

  // 1.12.1 played each sound with stop and resume sent together: the player
  // dropped the stop and every play started one more position check on every
  // frame, which Android never turned off. The Blitz got slower and slower.
  testWidgets('cada som para e toca de novo, sem consultar a posição', (
    tester,
  ) async {
    final som = PlatformSoundPlayer();
    final players = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
    som.debugUsar('limpa.mp3', players);
    await tester.pump();

    for (var i = 0; i < 60; i++) {
      som.play('limpa.mp3', volume: 0.8);
      await tester.pump(const Duration(milliseconds: 16));
    }
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Stop always goes before play; the volume only once per player.
    expect(plataforma.chamadas.where((c) => c == 'stop'), hasLength(60));
    expect(plataforma.chamadas.where((c) => c == 'resume'), hasLength(60));
    expect(plataforma.chamadas.where((c) => c == 'volume'), hasLength(3));
    final semVolume = plataforma.chamadas.where((c) => c != 'volume').toList();
    for (var i = 0; i < semVolume.length; i += 2) {
      expect(semVolume.sublist(i, i + 2), ['stop', 'resume']);
    }
    expect(plataforma.posicoes, 0);
  });
}
