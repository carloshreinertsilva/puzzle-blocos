/// One guided move in the tutorial: what Capi says, the board, the piece
/// in the middle slot and where the hint hand points.
class TutorialStep {
  const TutorialStep({
    required this.say,
    required this.board,
    required this.piece,
    required this.target,
    this.needLines = 0,
  });

  final String say;

  /// 8 rows: '.' empty, '0'-'6' a block of that color.
  final List<String> board;
  final String piece;
  final (int, int) target;

  /// Lines the move has to clear to count (0 = any placement).
  final int needLines;
}

abstract final class Tutorial {
  static const steps = [
    TutorialStep(
      say:
          'Oi! Eu sou o Capi. Me ajuda a construir? '
          'Arraste a peça até o tabuleiro.',
      board: [
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ],
      piece: 'o20',
      target: (3, 3),
    ),
    TutorialStep(
      say:
          'Isso! Agora complete a fileira: '
          'quando uma linha enche, ela some.',
      board: [
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '012..456',
      ],
      piece: 'i20',
      target: (7, 3),
      needLines: 1,
    ),
    TutorialStep(
      say: 'Uau! Agora duas linhas de uma vez: vale muito mais pontos!',
      board: [
        '........',
        '........',
        '........',
        '........',
        '........',
        '5.......',
        '645..123',
        '310..562',
      ],
      piece: 'o20',
      target: (6, 3),
      needLines: 2,
    ),
  ];

  static const retry = 'Quase! Encaixe a peça onde a mãozinha mostra.';
  static const done = 'Você pegou o jeito! Agora é pra valer: vamos à Fase 1?';
}
