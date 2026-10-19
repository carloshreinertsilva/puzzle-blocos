/// When ads may appear. The game screen never shows banners or any ad
/// during play; there are only two kinds:
///
/// * Rewarded ads, always the player's choice (revive, bonus rewards).
/// * Interstitials, only on the way from one finished level to the next,
///   and spaced far apart.
///
/// Any full-screen ad (including a rewarded one the player just watched)
/// resets the interstitial clock, so a player who revives does not see
/// another ad right after.
class AdPolicy {
  const AdPolicy({
    this.minInterval = const Duration(minutes: 6),
    this.firstLevel = 6,
    this.sessionGrace = const Duration(minutes: 5),
  });

  /// Minimum gap between full-screen ads (meant to be 5 to 10 minutes).
  final Duration minInterval;

  /// No interstitial before this level has been completed.
  final int firstLevel;

  /// No interstitial during the first minutes after the app opens.
  final Duration sessionGrace;

  bool canShowInterstitial({
    required DateTime now,
    required int completedLevel,
    required DateTime sessionStart,
    DateTime? lastFullscreenAt,
    bool adsRemoved = false,
  }) {
    if (adsRemoved) return false;
    if (completedLevel < firstLevel) return false;
    if (now.difference(sessionStart) < sessionGrace) return false;
    if (lastFullscreenAt != null &&
        now.difference(lastFullscreenAt) < minInterval) {
      return false;
    }
    return true;
  }
}
