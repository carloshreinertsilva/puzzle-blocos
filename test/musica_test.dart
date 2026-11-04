import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/services/musica.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:puzzle_blocos/services/sound/music_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake implements MusicPlayer {
  final tocadas = <String>[];
  double volume = -1;
  bool parada = false;

  @override
  Future<void> play(String file, double v) async {
    tocadas.add(file);
    volume = v;
    parada = false;
  }

  @override
  Future<void> setVolume(double v) async => volume = v;
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async => parada = true;
}

void main() {
  late ProgressStore store;
  late _Fake player;
  late Musica musica;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    store = await ProgressStore.load();
    player = _Fake();
    musica = Musica(store, player: player);
  });
  tearDown(() => musica.dispose());

  testWidgets('menu, then the level track, then back to the menu', (t) async {
    musica.tocar(Trilha.menu);
    await t.pump(const Duration(seconds: 1));
    expect(player.tocadas, ['musica/menu.mp3']);
    expect(player.volume, closeTo(Trilha.menu.volume, 0.01));

    musica.entrarNoJogo(Trilha.fases);
    await t.pump(const Duration(seconds: 2));
    expect(player.tocadas.last, 'musica/fases.mp3');
    expect(player.volume, closeTo(Trilha.fases.volume, 0.01));

    // The next level opens before the old screen closes: no menu between.
    musica.entrarNoJogo(Trilha.fases);
    musica.sairDoJogo();
    await t.pump(const Duration(seconds: 2));
    expect(player.tocadas.last, 'musica/fases.mp3');

    musica.sairDoJogo();
    await t.pump(const Duration(seconds: 2));
    expect(player.tocadas.last, 'musica/menu.mp3');
  });

  testWidgets('a win lowers the music for a moment', (t) async {
    musica.tocar(Trilha.fases);
    await t.pump(const Duration(seconds: 1));
    musica.abaixar();
    await t.pump(const Duration(milliseconds: 500));
    expect(player.volume, closeTo(Trilha.fases.volume * 0.3, 0.01));
    await t.pump(const Duration(seconds: 4));
    expect(player.volume, closeTo(Trilha.fases.volume, 0.01));
  });

  testWidgets('turned off: stops, and comes back with the right track', (
    t,
  ) async {
    musica.tocar(Trilha.menu);
    await t.pump(const Duration(seconds: 1));
    await musica.ligar(false);
    expect(player.parada, isTrue);
    expect(store.musicOn, isFalse);

    musica.entrarNoJogo(Trilha.blitz);
    await t.pump(const Duration(seconds: 1));
    expect(player.tocadas, ['musica/menu.mp3'], reason: 'off: nothing plays');

    musica.ligar(true);
    await t.pump(const Duration(seconds: 1));
    expect(player.tocadas.last, 'musica/blitz.mp3');
  });
}
