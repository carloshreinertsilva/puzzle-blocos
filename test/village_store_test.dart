import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('vila: saves from the fixed order become the first items', () async {
    SharedPreferences.setMockInitialValues({'villageBuilt': 3});
    final store = await ProgressStore.load();
    expect(store.villageItems, ['flores', 'cerca', 'banco']);
    expect(store.villageBuilt, 3);

    // From now on the player picks, in any order, never twice.
    await store.addVillageItem('roda');
    await store.addVillageItem('roda');
    expect(store.villageItems, ['flores', 'cerca', 'banco', 'roda']);
    expect(store.villageBuilt, 4);
  });
}
