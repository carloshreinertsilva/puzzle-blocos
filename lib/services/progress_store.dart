import 'package:shared_preferences/shared_preferences.dart';

/// Player progress and settings, saved on the device.
class ProgressStore {
  ProgressStore(this._prefs);

  static Future<ProgressStore> load() async =>
      ProgressStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  int get level => _prefs.getInt('level') ?? 1;
  Future<void> setLevel(int v) => _prefs.setInt('level', v);

  int get bestScore => _prefs.getInt('bestScore') ?? 0;
  Future<void> setBestScore(int v) => _prefs.setInt('bestScore', v);

  /// Losses in a row on the current level; makes the next attempt gentler.
  int failStreakFor(int level) =>
      _prefs.getInt('failLevel') == level ? _prefs.getInt('failCount') ?? 0 : 0;
  Future<void> setFailStreak(int level, int count) async {
    await _prefs.setInt('failLevel', level);
    await _prefs.setInt('failCount', count);
  }

  bool get soundOn => _prefs.getBool('soundOn') ?? true;
  Future<void> setSoundOn(bool v) => _prefs.setBool('soundOn', v);

  bool get hapticsOn => _prefs.getBool('hapticsOn') ?? true;
  Future<void> setHapticsOn(bool v) => _prefs.setBool('hapticsOn', v);

  bool get adsRemoved => _prefs.getBool('adsRemoved') ?? false;

  DateTime? get lastFullscreenAt {
    final ms = _prefs.getInt('lastFullscreenAt');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastFullscreenAt(DateTime t) =>
      _prefs.setInt('lastFullscreenAt', t.millisecondsSinceEpoch);
}
