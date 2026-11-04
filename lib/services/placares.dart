import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

import 'progress_store.dart';

/// The Google Play Games leaderboards (Android only).
///
/// Play Games signs the player in by itself when the game opens; scores go
/// up after each match, and the Ranking button shows the boards (asking to
/// sign in first when the player isn't). Off Android, and in tests, nothing
/// here runs ([ativo] stays false).
abstract final class Placares {
  /// Turned on by main() on Android.
  static bool ativo = false;

  // IDs from the Play Console (Play Games Services → Placares).
  static const infinito = 'CgkInKLAmqYVEAIQAg';
  static const blitz = 'CgkInKLAmqYVEAIQAw';
  static const torre = 'CgkInKLAmqYVEAIQBA';
  static const estrelas = 'CgkInKLAmqYVEAIQBQ';

  static bool _entrou = false;

  /// At the opening: checks the automatic sign-in and sends the records
  /// kept on the phone, so the boards catch up with what was played
  /// before this version.
  static Future<void> iniciar(ProgressStore store) async {
    if (!ativo) return;
    try {
      _entrou = await GameAuth.isSignedIn.timeout(const Duration(seconds: 10));
      if (_entrou) await enviar(store);
    } catch (e) {
      debugPrint('Play Games: $e');
    }
  }

  /// The four records as they are now (the boards keep only the best).
  static Future<void> enviar(ProgressStore store) async {
    if (!ativo || !_entrou) return;
    final pontos = {
      infinito: store.bestScore,
      blitz: store.blitzBestScore,
      torre: store.towerBestHeight,
      estrelas: store.starsEarned,
    };
    for (final MapEntry(key: id, value: valor) in pontos.entries) {
      if (valor <= 0) continue;
      try {
        await Leaderboards.submitScore(
          score: Score(androidLeaderboardID: id, value: valor),
        );
      } catch (e) {
        debugPrint('Play Games: $e');
      }
    }
  }

  /// The Ranking button: signs in when needed, then shows all boards.
  /// False when the player could not be signed in.
  static Future<bool> mostrar(ProgressStore store) async {
    if (!ativo) return false;
    try {
      if (!_entrou) {
        await GameAuth.signIn();
        _entrou = await GameAuth.isSignedIn.timeout(
          const Duration(seconds: 10),
        );
        if (!_entrou) return false;
        await enviar(store);
      }
      await Leaderboards.showLeaderboards();
      return true;
    } catch (e) {
      debugPrint('Play Games: $e');
      return false;
    }
  }
}
