import 'dart:math';

import 'package:flutter/foundation.dart';

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

/// Game controller for Capi's 2.5D Tower stacking mini-game.
class TowerController extends ChangeNotifier {
  TowerController({required this.store, required this.feedback}) {
    reset();
  }

  final ProgressStore store;
  final GameFeedback feedback;

  static const double blockDz = 0.42;
  static const double baseSize = 3.0;
  static const double perfectThreshold = 0.12;

  final List<TowerBlock> blocks = [];
  final List<FallingSlice> fallingSlices = [];

  int height = 0;
  int get bestHeight => store.towerBestHeight;
  bool isNewBest = false;
  int combo = 0;
  int maxCombo = 0;
  int starsGained = 0;
  bool gameOver = false;
  bool playing = false;

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

  void reset() {
    blocks.clear();
    fallingSlices.clear();
    height = 0;
    combo = 0;
    maxCombo = 0;
    starsGained = 0;
    gameOver = false;
    isNewBest = false;
    playing = true;

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
    if (gameOver) {
      // Keep falling slices active
      var changed = false;
      for (final slice in fallingSlices) {
        if (slice.z > -10.0) {
          slice.update(dt);
          changed = true;
        }
      }
      if (changed) notifyListeners();
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

    // Update falling slices
    for (final slice in fallingSlices) {
      if (slice.z > -10.0) {
        slice.update(dt);
      }
    }
    fallingSlices.removeWhere((s) => s.z < -10.0);

    notifyListeners();
  }

  /// Places the current moving block (tap screen).
  bool place() {
    if (gameOver || !playing) return false;

    final prev = blocks.last;
    final currentZ = height * blockDz;
    final colorIdx = height % 8;

    if (isAxisX) {
      final diff = currentX - prev.x;
      if (diff.abs() <= perfectThreshold) {
        // Perfect alignment!
        currentX = prev.x;
        combo++;
        if (combo > maxCombo) maxCombo = combo;
        feedback.praise(combo);

        // Combo reward: recover some width if shaved
        if (combo >= 3 && currentDx < baseSize) {
          currentDx = min(baseSize, currentDx + 0.3);
          currentX = prev.x - 0.15;
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
        _spawnNext();
        notifyListeners();
        return true;
      } else if (diff > 0 && diff < prev.dx) {
        // Overlap right: cut off the right slice
        combo = 0;
        final newDx = prev.dx - diff;
        final sliceDx = diff;
        final sliceX = prev.x + newDx;

        fallingSlices.add(
          FallingSlice(
            x: sliceX,
            y: currentY,
            z: currentZ,
            dx: sliceDx,
            dy: currentDy,
            dz: blockDz,
            colorIndex: colorIdx,
            vx: 1.5,
          ),
        );

        currentX = prev.x;
        currentDx = newDx;

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
        feedback.click();
        _spawnNext();
        notifyListeners();
        return true;
      } else if (diff < 0 && -diff < prev.dx) {
        // Overlap left: cut off the left slice
        combo = 0;
        final sliceDx = -diff;
        final newDx = prev.dx - sliceDx;
        final sliceX = currentX;

        fallingSlices.add(
          FallingSlice(
            x: sliceX,
            y: currentY,
            z: currentZ,
            dx: sliceDx,
            dy: currentDy,
            dz: blockDz,
            colorIndex: colorIdx,
            vx: -1.5,
          ),
        );

        currentX = prev.x;
        currentDx = newDx;

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
        feedback.click();
        _spawnNext();
        notifyListeners();
        return true;
      } else {
        // Completely missed!
        _triggerGameOver(currentZ, colorIdx);
        return false;
      }
    } else {
      // Axis Y
      final diff = currentY - prev.y;
      if (diff.abs() <= perfectThreshold) {
        // Perfect alignment!
        currentY = prev.y;
        combo++;
        if (combo > maxCombo) maxCombo = combo;
        feedback.praise(combo);

        if (combo >= 3 && currentDy < baseSize) {
          currentDy = min(baseSize, currentDy + 0.3);
          currentY = prev.y - 0.15;
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
        _spawnNext();
        notifyListeners();
        return true;
      } else if (diff > 0 && diff < prev.dy) {
        // Overlap forward
        combo = 0;
        final newDy = prev.dy - diff;
        final sliceDy = diff;
        final sliceY = prev.y + newDy;

        fallingSlices.add(
          FallingSlice(
            x: currentX,
            y: sliceY,
            z: currentZ,
            dx: currentDx,
            dy: sliceDy,
            dz: blockDz,
            colorIndex: colorIdx,
            vy: 1.5,
          ),
        );

        currentY = prev.y;
        currentDy = newDy;

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
        feedback.click();
        _spawnNext();
        notifyListeners();
        return true;
      } else if (diff < 0 && -diff < prev.dy) {
        // Overlap backward
        combo = 0;
        final sliceDy = -diff;
        final newDy = prev.dy - sliceDy;
        final sliceY = currentY;

        fallingSlices.add(
          FallingSlice(
            x: currentX,
            y: sliceY,
            z: currentZ,
            dx: currentDx,
            dy: sliceDy,
            dz: blockDz,
            colorIndex: colorIdx,
            vy: -1.5,
          ),
        );

        currentY = prev.y;
        currentDy = newDy;

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
        feedback.click();
        _spawnNext();
        notifyListeners();
        return true;
      } else {
        // Completely missed!
        _triggerGameOver(currentZ, colorIdx);
        return false;
      }
    }
  }

  void _triggerGameOver(double currentZ, int colorIdx) {
    gameOver = true;
    playing = false;

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
    final finalHeight = blocks.length - 1;

    // Stars earned: +1 at 5, +1 at 10, +1 at 15, etc., plus bonus for every 10
    starsGained = (finalHeight ~/ 5) + (finalHeight ~/ 10);
    if (starsGained > 0) {
      store.addStars(starsGained);
    }

    if (finalHeight > bestHeight) {
      isNewBest = true;
      store.recordTowerHeight(finalHeight);
    }
    store.recordTowerGame();
    feedback.lose();
    notifyListeners();
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
