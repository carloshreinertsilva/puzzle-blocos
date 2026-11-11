import '../core/daily_missions.dart';

import 'dart:convert';

import '../core/board.dart';
import '../core/shapes.dart';
import '../services/progress_store.dart';
import '../game/game_controller.dart';
import '../core/passe.dart';
import '../core/ranking.dart';
import '../services/ranking_servidor.dart';
import '../game/obra_controller.dart';
import '../tower/tower_controller.dart';
import '../game/puzzle_game.dart';
import 'bridge_stub.dart' if (dart.library.js_interop) 'bridge_web.dart';

/// Build with --dart-define=TEST_BRIDGE=true to expose the game to browser
/// tests (Playwright) as `window.__bb`. Off in normal builds.
const kTestBridge = bool.fromEnvironment('TEST_BRIDGE');

/// What the browser tests can see and do. Buttons are found through the
/// accessibility tree; this covers what the canvas hides: the board, the
/// tray, where things are on screen, and which praise words appeared.
class TestBridge {
  TestBridge._();
  static final instance = TestBridge._();

  String screen = 'home';
  GameController? controller;
  PuzzleGame? game;

  /// The construction puzzle on screen, and how to drag its pieces.
  ObraController? obra;
  TowerController? tower;

  /// The ranking of the browser tests: in memory, with a few rivals on
  /// every board (this week's and the all-time one).
  late final RankingDeTeste ranking = _rankingComRivais();

  static RankingDeTeste _rankingComRivais() {
    final r = RankingDeTeste();
    const rivais = [
      ('r1', 'Bia Blocos', 'crown', true, 1.0),
      ('r2', 'Zeca', 'pirate', false, 0.6),
      ('r3', 'Lia_22', 'helmet', false, 0.3),
    ];
    const melhores = {
      Quadro.torre: 40,
      Quadro.infinito: 9000,
      Quadro.blitz: 6000,
      Quadro.fases: 80,
    };
    final agora = DateTime.now();
    for (final q in Quadro.values) {
      for (final p in Periodo.values) {
        for (final (uid, nome, chapeu, emb, k) in rivais) {
          r.enviar(
            Ranking.id(q, p, agora),
            EntradaRanking(
              uid: uid,
              nome: nome,
              pontos: (melhores[q]! * k * (p == Periodo.semana ? 0.5 : 1))
                  .round(),
              chapeu: chapeu,
              embaixador: emb,
            ),
          );
        }
      }
    }
    return r;
  }

  /// What the player has on the test ranking: board id → score.
  Map<String, Object?> _meuRanking() => {
    'nome': store?.rankingNome,
    'denuncias': ranking.denuncias.length,
    'linhas': {
      for (final e in ranking.quadros.entries)
        if (e.value[ranking.uid] != null) e.key: e.value[ranking.uid]!.pontos,
    },
  };
  Map<String, Object?>? Function(int piece)? obraDrag;
  final praises = <String>[];

  void install() => installJsBridge(this);

  String stateJson() => jsonEncode(state());

  /// Opens a route by name, as an Android App Link does (set by the app).
  void Function(String rota)? abrirRota;

  /// The star wallet, set by the app (so the home screen reports it too).
  int Function()? wallet;
  ProgressStore? store;

