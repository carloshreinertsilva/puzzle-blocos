import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/blueprint.dart';
import 'package:puzzle_blocos/game/obra_controller.dart';

void main() {
  test('obras: só a primeira dica é grátis', () {
    final obra = ObraController(Blueprints.level(3));
    expect(obra.nextHintPaid, isFalse);
    obra.showHint();
    expect(obra.hints, 1);
    expect(obra.hint, isNotNull);

    // Pressing again while the hint is on screen repeats it for free.
    expect(obra.nextHintPaid, isFalse);
    obra.showHint();
    expect(obra.hints, 1);

    // Following the hint clears it: the next one is paid.
    final (piece, r, c) = obra.hint!;
    expect(obra.place(piece, r, c), isTrue);
    expect(obra.hint, isNull);
    if (!obra.solved) {
      expect(obra.nextHintPaid, isTrue);
      obra.showHint();
      expect(obra.hints, 2);
      expect(obra.stars, 1);
    }
  });
}
