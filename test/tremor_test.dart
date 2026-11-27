import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/game/tremor.dart';

void main() {
  const dt = 1 / 60;

  test('parado, o palco fica exatamente no lugar', () {
    final t = Tremor();
    expect(t.parado, isTrue);
    expect(t.avancar(dt, 20), Offset.zero);
  });

  test('o tremor acaba no tempo certo e volta ao zero exato', () {
    final t = Tremor()..somar(1);
    var quadros = 0;
    Offset ultimo = Offset.zero;
    while (!t.parado && quadros < 600) {
      ultimo = t.avancar(dt, 20);
      quadros++;
    }
    // 1 de trauma a 2,4 por segundo: pouco mais de 0,4 s.
    expect(quadros, inInclusiveRange(24, 27));
    expect(ultimo, Offset.zero);
    expect(t.avancar(dt, 20), Offset.zero);
  });

  test('nunca passa do alcance e não pula de um quadro para o outro', () {
    final t = Tremor()..somar(1);
    var antes = Offset.zero;
    var primeiro = true;
    while (!t.parado) {
      final o = t.avancar(dt, 20);
      expect(o.dx.abs(), lessThanOrEqualTo(20));
      expect(o.dy.abs(), lessThanOrEqualTo(14));
      // O sorteio antigo saltava até o dobro do alcance entre dois quadros.
      if (!primeiro) expect((o - antes).distance, lessThan(22));
      antes = o;
      primeiro = false;
    }
  });

  test('batidas somam (até 1) e uma pequena mexe bem menos que uma grande', () {
    final t = Tremor()
      ..somar(0.5)
      ..somar(0.3);
    expect(t.trauma, closeTo(0.8, 1e-9));
    t.somar(0.9);
    expect(t.trauma, 1);

    double pico(double trauma) {
      final x = Tremor()..somar(trauma);
      var m = 0.0;
      while (!x.parado) {
        final d = x.avancar(dt, 20).distance;
        if (d > m) m = d;
      }
      return m;
    }

    expect(pico(0.3), lessThan(pico(1) * 0.2));
  });
}
