import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import 'ad_policy.dart';

enum RewardPlacement {
  revive,
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

/// Shows ads. The AdMob implementation plugs in here; until then release
/// builds use [NoAdService] and test builds [DebugAdService].
abstract class AdService {
  /// Whether rewarded videos really exist. Without them the game doesn't
  /// promise "watch a video" anywhere.
  bool get hasVideoAds;

  /// Returns true when the player watched to the end and earned the reward.
  Future<bool> showRewarded(BuildContext context, RewardPlacement placement);
  Future<void> showInterstitial(BuildContext context);
}

/// Release builds before AdMob: no ads at all. Interstitials are skipped and
/// the one rewarded perk players still see (the second chance) is simply
/// given; the free-tool-for-a-video offer is hidden.
class NoAdService implements AdService {
  @override
  bool get hasVideoAds => false;

  @override
  Future<bool> showRewarded(BuildContext context, RewardPlacement placement) =>
      Future.value(true);

  @override
  Future<void> showInterstitial(BuildContext context) async {}
}

/// Debug and browser-test builds: a black placeholder screen stands in for
/// each ad, so the ad flows can be exercised.
class DebugAdService implements AdService {
  @override
  bool get hasVideoAds => true;

  @override
  Future<bool> showRewarded(BuildContext context, RewardPlacement placement) =>
      _show(context, 'Anúncio com recompensa (teste)');

  @override
  Future<void> showInterstitial(BuildContext context) =>
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

  Future<bool> rewarded(BuildContext context, RewardPlacement placement) async {
    final ok = await service.showRewarded(context, placement);
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
    await service.showInterstitial(context);
    await store.setLastFullscreenAt(DateTime.now());
  }
}
