import 'dart:async';

import 'package:flutter/widgets.dart';

import 'progress_store.dart';
import 'sound/music_player.dart';

/// The background tracks (assets/audio/musica/, see CREDITOS.md there).
enum Trilha {
  /// Opening and menu: calm ukulele.
  menu('musica/menu.mp3', 0.35),

  /// During the levels: playful marimba, lower so the game sounds lead.
  fases('musica/fases.mp3', 0.20),

  /// Blitz 60s: faster.
  blitz('musica/blitz.mp3', 0.25);

  const Trilha(this.arquivo, this.volume);
  final String arquivo;
  final double volume;
}

/// Background music: one track at a time, faded out and in when the screen
/// changes, lowered for a moment under the win/lose sounds, paused when the
/// game leaves the screen. Turned off in Settings → Música.
///
/// Without a [MusicPlayer] (tests) it stays silent.
class Musica {
  // A private field behind a public parameter name.
  // ignore: prefer_initializing_formals
  Musica(this.store, {MusicPlayer? player}) : _player = player {
    if (_player != null) {
      _ciclo = AppLifecycleListener(
        onHide: () => _emSegundoPlano(true),
        onShow: () => _emSegundoPlano(false),
      );
    }
  }

  final ProgressStore store;
  final MusicPlayer? _player;
  AppLifecycleListener? _ciclo;

  static const _passo = Duration(milliseconds: 40);
  static const _saida = Duration(milliseconds: 400);
  static const _entrada = Duration(milliseconds: 700);

  /// What the current screen wants (kept while the music is off, so turning
  /// it on plays the right track).
  Trilha? _pedida;
  Trilha? _tocando;
  double _volume = 0;
  bool _abaixada = false;
  bool _fora = false;

  /// Each change bumps this; an older fade that is still running stops.
  int _vez = 0;
  Timer? _rampa;
  Completer<void>? _fimRampa;
  Timer? _volta;

  Trilha? get tocando => _tocando;

  double get _alvo {
    final t = _tocando;
    if (t == null) return 0;
    return _abaixada ? t.volume * 0.3 : t.volume;
  }

  /// The screen's track: nothing changes if it is already playing.
  Future<void> tocar(Trilha trilha) async {
    _pedida = trilha;
    final player = _player;
    if (player == null || !store.musicOn || _fora) return;
    if (_tocando == trilha) return;
    final vez = ++_vez;
    try {
      if (_tocando != null) {
        await _ir(0, _saida, vez);
        if (vez != _vez) return;
      }
      _tocando = trilha;
      _volume = 0;
      await player.play(trilha.arquivo, 0);
      if (vez != _vez) return;
      await _ir(_alvo, _entrada, vez);
    } catch (e) {
      debugPrint('Música: $e');
    }
  }

  /// Game screens open on top of each other for a moment (the next level,
  /// the tutorial handing over): the menu track comes back only when the
  /// last one closes.
  int _jogos = 0;

  void entrarNoJogo(Trilha trilha) {
    _jogos++;
    unawaited(tocar(trilha));
  }

  void sairDoJogo() {
    if (_jogos > 0) _jogos--;
    if (_jogos == 0) unawaited(tocar(Trilha.menu));
  }

  /// Lower for a moment, so a stinger (win, lose) is heard over the music.
  void abaixar({Duration por = const Duration(milliseconds: 2500)}) {
    if (_player == null || _tocando == null) return;
    _abaixada = true;
    final vez = ++_vez;
    unawaited(_ir(_alvo, const Duration(milliseconds: 200), vez));
    _volta?.cancel();
    _volta = Timer(por, () {
      _abaixada = false;
      final v = ++_vez;
      unawaited(_ir(_alvo, const Duration(milliseconds: 900), v));
    });
  }

  /// Settings → Música.
  Future<void> ligar(bool ligada) async {
    await store.setMusicOn(ligada);
    if (ligada) {
      final t = _pedida;
      if (t != null) await tocar(t);
    } else {
      await _parar();
    }
  }

  Future<void> _parar() async {
    ++_vez;
    _cancelarRampa();
    _volta?.cancel();
    _tocando = null;
    _volume = 0;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  void _emSegundoPlano(bool fora) {
    _fora = fora;
    final player = _player;
    if (player == null || !store.musicOn) return;
    try {
      if (fora) {
        unawaited(player.pause());
      } else if (_tocando != null) {
        unawaited(player.resume());
      } else if (_pedida != null) {
        unawaited(tocar(_pedida!));
      }
    } catch (_) {}
  }

  /// Slides the volume to [alvo] over [tempo]; ends early when a newer
  /// change starts.
  Future<void> _ir(double alvo, Duration tempo, int vez) {
    final player = _player;
    if (player == null) return Future.value();
    _cancelarRampa();
    final inicio = _volume;
    final passos = (tempo.inMilliseconds / _passo.inMilliseconds).ceil();
    if (passos <= 0) {
      _volume = alvo;
      return player.setVolume(alvo);
    }
    final fim = _fimRampa = Completer<void>();
    var i = 0;
    _rampa = Timer.periodic(_passo, (t) {
      if (vez != _vez) {
        t.cancel();
        if (!fim.isCompleted) fim.complete();
        return;
      }
      i++;
      _volume = inicio + (alvo - inicio) * (i / passos);
      unawaited(player.setVolume(_volume).catchError((_) {}));
      if (i >= passos) {
        t.cancel();
        if (!fim.isCompleted) fim.complete();
      }
    });
    return fim.future;
  }

  /// Stops a running fade; whoever waits on it goes on.
  void _cancelarRampa() {
    _rampa?.cancel();
    final f = _fimRampa;
    if (f != null && !f.isCompleted) f.complete();
  }

  void dispose() {
    _cancelarRampa();
    _volta?.cancel();
    _ciclo?.dispose();
  }
}
