import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/l10n/en.dart';
import 'package:puzzle_blocos/l10n/es.dart';

void main() {
  test('privacy dialog texts are translated', () {
    final src = File('lib/ui/privacy_dialog.dart').readAsStringSync();
    final re = RegExp(
      r"_section\(\s*'((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)'",
      multiLine: true,
    );
    var n = 0;
    for (final m in re.allMatches(src)) {
      for (final g in [m[1]!, m[2]!]) {
        final k = g.replaceAll(r'\n', '\n').replaceAll(r"\'", "'");
        expect(en.containsKey(k), isTrue, reason: 'en: $k');
        expect(es.containsKey(k), isTrue, reason: 'es: $k');
        n++;
      }
    }
    expect(n, 12);
  });
}
