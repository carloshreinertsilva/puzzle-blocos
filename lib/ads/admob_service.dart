import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_service.dart';

AdService? createAdMobService() =>
    Platform.isAndroid && AdConfig.enabled ? AdMobService() : null;

/// Real ads through Google AdMob. First asks for consent where the law
/// requires it (Google's consent message), then keeps one rewarded video and
/// one interstitial loaded so they show without a wait.
class AdMobService implements AdService {
  /// Loaded ads expire after an hour; older ones are thrown away.
  static const _maxAge = Duration(minutes: 55);

  /// How long a player waits for a video that is still loading.
  static const _loadWait = Duration(seconds: 8);

  bool _canRequestAds = false;
  bool _sdkStarted = false;
  bool _privacyOptionsRequired = false;

  RewardedAd? _rewarded;
  DateTime? _rewardedAt;
  Completer<void>? _rewardedLoad;

  InterstitialAd? _interstitial;
  DateTime? _interstitialAt;
  bool _loadingInterstitial = false;

  @override
  bool get hasVideoAds => true;

  @override
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  @override
  Future<void> start() async {
    // Consent from an earlier session is cached: ads can load right away
    // while the consent info refreshes.
    await _afterConsent();
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) {
        if (!done.isCompleted) done.complete();
      }),
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    await _afterConsent();
  }

  Future<void> _afterConsent() async {
    _privacyOptionsRequired =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (!_canRequestAds) return;
    if (!_sdkStarted) {
      _sdkStarted = true;
      // A cute puzzle game: only ads fit for general audiences.
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
      );
      await MobileAds.instance.initialize();
    }
    _loadRewarded();
    _loadInterstitial();
  }

  @override
  Future<void> showPrivacyOptions() async {
    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((_) => done.complete());
    await done.future;
    await _afterConsent();
  }

  static bool _fresh(DateTime? loadedAt) =>
      loadedAt != null && DateTime.now().difference(loadedAt) < _maxAge;

  void _loadRewarded() {
    if (!_canRequestAds || _rewardedLoad != null) return;
    if (_rewarded != null) {
      if (_fresh(_rewardedAt)) return;
      _rewarded!.dispose();
      _rewarded = null;
    }
    final loading = _rewardedLoad = Completer<void>();
    RewardedAd.load(
      adUnitId: AdConfig.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedAt = DateTime.now();
          _rewardedLoad = null;
          loading.complete();
        },
        onAdFailedToLoad: (_) {
          _rewardedLoad = null;
          loading.complete();
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (!_canRequestAds || _loadingInterstitial) return;
    if (_interstitial != null) {
      if (_fresh(_interstitialAt)) return;
      _interstitial!.dispose();
      _interstitial = null;
    }
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialAt = DateTime.now();
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (_) => _loadingInterstitial = false,
      ),
    );
  }

  @override
  Future<bool> showRewarded(
    BuildContext context,
    RewardPlacement placement,
  ) async {
    _loadRewarded();
    final loading = _rewardedLoad;
    if (loading != null) await _waitForVideo(context, loading.future);
    final ad = _rewarded;
    if (ad == null) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'Nenhum vídeo disponível agora. Tente de novo daqui a pouco.',
            ),
          ),
        );
      }
      return false;
    }
    _rewarded = null;
    var earned = false;
    final closed = Completer<bool>();
    void finish(RewardedAd ad) {
      ad.dispose();
      if (!closed.isCompleted) closed.complete(earned);
      _loadRewarded();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, _) => finish(ad),
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return closed.future;
  }

  /// A spinner over the game while the video finishes loading.
  Future<void> _waitForVideo(BuildContext context, Future<void> loading) async {
    final navigator = Navigator.of(context);
    var open = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Semantics(
            label: 'Carregando vídeo',
            child: const CircularProgressIndicator(),
          ),
        ),
      ).whenComplete(() => open = false),
    );
    await loading.timeout(_loadWait, onTimeout: () {});
    if (open) navigator.pop();
  }

  @override
  Future<bool> showInterstitial(BuildContext context) async {
    final ad = _interstitial;
    if (ad == null || !_fresh(_interstitialAt)) {
      // Not ready: skip this one rather than make the player wait.
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        closed.complete(true);
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        closed.complete(false);
        _loadInterstitial();
      },
    );
    await ad.show();
    return closed.future;
  }
}
