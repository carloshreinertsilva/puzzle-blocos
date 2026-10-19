import 'dart:math';

import 'board.dart';

/// Drawings that levels can start with. Each has rows and columns that are
/// almost complete, so the first moves already clear lines, which makes the
/// opening of a level feel good instead of empty. None has a full line.
const boardPatterns = <String, List<String>>{
  'coração': [
    '........',
    '.##..##.',
    '####.###',
    '###.####',
    '.######.',
    '..####..',
    '...##...',
    '........',
  ],
  'escada': [
    '........',
    '........',
    '##......',
    '###.....',
    '####....',
    '#####...',
    '######..',
    '.######.',
  ],
  'moldura': [
    '###..###',
    '#......#',
    '#......#',
    '........',
    '........',
    '#......#',
    '#......#',
    '###..###',
  ],
  'listras': [
    '........',
    '######..',
    '........',
    '..######',
    '........',
    '######..',
    '........',
    '..######',
  ],
  'seta': [
    '...##...',
    '..####..',
    '.######.',
    '###..###',
    '...##...',
    '...##...',
    '...##...',
    '........',
  ],
  'colunas': [
    '##....##',
    '##....##',
    '##....##',
    '........',
    '........',
    '##....##',
    '##....##',
    '##....##',
  ],
  'base': [
    '........',
    '........',
    '........',
    '........',
    '........',
    '........',
    '###.####',
    '####.###',
  ],
  'cruz': [
    '...##...',
    '...##...',
    '...##...',
    '###..###',
    '###..###',
    '...##...',
    '...##...',
    '........',
  ],
  'taça': [
    '#......#',
    '#......#',
    '#......#',
    '#......#',
    '#......#',
    '##....##',
    '.######.',
    '........',
  ],
  'degrau': [
    '........',
    '........',
    '........',
    '........',
    '......##',
    '....####',
    '..######',
    '.#######',
  ],
  'pilares': [
    '#......#',
    '#......#',
    '##....##',
    '##....##',
    '###..###',
    '###..###',
    '........',
    '........',
  ],
  'casinha': [
    '...##...',
    '..####..',
    '.######.',
    '###..###',
    '.##..##.',
    '.##..##.',
    '.######.',
    '........',
  ],
};

/// Cells of a pattern after a random mirror/transpose, as (row, col).
List<(int, int)> patternCells(List<String> art, Random rng) {
  final flipH = rng.nextBool();
  final flipV = rng.nextBool();
  final transpose = rng.nextBool();
  const last = Board.size - 1;
  return [
    for (var r = 0; r < Board.size; r++)
      for (var c = 0; c < Board.size; c++)
        if (art[r][c] == '#')
          () {
            var rr = flipV ? last - r : r;
            var cc = flipH ? last - c : c;
            if (transpose) (rr, cc) = (cc, rr);
            return (rr, cc);
          }(),
  ];
}
