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
}
