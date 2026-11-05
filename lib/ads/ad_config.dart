import 'package:flutter/foundation.dart';

/// Google AdMob IDs, one set per platform.
///
/// Debug builds, and builds made with `--dart-define=ADMOB_TEST=true`, use
/// Google's official test IDs: those ads say "Test Ad" and never count as
/// invalid traffic. Release builds use the real IDs below; while a
/// platform's are empty, its release builds show no ads at all.
abstract final class AdConfig {
  static const forceTestAds = bool.fromEnvironment('ADMOB_TEST');
  static bool get useTestAds => kDebugMode || forceTestAds;

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  // Google's test ad units.
  static const testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  static const testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  // Real ad units from the AdMob console. The app IDs go in
  // android/app/src/main/AndroidManifest.xml and ios/Runner/Info.plist.
  static const prodRewardedAndroid = 'ca-app-pub-2477171262502738/4877674077';
  static const prodInterstitialAndroid =
      'ca-app-pub-2477171262502738/8764948192';
  // The iOS app in AdMob (empty until it is created there).
  static const prodRewardedIos = '';
  static const prodInterstitialIos = '';

  static String get _prodRewarded =>
      _ios ? prodRewardedIos : prodRewardedAndroid;
  static String get _prodInterstitial =>
      _ios ? prodInterstitialIos : prodInterstitialAndroid;

  static bool get enabled =>
      useTestAds || (_prodRewarded.isNotEmpty && _prodInterstitial.isNotEmpty);
  static String get rewarded => useTestAds
      ? (_ios ? testRewardedIos : testRewardedAndroid)
      : _prodRewarded;
  static String get interstitial => useTestAds
      ? (_ios ? testInterstitialIos : testInterstitialAndroid)
      : _prodInterstitial;
}
