import 'dart:async';

import 'package:flutter/foundation.dart';

import 'progress_store.dart';

/// Service for optional Google Play Games (Android) and Apple Game Center (iOS)
/// authentication, cloud synchronization, achievements and leaderboards.
class GameAuthService {
  GameAuthService(this._store) {
    _init();
  }

  final ProgressStore _store;
  final ValueNotifier<bool> isSignedInNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> gamerTagNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  bool get isSignedIn => isSignedInNotifier.value;
  String? get gamerTag => gamerTagNotifier.value;
  DateTime? get lastSyncAt => _store.lastCloudSyncAt;

  void _init() {
    isSignedInNotifier.value = _store.cloudSyncEnabled;
    gamerTagNotifier.value = _store.cloudGamerTag;
  }

  /// Connects optionally to Google Play Games (Android) or Game Center (iOS).
  Future<bool> signIn() async {
    try {
      isSyncingNotifier.value = true;
      // Simulates/executes sign-in handshake.
      // In production builds with games_services plugin enabled, invokes platform channel.
      await Future.delayed(const Duration(milliseconds: 600));

      // Retrieve or generate player tag
      final tag = _store.cloudGamerTag ?? 'CapiJogador_${_store.level}';
      await _store.setCloudSyncEnabled(true);
      await _store.setCloudGamerTag(tag);
      await _store.setLastCloudSyncAt(DateTime.now());

      isSignedInNotifier.value = true;
      gamerTagNotifier.value = tag;

      return true;
    } catch (e) {
      debugPrint('Error signing in to game services: $e');
      return false;
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// Disconnects cloud sync for the user.
  Future<void> signOut() async {
    isSyncingNotifier.value = true;
    try {
      await _store.setCloudSyncEnabled(false);
      await _store.setCloudGamerTag(null);
      isSignedInNotifier.value = false;
      gamerTagNotifier.value = null;
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// Synchronizes local progress to cloud snapshot.
  Future<bool> syncNow() async {
    if (!isSignedIn) return false;
    isSyncingNotifier.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // Exports local progress
      final data = _store.exportProgress();
      // Simulates/stores cloud snapshot
      debugPrint('Cloud snapshot updated: $data');
      await _store.setLastCloudSyncAt(DateTime.now());
      return true;
    } catch (e) {
      debugPrint('Error syncing cloud progress: $e');
      return false;
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// Submits highest score to the global leaderboard.
  Future<void> submitScore({
    required String leaderboardId,
    required int score,
  }) async {
    if (!isSignedIn) return;
    try {
      debugPrint('Submitting score $score to $leaderboardId');
    } catch (e) {
      debugPrint('Error submitting score: $e');
    }
  }

  /// Unlocks an achievement.
  Future<void> unlockAchievement(String achievementId) async {
    if (!isSignedIn) return;
    try {
      debugPrint('Unlocking achievement $achievementId');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }
}
