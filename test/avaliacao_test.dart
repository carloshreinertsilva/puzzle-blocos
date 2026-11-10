import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/services/avaliacao.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> _store({int vencidas = 20}) async {
  SharedPreferences.setMockInitialValues({'levelsWon': vencidas});
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
}
