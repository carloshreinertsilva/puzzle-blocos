import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/presente_diario.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('7 days in a row, once a day; missing a day starts again', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final d1 = DateTime(2026, 11, 28, 9);

    expect(PresenteDiario.dia(store, d1), 0);
    final r1 = await PresenteDiario.pegar(store, d1);
    expect(r1!.quantidade, 5);
    expect(store.stars, 5);
    expect(
      await PresenteDiario.pegar(store, d1.add(const Duration(hours: 5))),
      isNull,
    );

    // Next days, across the end of the month.
    var dia = d1;
    for (var i = 1; i < 7; i++) {
      dia = DateTime(dia.year, dia.month, dia.day + 1, 20);
      expect(PresenteDiario.dia(store, dia), i);
      expect(await PresenteDiario.pegar(store, dia), isNotNull);
    }
    expect(store.toolCount(CapiTool.hammer), greaterThanOrEqualTo(1));
    // After day 7, day 1 again.
    dia = DateTime(dia.year, dia.month, dia.day + 1, 8);
    expect(PresenteDiario.dia(store, dia), 0);
    await PresenteDiario.pegar(store, dia);
    // Skipping a day: back to day 1.
    final depois = DateTime(dia.year, dia.month, dia.day + 2, 8);
    expect(PresenteDiario.dia(store, depois), 0);
  });
}
