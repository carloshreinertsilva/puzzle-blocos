import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/services/avaliacao.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store({int vencidas = 20, int segundos = 0}) async {
  SharedPreferences.setMockInitialValues({
    'levelsWon': vencidas,
    'tempoDeJogoSeg': segundos,
  });
  return ProgressStore.load();
}

void main() {
  final agora = DateTime(2026, 11, 10, 15);

  test('not before the player has won enough levels', () async {
    final novato = await _store(vencidas: 5);
    expect(Avaliacao.devePedir(novato, 6, agora), isFalse);
    final s = await _store();
    expect(Avaliacao.devePedir(s, Avaliacao.faseMinima - 1, agora), isFalse);
    expect(Avaliacao.devePedir(s, Avaliacao.faseMinima, agora), isTrue);
  });

  test('at most every 60 days, and 3 times ever', () async {
    final s = await _store();
    await s.setAvaliacaoPedida(agora);
    expect(
      Avaliacao.devePedir(s, 20, agora.add(const Duration(days: 59))),
      isFalse,
    );
    var t = agora.add(const Duration(days: 60));
    expect(Avaliacao.devePedir(s, 20, t), isTrue);
    await s.setAvaliacaoPedida(t);
    t = t.add(const Duration(days: 60));
    await s.setAvaliacaoPedida(t);
    expect(s.avaliacaoPedidos, 3);
    expect(
      Avaliacao.devePedir(s, 20, t.add(const Duration(days: 365))),
      isFalse,
    );
  });

  test('not right after a full-screen ad', () async {
    final s = await _store();
    await s.setLastFullscreenAt(agora.subtract(const Duration(minutes: 1)));
    expect(Avaliacao.devePedir(s, 20, agora), isFalse);
    expect(
      Avaliacao.devePedir(s, 20, agora.add(const Duration(minutes: 3))),
      isTrue,
    );
  });

  test('on the menu: five minutes played and three levels won', () async {
    final pouco = await _store(vencidas: 3, segundos: 299);
    expect(Avaliacao.devePedirNoMenu(pouco, agora), isFalse);
    final poucas = await _store(vencidas: 2, segundos: 900);
    expect(Avaliacao.devePedirNoMenu(poucas, agora), isFalse);
    final s = await _store(vencidas: 3, segundos: 300);
    expect(Avaliacao.devePedirNoMenu(s, agora), isTrue);
    // Asked once: not again for a long while, by either way.
    await s.setAvaliacaoPedida(agora);
    final amanha = agora.add(const Duration(days: 1));
    expect(Avaliacao.devePedirNoMenu(s, amanha), isFalse);
  });

  test('time in the matches adds up, half an hour at most per stay', () async {
    final s = await _store();
    await s.addTempoDeJogo(const Duration(minutes: 2));
    await s.addTempoDeJogo(const Duration(hours: 5));
    expect(s.tempoDeJogo, const Duration(minutes: 32));
  });
}
