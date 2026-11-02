import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/services/duelo_link.dart';

void main() {
  test('a challenge link goes and comes back the same', () {
    const c = DueloConvite(semente: 7777, meta: 300, blitz: true);
    expect(
      c.link.toString(),
      'https://capiblocks.vercel.app/duelo?s=7777&p=300&m=blitz',
    );
    final lido = DueloConvite.ler(c.link)!;
    expect((lido.semente, lido.meta, lido.blitz), (7777, 300, true));
    expect(c.mensagem, contains('300 pontos'));
    expect(c.mensagem, endsWith(c.link.toString()));
  });

  test('old links still open the challenge', () {
    final c = DueloConvite.ler(
      Uri.parse('https://capiblocks.vercel.app/?duelo=4242&p=200'),
    )!;
    expect((c.semente, c.meta, c.blitz), (4242, 200, false));
  });

  test('Android hands the path and query on their own', () {
    final c = DueloConvite.ler(Uri.parse('/duelo?s=12&p=34'))!;
    expect((c.semente, c.meta), (12, 34));
  });

  test('anything else is not a challenge', () {
    expect(
      DueloConvite.ler(Uri.parse('https://capiblocks.vercel.app/')),
      isNull,
    );
    expect(DueloConvite.ler(Uri.parse('/privacidade/')), isNull);
    expect(DueloConvite.ler(Uri.parse('/duelo')), isNull);
  });
}
