import 'package:shared_preferences/shared_preferences.dart';

/// The 4 tools of Capi (Step 2).
enum CapiTool {
  hammer,
  rotate,
  reroll,
  shovel;

  String get label => switch (this) {
    CapiTool.hammer => 'Martelo',
    CapiTool.rotate => 'Girar',
    CapiTool.reroll => 'Trocar',
    CapiTool.shovel => 'Pá 3x3',
  };

  String get description => switch (this) {
    CapiTool.hammer => 'Quebra 1 bloco ou pedra',
    CapiTool.rotate => 'Gira uma peça da bandeja',
    CapiTool.reroll => 'Troca as 3 peças da bandeja',
    CapiTool.shovel => 'Limpa uma área 3x3',
  };

  int get starCost => switch (this) {
    CapiTool.hammer => 5,
    CapiTool.rotate => 4,
    CapiTool.reroll => 6,
    CapiTool.shovel => 8,
  };

  String get actionPrompt => switch (this) {
    CapiTool.hammer => 'Toque em um bloco para quebrar',
    CapiTool.rotate => 'Toque na peça para girar',
    CapiTool.reroll => '',
    CapiTool.shovel => 'Toque onde quer abrir espaço 3x3',
  };
}

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

  /// Capybara pups freed from the board; they go live in the village.
  int get pupsSaved => _prefs.getInt('pupsSaved') ?? 0;

  Future<void> recordMove({
    required int lines,
    required int combo,
    required int gems,
    required int rocks,
    int pups = 0,
  }) async {
    if (lines > 0) {
      await _prefs.setInt('linesCleared', linesCleared + lines);
    }
    if (combo > bestCombo) await _prefs.setInt('bestCombo', combo);
    if (gems > 0) await _prefs.setInt('gemsCollected', gemsCollected + gems);
    if (rocks > 0) await _prefs.setInt('rocksBroken', rocksBroken + rocks);
    if (pups > 0) await _prefs.setInt('pupsSaved', pupsSaved + pups);
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

  // Stars: per level which missions were done (a bitmask, see Missions),
  // and the wallet the village spends from.
  int levelStars(int level) => _prefs.getInt('stars_$level') ?? 0;
  Future<void> setLevelStars(int level, int bits) =>
      _prefs.setInt('stars_$level', bits);

  int get stars => _prefs.getInt('stars') ?? 0;
  int get starsEarned => _prefs.getInt('starsEarned') ?? 0;
  Future<void> addStars(int n) async {
    if (n <= 0) return;
    await _prefs.setInt('stars', stars + n);
    await _prefs.setInt('starsEarned', starsEarned + n);
  }

  /// Returns false (and spends nothing) when there are not enough stars.
  Future<bool> spendStars(int n) async {
    if (n > stars) return false;
    await _prefs.setInt('stars', stars - n);
    return true;
  }

  /// Village items built so far (they are built in a fixed order).
  int get villageBuilt => _prefs.getInt('villageBuilt') ?? 0;
  Future<void> setVillageBuilt(int n) => _prefs.setInt('villageBuilt', n);

  /// Obras mode: the next obra to build and the best stars of each one.
  int get obraLevel => _prefs.getInt('obraLevel') ?? 1;
  Future<void> setObraLevel(int v) => _prefs.setInt('obraLevel', v);
  int obraStars(int n) => _prefs.getInt('obraStars_$n') ?? 0;
  Future<void> setObraStars(int n, int stars) =>
      _prefs.setInt('obraStars_$n', stars);

  // --- Capi Tools (Step 2) ---

  int toolCount(CapiTool tool) => switch (tool) {
    CapiTool.hammer => _prefs.getInt('tool_hammer') ?? 2,
    CapiTool.rotate => _prefs.getInt('tool_rotate') ?? 2,
    CapiTool.reroll => _prefs.getInt('tool_reroll') ?? 2,
    CapiTool.shovel => _prefs.getInt('tool_shovel') ?? 1,
  };

  Future<void> addTool(CapiTool tool, [int count = 1]) async {
    final current = toolCount(tool);
    final key = switch (tool) {
      CapiTool.hammer => 'tool_hammer',
      CapiTool.rotate => 'tool_rotate',
      CapiTool.reroll => 'tool_reroll',
      CapiTool.shovel => 'tool_shovel',
    };
    await _prefs.setInt(key, current + count);
  }

  Future<bool> useTool(CapiTool tool) async {
    final current = toolCount(tool);
    if (current <= 0) return false;
    final key = switch (tool) {
      CapiTool.hammer => 'tool_hammer',
      CapiTool.rotate => 'tool_rotate',
      CapiTool.reroll => 'tool_reroll',
      CapiTool.shovel => 'tool_shovel',
    };
    await _prefs.setInt(key, current - 1);
    return true;
  }

  Future<bool> buyToolWithStars(CapiTool tool) async {
    final cost = tool.starCost;
    if (stars < cost) return false;
    final ok = await spendStars(cost);
    if (!ok) return false;
    await addTool(tool, 1);
    return true;
  }

  bool get adsRemoved => _prefs.getBool('adsRemoved') ?? false;

  DateTime? get lastFullscreenAt {
    final ms = _prefs.getInt('lastFullscreenAt');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastFullscreenAt(DateTime t) =>
      _prefs.setInt('lastFullscreenAt', t.millisecondsSinceEpoch);
}
