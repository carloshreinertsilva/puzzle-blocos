import 'package:flutter/material.dart';

const appTitle = 'Bloco a Bloco';

abstract final class Palette {
  static const bgTop = Color(0xFF1C2155);
  static const bgBottom = Color(0xFF2A1650);
  static const panel = Color(0xFF121637);
  static const panelEdge = Color(0xFF2E3577);
  static const emptyCell = Color(0xFF1D2250);
  static const text = Color(0xFFF4F1FF);
  static const textDim = Color(0xFFA9A6D6);
  static const accent = Color(0xFFFFC94D);
  static const accentDeep = Color(0xFFFF8A3D);
  static const good = Color(0xFF51CF66);
  static const danger = Color(0xFFFF6B6B);

  static const blocks = [
    Color(0xFFFF6B6B), // coral
    Color(0xFFFFA94D), // orange
    Color(0xFFFFD43B), // yellow
    Color(0xFF51CF66), // green
    Color(0xFF22B8CF), // teal
    Color(0xFF4C6EF5), // blue
    Color(0xFFB05CF5), // purple
  ];

  static const rock = Color(0xFF8E93AE);
  static const rockTough = Color(0xFF5D627E);
  static const gem = Color(0xFF8CF0FF);

  static Color lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;
  static Color darken(Color c, double t) => Color.lerp(c, Colors.black, t)!;
}

const backgroundGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Palette.bgTop, Palette.bgBottom],
  ),
);

/// "12.345" style thousands separator.
String formatInt(int v) {
  final s = v.abs().toString();
  final out = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
    out.write(s[i]);
  }
  return out.toString();
}
