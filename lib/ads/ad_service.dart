import 'package:flutter/material.dart';

import '../services/analytics.dart';
import '../services/progress_store.dart';
import 'ad_policy.dart';

enum RewardPlacement {
  revive,
  doubleStars,
  bonusChest,
  wardrobeItem,
  obraHint,
  toolHammer,
  toolRotate,
  toolReroll,
  toolShovel;

  static RewardPlacement forTool(CapiTool tool) => switch (tool) {
    CapiTool.hammer => RewardPlacement.toolHammer,
    CapiTool.rotate => RewardPlacement.toolRotate,
    CapiTool.reroll => RewardPlacement.toolReroll,
    CapiTool.shovel => RewardPlacement.toolShovel,
  };
}

/// Shows ads: AdMob on Android (`admob_service.dart`), [NoAdService] in
/// release builds without ad units, [DebugAdService] on the web in debug and
/// in browser tests.
abstract class AdService {
  /// Whether rewarded videos really exist. Without them the game doesn't
  /// promise "watch a video" anywhere.
  bool get hasVideoAds;

  /// Whether the settings must offer a way to change the ad consent choice
  /// (AdMob, in regions whose law requires it).
  bool get privacyOptionsRequired;

  /// Gets ready after launch (consent, ad network, first ads).
  Future<void> start();

  Future<void> showPrivacyOptions();

  /// Returns true when the player watched to the end and earned the reward.
  Future<bool> showRewarded(BuildContext context, RewardPlacement placement);

  /// Returns true when an ad was actually shown.
  Future<bool> showInterstitial(BuildContext context);
}

/// Release builds before AdMob: no ads at all. Interstitials are skipped and
/// the one rewarded perk players still see (the second chance) is simply
/// given; the free-tool-for-a-video offer is hidden.
class NoAdService implements AdService {
  @override
  bool get hasVideoAds => false;

  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> start() async {}

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<bool> showRewarded(BuildContext context, RewardPlacement placement) =>
      Future.value(true);

  @override
  Future<bool> showInterstitial(BuildContext context) => Future.value(false);
}

/// Debug and browser-test builds: a black placeholder screen stands in for
/// each ad, so the ad flows can be exercised.
class DebugAdService implements AdService {
  @override
  bool get hasVideoAds => true;

  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> start() async {}

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<bool> showRewarded(BuildContext context, RewardPlacement placement) =>
      _show(context, 'Anúncio com recompensa (teste)');

  @override
  Future<bool> showInterstitial(BuildContext context) =>
      _show(context, 'Anúncio entre fases (teste)');

  Future<bool> _show(BuildContext context, String label) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, _, _) => _FakeAd(label: label),
    );
    return result ?? false;
  }
}

class _FakeAd extends StatefulWidget {
  const _FakeAd({required this.label});
  final String label;

  @override
  State<_FakeAd> createState() => _FakeAdState();
}

class _FakeAdState extends State<_FakeAd> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black,
    child: Center(
      child: Text(
        widget.label,
        style: const TextStyle(color: Colors.white70, fontSize: 18),
      ),
    ),
  );
}

/// Applies [AdPolicy] and remembers when the last full-screen ad ran, across
/// app restarts, so reopening the app does not reset the clock.
class AdCoordinator {
  AdCoordinator(this.service, this.store, {this.policy = const AdPolicy()});

  final AdService service;
  final ProgressStore store;
  final AdPolicy policy;
  final DateTime sessionStart = DateTime.now();

  bool get hasVideoAds => service.hasVideoAds;
  bool get privacyOptionsRequired => service.privacyOptionsRequired;

  Future<void> start() => service.start();
  Future<void> showPrivacyOptions() => service.showPrivacyOptions();

  Future<bool> rewarded(BuildContext context, RewardPlacement placement) async {
    final ok = await service.showRewarded(context, placement);
    Analytics.event('reward_ad', {
      'placement': placement.name,
      'rewarded': ok ? 1 : 0,
    });
    await store.setLastFullscreenAt(DateTime.now());
    return ok;
  }

  Future<void> betweenLevels(BuildContext context, int completedLevel) async {
    final allowed = policy.canShowInterstitial(
      now: DateTime.now(),
      completedLevel: completedLevel,
      sessionStart: sessionStart,
      lastFullscreenAt: store.lastFullscreenAt,
      adsRemoved: store.adsRemoved,
    );
    if (!allowed) return;
    if (await service.showInterstitial(context)) {
      Analytics.event('interstitial_ad', {'level': completedLevel});
      await store.setLastFullscreenAt(DateTime.now());
    }
  }
}
