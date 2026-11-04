import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/l10n/en.dart';
import 'package:puzzle_blocos/l10n/es.dart';
import 'package:puzzle_blocos/l10n/idioma.dart';

/// Every text the code passes to `tr`/`trN`, as written (Portuguese).
Set<String> textosNoCodigo() {
  final literal = RegExp(
    "'(?:[^'\\\\]|\\\\.)*'"
    r'|"(?:[^"\\]|\\.)*"',
  );
  final chamada = RegExp(r'\btrN?\(');
  final out = <String>{};
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    if (f.path.contains(
      '${Platform.pathSeparator}l10n${Platform.pathSeparator}',
    )) {
      continue;
    }
    final src = f.readAsStringSync();
    for (final m in chamada.allMatches(src)) {
      // The string arguments right after the call (trN has two), each
      // possibly split in adjacent literals.
      var i = m.end;
      final isN = src.substring(m.start, m.end).startsWith('trN');
      if (isN) {
        i = src.indexOf(',', i) + 1; // skip the count
      }
      for (var arg = 0; arg < (isN ? 2 : 1); arg++) {
        final buf = StringBuffer();
        var found = false;
        while (true) {
          while (i < src.length && ' \n\r\t'.contains(src[i])) {
            i++;
          }
          final lit = literal.matchAsPrefix(src, i);
          if (lit == null) break;
          found = true;
          buf.write(_unescape(lit[0]!.substring(1, lit[0]!.length - 1)));
          i = lit.end;
        }
        if (!found) break; // not a literal: checked by hand elsewhere
        out.add(buf.toString());
        while (i < src.length && ' \n\r\t'.contains(src[i])) {
          i++;
        }
        if (i < src.length && src[i] == ',') i++;
      }
    }
  }
  return out;
}

String _unescape(String s) => s
    .replaceAll(r"\'", "'")
    .replaceAll(r'\"', '"')
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\$', r'$')
    .replaceAll(r'\\', r'\');

void main() {
  test('idiomas: todo texto do jogo tem tradução em inglês e espanhol', () {
    final textos = textosNoCodigo();
    expect(textos, isNotEmpty);
    final semIngles = [
      for (final t in textos)
        if (!en.containsKey(t)) t,
    ];
    final semEspanhol = [
      for (final t in textos)
        if (!es.containsKey(t)) t,
    ];
    expect(semIngles, isEmpty, reason: 'faltam em inglês');
    expect(semEspanhol, isEmpty, reason: 'faltam em espanhol');
  });

  test('idiomas: as traduções mantêm os mesmos {campos}', () {
    final campo = RegExp(r'\{\w+\}');
    Set<String> campos(String s) =>
        campo.allMatches(s).map((m) => m[0]!).toSet();
    for (final tabela in [en, es]) {
      for (final e in tabela.entries) {
        expect(campos(e.value), campos(e.key), reason: e.key);
      }
    }
  });

  test('idiomas: tr troca o texto e os campos', () {
    Lingua.atual.value = Idioma.pt;
    expect(tr('Olá, {nome}!', {'nome': 'Capi'}), 'Olá, Capi!');
    Lingua.atual.value = Idioma.pt;
  });
}
