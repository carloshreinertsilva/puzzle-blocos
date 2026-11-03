import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/village.dart';
import 'package:puzzle_blocos/village/scene.dart';

void main() {
  // Capi and the pups stand on the grass, never inside a building: there
  // they would look buried behind it or floating on top of it.
  test('vila: o Capi e os filhotes nunca pisam dentro dos itens', () {
    const body = 0.2;
    for (final item in Village.items) {
      final spot = item.spot.inflate(body);
      expect(
        spot.contains(Village.capiSpot),
        isFalse,
        reason: 'Capi dentro de ${item.id}',
      );
      for (var i = 0; i < Pups.max; i++) {
        for (var t = 0.0; t < 60; t += 0.25) {
          final at = Pups.at(i, t);
          expect(
            spot.contains(at),
            isFalse,
            reason: 'filhote $i dentro de ${item.id} (t=$t, $at)',
          );
        }
      }
    }
  });

  test('vila: nenhum filhote passa na frente do Capi', () {
    for (var i = 0; i < Pups.max; i++) {
      for (var t = 0.0; t < 60; t += 0.25) {
        final gap = (Pups.at(i, t) - Village.capiSpot).distance;
        expect(gap, greaterThan(0.9), reason: 'filhote $i (t=$t)');
      }
    }
  });
}
