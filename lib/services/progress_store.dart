import '../core/passe.dart' show PasseDoCapi;
import '../core/wardrobe.dart' show Slot;
import '../l10n/idioma.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/village.dart';

/// The 4 tools of Capi (Step 2).
enum CapiTool {
  hammer,
  rotate,
  reroll,
  shovel;

  String get label => switch (this) {
    CapiTool.hammer => tr('Martelo'),
    CapiTool.rotate => tr('Girar'),
    CapiTool.reroll => tr('Trocar'),
    CapiTool.shovel => tr('Pá 3x3'),
  };

  String get description => switch (this) {
    CapiTool.hammer => tr('Quebra 1 bloco ou pedra'),
    CapiTool.rotate => tr('Gira uma peça da bandeja'),
    CapiTool.reroll => tr('Troca as 3 peças da bandeja'),
    CapiTool.shovel => tr('Limpa uma área 3x3'),
  };

  int get starCost => switch (this) {
    CapiTool.hammer => 5,
    CapiTool.rotate => 4,
    CapiTool.reroll => 6,
    CapiTool.shovel => 8,
  };

  String get actionPrompt => switch (this) {
    CapiTool.hammer => tr('Toque em um bloco para quebrar'),
    CapiTool.rotate => tr('Toque na peça para girar'),
    CapiTool.reroll => '',
    CapiTool.shovel => tr('Toque onde quer abrir espaço 3x3'),
  };
}

/// Player progress and settings, saved on the device.
class ProgressStore {
  ProgressStore(this._prefs);

  static Future<ProgressStore> load() async =>
      ProgressStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  // --- Cloud save (see services/jogo_salvo.dart) ---

  /// Settings and notices of this phone, which a save from another phone
  /// does not carry or replace.
  static const _soDoAparelho = {
    'analyticsOn',
    'hapticsOn',
    'soundOn',
    'musicOn',
    'idioma',
    'remindersAsked',
    'remindersOn',
    'lastFullscreenAt',
    'pgsConvites',
    'pgsConviteDia',
    'updateOffered',
    'nuvemRecusada',
  };

  static bool _daNuvem(String key) => !_soDoAparelho.contains(key);

  /// The whole progress as plain values, for the cloud save.
  Map<String, Object> exportar() => {
    for (final key in _prefs.getKeys().where(_daNuvem))
      if (_prefs.get(key) case final Object v) key: v,
  };

  /// Replaces the progress with a cloud save (this phone's settings stay).
  Future<void> importar(Map<String, dynamic> dados) async {
    for (final key in _prefs.getKeys().where(_daNuvem).toList()) {
      await _prefs.remove(key);
    }
    for (final MapEntry(:key, :value) in dados.entries) {
      if (!_daNuvem(key)) continue;
      switch (value) {
        case bool v:
          await _prefs.setBool(key, v);
        case int v:
          await _prefs.setInt(key, v);
        case double v:
          await _prefs.setDouble(key, v);
        case String v:
          await _prefs.setString(key, v);
        case List v:
          await _prefs.setStringList(key, [for (final x in v) '$x']);
      }
    }
  }

  /// The cloud save the player chose not to load (its time), so the same
  /// one is not offered again.
  int get nuvemRecusada => _prefs.getInt('nuvemRecusada') ?? 0;
  Future<void> setNuvemRecusada(int salvoEm) =>
      _prefs.setInt('nuvemRecusada', salvoEm);

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

  /// Background music (Settings → Música), apart from the game sounds.
  bool get musicOn => _prefs.getBool('musicOn') ?? true;
  Future<void> setMusicOn(bool v) => _prefs.setBool('musicOn', v);
  Future<void> setSoundOn(bool v) => _prefs.setBool('soundOn', v);

