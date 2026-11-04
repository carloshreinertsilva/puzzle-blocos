import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/services/jogo_salvo.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a save carries the progress, not the phone settings', () async {
    SharedPreferences.setMockInitialValues({
      'level': 42,
      'stars': 120,
      'starsEarned': 310,
      'stars_3': 7,
      'villageItems': ['casa', 'pier'],
      'equipped_hat': 'pirate',
      'soundOn': false,
      'idioma': 'en',
    });
    final antigo = ProgressStore(await SharedPreferences.getInstance());
    final salvo = Progresso.ler(Progresso.doAparelho(antigo).json)!;
    expect(salvo.fase, 42);
    expect(salvo.estrelas, 310);
    expect(salvo.dados.containsKey('soundOn'), isFalse);
    expect(salvo.dados.containsKey('idioma'), isFalse);

    // A new phone: level 1, its own settings.
    SharedPreferences.setMockInitialValues({
      'level': 1,
      'stars_1': 1,
      'soundOn': true,
      'idioma': 'es',
    });
    final prefs = await SharedPreferences.getInstance();
    final novo = ProgressStore(prefs);
    expect(salvo.maisAvancadoQue(Progresso.doAparelho(novo)), isTrue);

    await JogoSalvo.carregar(novo, salvo);
    expect(novo.level, 42);
    expect(novo.stars, 120);
    expect(novo.starsEarned, 310);
    expect(novo.levelStars(3), 7);
    expect(novo.levelStars(1), 0, reason: 'the old progress is replaced');
    expect(prefs.getStringList('villageItems'), ['casa', 'pier']);
    expect(prefs.getString('equipped_hat'), 'pirate');
    expect(prefs.getBool('soundOn'), isTrue, reason: 'phone setting stays');
    expect(prefs.getString('idioma'), 'es');
  });

  test('further along: a higher level, then more stars', () {
    Progresso p(int fase, int estrelas) =>
        Progresso(fase: fase, estrelas: estrelas, salvoEm: 0, dados: {});
    expect(p(10, 0).maisAvancadoQue(p(9, 500)), isTrue);
    expect(p(10, 50).maisAvancadoQue(p(10, 40)), isTrue);
    expect(p(10, 40).maisAvancadoQue(p(10, 40)), isFalse);
    expect(Progresso.ler('lixo'), isNull);
    expect(Progresso.ler('{"v":2}'), isNull);
  });
}
