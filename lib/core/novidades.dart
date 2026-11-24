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
  duelo,
  convites,
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
    3: [
      Novidade(
        'Cofrinho do Capi',
        'Cada estrela que você ganha jogando, o Capi guarda outra no '
            'cofrinho. Quando encher, quebre e leve todas!',
        DestinoNovidade.loja,
      ),
    ],
    4: [
      Novidade(
        'Placar dos duelos',
        'Quando um amigo joga o seu desafio, você fica sabendo se ele passou '
            'você. E o placar com cada amigo fica guardado.',
        DestinoNovidade.duelo,
      ),
    ],
    5: [
      Novidade(
        'Você foi desafiado!',
        'Ao abrir o link de um amigo, você vê quem desafiou e quantos pontos '
            'precisa bater antes de começar.',
        DestinoNovidade.duelo,
      ),
    ],
    6: [
      Novidade(
        'Revanche com aviso',
        'Seu amigo passou você? Peça revanche no mesmo tabuleiro. Se '
            'vencer, ele recebe um aviso no celular. E você fica sabendo na '
            'hora quando alguém joga o seu desafio.',
        DestinoNovidade.duelo,
      ),
    ],
    7: [
      Novidade(
        'Duelo de 30 peças',
        'Agora cada duelo tem 30 peças para cada um, sem ferramentas, e o '
            'contador mostra quantas faltam. Quem fizer mais pontos vence.',
        DestinoNovidade.duelo,
      ),
    ],
    8: [
      Novidade(
        'Roleta na Torre',
        'Pare a seta antes do vídeo e continue a subida com o bloco até 3x maior!',
        DestinoNovidade.torre,
      ),
      Novidade(
        'Passe do Capi turbinado',
        'Níveis mais rápidos, e o premium agora dá +1 dica grátis por partida e estrelas em dobro no Desafio diário.',
        DestinoNovidade.passe,
      ),
      Novidade(
        'Dobre as estrelas em todos os modos',
        'No Desafio diário, no Infinito, no Blitz e na Torre, um vídeo dobra as estrelas da partida.',
        DestinoNovidade.blitz,
      ),
      Novidade(
        'Atalhos no fim da fase',
        'Ao vencer uma fase, você já vê o modo que acabou de liberar, quanto '
            'falta para o próximo prêmio do Passe e o seu Cofrinho.',
        DestinoNovidade.passe,
      ),
      Novidade(
        'Menu mais esperto',
        'Os cartões mostram o que há de novo, a Loja avisa as ofertas do dia e o Capi dá uma dica por dia.',
        DestinoNovidade.loja,
      ),
      Novidade(
        'Lembretes no iPhone',
        'O Capi agora avisa no iPhone também: seu presente, sua sequência e os prêmios do Passe esperando.',
        DestinoNovidade.passe,
      ),
      Novidade(
        'Todo mundo no ranking',
        'Agora você entra no ranking desde a primeira partida. Escolha o seu nome e suba na lista da semana!',
        DestinoNovidade.ranking,
      ),
    ],
    9: [
      Novidade(
        'Convide amigos e ganhe prêmios',
        'Quem entra pelo seu convite ganha estrelas e um presente. E você '
            'ganha estrelas, a Faixa de Embaixador e a Coroa de Amizade!',
        DestinoNovidade.convites,
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
