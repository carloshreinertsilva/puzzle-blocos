import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/village.dart';

void main() {
  test('village: items on the island, not on top of each '
      'other', () {
    final island = Offset.zero & const Size.square(Village.island);
    for (final item in Village.items) {
      expect(island.contains(item.spot.topLeft), isTrue, reason: item.id);
      expect(island.contains(item.spot.bottomRight), isTrue, reason: item.id);
      for (final other in Village.items) {
        if (other == item) continue;
        expect(
          item.spot.overlaps(other.spot),
          isFalse,
          reason: '${item.id} x ${other.id}',
        );
      }
    }
    // The market offers what is left, cheapest first, in any order.
    expect(Village.suggestion(const [])!.cost, 18);
    final left = Village.toBuild(const ['flores', 'pier']);
    expect(left.length, Village.items.length - 2);
    expect(left.map((i) => i.id), isNot(contains('pier')));
    expect(Village.suggestion([for (final i in Village.items) i.id]), isNull);
    // The whole village costs a few weeks of play (docs/economia.md).
    final total = Village.items.fold(0, (sum, i) => sum + i.cost);
    expect(total, inInclusiveRange(400, 480));
  });
}
