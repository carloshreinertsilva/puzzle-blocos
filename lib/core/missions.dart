/// The three stars of a level: win it, pull off a big move, and win without
/// the second chance. Kept per level as a bitmask, so replaying a level can
/// add the stars still missing.
enum Mission { win, bigMove, noRevive }

abstract final class Missions {
  /// Levels up to this ask for a double clear; later ones for a combo x3.
  static const doubleClearUntil = 10;

  static String text(Mission m, int level) => switch (m) {
    Mission.win => 'Vencer a fase',
    Mission.bigMove =>
      level <= doubleClearUntil
          ? 'Limpar 2 linhas de uma vez'
          : 'Fazer um combo x3',
    Mission.noRevive => 'Sem usar o "Continuar"',
  };

  /// Which missions a won attempt completed, as a bitmask.
  static int earned({
    required int level,
    required int bestLines,
    required int bestCombo,
    required bool revived,
  }) {
    final big = level <= doubleClearUntil ? bestLines >= 2 : bestCombo >= 3;
    return bit(Mission.win) |
        (big ? bit(Mission.bigMove) : 0) |
        (revived ? 0 : bit(Mission.noRevive));
  }

  static int bit(Mission m) => 1 << m.index;

  static bool has(int bits, Mission m) => bits & bit(m) != 0;

  static int count(int bits) =>
      Mission.values.where((m) => has(bits, m)).length;

  /// Stars for an endless run: one per 2,500 points, at most four.
  static int forEndless(int score) => (score ~/ 2500).clamp(0, 4);

  /// Stars for completing the daily challenge.
  static const daily = 3;
}
