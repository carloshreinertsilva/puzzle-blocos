import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'sound_player.dart';

class PlatformSoundPlayer implements SoundPlayer {
  web.AudioContext? _context;
  final _buffers = <String, web.AudioBuffer>{};

  web.AudioContext get _ctx => _context ??= web.AudioContext();

  @override
  Future<void> loadAll(List<String> files) async {
    for (final file in files) {
      try {
        _buffers[file] = await _decode(file);
      } catch (_) {
        // A sound that fails to decode just stays silent.
      }
    }
  }

  Future<web.AudioBuffer> _decode(String file) async {
    final data = await rootBundle.load('assets/audio/$file');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    // decodeAudioData takes ownership of the buffer, so hand it a copy.
    final copy = Uint8List.fromList(bytes).buffer.toJS;
    return _ctx.decodeAudioData(copy).toDart;
  }

  @override
  void play(String file, {double volume = 1}) {
    final buffer = _buffers[file];
    if (buffer == null) return;
    final ctx = _ctx;
    // Browsers start audio suspended until a tap; plays come from taps,
    // so resuming here unlocks it.
    if (ctx.state != 'running') ctx.resume().toDart.ignore();
    final gain = ctx.createGain()..gain.value = volume;
    gain.connect(ctx.destination);
    final source = ctx.createBufferSource()..buffer = buffer;
    source.connect(gain);
    source.start();
  }
}