  Map<String, Object?> state() {
    final sStore = store ?? controller?.store;
    final today = DateTime.now();
    final dMissions = sStore != null
        ? DailyMissionsManager.missionsFor(sStore, today)
        : null;
    final hats = sStore?.unlockedHats;
    final equipped = sStore?.equippedHat;
    final chestAvail = sStore != null
        ? DailyMissionsManager.isChestAvailable(sStore, today)
        : false;
    final chestDone = sStore != null
        ? DailyMissionsManager.isChestClaimed(sStore, today)
        : false;
    final t = tower;
    if (t != null) {
      return {
        'screen': screen,
        'stars': wallet?.call(),
        'tower': {
          'height': t.height,
          'placedFloors': t.blocks.length - 1,
          'bestHeight': t.bestHeight,
          'combo': t.combo,
          'gameOver': t.gameOver,
          'playing': t.playing,
          'starsGained': t.starsGained,
          'floors': t.floors,
          'zone': t.zone.name,
          'canContinue': t.canContinue,
          // How far the moving block is from a perfect fit, and the room
          // there is (the size of the block below, along the same axis).
          'offset': t.isAxisX
              ? t.currentX - t.blocks.last.x
              : t.currentY - t.blocks.last.y,
          'room': t.isAxisX ? t.blocks.last.dx : t.blocks.last.dy,
        },
      };
    }
    final o = obra;
    if (o != null) {
      return {
        'screen': screen,
        'stars': wallet?.call(),
        'obra': {
          'id': o.blueprint.id,
          'pieces': o.blueprint.pieces.length,
          'placed': o.placed.where((p) => p != null).length,
          'at': [
            for (final p in o.placed)
              if (p case (final r, final c)) [r, c] else null,
          ],
          'solution': [
            for (final (r, c) in o.blueprint.solution) [r, c],
          ],
          'solved': o.solved,
          'stars': o.stars,
          'undos': o.undos,
          'hints': o.hints,
          'hint': o.hint?.$1,
        },
      };
    }
    final c = controller;
    final g = game;
    if (c == null) {
      return {
        'screen': screen,
        'stars': wallet?.call(),
        'equippedHat': equipped,
        'ranking': _meuRanking(),
        'unlockedHats': hats,
        'dailyChestAvailable': chestAvail,
        'dailyChestClaimed': chestDone,
        if (sStore != null) 'villageItems': sStore.villageItems,
        if (sStore != null)
          'passe': {
            'nivel': PasseDoCapi.nivel(sStore, DateTime.now()),
            'premium': PasseDoCapi.premium(sStore, DateTime.now()),
          },
        if (dMissions != null && sStore != null)
          'missions': [
            for (final m in dMissions)
              {
                'index': m.index,
                'type': m.type.name,
                'target': m.target,
                'progress': sStore.dailyMissionProgress(today, m.index),
                'claimed': sStore.isDailyMissionClaimed(today, m.index),
                'completed': DailyMissionsManager.isCompleted(sStore, m, today),
              },
          ],
      };
    }
    final s = c.session;
    final level = s.level;
    return {
      'screen': screen,
      'mode': c.mode.name,
      'level': level.number,
      'kind': level.kind.name,
      'isHard': level.isHard,
      'pattern': level.pattern,
      'status': s.status.name,
      'showOutcome': c.showOutcome,
      'paused': c.paused,
      'intros': [for (final i in c.intros) i.name],
      'score': s.score,
      'combo': s.combo,
      'revived': s.revived,
      'goals': {
        'targetScore': level.targetScore,
        'gemsTarget': level.gemsTarget,
        'gems': s.gems,
        'rocksLeft': s.rocksLeft,
        'pupsLeft': s.pupsLeft,
        'pupsSaved': s.pupsSaved,
      },
      'board': [
        for (var r = 0; r < Board.size; r++)
          [for (var col = 0; col < Board.size; col++) _cell(s.board.at(r, col))]
              .join(),
      ],
      'tray': [
        for (final p in s.tray)
          p == null
              ? null
              : {
                  'id': p.shape.id,
                  'rows': p.shape.rows,
                  'cols': p.shape.cols,
                  'cells': [
                    for (final (r, col) in p.shape.cells) [r, col],
                  ],
                },
      ],
      'tools': {
        'hammer': c.store.toolCount(CapiTool.hammer),
        'rotate': c.store.toolCount(CapiTool.rotate),
        'reroll': c.store.toolCount(CapiTool.reroll),
        'shovel': c.store.toolCount(CapiTool.shovel),
      },
      if (c.activeToolMode != null) 'activeTool': c.activeToolMode!.name,
      if (c.isBlitz) 'blitzSecondsLeft': c.blitzSecondsLeft,
      if (c.isDuel) ...{
        'duelSeed': c.duelSeed,
        'duelTargetScore': c.duelTargetScore,
        'duelRivalName': c.duelRivalName,
        'duelWon': c.duelWon,
      },
      'praises': praises,
      'stars': wallet?.call(),
      'starBits': c.starBits,
      'liveStarBits': c.liveStarBits,
      'starsGained': c.starsGained,
      'replay': c.isReplay,
      if (c.tutorial) 'tutorialStep': c.tutorialStep,
      if (c.tutorial) 'capi': c.capiLine,
      if (c.hint case final h?) 'hint': [h.$1, h.$2, h.$3],
      'hintOffer': c.hintOffer,
      'hintNudge': c.hintNudge,
      if (g != null && g.cellSize > 1) 'geometry': g.testGeometry(),
    };
  }

