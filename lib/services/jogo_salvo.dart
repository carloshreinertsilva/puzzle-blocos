import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

import 'placares.dart';
import 'progress_store.dart';

/// A copy of the progress: where the player is, and every saved value.
class Progresso {
  const Progresso({
    required this.fase,
    required this.estrelas,
    required this.salvoEm,
    required this.dados,
  });

  final int fase;
  final int estrelas;
  final int salvoEm;
  final Map<String, dynamic> dados;

  factory Progresso.doAparelho(ProgressStore store, {DateTime? agora}) =>
      Progresso(
        fase: store.level,
        estrelas: store.starsEarned,
        salvoEm: (agora ?? DateTime.now()).millisecondsSinceEpoch,
        dados: store.exportar(),
      );

  String get json => jsonEncode({
    'v': 1,
    'fase': fase,
    'estrelas': estrelas,
    'salvoEm': salvoEm,
    'dados': dados,
  });

  /// Null when [texto] is not a save of this game.
  static Progresso? ler(String? texto) {
    if (texto == null || texto.isEmpty) return null;
    try {
      final m = jsonDecode(texto) as Map<String, dynamic>;
      if (m['v'] != 1) return null;
      return Progresso(
        fase: m['fase'] as int,
        estrelas: m['estrelas'] as int,
        salvoEm: m['salvoEm'] as int,
        dados: (m['dados'] as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Further along: a higher level, then more stars earned.
  bool maisAvancadoQue(Progresso outro) =>
      fase != outro.fase ? fase > outro.fase : estrelas > outro.estrelas;
}

/// The progress kept in Google Play Games (Saved Games), Android only: sent
/// after each match, and offered back on a new phone (or after a fresh
/// install) when the cloud copy is further along than this one.
abstract final class JogoSalvo {
  static const nome = 'capiblocks';

  /// Google can be slow (or not answer at all while Saved Games is still
  /// being switched on): never wait forever.
  static const _limite = Duration(seconds: 20);

  static DateTime? _ultimoEnvio;
  static Future<Progresso?>? _verificacao;

  /// A cloud copy further along than this phone, waiting for the player's
  /// choice: until then nothing is sent, so it can't be overwritten.
  static Progresso? _pendente;

  /// At the opening, once signed in: the cloud copy, when it is further
  /// along than this phone and the player has not turned it down yet.
  /// Otherwise this phone's progress goes up.
  static Future<Progresso?> verificar(ProgressStore store) =>
      _verificacao ??= _verificar(store);

  /// After signing in later (the menu's invite, Settings → Leaderboards).
  static Future<Progresso?> verificarDeNovo(ProgressStore store) {
    _verificacao = null;
    return verificar(store);
  }

  static Future<Progresso?> _verificar(ProgressStore store) async {
    if (!Placares.ativo || !await Placares.conectado()) return null;
    try {
      // Loading a save that doesn't exist is an error: look at the list
      // first (an error there means no answer from the cloud).
      final salvos = await SaveGame.getSavedGames(
        forceRefresh: true,
        ignoreImages: true,
      ).timeout(_limite);
      if (salvos == null) throw StateError('sem resposta');
      final existe = salvos.any((s) => s.name == nome);
      final nuvem = existe
          ? Progresso.ler(await SaveGame.loadGame(name: nome).timeout(_limite))
          : null;
      if (existe && nuvem == null) throw StateError('cópia ilegível');
      final aqui = Progresso.doAparelho(store);
      if (nuvem != null &&
          nuvem.maisAvancadoQue(aqui) &&
          nuvem.salvoEm != store.nuvemRecusada) {
        return _pendente = nuvem;
      }
      await _enviar(store);
    } catch (e) {
      // No answer from the cloud: nothing is sent this time either.
      debugPrint('Jogos salvos: $e');
      _verificacao = null;
    }
    return null;
  }

  /// Sends this phone's progress (at most once a minute).
  static Future<void> salvar(ProgressStore store) async {
    if (!Placares.ativo || !await Placares.conectado()) return;
    // Only after the cloud copy was looked at, and never over a better one
    // the player hasn't answered about.
    await verificar(store);
    if (_pendente != null || _verificacao == null) return;
    final hora = DateTime.now();
    if (_ultimoEnvio != null &&
        hora.difference(_ultimoEnvio!) < const Duration(minutes: 1)) {
      return;
    }
    await _enviar(store);
  }

  /// Settings → Cloud save: sends at once, unless a better copy waits for
  /// an answer. True when it was sent.
  static Future<bool> salvarAgora(ProgressStore store) async {
    if (!Placares.ativo || !await Placares.conectado()) return false;
    // Right after verificarDeNovo: a failed check is not tried again here.
    final v = _verificacao;
    if (v == null) return false;
    await v;
    if (_pendente != null || _verificacao == null) return false;
    return _enviar(store);
  }

  static Future<bool> _enviar(ProgressStore store) async {
    final hora = DateTime.now();
    _ultimoEnvio = hora;
    final p = Progresso.doAparelho(store, agora: hora);
    try {
      await SaveGame.saveGame(
        data: p.json,
        name: nome,
        description: 'Fase ${p.fase} · ${p.estrelas} ★',
      ).timeout(_limite);
      return true;
    } catch (e) {
      debugPrint('Jogos salvos: $e');
      return false;
    }
  }

  /// The player chose the cloud copy: it replaces this phone's progress.
  static Future<void> carregar(ProgressStore store, Progresso p) async {
    _pendente = null;
    await store.importar(p.dados);
  }

  /// The player kept this phone's progress: it overwrites the cloud copy,
  /// and that copy is not offered again.
  static Future<void> manter(ProgressStore store, Progresso nuvem) async {
    _pendente = null;
    await store.setNuvemRecusada(nuvem.salvoEm);
    await _enviar(store);
  }
}
