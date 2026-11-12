import 'dart:math';

/// Where a piece of news takes the player ("Ver agora").
enum DestinoNovidade {
  ranking,
  torre,
  missoes,
  guardaRoupa,
  passe,
  loja,
  blitz,
}

/// One thing that is new in the game, in Portuguese (shown through `tr`).
class Novidade {
  const Novidade(this.titulo, this.texto, this.destino);
  final String titulo;
  final String texto;
  final DestinoNovidade destino;
}

/// What is new, told to the player on the menu the first time the game
/// opens after an update ("O que há de novo"), with a dot on each thing
/// until it is opened.
///
/// Every change the player can see adds a line here, in a new edition
/// (the next number), together with the stores' notes
/// (`distribution/whatsnew/`). See CLAUDE.md.
abstract final class Novidades {
  static const edicoes = <int, List<Novidade>>{
    1: [
      Novidade(
        'Ranking de todo mundo',
        'Android e iPhone agora disputam o mesmo ranking. Veja a sua '
            'posição na semana!',
        DestinoNovidade.ranking,
      ),
      Novidade(
        'Torre do Capi nova',
        'A subida agora vai até a Lua, com o Capi torcendo por você.',
        DestinoNovidade.torre,
      ),
    ],
    2: [
      Novidade(
        'Blitz com tempo extra',
        'Jogadas grandes dão segundos a mais e, quando o tempo acaba, um '
            'vídeo dá +10 segundos.',
        DestinoNovidade.blitz,
      ),
    ],
  };

  /// How many are shown at once.
  static const porVez = 3;

  /// The newest edition.
  static int get atual => edicoes.keys.reduce(max);

  /// What a player who saw up to edition [vistas] has not been told yet:
  /// the newest first, at most [porVez].
  static List<Novidade> pendentes(int vistas) {
    final novas = edicoes.keys.where((e) => e > vistas).toList()
      ..sort((a, b) => b.compareTo(a));
    return [for (final e in novas) ...edicoes[e]!].take(porVez).toList();
  }
}
