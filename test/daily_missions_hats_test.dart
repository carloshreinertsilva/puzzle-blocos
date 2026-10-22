import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:puzzle_blocos/core/daily_missions.dart';
import 'package:puzzle_blocos/core/hats.dart';
import 'package:puzzle_blocos/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProgressStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await ProgressStore.load();
  });

  group('CapiHat & Wardrobe', () {
    test('default hat is helmet and is always unlocked', () {
      expect(store.equippedHat, equals('helmet'));
      expect(store.unlockedHats, contains('helmet'));
      expect(CapiHat.helmet.isUnlocked(store), isTrue);
      expect(CapiHat.helmet.isEquipped(store), isTrue);
    });

    test('fromId returns matching hat or fallback to helmet', () {
      expect(CapiHat.fromId('crown'), equals(CapiHat.crown));
      expect(CapiHat.fromId('party'), equals(CapiHat.party));
      expect(CapiHat.fromId('chef'), equals(CapiHat.chef));
      expect(CapiHat.fromId('pirate'), equals(CapiHat.pirate));
      expect(CapiHat.fromId('straw'), equals(CapiHat.straw));
      expect(CapiHat.fromId('wizard'), equals(CapiHat.wizard));
      expect(CapiHat.fromId('non_existent'), equals(CapiHat.helmet));
    });

    test('unlocking and equipping hats', () async {
      expect(CapiHat.crown.isUnlocked(store), isFalse);

      await store.unlockHat('crown');
      expect(CapiHat.crown.isUnlocked(store), isTrue);
      expect(store.unlockedHats, containsAll(['helmet', 'crown']));

      await store.equipHat('crown');
      expect(store.equippedHat, equals('crown'));
      expect(CapiHat.crown.isEquipped(store), isTrue);
      expect(CapiHat.helmet.isEquipped(store), isFalse);
    });
  });

  group('DailyMissionsManager', () {
    final testDay = DateTime(2026, 10, 22);

    test(
      'generates exactly 3 distinct missions deterministically for a day',
      () {
        final missions1 = DailyMissionsManager.missionsForDay(testDay);
        final missions2 = DailyMissionsManager.missionsForDay(testDay);

        expect(missions1.length, equals(3));
        expect(missions2.length, equals(3));

        // Same day yields identical mission configuration
        for (var i = 0; i < 3; i++) {
          expect(missions1[i].type, equals(missions2[i].type));
          expect(missions1[i].target, equals(missions2[i].target));
          expect(missions1[i].rewardStars, equals(missions2[i].rewardStars));
        }

        // Distinct types in the same day
        final types = missions1.map((m) => m.type).toSet();
        expect(types.length, equals(3));
      },
    );

    test('progress reporting and mission completion', () async {
      final missions = DailyMissionsManager.missionsForDay(testDay);
      final m0 = missions[0];

      expect(DailyMissionsManager.isCompleted(store, m0, testDay), isFalse);

      // Report event for m0's type
      await DailyMissionsManager.reportEvent(
        store,
        m0.type,
        m0.target,
        testDay,
      );

      expect(store.dailyMissionProgress(testDay, 0), equals(m0.target));
      expect(DailyMissionsManager.isCompleted(store, m0, testDay), isTrue);
      expect(DailyMissionsManager.isClaimed(store, m0, testDay), isFalse);

      // Claim reward
      final initialStars = store.stars;
      final claimed = await DailyMissionsManager.claimMission(
        store,
        m0,
        testDay,
      );

      expect(claimed, isTrue);
      expect(store.stars, equals(initialStars + m0.rewardStars));
      expect(DailyMissionsManager.isClaimed(store, m0, testDay), isTrue);

      // Cannot claim again
      final claimAgain = await DailyMissionsManager.claimMission(
        store,
        m0,
        testDay,
      );
      expect(claimAgain, isFalse);
    });

    test(
      'daily chest unlocks after all 3 missions and rewards 5 stars + new hat',
      () async {
        final missions = DailyMissionsManager.missionsForDay(testDay);

        // Complete all 3 missions
        for (final m in missions) {
          await DailyMissionsManager.reportEvent(
            store,
            m.type,
            m.target,
            testDay,
          );
        }

        expect(DailyMissionsManager.isChestAvailable(store, testDay), isTrue);
        expect(DailyMissionsManager.isChestClaimed(store, testDay), isFalse);

        final initialStars = store.stars;
        final unlockedHat = await DailyMissionsManager.claimChest(
          store,
          testDay,
        );

        expect(DailyMissionsManager.isChestClaimed(store, testDay), isTrue);
        expect(DailyMissionsManager.isChestAvailable(store, testDay), isFalse);
        expect(
          store.stars,
          equals(initialStars + DailyMissionsManager.chestStarsReward),
        );
        expect(unlockedHat, isNotNull);
        expect(store.unlockedHats, contains(unlockedHat!.id));

        // Attempting to claim again returns null
        final claimAgain = await DailyMissionsManager.claimChest(
          store,
          testDay,
        );
        expect(claimAgain, isNull);
      },
    );
  });
}