  static String _cell(Cell c) => switch (c.type) {
    CellType.empty => '.',
    CellType.rock => c.hp > 1 ? 'R' : 'r',
    CellType.block => c.pup ? 'p' : (c.gem ? 'g' : 'b'),
  };

  /// Pointer path (in page pixels) that drags tray [slot] onto (row, col).
  Map<String, Object?>? dragPath(int slot, int row, int col) {
    final g = game;
    final p = controller?.session.tray[slot];
    if (g == null || p == null) return null;
    return g.dragPath(slot, p.shape, row, col);
  }

  /// Wins the current attempt (to reach later screens quickly).
  Future<bool> useTool(String toolName, [int? r, int? c, int? slot]) async {
    final ctrl = controller;
    if (ctrl == null) return false;
    final tool = CapiTool.values.firstWhere((t) => t.name == toolName);
    await ctrl.selectTool(tool);
    if (tool == CapiTool.reroll) return true;
    if (tool == CapiTool.rotate && slot != null) {
      return await ctrl.executeRotate(slot);
    }
    if (tool == CapiTool.hammer && r != null && c != null) {
      return await ctrl.executeHammer(r, c);
    }
    if (tool == CapiTool.shovel && r != null && c != null) {
      return await ctrl.executeShovel(r, c);
    }
    return true;
  }

  Future<void> addTool(String toolName, int count) async {
    final ctrl = controller;
    if (ctrl == null) return;
    final tool = CapiTool.values.firstWhere((t) => t.name == toolName);
    await ctrl.store.addTool(tool, count);
  }

  bool placeTower([bool perfect = true]) {
    final t = tower;
    if (t == null) return false;
    t.debugPlace(perfect: perfect);
    return true;
  }

  bool missTower() {
    final t = tower;
    if (t == null) return false;
    t.debugPlace(perfect: false, offset: 9.0);
    return true;
  }

  Future<void> equipHat(String hatId) async {
    final s = store ?? controller?.store;
    if (s != null) await s.equipHat(hatId);
  }

  /// Stars as if earned by playing (they also count for the Passe do Capi).
  Future<void> earnStars(int n) async {
    final s = store ?? controller?.store;
    if (s != null) await s.addStars(n);
  }

  Future<void> unlockHat(String hatId) async {
    final s = store ?? controller?.store;
    if (s != null) await s.unlockHat(hatId);
  }

  Future<void> progressDailyMission(int index, int amount) async {
    final s = store ?? controller?.store;
    if (s == null) return;
    final today = DateTime.now();
    final cur = s.dailyMissionProgress(today, index);
    await s.setDailyMissionProgress(today, index, cur + amount);
  }

  Future<String?> claimDailyChest() async {
    final s = store ?? controller?.store;
    if (s == null) return null;
    final h = await DailyMissionsManager.claimChest(s, DateTime.now());
    return h?.id;
  }

  bool win() {
    if (obra case final o?) {
      o.debugSolve();
      return true;
    }
    final c = controller;
    if (c == null) return false;
    c.debugWin();
    return true;
  }

  /// Sets up a scenario: [board] as 8 strings ('.', 'b', 'g', 'p', 'r',
  /// 'R') and the tray as shape ids (null for an empty slot).
  bool load(String json) {
    final c = controller;
    if (c == null) return false;
    final data = jsonDecode(json) as Map<String, dynamic>;
    final rows = (data['board'] as List?)?.cast<String>();
    final tray = (data['tray'] as List?)?.cast<String?>();
    c.debugLoad(
      board: rows,
      tray: tray
          ?.map(
            (id) => id == null ? null : allShapes.firstWhere((s) => s.id == id),
          )
          .toList(),
    );
    return true;
  }
}
