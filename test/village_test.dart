import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/village.dart';

void main() {
  test('village: items in build order, on the island, not on top of each '
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
    expect(Village.next(0)!.id, 'flores');
    expect(Village.next(Village.items.length), isNull);
    // The whole village costs about 30 levels' worth of stars.
    final total = Village.items.fold(0, (sum, i) => sum + i.cost);
    expect(total, inInclusiveRange(60, 90));
  });
}
