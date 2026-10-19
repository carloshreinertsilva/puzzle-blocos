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

  // Statistics shown on the stats screen.
  int get gamesPlayed => _prefs.getInt('gamesPlayed') ?? 0;
  int get levelsWon => _prefs.getInt('levelsWon') ?? 0;
  int get linesCleared => _prefs.getInt('linesCleared') ?? 0;
  int get bestCombo => _prefs.getInt('bestCombo') ?? 0;
  int get gemsCollected => _prefs.getInt('gemsCollected') ?? 0;
  int get rocksBroken => _prefs.getInt('rocksBroken') ?? 0;

  Future<void> recordMove({
    required int lines,
    required int combo,
    required int gems,
    required int rocks,
  }) async {
    if (lines > 0) {
      await _prefs.setInt('linesCleared', linesCleared + lines);
    }
    if (combo > bestCombo) await _prefs.setInt('bestCombo', combo);
    if (gems > 0) await _prefs.setInt('gemsCollected', gemsCollected + gems);
    if (rocks > 0) await _prefs.setInt('rocksBroken', rocksBroken + rocks);
  }

  Future<void> recordGame({required bool levelWon}) async {
    await _prefs.setInt('gamesPlayed', gamesPlayed + 1);
    if (levelWon) await _prefs.setInt('levelsWon', levelsWon + 1);
  }

  // Daily challenge: the last day completed and the run of days in a row.
  static int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  bool dailyDone(DateTime day) => _prefs.getInt('dailyDone') == dayKey(day);

  int dailyStreak(DateTime today) {
    final last = _prefs.getInt('dailyDone');
    if (last == null) return 0;
    final yesterday = dayKey(today.subtract(const Duration(days: 1)));
    if (last != dayKey(today) && last != yesterday) return 0;
    return _prefs.getInt('dailyStreak') ?? 0;
  }

  Future<void> completeDaily(DateTime day) async {
    if (dailyDone(day)) return;
    final streak = dailyStreak(day) + 1;
    await _prefs.setInt('dailyDone', dayKey(day));
    await _prefs.setInt('dailyStreak', streak);
  }

  /// Mechanics already explained to the player (rocks, gems, ...).
  bool hasSeen(String topic) => _prefs.getBool('seen_$topic') ?? false;
  Future<void> markSeen(String topic) => _prefs.setBool('seen_$topic', true);

  bool get adsRemoved => _prefs.getBool('adsRemoved') ?? false;

  DateTime? get lastFullscreenAt {
    final ms = _prefs.getInt('lastFullscreenAt');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastFullscreenAt(DateTime t) =>
      _prefs.setInt('lastFullscreenAt', t.millisecondsSinceEpoch);
}
