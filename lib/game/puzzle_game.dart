import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import '../core/board.dart';
import '../core/game_session.dart';
import '../l10n/idioma.dart';
import '../ui/block_painter.dart';
import '../ui/level_text.dart';
import '../ui/palette.dart';
import '../core/shapes.dart';
import '../services/progress_store.dart';
import '../testing/test_bridge.dart';
import 'board_view.dart';
import 'capi_carrier.dart';
import 'effects.dart';
import 'game_controller.dart';
import 'hint_hand.dart';
import 'pup_rescue.dart';
import 'tray_piece.dart';

/// The play area: board, tray and effects. Menus and the HUD are Flutter
/// widgets layered on top; this scene only draws the game itself.
class PuzzleGame extends FlameGame {
  PuzzleGame({
    required this.controller,
    required this.topInset,
    this.bottomInset = 0,
  });

  final GameController controller;

  /// Height reserved at the top for the HUD.
  final double topInset;

  /// The phone's own bar at the bottom (iPhone home indicator, Android
  /// gesture bar): nothing to drag sits under it.
  final double bottomInset;

  BlockSprites? sprites;
  Rect boardRect = Rect.zero;
  double cellSize = 1;
  double trayCellSize = 1;

  /// The stage shakes on big clears; everything sits inside it.
  final stage = PositionComponent();
  final boardView = BoardView();
  final trays = [for (var i = 0; i < 3; i++) TrayPiece(i)];
  Sparks? sparks;
  TrayPiece? activeDrag;

  /// Build with --dart-define=DEMO_PRAISE=true to cycle through the praise
  /// tiers every few seconds (for checking the effects without playing).
  static const _demoPraise = bool.fromEnvironment('DEMO_PRAISE');
  double _demoClock = 0;
  int _demoTier = 0;

