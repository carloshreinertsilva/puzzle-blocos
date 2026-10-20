import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../core/board.dart';
import 'board_view.dart';
import 'effects.dart';
import 'puzzle_game.dart';

/// One of the three tray slots. The whole slot is the touch target, so
/// small pieces are easy to grab. While dragged, the piece grows to board
/// size and floats above the finger so the finger never hides it.
class TrayPiece extends PositionComponent
    with DragCallbacks, HasGameReference<PuzzleGame> {
  TrayPiece(this.slot);

  final int slot;

  bool _dragging = false;
  Vector2 _finger = Vector2.zero();

  /// 0 = tray size, 1 = board size.
  double _grow = 0;

  /// Center of the drawn piece, in local coordinates.
  Vector2 _center = Vector2.zero();

  /// Slide-in progress for a fresh tray (1 = settled).
  double _appear = 1;
  double _appearDelay = 0;

  (int, int)? _snap;

  Piece? get piece => game.controller.session.tray[slot];

  void layout(Rect slotRect) {
    position = Vector2(slotRect.left, slotRect.top);
    size = Vector2(slotRect.width, slotRect.height);
    if (!_dragging) _center = size / 2;
  }

  void playAppear() {
    _appear = 0;
    _appearDelay = slot * 0.07;
    _center = size / 2;
    _grow = 0;
  }

  double get _cellNow {
    final full = game.cellSize;
    return lerpDouble(game.trayCellSize, full * 0.94, _grow)!;
  }

  Vector2 get _lift => Vector2(0, -game.liftFor(piece?.shape.rows ?? 1));

  @override
  void update(double dt) {
    final k = 1 - exp(-dt * 20);
    _grow += ((_dragging ? 1.0 : 0.0) - _grow) * k;
    if (!_dragging) {
      _center += (size / 2 - _center) * (1 - exp(-dt * 16));
    }
    if (_appear < 1) {
      if (_appearDelay > 0) {
        _appearDelay -= dt;
      } else {
        _appear = min(1, _appear + dt / 0.32);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final p = piece;
    final sprites = game.sprites;
    if (p == null || sprites == null) return;

    final s = p.shape;
    final cell = _cellNow;
    final slideX = (1 - easeOutBack(_appear)) * game.size.x * 0.5;
    final origin = Offset(
      _center.x + slideX - s.cols * cell / 2,
      _center.y - s.rows * cell / 2,
    );
    final fits = game.controller.session.board.fitsAnywhere(s);
    final opacity = fits || _dragging ? 1.0 : 0.35;
    for (var i = 0; i < s.cells.length; i++) {
      final (r, c) = s.cells[i];
      final dst = Rect.fromLTWH(
        origin.dx + c * cell,
        origin.dy + r * cell,
        cell,
        cell,
      );
      sprites.draw(canvas, sprites.blocks[p.color], dst, opacity: opacity);
      if (i == p.gemCell) {
        sprites.draw(canvas, sprites.gem, dst, opacity: opacity);
      }
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (piece == null || !game.controller.playing || game.activeDrag != null) {
      return;
    }
    super.onDragStart(event);
    _dragging = true;
    game.activeDrag = this;
    _finger = event.canvasPosition - position;
    _center = _finger + _lift;
    game.controller.feedback.pick();
    game.controller.noteActivity();
    priority = 10;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_dragging) return;
    // Follow the pointer by its movement. (In this Flame version the
    // event's "end" position already adds the delta to the current
    // position, which made the piece run one step ahead of the finger.)
    _finger += event.localDelta;
    _center = _finger + _lift;
    _updateSnap();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _release();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _snap = null;
    _release();
  }

  void _release() {
    if (!_dragging) return;
    _dragging = false;
    game.activeDrag = null;
    game.boardView.preview = null;
    priority = 0;
    final snap = _snap;
    _snap = null;
    if (snap != null) {
      game.controller.place(slot, snap.$1, snap.$2);
      _center = size / 2;
      _grow = 0;
    }
  }

  void _updateSnap() {
    final p = piece;
    if (p == null) return;
    final s = p.shape;
    final cell = game.cellSize;
    final topLeft =
        position + _center - Vector2(s.cols * cell / 2, s.rows * cell / 2);
    final col = ((topLeft.x - game.boardRect.left) / cell).round();
    final row = ((topLeft.y - game.boardRect.top) / cell).round();
    final board = game.controller.session.board;
    if (board.canPlace(s, row, col)) {
      _snap = (row, col);
      final (rows, cols) = board.linesCompletedBy(s, row, col);
      final prev = game.boardView.preview;
      if (prev == null || prev.row != row || prev.col != col) {
        game.boardView.preview = PlacementPreview(p, row, col, rows, cols);
      }
    } else {
      _snap = null;
      game.boardView.preview = null;
    }
  }
}
