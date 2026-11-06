import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/services/jogo_salvo.dart';
import 'package:puzzle_blocos/services/placares.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    Placares.ativo = false;
  });

  test('every leaderboard has its Game Center id', () {
    for (final id in [
      Placares.infinito,
      Placares.blitz,
      Placares.torre,
      Placares.estrelas,
    ]) {
      expect(Placares.iosIds[id], startsWith('capiblocks_'));
    }
  });

  test('on iPhone: Game Center, and no cloud save yet', () {
    Placares.ativo = true;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(Placares.nome, 'Game Center');
    expect(JogoSalvo.ativo, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(Placares.nome, 'Google Play Games');
    expect(JogoSalvo.ativo, isTrue);
  });
}
