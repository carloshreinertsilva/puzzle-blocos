import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/ads/ad_service.dart';

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
}
