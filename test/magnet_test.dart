import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/game/tray_piece.dart';

void main() {
  test('the exact spot wins when it fits', () {
    expect(nearestFit(2.2, 3.1, (r, c) => true), (3, 2));
  });

  test('a drop slightly off goes to the nearest spot that fits', () {
    // (3, 2) is taken; (3, 3) is 0.6 away, (4, 2) 1.0 away (too far).
    final free = {(3, 3), (4, 2)};
    expect(nearestFit(2.4, 3.0, (r, c) => free.contains((r, c))), (3, 3));
  });

  test('too far: no spot', () {
    expect(nearestFit(2.0, 3.0, (r, c) => (r, c) == (4, 4)), isNull);
  });
}
