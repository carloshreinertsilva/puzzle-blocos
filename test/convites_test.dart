import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/convites.dart';
import 'package:puzzle_blocos/core/wardrobe.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return ProgressStore.load();
}

void main() {
  test('codes: 6 easy characters, read back from links and the referrer', () {
    final rng = Random(7);
    for (var i = 0; i < 200; i++) {
      final c = Convites.gerarCodigo(rng);
      expect(c, matches(RegExp(r'^[A-HJKMNP-Z2-9]{6}$')));
      expect(Convites.normalizar(c.toLowerCase()), c);
      expect(Convites.lerLink(Convites.link(c)), c);
    }
    expect(Convites.normalizar(' abc 234 '), 'ABC234');
    expect(Convites.normalizar('ABC23'), isNull, reason: 'too short');
    expect(Convites.normalizar('ABC230'), isNull, reason: '0 is not used');
    expect(
      Convites.lerLink(
        Uri.parse('https://capiblocks.vercel.app/convite/?c=abc234'),
      ),
      'ABC234',
    );
    expect(
      Convites.lerLink(Uri.parse('https://capiblocks.vercel.app/duelo?s=1')),
      isNull,
    );
    expect(Convites.lerReferrer('utm_source=convite&convite=ABC234'), 'ABC234');
    expect(
      Convites.lerReferrer('utm_source=google-play&utm_medium=organic'),
      isNull,
    );
    expect(Convites.lerReferrer(null), isNull);
    expect(
      Convites.mensagem('ABC234'),
      contains('https://capiblocks.vercel.app/convite?c=ABC234'),
    );
  });

  test('a friend\'s code: the gift once, never one\'s own code', () async {
    final store = await _store();
    final meu = await Convites.meuCodigo(store, Random(1));
    expect(await Convites.meuCodigo(store), meu, reason: 'made once');
    final antes = store.stars;

    expect(await Convites.usar(store, meu), isFalse);
    expect(await Convites.usar(store, 'xx'), isFalse);
    expect(store.stars, antes);

    expect(await Convites.usar(store, 'abc234'), isTrue);
    expect(store.conviteUsado, 'ABC234');
    expect(store.stars, antes + Convites.presenteEstrelas);
    expect(store.unlockedHats, contains(Convites.itemPresente));

    expect(await Convites.usar(store, 'DEF567'), isFalse, reason: 'once');
    expect(store.stars, antes + Convites.presenteEstrelas);
  });

  test(
    'rewards for whoever invites: each step once, as friends arrive',
    () async {
      final store = await _store();
      final antes = store.stars;
      expect(Convites.proxima(store)!.amigos, 1);

      expect(await Convites.receberMetas(store, 0), isEmpty);
      final um = await Convites.receberMetas(store, 1);
      expect(um.map((m) => m.amigos), [1]);
      expect(store.stars, antes + 50);
      expect(await Convites.receberMetas(store, 1), isEmpty, reason: 'once');
      expect(Convites.embaixador(store), isFalse);

      // A late count jumps steps: all reached are given.
      final cinco = await Convites.receberMetas(store, 5);
      expect(cinco.map((m) => m.amigos), [3, 5]);
      expect(
        store.unlockedHats,
        containsAll(['faixa_embaixador', 'coroa_amizade']),
      );
      expect(Convites.embaixador(store), isTrue);
      expect(Convites.proxima(store), isNull);
      // A lower count later (server hiccup) takes nothing back.
      await Convites.receberMetas(store, 2);
      expect(store.conviteAmigos, 5);
    },
  );

  test('the friendship items exist and say how to get them', () {
    for (final m in Convites.metas) {
      if (m.item != null) expect(Wardrobe.byId(m.item!)!.fonte, isA<Amizade>());
    }
    final presente = Wardrobe.byId(Convites.itemPresente)!;
    expect((presente.fonte as Amizade).amigos, 0);
    expect(presente.comoGanhar, isNotEmpty);
  });
}
