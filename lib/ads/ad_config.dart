import 'package:flutter/foundation.dart';

/// Configuration and Ad Unit IDs for Google AdMob.
/// Uses official Google test IDs by default to prevent invalid traffic policy violations.
/// Replace production fields when real ad units are created in the AdMob console.
class AdConfig {
  static const bool useTestAds = true;

  // Google AdMob Official Test Unit IDs
  static const String testAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testAndroidRewarded =
      'ca-app-pub-3940256099942544/5224354917';

  static const String testIosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
  static const String testIosRewarded =
      'ca-app-pub-3940256099942544/1712485313';

  // Production Ad Unit IDs (replace when ready)
  static const String prodAndroidInterstitial = '';
  static const String prodAndroidRewarded = '';
  static const String prodIosInterstitial = '';
  static const String prodIosRewarded = '';

  static String get interstitialAdUnitId {
    if (useTestAds || kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? testIosInterstitial
          : testAndroidInterstitial;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? prodIosInterstitial
        : prodAndroidInterstitial;
  }

  static String get rewardedAdUnitId {
    if (useTestAds || kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? testIosRewarded
          : testAndroidRewarded;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? prodIosRewarded
        : prodAndroidRewarded;
  }
}