  bool _announcePending = false;
  double _shake = 0;
  double _shakePower = 0;
  final _rng = Random();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    add(stage);
    stage.add(boardView);
    stage.addAll(trays);
    controller.onPlaced = _onPlaced;
    controller.onRevived = _onRevived;
    controller.onRestarted = _onRestarted;
    controller.onReady = _announce;
    controller.onToolUsed = _onToolUsed;
    controller.onPieceRotated = _onPieceRotated;
    controller.onTrayRerolled = _onTrayRerolled;
    if (kTestBridge) TestBridge.instance.game = this;
    for (final t in trays) {
      t.playAppear();
    }
    stage.add(HintHand()..priority = 15);
    stage.add(CapiCarrier()..priority = 16);
    if (!controller.tutorial && controller.intros.isEmpty) _announce();
  }

  /// Shows the start banner on the next frame, once the layout is known.
  void _announce() => _announcePending = true;

  /// "Fase 12 / Colete 8 gemas" over the board when an attempt starts.
  void _showAnnouncement() {
    final level = controller.level;
    stage.add(
      PraiseBanner(
        Praise(
          2,
          levelTitle(level),
          level.isHard
              ? const [Color(0xFFFFE3E3), Color(0xFFFF6B6B)]
              : const [Color(0xFFFFFFFF), Color(0xFFFFD43B)],
        ),
        position: Vector2(boardRect.center.dx, boardRect.center.dy),
        cellSize: cellSize * 0.85,
        subtitle: goalSummary(level),
        hold: 0.7,
        maxWidth: boardRect.width,
      )..priority = 40,
    );
  }

  @override
  void onRemove() {
    if (kTestBridge && TestBridge.instance.game == this) {
      TestBridge.instance.game = null;
    }
    controller.onPlaced = null;
    controller.onRevived = null;
    controller.onRestarted = null;
    controller.onReady = null;
    controller.onToolUsed = null;
    controller.onPieceRotated = null;
    controller.onTrayRerolled = null;
    sprites?.dispose();
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final w = size.x, h = size.y;
    final usable = h - topInset;
    final side = min(w - 36, usable / 1.5);
    cellSize = side / Board.size;
    // As big as a five-cell piece still fits in its third of the width.
    trayCellSize = min(cellSize * 0.56, ((w - 16) / 3) / 5.4);
    // The spare height is shared out: above the board, between it and the
    // pieces (at most a little over a cell, so they stay together) and
    // under the pieces. Tall phones then don't end in an empty strip.
    final trayH = cellSize * 3.2;
    final content = side + cellSize * 0.55 + trayH;
    final free = max(0.0, usable - bottomInset - content);
    final gap = min(free / 3, cellSize * 1.2);
    final top = topInset + max(8, (free - gap) / 2);
    boardRect = Rect.fromLTWH((w - side) / 2, top, side, side);
    final trayTop = boardRect.bottom + cellSize * 0.55 + gap;
    final slotW = (w - 16) / 3;
    for (var i = 0; i < 3; i++) {
      trays[i].layout(Rect.fromLTWH(8 + slotW * i, trayTop, slotW, trayH));
    }

    final ratio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    if (sprites?.cellSize != cellSize) {
      sprites?.dispose();
      sprites = BlockSprites(cellSize, ratio);
    }
    sparks?.removeFromParent();
    sparks = Sparks(cellSize);
    stage.add(sparks!..priority = 20);
  }

  /// How far above the finger a dragged piece floats.
  double liftFor(int rows) => rows * cellSize / 2 + cellSize * 1.1;

  /// Where things are on screen, for browser tests.
  Map<String, Object?> testGeometry() => {
    'board': {
      'left': boardRect.left,
      'top': boardRect.top,
      'size': boardRect.width,
      'cell': cellSize,
    },
    'slots': [
      for (final t in trays)
        {'x': t.position.x, 'y': t.position.y, 'w': t.size.x, 'h': t.size.y},
    ],
    'viewport': {'w': size.x, 'h': size.y, 'top': topInset},
  };

  /// Pointer path that drops [shape] from tray [slot] at (row, col): press
  /// on the slot, release where the floating piece lines up with the cell.
  Map<String, Object?> dragPath(int slot, Shape shape, int row, int col) {
    final t = trays[slot];
    final cx = boardRect.left + (col + shape.cols / 2) * cellSize;
    final cy = boardRect.top + (row + shape.rows / 2) * cellSize;
    return {
      'from': {
        'x': t.position.x + t.size.x / 2,
        'y': t.position.y + t.size.y / 2,
      },
      'to': {'x': cx, 'y': cy + liftFor(shape.rows)},
    };
  }

  Rect cellRect(int r, int c) => Rect.fromLTWH(
    boardRect.left + c * cellSize,
    boardRect.top + r * cellSize,
    cellSize,
    cellSize,
  );

  @override
  void update(double dt) {
    super.update(dt);
    if (_announcePending && sprites != null) {
      _announcePending = false;
      _showAnnouncement();
    }
    if (_demoPraise && sprites != null && (_demoClock += dt) > 2.4) {
      _demoClock = 0;
      _demoTier = _demoTier % 4 + 1;
      _celebrate(
        PlaceResult(
          outcome: PlaceOutcome(
            placed: const [],
            rows: const [],
            cols: const [],
            cleared: const [],
            gems: 0,
            rocksBroken: 0,
          ),
          points: 0,
          combo: _demoTier,
          boardCleared: false,
          newTray: false,
        ),
        _demoTier,
      );
    }
    if (_shake > 0) {
      _shake = max(0, _shake - dt);
      final a = _shakePower * (_shake / 0.3);
      stage.position = Vector2(
        (_rng.nextDouble() - 0.5) * 2 * a,
        (_rng.nextDouble() - 0.5) * 2 * a,
      );
    } else if (stage.position != Vector2.zero()) {
      stage.position = Vector2.zero();
    }
  }

  void _onPlaced(PlaceResult result, Piece piece) {
    final out = result.outcome;
    boardView.pop(out.placed);

    if (out.lines > 0) {
      _clearEffects(out.cleared, out.placed);
      final center = _centerOf(out.placed);
      stage.add(
        PopText(
          '+${formatInt(result.points)}',
          position: Vector2(center.dx, center.dy),
          fontSize: cellSize * 0.62,
          color: Palette.accent,
        )..priority = 30,
      );
      _celebrate(result, out.lines);
    }

    if (result.newTray) {
      for (final t in trays) {
        t.playAppear();
      }
    }
  }

  void _celebrate(PlaceResult result, int lines) {
    final praise = Praise.forClear(
      lines: lines,
      combo: result.combo,
      boardCleared: result.boardCleared,
      rng: _rng,
    );
    final at = Vector2(
      boardRect.center.dx,
      boardRect.top + boardRect.height * 0.4,
    );
    if (praise.tier >= 2) {
      stage.add(
        LightBurst(
          position: at,
          radius: boardRect.width * (0.35 + 0.1 * praise.tier),
          color: praise.colors[praise.colors.length ~/ 2],
        )..priority = 25,
      );
    }
    stage.add(
      PraiseBanner(
        praise,
        position: at,
        cellSize: cellSize,
        subtitle: result.combo >= 2
            ? tr('Combo x{n}', {'n': result.combo})
            : null,
        maxWidth: boardRect.width,
      )..priority = 40,
    );
    if (praise.tier >= 3) {
      add(
        ScreenFlash(Offset.zero & size.toSize(), strength: 0.12 * praise.tier),
      );
      sparks?.confetti(boardRect, count: 25 + 15 * (praise.tier - 2));
    }
    _shake = 0.3 + 0.05 * praise.tier;
    _shakePower = cellSize * 0.05 * praise.tier;
    controller.feedback.praise(praise.tier);
    if (kTestBridge) TestBridge.instance.praises.add(praise.text);
  }

  void _onToolUsed(CapiTool tool, List<ClearedCell> cleared) {
    if (cleared.isEmpty) return;
    _clearEffects(cleared, [for (final c in cleared) (c.row, c.col)]);
    _shake = 0.2;
    _shakePower = cellSize * 0.04;
  }

  void _onPieceRotated(int slot) {
    trays[slot].playAppear();
  }

  void _onTrayRerolled() {
    for (final t in trays) {
      t.playAppear();
    }
  }

  void _onRevived(List<ClearedCell> cleared) {
    _clearEffects(cleared, const []);
    for (final t in trays) {
      t.playAppear();
    }
  }

  void _onRestarted() {
    boardView.preview = null;
    activeDrag = null;
    for (final t in trays) {
      t.playAppear();
    }
  }

  void _clearEffects(List<ClearedCell> cleared, List<(int, int)> origin) {
    final s = sprites;
    final fx = sparks;
    if (s == null || fx == null) return;
    final from = origin.isEmpty ? const Offset(3.5, 3.5) : _avgCell(origin);
    for (final cell in cleared) {
      final dst = cellRect(cell.row, cell.col);
      final delay =
          0.028 *
          (Offset(cell.col.toDouble(), cell.row.toDouble()) - from).distance;
      final before = cell.before;
      final color = before.type == CellType.rock
          ? Palette.rock
          : Palette.blocks[before.color];
      if (cell.after.isEmpty) {
        stage.add(
          VanishingCell(
            image: s.forCell(before),
            overlay: before.gem ? s.gem : null,
            rect: dst,
            delay: delay,
          )..priority = 5,
        );
      }
      fx.burst(
        dst.center,
        before.gem ? Palette.gem : color,
        count: before.gem ? 9 : 4,
        delay: delay,
      );
      if (before.pup && cell.after.isEmpty) {
        stage.add(
          PupRescue(
            from: dst.center,
            to: Offset(size.x / 2, topInset - cellSize * 0.4),
            cell: cellSize,
            delay: delay,
          )..priority = 35,
        );
        stage.add(
          PopText(
            tr('Salvo!'),
            position: Vector2(dst.center.dx, dst.center.dy - cellSize),
            fontSize: cellSize * 0.5,
            color: const Color(0xFFFF9EC7),
            delay: delay + 0.2,
          )..priority = 30,
        );
      }
      if (before.gem) {
        stage.add(
          PopText(
            '+1',
            position: Vector2(dst.center.dx, dst.center.dy),
            fontSize: cellSize * 0.5,
            color: Palette.gem,
            delay: delay,
          )..priority = 30,
        );
      }
    }
  }

  Offset _avgCell(List<(int, int)> cells) {
    var r = 0.0, c = 0.0;
    for (final (cr, cc) in cells) {
      r += cr;
      c += cc;
    }
    return Offset(c / cells.length, r / cells.length);
  }

  Offset _centerOf(List<(int, int)> cells) {
    final a = _avgCell(cells);
    return Offset(
      boardRect.left + (a.dx + 0.5) * cellSize,
      boardRect.top + (a.dy + 0.5) * cellSize,
    );
  }
}
