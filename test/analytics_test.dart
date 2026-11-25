import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_blocos/game/game_controller.dart';
import 'package:puzzle_blocos/services/analytics.dart';
import 'package:puzzle_blocos/services/feedback.dart';
import 'package:puzzle_blocos/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Recorder implements AnalyticsBackend {
  final events = <(String, Map<String, Object>)>[];
  bool enabled = true;

  @override
  void log(String name, Map<String, Object> params) =>
      events.add((name, params));

  @override
  Future<void> setEnabled(bool on) async => enabled = on;
}

void main() {
  late _Recorder recorder;
  setUp(() => Analytics.use(recorder = _Recorder()));
  tearDown(() => Analytics.use(null));

  test('a level reports its start and its end', () async {
    SharedPreferences.setMockInitialValues({'level': 4});
    final store = await ProgressStore.load();
    final game = GameController(
      store: store,
      feedback: GameFeedback(store),
      mode: GameMode.levels,
    );
    final (name, params) = recorder.events.first;
    expect(name, 'level_start');
    expect(params, {'mode': 'levels', 'level': 4});
    game.debugWin();
    final end = recorder.events.firstWhere((e) => e.$1 == 'level_end').$2;
    expect(end['level'], 4);
    expect(end['success'], 1);
    expect(end['revived'], 0);
    // Firebase takes only text and numbers.
    for (final (_, params) in recorder.events) {
      for (final v in params.values) {
        expect(v is String || v is num, isTrue);
      }
    }
    game.dispose();
  });

  test('turning statistics off reaches the backend', () async {
    await Analytics.setEnabled(false);
    expect(recorder.enabled, isFalse);
  });

  test('without a backend, events go nowhere', () {
    Analytics.use(null);
    Analytics.event('level_start', {'level': 1});
  });

  test('events from before the start wait for Firebase', () async {
    Analytics.use(null);
    Analytics.reiniciarEspera();
    Analytics.event('tutorial_begin');
    final novo = _Recorder();
    await Analytics.start(enabled: true, criar: () async => novo);
    expect(novo.events.map((e) => e.$1), ['tutorial_begin']);
    Analytics.event('level_start', {'level': 1});
    expect(novo.events.length, 2);
  });

  test('with statistics off, the waiting events are dropped', () async {
    Analytics.use(null);
    Analytics.reiniciarEspera();
    Analytics.event('tutorial_begin');
    final novo = _Recorder();
    await Analytics.start(enabled: false, criar: () async => novo);
    expect(novo.events, isEmpty);
    expect(novo.enabled, isFalse);
  });

  test('the tutorial reports its start and a skip', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final game = GameController(
      store: store,
      feedback: GameFeedback(store),
      mode: GameMode.tutorial,
    );
    expect(recorder.events.map((e) => e.$1), contains('tutorial_begin'));
    game.skipTutorial();
    final pulou = recorder.events.firstWhere((e) => e.$1 == 'tutorial_pulado');
    expect(pulou.$2, {'passo': 0});
    game.dispose();
  });
}
