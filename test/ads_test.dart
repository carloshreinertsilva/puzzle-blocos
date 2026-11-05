import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_config.dart';
import 'package:puzzle_blocos/ads/ad_policy.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';
import 'package:puzzle_blocos/ads/admob.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An interstitial that never loaded (no network, no fill).
class _NoFillAds extends NoAdService {
  int asked = 0;

  @override
  Future<bool> showInterstitial(BuildContext context) async {
    asked++;
    return false;
  }
}

void main() {
  testWidgets('release builds without an ad network show no ads', (
    tester,
  ) async {
    final ads = NoAdService();
    expect(ads.hasVideoAds, isFalse);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    // The second chance is simply given, with no placeholder screen.
    expect(await ads.showRewarded(context, RewardPlacement.revive), isTrue);
    await ads.showInterstitial(context);
    await tester.pump();
    expect(find.textContaining('Anúncio'), findsNothing);
  });

  testWidgets('an interstitial that did not show leaves the clock alone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final service = _NoFillAds();
    final ads = AdCoordinator(
      service,
      store,
      policy: const AdPolicy(sessionGrace: Duration.zero, firstLevel: 0),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    await ads.betweenLevels(context, 10);
    expect(service.asked, 1);
    // Nothing was shown, so the next level may try again.
    expect(store.lastFullscreenAt, isNull);
  });

  test('debug builds use Google test ad units', () {
    expect(AdConfig.useTestAds, isTrue);
    expect(AdConfig.enabled, isTrue);
    expect(AdConfig.rewarded, startsWith('ca-app-pub-3940256099942544/'));
    expect(AdConfig.interstitial, startsWith('ca-app-pub-3940256099942544/'));
  });

  test('iOS gets its own test ad units', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      expect(AdConfig.rewarded, AdConfig.testRewardedIos);
      expect(AdConfig.interstitial, AdConfig.testInterstitialIos);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    expect(AdConfig.rewarded, AdConfig.testRewardedAndroid);
  });

  test('AdMob only runs on the phones', () {
    // Tests run on the desktop VM: no AdMob, the app picks another service.
    expect(createAdMobService(), isNull);
  });
}