  bool get hapticsOn => _prefs.getBool('hapticsOn') ?? true;
  Future<void> setHapticsOn(bool v) => _prefs.setBool('hapticsOn', v);
  bool get analyticsOn => _prefs.getBool('analyticsOn') ?? true;
  Future<void> setAnalyticsOn(bool v) => _prefs.setBool('analyticsOn', v);

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
    // Stars earned by playing are also the Passe do Capi's points.
    final t = PasseDoCapi.temporada(DateTime.now());
    await _prefs.setInt('passPoints_$t', passPoints(t) + n);
  }

  /// Rewarded videos used today for [what] ('dobrar', 'guardaRoupa').
  int videosToday(String what, DateTime day) =>
      _prefs.getInt('videos_${what}_${dayKey(day)}') ?? 0;

  Future<void> addVideoToday(String what, DateTime day) => _prefs.setInt(
    'videos_${what}_${dayKey(day)}',
    videosToday(what, day) + 1,
  );

  /// Videos watched toward an item (see Wardrobe.videosRaro).
  int itemVideos(String id) => _prefs.getInt('itemVideos_$id') ?? 0;

  Future<void> addItemVideo(String id) =>
      _prefs.setInt('itemVideos_$id', itemVideos(id) + 1);

  // --- Notifications (see services/avisos.dart) ---

  /// Daily reminders: off until the player says yes.
  /// The language picked in the settings: 'auto' (the phone's), 'pt',
  /// 'en' or 'es'.
  String get idioma => _prefs.getString('idioma') ?? 'auto';
  Future<void> setIdioma(String code) => _prefs.setString('idioma', code);

  bool get remindersOn => _prefs.getBool('remindersOn') ?? false;
  Future<void> setRemindersOn(bool on) => _prefs.setBool('remindersOn', on);

  /// Whether the player was already asked about reminders.
  bool get remindersAsked => _prefs.getBool('remindersAsked') ?? false;
  Future<void> setRemindersAsked() => _prefs.setBool('remindersAsked', true);

  /// How many times the menu invited the player to sign in to Play Games,
  /// and the day of the last time (at most twice, on different days).
  int get playGamesConvites => _prefs.getInt('pgsConvites') ?? 0;
  int get playGamesConviteDia => _prefs.getInt('pgsConviteDia') ?? 0;
  Future<void> marcarConvitePlayGames(int dia) async {
    await _prefs.setInt('pgsConvites', playGamesConvites + 1);
    await _prefs.setInt('pgsConviteDia', dia);
  }

  // --- Daily gift (see core/presente_diario.dart) ---

  int get giftLastDay => _prefs.getInt('giftLastDay') ?? 0;
  int get giftIndex => _prefs.getInt('giftIndex') ?? 0;

  /// The day the gift last opened by itself (once a day, not more).
  int get giftShownDay => _prefs.getInt('giftShown') ?? 0;
  Future<void> setGiftShown(int day) => _prefs.setInt('giftShown', day);

  Future<void> setGift(int day, int index) async {
    await _prefs.setInt('giftLastDay', day);
    await _prefs.setInt('giftIndex', index);
  }

  // --- Passe do Capi (see core/passe.dart) ---

  int passPoints(int temporada) => _prefs.getInt('passPoints_$temporada') ?? 0;

  bool passPremium(int temporada) =>
      _prefs.getBool('passPremium_$temporada') ?? false;

  Future<void> setPassPremium(int temporada) =>
      _prefs.setBool('passPremium_$temporada', true);

  bool passClaimed(int temporada, int nivel, {required bool premium}) =>
      _prefs.getBool(
        'passClaim_${temporada}_${nivel}_${premium ? 'p' : 'g'}',
      ) ??
      false;

  Future<void> markPassClaimed(
    int temporada,
    int nivel, {
    required bool premium,
  }) => _prefs.setBool(
    'passClaim_${temporada}_${nivel}_${premium ? 'p' : 'g'}',
    true,
  );

  /// Returns false (and spends nothing) when there are not enough stars.
  Future<bool> spendStars(int n) async {
    if (n > stars) return false;
    await _prefs.setInt('stars', stars - n);
    return true;
  }

  /// Ids of the village items built so far, in the order they were built.
  /// The player picks what to build; saves from before that only kept a
  /// count of items built in a fixed order, so those become the first ones.
  List<String> get villageItems =>
      _prefs.getStringList('villageItems') ??
      [
        for (final item in Village.items.take(
          _prefs.getInt('villageBuilt') ?? 0,
        ))
          item.id,
      ];

  /// How many village items are built.
  int get villageBuilt => villageItems.length;

  Future<void> addVillageItem(String id) async {
    final items = villageItems;
    if (items.contains(id)) return;
    await _prefs.setStringList('villageItems', [...items, id]);
  }

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
  Future<void> setAdsRemoved(bool v) => _prefs.setBool('adsRemoved', v);

  // --- Shop ---

  /// Stars bought in the shop: they go to the wallet but not to the
  /// "stars earned" statistic.
  Future<void> addBoughtStars(int n) async {
    if (n <= 0) return;
    await _prefs.setInt('stars', stars + n);
  }

  /// One-time purchases already delivered (product ids).
  List<String> get ownedProducts => _prefs.getStringList('ownedProducts') ?? [];
  bool owns(String productId) => ownedProducts.contains(productId);
  Future<void> addOwnedProduct(String productId) async {
    if (owns(productId)) return;
    await _prefs.setStringList('ownedProducts', [...ownedProducts, productId]);
  }

  /// Store purchase ids already delivered, so a consumable delivered again
  /// by the store (app restart, slow connection) pays only once.
  bool purchaseDelivered(String purchaseId) =>
      (_prefs.getStringList('deliveredPurchases') ?? []).contains(purchaseId);
  Future<void> markPurchaseDelivered(String purchaseId) async {
    final list = _prefs.getStringList('deliveredPurchases') ?? [];
    if (list.contains(purchaseId)) return;
    // Old ids are never delivered again; keep the list short.
    final kept = list.length >= 200 ? list.sublist(list.length - 199) : list;
    await _prefs.setStringList('deliveredPurchases', [...kept, purchaseId]);
  }

  /// When the game was first opened with the shop (the starter pack is
  /// offered for a few days from then).
  DateTime? get firstOpenAt {
    final ms = _prefs.getInt('firstOpenAt');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> noteFirstOpen(DateTime now) async {
    if (firstOpenAt != null) return;
    await _prefs.setInt('firstOpenAt', now.millisecondsSinceEpoch);
  }

  // --- Blitz & Duelo (Step 3) ---

  int get blitzBestScore => _prefs.getInt('blitzBestScore') ?? 0;

  Future<bool> recordBlitzScore(int score) async {
    if (score > blitzBestScore) {
      await _prefs.setInt('blitzBestScore', score);
      return true;
    }
    return false;
  }

  int get duelsWon => _prefs.getInt('duelsWon') ?? 0;

  /// Challenges (by seed) already beaten: each pays its stars only once.
  bool duelSeedWon(int seed) => _prefs.getBool('duelSeed_$seed') ?? false;
  Future<void> markDuelSeedWon(int seed) =>
      _prefs.setBool('duelSeed_$seed', true);

  /// Adds up to [amount] stars from [source] (blitz, tower...), at most
  /// [cap] per day from that source, so a quick minigame can't be farmed
  /// for endless stars. Returns the stars actually added.
  Future<int> addStarsCapped(
    String source,
    int amount,
    int cap,
    DateTime day,
  ) async {
    final key = 'starsFrom_${source}_${dayKey(day)}';
    final given = _prefs.getInt(key) ?? 0;
    final grant = amount.clamp(0, cap - given).toInt();
    if (grant <= 0) return 0;
    await _prefs.setInt(key, given + grant);
    await addStars(grant);
    return grant;
  }

  Future<void> recordDuelWin() async {
    await _prefs.setInt('duelsWon', duelsWon + 1);
  }

  // --- Torre do Capi (Step 4) ---

  int get towerBestHeight => _prefs.getInt('towerBestHeight') ?? 0;

  Future<bool> recordTowerHeight(int height) async {
    if (height > towerBestHeight) {
      await _prefs.setInt('towerBestHeight', height);
      return true;
    }
    return false;
  }

  int get towerGamesPlayed => _prefs.getInt('towerGamesPlayed') ?? 0;

  Future<void> recordTowerGame() async {
    await _prefs.setInt('towerGamesPlayed', towerGamesPlayed + 1);
  }

  DateTime? get lastFullscreenAt {
    final ms = _prefs.getInt('lastFullscreenAt');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastFullscreenAt(DateTime t) =>
      _prefs.setInt('lastFullscreenAt', t.millisecondsSinceEpoch);
  // --- Hats & Wardrobe (Step 5) ---

  String get equippedHat => _prefs.getString('equippedHat') ?? 'helmet';

  Future<void> equipHat(String hatId) async {
    await _prefs.setString('equippedHat', hatId);
  }

  List<String> get unlockedHats {
    final list = _prefs.getStringList('unlockedHats');
    if (list == null || list.isEmpty) {
      return ['helmet'];
    }
    if (!list.contains('helmet')) {
      return ['helmet', ...list];
    }
    return list;
  }

  Future<void> unlockHat(String hatId) async {
    final cur = unlockedHats;
    if (!cur.contains(hatId)) {
      await _prefs.setStringList('unlockedHats', [...cur, hatId]);
    }
  }

  /// The item worn in a slot other than the head (see wardrobe.dart), or
  /// null. Owned items share the `unlockedHats` list, whatever the slot.
  String? equippedIn(Slot slot) => _prefs.getString('equipped_${slot.name}');

  Future<void> equipIn(Slot slot, String? id) => id == null
      ? _prefs.remove('equipped_${slot.name}')
      : _prefs.setString('equipped_${slot.name}', id);

  // --- Daily Missions & Chest (Step 5) ---

  int dailyMissionProgress(DateTime day, int index) {
    return _prefs.getInt('mission_prog_${dayKey(day)}_$index') ?? 0;
  }

  Future<void> setDailyMissionProgress(
    DateTime day,
    int index,
    int value,
  ) async {
    await _prefs.setInt('mission_prog_${dayKey(day)}_$index', value);
  }

  bool isDailyMissionClaimed(DateTime day, int index) {
    return _prefs.getBool('mission_claimed_${dayKey(day)}_$index') ?? false;
  }

  Future<void> setDailyMissionClaimed(
    DateTime day,
    int index,
    bool claimed,
  ) async {
    await _prefs.setBool('mission_claimed_${dayKey(day)}_$index', claimed);
  }

  /// The level the day's missions were picked for (so unlocking a mode
  /// mid-day doesn't reshuffle them).
  int missionsLevel(DateTime day) =>
      _prefs.getInt('missionsLevel_${dayKey(day)}') ?? level;
  Future<void> fixMissionsLevel(DateTime day) async {
    final key = 'missionsLevel_${dayKey(day)}';
    if (!_prefs.containsKey(key)) await _prefs.setInt(key, level);
  }

  /// Days in a row the missions chest was opened (separate from the daily
  /// challenge's streak).
  int missionsStreak(DateTime today) {
    final last = _prefs.getInt('missionsDone');
    if (last == null) return 0;
    final yesterday = dayKey(today.subtract(const Duration(days: 1)));
    if (last != dayKey(today) && last != yesterday) return 0;
    return _prefs.getInt('missionsStreak') ?? 0;
  }

  Future<void> completeMissionsDay(DateTime day) async {
    if (_prefs.getInt('missionsDone') == dayKey(day)) return;
    final streak = missionsStreak(day) + 1;
    await _prefs.setInt('missionsDone', dayKey(day));
    await _prefs.setInt('missionsStreak', streak);
  }

  bool isDailyChestClaimed(DateTime day) {
    return _prefs.getBool('chest_claimed_${dayKey(day)}') ?? false;
  }

  Future<void> setDailyChestClaimed(DateTime day, bool claimed) async {
    await _prefs.setBool('chest_claimed_${dayKey(day)}', claimed);
  }

  /// The bonus chest (a video for a few stars), once a day.
  bool isBonusChestClaimed(DateTime day) =>
      _prefs.getBool('bonus_chest_${dayKey(day)}') ?? false;
  Future<void> setBonusChestClaimed(DateTime day) =>
      _prefs.setBool('bonus_chest_${dayKey(day)}', true);

  // --- Inviting friends (see core/convites.dart) ---

  /// This player's invite code, made once on this phone.
  String? get conviteCodigo => _prefs.getString('conviteCodigo');
  Future<void> setConviteCodigo(String c) =>
      _prefs.setString('conviteCodigo', c);

  /// Whether the code is saved on the server (so friends can use it).
  bool get conviteCodigoNoServidor =>
      _prefs.getBool('conviteCodigoServidor') ?? false;
  Future<void> setConviteCodigoNoServidor() =>
      _prefs.setBool('conviteCodigoServidor', true);

  /// The friend's code this player came in with (once per phone).
  String? get conviteUsado => _prefs.getString('conviteUsado');
  Future<void> setConviteUsado(String c) => _prefs.setString('conviteUsado', c);

  /// What the server already knows about this player's invite: 0 nothing,
  /// 1 that they came in with it, 2 that they reached the level that makes
  /// it count.
  int get conviteEnviado => _prefs.getInt('conviteEnviado') ?? 0;
  Future<void> setConviteEnviado(int n) => _prefs.setInt('conviteEnviado', n);

  /// Friends who came in with this player's code and played enough (last
  /// count from the server).
  int get conviteAmigos => _prefs.getInt('conviteAmigos') ?? 0;
  Future<void> setConviteAmigos(int n) => _prefs.setInt('conviteAmigos', n);

  /// Reward steps (friends needed) already given.
  List<int> get conviteMetasDadas => [
    for (final s in _prefs.getStringList('conviteMetas') ?? <String>[])
      ?int.tryParse(s),
  ];
  Future<void> addConviteMeta(int n) async {
    final atual = conviteMetasDadas;
    if (atual.contains(n)) return;
    await _prefs.setStringList('conviteMetas', [
      for (final m in [...atual, n]) '$m',
    ]);
  }

  /// Whether the Play Store's install referrer was read already.
  bool get conviteReferrerLido => _prefs.getBool('conviteReferrer') ?? false;
  Future<void> setConviteReferrerLido() =>
      _prefs.setBool('conviteReferrer', true);

  /// Store rating: how many times it was asked for, and when last.
  int get avaliacaoPedidos => _prefs.getInt('avaliacaoPedidos') ?? 0;
  DateTime? get avaliacaoPedidaEm {
    final ms = _prefs.getInt('avaliacaoPedidaEm');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setAvaliacaoPedida(DateTime t) async {
    await _prefs.setInt('avaliacaoPedidaEm', t.millisecondsSinceEpoch);
    await _prefs.setInt('avaliacaoPedidos', avaliacaoPedidos + 1);
  }
}
