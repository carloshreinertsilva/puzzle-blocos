import 'package:flutter/material.dart';

import '../core/hats.dart';
import 'capi.dart';

/// Small painter widget for the Daily Missions icon (clipboard with checkmarks).
class MissionsIcon extends StatelessWidget {
  const MissionsIcon({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'art/missions/icone-missoes-128.png',
      width: size,
      height: size,
      errorBuilder: (_, _, _) => Icon(
        Icons.assignment_turned_in_rounded,
        size: size,
        color: const Color(0xFF818CF8),
      ),
    );
  }
}

/// Small painter widget for the Daily Treasure Chest.
class ChestIcon extends StatelessWidget {
  const ChestIcon({super.key, this.size = 48, this.open = false});
  final double size;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'art/missions/icone-bau-128.png',
      width: size,
      height: size,
      errorBuilder: (_, _, _) => Icon(
        open ? Icons.lock_open_rounded : Icons.inventory_2_rounded,
        size: size,
        color: const Color(0xFFFBBF24),
      ),
    );
  }
}

/// Miniature hat icon or wardrobe icon.
class HatWardrobeIcon extends StatelessWidget {
  const HatWardrobeIcon({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'art/hats/icone-chapeus-128.png',
      width: size,
      height: size,
      errorBuilder: (_, _, _) => Icon(
        Icons.checkroom_rounded,
        size: size,
        color: const Color(0xFFF59E0B),
      ),
    );
  }
}

/// Small preview of a specific hat on a mini Capi head.
class HatPreviewItem extends StatelessWidget {
  const HatPreviewItem({super.key, required this.hat, this.size = 64});

  final CapiHat hat;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CapiPainter(mood: CapiMood.happy, t: 0.0, hat: hat),
      ),
    );
  }
}
