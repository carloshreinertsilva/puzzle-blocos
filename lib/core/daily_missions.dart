import 'dart:math';

import '../services/progress_store.dart';
import 'hats.dart';

enum DailyMissionType {
  clearLines('clear_lines', 'Limpar linhas', 'Limpe {n} linhas no total'),
  makeCombos('make_combos', 'Fazer combos', 'Faça {n} combos no tabuleiro'),
  playLevels('play_levels', 'Vencer fases', 'Vença {n} fases na estrada'),
  playEndless(
    'play_endless',
    'Pontuar no Infinito',
    'Faça {n} pontos no Infinito',
  ),
  playBlitz('play_blitz', 'Jogar Blitz', 'Jogue {n} partida de Blitz 60s'),
  playTower('play_tower', 'Subir a Torre', 'Suba {n} andares na Torre do Capi');

  const DailyMissionType(this.key, this.shortTitle, this.template);

  final String key;
  final String shortTitle;
  final String template;
}

class DailyMission {
  const DailyMission({
    required this.index,
    required this.type,
    required this.target,
    required this.rewardStars,
  });

  final int index; // 0, 1 or 2
  final DailyMissionType type;
  final int target;
  final int rewardStars;

  String get description => type.template.replaceAll('{n}', '$target');
}

abstract final class DailyMissionsManager {
  static const int chestStarsReward = 5;

  /// Returns the 3 deterministic daily missions for [day].
  static List<DailyMission> missionsForDay(DateTime day) {
    final key = ProgressStore.dayKey(day);
    final rng = Random(key * 1337 + 42);

    final types = List<DailyMissionType>.from(DailyMissionType.values)
      ..shuffle(rng);
    final selectedTypes = types.take(3).toList();

    return [
      _createMission(0, selectedTypes[0], rng),
      _createMission(1, selectedTypes[1], rng),
      _createMission(2, selectedTypes[2], rng),
    ];
  }

  static DailyMission _createMission(
    int index,
    DailyMissionType type,
    Random rng,
  ) {
    return switch (type) {
      DailyMissionType.clearLines => DailyMission(
        index: index,
        type: type,
        target: 12 + rng.nextInt(3) * 4, // 12, 16 or 20
        rewardStars: 2,
      ),
      DailyMissionType.makeCombos => DailyMission(
        index: index,
        type: type,
        target: 3 + rng.nextInt(3), // 3, 4 or 5
        rewardStars: 2,
      ),
      DailyMissionType.playLevels => DailyMission(
        index: index,
        type: type,
        target: 1 + rng.nextInt(2), // 1 or 2
        rewardStars: 2,
      ),
      DailyMissionType.playEndless => DailyMission(
        index: index,
        type: type,
        target: 1000 + rng.nextInt(3) * 500, // 1000, 1500 or 2000
        rewardStars: 1,
      ),
      DailyMissionType.playBlitz => DailyMission(
        index: index,
        type: type,
        target: 1,
        rewardStars: 1,
      ),
      DailyMissionType.playTower => DailyMission(
        index: index,
        type: type,
        target: 8 + rng.nextInt(3) * 4, // 8, 12 or 16
        rewardStars: 2,
      ),
    };
  }

  /// Increments progress for all active missions of [type] on [day].
  static Future<void> reportEvent(
    ProgressStore store,
    DailyMissionType type,
    int amount, [
    DateTime? day,
  ]) async {
    final currentDay = day ?? DateTime.now();
    final missions = missionsForDay(currentDay);
    for (final m in missions) {
      if (m.type == type) {
        final cur = store.dailyMissionProgress(currentDay, m.index);
        final next = (cur + amount).clamp(0, m.target);
        if (next > cur) {
          await store.setDailyMissionProgress(currentDay, m.index, next);
        }
      }
    }
  }

  /// Checks if mission [index] is completed.
  static bool isCompleted(
    ProgressStore store,
    DailyMission mission,
    DateTime day,
  ) {
    final progress = store.dailyMissionProgress(day, mission.index);
    return progress >= mission.target;
  }

  /// Checks if mission [index] reward was claimed.
  static bool isClaimed(
    ProgressStore store,
    DailyMission mission,
    DateTime day,
  ) {
    return store.isDailyMissionClaimed(day, mission.index);
  }

  /// Claims reward for mission.
  static Future<bool> claimMission(
    ProgressStore store,
    DailyMission mission,
    DateTime day,
  ) async {
    if (!isCompleted(store, mission, day) || isClaimed(store, mission, day)) {
      return false;
    }
    await store.setDailyMissionClaimed(day, mission.index, true);
    await store.addStars(mission.rewardStars);
    return true;
  }

  /// Checks if the daily chest is ready to be opened (all 3 missions completed).
  static bool isChestAvailable(ProgressStore store, DateTime day) {
    final missions = missionsForDay(day);
    for (final m in missions) {
      if (!isCompleted(store, m, day)) return false;
    }
    return !store.isDailyChestClaimed(day);
  }

  /// Checks if chest has already been claimed today.
  static bool isChestClaimed(ProgressStore store, DateTime day) {
    return store.isDailyChestClaimed(day);
  }

  /// Claims the daily chest: gives 5 stars, streak bonus, and unlocks a random locked hat if any.
  static Future<CapiHat?> claimChest(ProgressStore store, DateTime day) async {
    if (!isChestAvailable(store, day)) return null;

    await store.setDailyChestClaimed(day, true);
    await store.addStars(chestStarsReward);
    await store.completeDaily(day);

    // Find locked hats
    final unlocked = store.unlockedHats;
    final locked = CapiHat.values
        .where((h) => !unlocked.contains(h.id))
        .toList();

    if (locked.isNotEmpty) {
      // Pick one locked hat deterministically based on day and locked count
      final key = ProgressStore.dayKey(day);
      final index = key % locked.length;
      final newlyUnlocked = locked[index];
      await store.unlockHat(newlyUnlocked.id);
      return newlyUnlocked;
    }

    return null;
  }

  /// Count of unclaimed rewards available (missions ready to claim + chest ready).
  static int unclaimedCount(ProgressStore store, DateTime day) {
    final missions = missionsForDay(day);
    var count = 0;
    for (final m in missions) {
      if (isCompleted(store, m, day) && !isClaimed(store, m, day)) {
        count++;
      }
    }
    if (isChestAvailable(store, day)) {
      count++;
    }
    return count;
  }
}
