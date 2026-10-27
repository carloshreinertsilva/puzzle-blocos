import 'package:flutter/foundation.dart';

/// Google AdMob IDs (Android only for now).
///
/// Debug builds, and builds made with `--dart-define=ADMOB_TEST=true`, use
/// Google's official test IDs: those ads say "Test Ad" and never count as
/// invalid traffic. Release builds use the real IDs below; while they are
/// empty, release builds show no ads at all.
abstract final class AdConfig {
  static const forceTestAds = bool.fromEnvironment('ADMOB_TEST');
  static bool get useTestAds => kDebugMode || forceTestAds;

  // Google's test ad units for Android.
  static const testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  // Real ad units from the AdMob console (the app ID goes in
  // android/app/src/main/AndroidManifest.xml).
  static const prodRewarded = '';
  static const prodInterstitial = '';

  static bool get enabled =>
      useTestAds || (prodRewarded.isNotEmpty && prodInterstitial.isNotEmpty);
  static String get rewarded => useTestAds ? testRewarded : prodRewarded;
  static String get interstitial =>
      useTestAds ? testInterstitial : prodInterstitial;
}
