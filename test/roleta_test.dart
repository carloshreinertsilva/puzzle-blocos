import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/tower/roleta.dart';

void main() {
  test('Cinco setores: 1x | 1,2x | 3x | 1,5x | 1x, o 3x no meio', () {
    expect(Roleta.multiplicadores, [1.0, 1.2, 3.0, 1.5, 1.0]);
    expect(Roleta.larguras.reduce((a, b) => a + b), closeTo(1, 1e-9));
    final meio = Roleta.larguras[2];
    for (final (i, l) in Roleta.larguras.indexed) {
      if (i != 2) expect(meio, lessThan(l), reason: 'o 3x é o mais estreito');
    }
    final (a, b) = Roleta.limites(2);
    expect((a + b) / 2, closeTo(0.5, 1e-9), reason: 'bem no meio');
  });

  test('A seta vai e volta: esquerda, direita e esquerda de novo', () {
    expect(Roleta.angulo(0), 0);
    expect(Roleta.angulo(Roleta.periodo / 4), closeTo(pi / 2, 1e-9));
    expect(Roleta.angulo(Roleta.periodo / 2), closeTo(pi, 1e-9));
    expect(Roleta.angulo(Roleta.periodo), closeTo(0, 1e-9));
    expect(Roleta.angulo(-1), 0);
    // Deterministic: the same moment always gives the same angle.
    expect(Roleta.angulo(7.3), Roleta.angulo(7.3));
    expect(
      Roleta.angulo(7.3),
      closeTo(Roleta.angulo(7.3 + Roleta.periodo), 1e-9),
    );
  });

  test('O multiplicador sai do setor sob a seta', () {
    expect(Roleta.multiplicadorEm(0), 1.0);
    expect(Roleta.multiplicadorEm(Roleta.periodo / 4), 3.0);
    expect(Roleta.multiplicadorEm(Roleta.periodo / 2), 1.0);
    expect(Roleta.setorEm(0.3), 1);
    expect(Roleta.setorEm(0.5), 2);
    expect(Roleta.setorEm(0.6), 3);
    expect(Roleta.setorEm(0.99), 4);
    expect(Roleta.setorEm(1), 4);
    // Going right, the needle passes 1,2x before the 3x.
    expect(Roleta.multiplicadorEm(Roleta.periodo * 0.17), 1.2);
  });

  test('O 3x é raro: a seta passa rápido por ele', () {
    var tres = 0;
    const n = 10000;
    for (var i = 0; i < n; i++) {
      if (Roleta.multiplicadorEm(Roleta.periodo * i / n) == 3) tres++;
    }
    expect(tres / n, lessThan(Roleta.larguras[2]));
    expect(tres, greaterThan(0));
  });

  test('Rótulos e crescimento limitado ao bloco base', () {
    expect(Roleta.rotulo(1), '1x');
    expect(Roleta.rotulo(1.2), '1,2x');
    expect(Roleta.rotulo(1.5, virgula: false), '1.5x');
    expect(Roleta.crescer(1, 1.5, 3), 1.5);
    expect(Roleta.crescer(2, 3, 3), 3);
    expect(Roleta.crescer(3, 1.2, 3), 3);
    expect(Roleta.crescer(3.2, 1.2, 3), 3.2, reason: 'nunca encolhe');
  });
}
