import '../core/daily_missions.dart';

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../services/analytics.dart';
import '../services/feedback.dart';
import '../services/progress_store.dart';

/// A static block placed in the tower.
class TowerBlock {
  const TowerBlock({
    required this.x,
    required this.y,
    required this.z,
    required this.dx,
    required this.dy,
    required this.dz,
    required this.colorIndex,
  });

  final double x;
  final double y;
  final double z;
  final double dx;
  final double dy;
  final double dz;
  final int colorIndex;
}

/// A cut-off slice of a block falling down with simple gravity.
class FallingSlice {
  FallingSlice({
    required this.x,
    required this.y,
    required this.z,
    required this.dx,
    required this.dy,
    required this.dz,
    required this.colorIndex,
    this.vx = 0.0,
    this.vy = 0.0,
  });

  double x;
  double y;
  double z;
  final double dx;
  final double dy;
  final double dz;
  final int colorIndex;
  double vx;
  double vy;
  double vz = 0.0;
  double rot = 0.0;
  double vRot = 0.05;

  void update(double dt) {
    vz -= 9.8 * dt;
    z += vz * dt;
    x += vx * dt;
    y += vy * dt;
    rot += vRot;
  }
}

/// A stretch of the climb: the sky changes at each one (see tower_painter).
class TowerZone {
  const TowerZone(this.floor, this.name);

  /// The first floor of the zone.
  final int floor;

  /// Its name, in Portuguese (shown through `tr`).
  final String name;
}

/// What just happened, for the painter to celebrate (or to shake).
enum TowerFxKind { perfect, cut, closeCall, zone, record, revive }

class TowerFx {
  const TowerFx(
    this.kind,
    this.at, {
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.combo = 0,
    this.zone,
  });
  final TowerFxKind kind;

  /// [TowerController.time] when it happened.
  final double at;

  /// Where, in the tower's world (the middle of the block's top).
  final double x, y, z;
  final int combo;
  final TowerZone? zone;
}

