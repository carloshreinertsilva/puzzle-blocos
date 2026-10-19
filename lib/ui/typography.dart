import 'package:flutter/painting.dart';

import 'palette.dart';

/// The game's two fonts: Lilita One (chunky display font for titles,
/// buttons, numbers and praise) and Fredoka (rounded, for smaller text).
abstract final class Fonts {
  static const display = 'Lilita';
  static const body = 'Fredoka';
}

TextStyle displayText(
  double size, {
  Color color = Palette.text,
  List<Shadow>? shadows,
}) => TextStyle(
  fontFamily: Fonts.display,
  fontSize: size,
  color: color,
  letterSpacing: 0.3,
  shadows: shadows,
);

/// Fredoka is a variable font; [weight] sets its weight axis.
TextStyle bodyText(
  double size, {
  Color color = Palette.text,
  double weight = 600,
}) => TextStyle(
  fontFamily: Fonts.body,
  fontSize: size,
  color: color,
  fontVariations: [FontVariation('wght', weight)],
);

/// Dark drop shadow used under display text on colored backgrounds.
const textDrop = [Shadow(color: Color(0x88000000), offset: Offset(0, 3))];
