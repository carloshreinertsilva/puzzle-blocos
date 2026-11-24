import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/core/cartao_convite.dart';
import 'package:puzzle_blocos/core/convites.dart';
import 'package:puzzle_blocos/screens/cartao_convite_dialog.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store({int fase = 12}) async {
  SharedPreferences.setMockInitialValues({
    'level': fase,
    'levelsWon': fase - 1,
    'bestScore': 1000,
  });
  return ProgressStore.load();
}

void main() {
  final agora = DateTime(2026, 11, 24, 15);

  bool mostra(ProgressStore s, DateTime t, {bool bom = true}) =>
      CartaoConvite.deveMostrar(s, t, momentoBom: bom);

  test('só a partir da fase em que um amigo conta', () async {
    expect(
      mostra(await _store(fase: Convites.faseQueConta - 1), agora),
      isFalse,
    );
    expect(mostra(await _store(fase: Convites.faseQueConta), agora), isTrue);
  });

  test('só depois de uma vitória ou de um recorde, nunca de derrota', () async {
    final s = await _store();
    expect(mostra(s, agora, bom: false), isFalse);

    // A loss: nothing changed.
    final antes = MarcaPartida.of(s);
    await s.recordGame(levelWon: false);
    expect(CartaoConvite.momentoBom(antes, s), isFalse);

    // A level won.
    await s.recordGame(levelWon: true);
    expect(CartaoConvite.momentoBom(antes, s), isTrue);

    // A new record (Infinito).
    final antes2 = MarcaPartida.of(s);
    await s.setBestScore(s.bestScore + 10);
    expect(CartaoConvite.momentoBom(antes2, s), isTrue);
  });

  test('no máximo uma vez a cada 3 dias', () async {
    final s = await _store();
    await CartaoConvite.mostrado(s, agora);
    expect(mostra(s, agora.add(const Duration(days: 2, hours: 23))), isFalse);
    expect(mostra(s, agora.add(CartaoConvite.intervalo)), isTrue);
  });

  test('nunca mais depois de 3 recusas', () async {
    final s = await _store();
    for (var i = 0; i < CartaoConvite.maxRecusas - 1; i++) {
      await CartaoConvite.recusado(s);
    }
    expect(mostra(s, agora), isTrue);
    await CartaoConvite.recusado(s);
    expect(s.conviteCartaoRecusas, CartaoConvite.maxRecusas);
    expect(mostra(s, agora.add(const Duration(days: 365))), isFalse);
  });

  test('nunca para quem já tem todos os amigos dos prêmios', () async {
    final s = await _store();
    expect(CartaoConvite.amigosBastam, Convites.metas.last.amigos);
    await s.setConviteAmigos(CartaoConvite.amigosBastam - 1);
    expect(mostra(s, agora), isTrue);
    await s.setConviteAmigos(CartaoConvite.amigosBastam);
    expect(mostra(s, agora), isFalse);
  });

  test('não logo depois de um anúncio de tela cheia', () async {
    final s = await _store();
    await s.setLastFullscreenAt(agora.subtract(const Duration(minutes: 1)));
    expect(mostra(s, agora), isFalse);
    expect(mostra(s, agora.add(const Duration(minutes: 2))), isTrue);
  });

  test('as três artes se revezam, e o rodízio fica guardado', () async {
    final s = await _store();
    final vistas = <ArteConvite>[];
    var t = agora;
    for (var i = 0; i < 4; i++) {
      vistas.add(await CartaoConvite.mostrado(s, t));
      t = t.add(CartaoConvite.intervalo);
    }
    expect(vistas, [
      ArteConvite.premios,
      ArteConvite.presente,
      ArteConvite.vila,
      ArteConvite.premios,
    ]);
    // Saved: the same store read again goes on from there.
    final relida = ProgressStore(await SharedPreferences.getInstance());
    expect(CartaoConvite.proxima(relida), ArteConvite.presente);
  });

  for (final arte in ArteConvite.values) {
    testWidgets('o cartão "${arte.name}" cabe num celular pequeno, com os '
        'dois botões', (tester) async {
      final s = await _store();
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      bool? escolha;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    escolha = await mostrarCartaoConvite(context, s, arte),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Convidar'), findsOneWidget);
      expect(find.bySemanticsLabel('Agora não'), findsOneWidget);
      await tester.tap(find.text('Agora não'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(escolha, isFalse);
    });
  }
}