/// Game controller for Capi's 2.5D Tower stacking mini-game.
class TowerController extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  TowerController({required this.store, required this.feedback}) {
    reset();
  }

  final ProgressStore store;
  final GameFeedback feedback;

  static const double blockDz = 0.42;
  static const double baseSize = 3.0;
  static const double perfectThreshold = 0.12;

  /// A cut that leaves less than this part of the block is a close call.
  static const double closeCallRatio = 0.4;

  /// With this many perfect floors in a row Capi is "on fire".
  static const int feverCombo = 3;

  /// One "continue" per climb, from this many floors on.
  static const int continueFromFloor = 5;

  /// The climb, from the village to the Moon.
  static const zones = [
    TowerZone(0, 'Vila do Capi'),
    TowerZone(10, 'Nuvens'),
    TowerZone(20, 'Pôr do sol'),
    TowerZone(30, 'Estrelas'),
    TowerZone(45, 'Espaço'),
    TowerZone(60, 'Lua'),
  ];

  final List<TowerBlock> blocks = [];
  final List<FallingSlice> fallingSlices = [];

  /// Recent events, for the painter (dropped after a few seconds).
  final List<TowerFx> fx = [];

  int height = 0;
  int get bestHeight => store.towerBestHeight;
  bool isNewBest = false;
  int combo = 0;
  int maxCombo = 0;
  int starsGained = 0;
  bool gameOver = false;
  bool playing = false;

  /// Seconds played (the painter's clock).
  double time = 0;

  /// When the last block landed and when the climb ended ([time]).
  double placedAt = -10;
  double overAt = -10;

  /// Screen shake, 1 right after a cut and fading out.
  double shake = 0;

  /// The record when this climb began, and whether it was beaten already.
  int recordToBeat = 0;
  bool recordBeaten = false;

  /// Whether the one "continue" of this climb was used.
  bool continued = false;

  // What was already counted for this climb (a continued climb ends twice).
  int _starsDue = 0;
  int _floorsReported = 0;
  bool _gameCounted = false;

  // Moving block properties
  double currentX = 0.0;
  double currentY = 0.0;
  double currentDx = baseSize;
  double currentDy = baseSize;
  bool isAxisX = true;
  double moveSpeed = 3.5;
  double moveProgress = 0.0; // Oscillates -1.0 to 1.0

  // Camera tracking: smooth camera height in world coordinates
  double cameraZ = 0.0;

  /// Floors built (the base does not count).
  int get floors => blocks.length - 1;

  bool get fever => combo >= feverCombo && !gameOver;

  /// The zone of floor [n].
  static TowerZone zoneAt(int n) => zones.lastWhere((z) => z.floor <= n);

  TowerZone get zone => zoneAt(floors);

  /// The next zone up, or null on the Moon.
  TowerZone? get nextZone {
    for (final z in zones) {
      if (z.floor > floors) return z;
    }
    return null;
  }

  /// Where Capi stands: the middle of the top block's top.
  (double, double, double) get top {
    final b = blocks.last;
    return (b.x + b.dx / 2, b.y + b.dy / 2, b.z + b.dz);
  }

  /// The top block is small: every tap is a risk.
  bool get tense => min(blocks.last.dx, blocks.last.dy) < 1.15;

  bool get canContinue => gameOver && !continued && floors >= continueFromFloor;

  void reset() {
    blocks.clear();
    fallingSlices.clear();
    fx.clear();
    height = 0;
    combo = 0;
    maxCombo = 0;
    starsGained = 0;
    gameOver = false;
    isNewBest = false;
    playing = true;
    time = 0;
    placedAt = -10;
    overAt = -10;
    shake = 0;
    recordToBeat = store.towerBestHeight;
    recordBeaten = false;
    continued = false;
    _starsDue = 0;
    _floorsReported = 0;
    _gameCounted = false;

    // Base block (level 0)
    currentDx = baseSize;
    currentDy = baseSize;
    currentX = -baseSize / 2;
    currentY = -baseSize / 2;

    blocks.add(
      TowerBlock(
        x: currentX,
        y: currentY,
        z: 0.0,
        dx: currentDx,
        dy: currentDy,
        dz: blockDz,
        colorIndex: 0,
      ),
    );

    cameraZ = 0.0;
    _spawnNext();
    notifyListeners();
  }

  void _spawnNext() {
    height++;
    isAxisX = height % 2 == 1;
    moveProgress = -1.0;
    // Speed slightly ramps up with height
    moveSpeed = (3.2 + min(height * 0.08, 4.0));

    final prev = blocks.last;
    currentDx = prev.dx;
    currentDy = prev.dy;

    if (isAxisX) {
      currentY = prev.y;
      currentX = -4.2;
    } else {
      currentX = prev.x;
      currentY = -4.2;
    }
  }

  /// Called on animation frame to update moving block position and falling slices.
  void tick(double dt) {
    time += dt;
    shake = max(0, shake - dt * 3.2);
    fx.removeWhere((e) => time - e.at > 3.5);
    for (final slice in fallingSlices) {
      if (slice.z > -10.0) slice.update(dt);
    }
    if (gameOver) {
      notifyListeners();
      return;
    }

    // Oscillate moving block between -4.2 and 4.2
    moveProgress += dt * moveSpeed;
    final pos = sin(moveProgress) * 4.2;

    final prev = blocks.last;
    if (isAxisX) {
      currentX = prev.x + pos;
    } else {
      currentY = prev.y + pos;
    }

    // Smoothly pan camera up toward current height
    final targetCameraZ = max(0.0, (height - 3) * blockDz);
    cameraZ += (targetCameraZ - cameraZ) * min(1.0, dt * 4.0);

    fallingSlices.removeWhere((s) => s.z < -10.0);

    notifyListeners();
  }

  /// Places the current moving block (tap screen).
  bool place() {
    if (gameOver || !playing) return false;

    final prev = blocks.last;
    final currentZ = height * blockDz;
    final colorIdx = height % 8;
    // Along the axis the block moves on: where it is, and the block below.
    final pos = isAxisX ? currentX : currentY;
    final prevPos = isAxisX ? prev.x : prev.y;
    final prevSize = isAxisX ? prev.dx : prev.dy;
    final diff = pos - prevPos;

    if (diff.abs() >= prevSize && diff.abs() > perfectThreshold) {
      // Completely missed!
      _triggerGameOver(currentZ, colorIdx);
      return false;
    }

    var newPos = prevPos;
    var newSize = prevSize;
    final perfect = diff.abs() <= perfectThreshold;
    if (perfect) {
      combo++;
      if (combo > maxCombo) maxCombo = combo;
      feedback.praise(combo);
      // Combo reward: recover some width if shaved
      if (combo >= feverCombo && newSize < baseSize) {
        newSize = min(baseSize, newSize + 0.3);
        newPos = prevPos - 0.15;
      }
    } else {
      // What hangs over the edge is cut off and falls.
      combo = 0;
      final cut = diff.abs();
      newSize = prevSize - cut;
      newPos = diff > 0 ? pos : prevPos;
      final slicePos = diff > 0 ? prevPos + prevSize : pos;
      final v = diff > 0 ? 1.5 : -1.5;
      fallingSlices.add(
        FallingSlice(
          x: isAxisX ? slicePos : currentX,
          y: isAxisX ? currentY : slicePos,
          z: currentZ,
          dx: isAxisX ? cut : currentDx,
          dy: isAxisX ? currentDy : cut,
          dz: blockDz,
          colorIndex: colorIdx,
          vx: isAxisX ? v : 0,
          vy: isAxisX ? 0 : v,
        ),
      );
      feedback.click();
    }

    if (isAxisX) {
      currentX = newPos;
      currentDx = newSize;
    } else {
      currentY = newPos;
      currentDy = newSize;
    }
    blocks.add(
      TowerBlock(
        x: currentX,
        y: currentY,
        z: currentZ,
        dx: currentDx,
        dy: currentDy,
        dz: blockDz,
        colorIndex: colorIdx,
      ),
    );
    placedAt = time;

    final (tx, ty, tz) = top;
    if (perfect) {
      fx.add(
        TowerFx(TowerFxKind.perfect, time, x: tx, y: ty, z: tz, combo: combo),
      );
    } else {
      final closeCall = newSize / prevSize < closeCallRatio;
      shake = closeCall ? 1 : 0.45;
      fx.add(
        TowerFx(
          closeCall ? TowerFxKind.closeCall : TowerFxKind.cut,
          time,
          x: tx,
          y: ty,
          z: tz,
        ),
      );
    }
    // A new zone, or the record left behind: the big moments.
    final z = zone;
    if (z.floor == floors && floors > 0) {
      fx.add(TowerFx(TowerFxKind.zone, time, x: tx, y: ty, z: tz, zone: z));
      feedback.praise(4);
    }
    if (!recordBeaten && recordToBeat > 0 && floors > recordToBeat) {
      recordBeaten = true;
      fx.add(TowerFx(TowerFxKind.record, time, x: tx, y: ty, z: tz));
      feedback.praise(5);
    }

    _spawnNext();
    notifyListeners();
    return true;
  }

  void _triggerGameOver(double currentZ, int colorIdx) {
    gameOver = true;
    playing = false;
    overAt = time;
    shake = 1;
    Analytics.event('tower_end', {'height': height, 'best_combo': maxCombo});

    // The whole block falls down
    fallingSlices.add(
      FallingSlice(
        x: currentX,
        y: currentY,
        z: currentZ,
        dx: currentDx,
        dy: currentDy,
        dz: blockDz,
        colorIndex: colorIdx,
        vx: isAxisX ? (currentX > 0 ? 1.0 : -1.0) : 0.0,
        vy: !isAxisX ? (currentY > 0 ? 1.0 : -1.0) : 0.0,
      ),
    );

    // Score height is the count of placed blocks minus base
    final finalHeight = floors;

    // Stars earned: +1 at 5, +1 at 10, +1 at 15, etc., plus bonus for every 10
    // A few stars a day at most: the tower is quick to replay. A continued
    // climb ends twice: the second time only what it added counts.
    final due = (finalHeight ~/ 5) + (finalHeight ~/ 10);
    final more = due - _starsDue;
    _starsDue = due;
    if (more > 0) {
      store.addStarsCapped('tower', more, 6, DateTime.now()).then((n) {
        starsGained += n;
        if (!_disposed) notifyListeners();
      });
    }

    if (finalHeight > bestHeight) {
      isNewBest = true;
      store.recordTowerHeight(finalHeight);
    }
    if (!_gameCounted) {
      _gameCounted = true;
      store.recordTowerGame();
    }
    DailyMissionsManager.reportEvent(
      store,
      DailyMissionType.playTower,
      finalHeight - _floorsReported,
    );
    _floorsReported = finalHeight;
    feedback.lose();
    notifyListeners();
  }

  /// The one second chance of a climb (after a video): the block that fell
  /// comes back and the climb goes on from the same floor.
  bool continueClimb() {
    if (!canContinue) return false;
    continued = true;
    gameOver = false;
    playing = true;
    combo = 0;
    fallingSlices.clear();
    height--;
    _spawnNext();
    final (tx, ty, tz) = top;
    fx.add(TowerFx(TowerFxKind.revive, time, x: tx, y: ty, z: tz));
    feedback.revive();
    Analytics.event('tower_continue', {'height': height});
    notifyListeners();
    return true;
  }

  /// Deterministic debug placement for tests.
  void debugPlace({bool perfect = true, double offset = 0.0}) {
    if (gameOver) return;
    final prev = blocks.last;
    if (perfect) {
      if (isAxisX) {
        currentX = prev.x;
      } else {
        currentY = prev.y;
      }
    } else {
      if (isAxisX) {
        currentX = prev.x + offset;
      } else {
        currentY = prev.y + offset;
      }
    }
    place();
  }
}
