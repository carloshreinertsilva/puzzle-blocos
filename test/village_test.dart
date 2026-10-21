import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/village.dart';

void main() {
  test('village: items in build order, all inside the scene, drawn back to '
      'front', () {
    final scene = Offset.zero & Village.sceneSize;
    for (final item in Village.items) {
      expect(scene.contains(item.rect.topLeft), isTrue, reason: item.id);
      expect(scene.contains(item.rect.bottomRight), isTrue, reason: item.id);
    }
    expect(Village.next(0)!.id, 'flores');
    expect(Village.next(Village.items.length), isNull);
    final drawn = Village.drawn(Village.items.length);
    for (var i = 1; i < drawn.length; i++) {
      expect(drawn[i].rect.bottom >= drawn[i - 1].rect.bottom, isTrue);
    }
    // The whole village costs about 30 levels' worth of stars.
    final total = Village.items.fold(0, (sum, i) => sum + i.cost);
    expect(total, inInclusiveRange(60, 90));
  });
}
