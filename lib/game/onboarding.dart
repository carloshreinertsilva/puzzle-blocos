import '../services/progress_store.dart';

/// How a new player is brought in: a guided tutorial with Capi, then the
/// first levels back to back (no menu), then the menu, with the other modes
/// unlocking as the player goes.
abstract final class Onboarding {
  /// Levels played one after the other before the menu shows up.
  static const railLevels = 3;
  static const endlessAt = 5;
  static const obrasAt = 6;
  static const dailyAt = 7;
  static const blitzAt = 8;
  static const duelAt = 8;
  static const towerAt = 9;

  static bool tutorialDone(ProgressStore s) =>
      s.hasSeen('tutorial') || s.level > 1 || s.gamesPlayed > 0;

  static bool menuUnlocked(ProgressStore s) =>
      s.hasSeen('menu') || s.level > railLevels;

  static bool endlessUnlocked(ProgressStore s) => s.level >= endlessAt;
  static bool obrasUnlocked(ProgressStore s) => s.level >= obrasAt;
  static bool dailyUnlocked(ProgressStore s) => s.level >= dailyAt;
  static bool blitzUnlocked(ProgressStore s) => s.level >= blitzAt;
  static bool duelUnlocked(ProgressStore s) => s.level >= duelAt;
  static bool towerUnlocked(ProgressStore s) => s.level >= towerAt;

  /// Capi's lines on the menu that the player has not seen yet, in order.
  static List<MenuNews> pendingNews(ProgressStore s) => [
    if (!s.hasSeen(MenuNews.welcome.key)) MenuNews.welcome,
    if (!s.hasSeen(MenuNews.village.key)) MenuNews.village,
    if (endlessUnlocked(s) && !s.hasSeen(MenuNews.endless.key))
      MenuNews.endless,
    if (obrasUnlocked(s) && !s.hasSeen(MenuNews.obras.key)) MenuNews.obras,
    if (dailyUnlocked(s) && !s.hasSeen(MenuNews.daily.key)) MenuNews.daily,
    if (blitzUnlocked(s) && !s.hasSeen(MenuNews.blitz.key)) MenuNews.blitz,
    if (duelUnlocked(s) && !s.hasSeen(MenuNews.duel.key)) MenuNews.duel,
    if (towerUnlocked(s) && !s.hasSeen(MenuNews.tower.key)) MenuNews.tower,
  ];
}

enum MenuNews {
  welcome(
    'news_welcome',
    'Essa é a nossa estrada! Cada fase que você vence abre a próxima. '
        'Toque em Jogar para seguir.',
  ),
  blitz(
    'news_blitz',
    'Novo modo Blitz! Você tem 60 segundos para fazer o máximo de pontos e combos.',
  ),
  duel(
    'news_duel',
    'Novo modo Duelo! Desafie seus amigos com links e comparem quem pontua mais.',
  ),
  village(
    'news_village',
    'E tem mais: com as estrelas das fases você constrói a minha vila! '
        'Toque em Vila do Capi para ver.',
  ),
  endless(
    'news_endless',
    'Novidade! Liberei o modo Infinito: sem metas, só você e o seu recorde.',
  ),
  obras(
    'news_obras',
    'Abri o modo Obras! É um quebra-cabeça: encaixe todas as peças no '
        'desenho, sem sobrar buraco. Cada obra vale até 3 estrelas.',
  ),
  daily(
    'news_daily',
    'Mais uma: o Desafio diário! Um novo todo dia. '
        'Volte sempre para manter a sequência.',
  ),
  tower(
    'news_tower',
    'Novo jogo: Torre do Capi! Toque para empilhar blocos em 2.5D e subir o mais alto que puder.',
  );

  const MenuNews(this.key, this.text);
  final String key;
  final String text;
}
