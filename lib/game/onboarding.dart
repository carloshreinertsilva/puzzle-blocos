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

  static bool tutorialDone(ProgressStore s) =>
      s.hasSeen('tutorial') || s.level > 1 || s.gamesPlayed > 0;

  static bool menuUnlocked(ProgressStore s) =>
      s.hasSeen('menu') || s.level > railLevels;

  static bool endlessUnlocked(ProgressStore s) => s.level >= endlessAt;
  static bool obrasUnlocked(ProgressStore s) => s.level >= obrasAt;
  static bool dailyUnlocked(ProgressStore s) => s.level >= dailyAt;

  /// Capi's lines on the menu that the player has not seen yet, in order.
  static List<MenuNews> pendingNews(ProgressStore s) => [
    if (!s.hasSeen(MenuNews.welcome.key)) MenuNews.welcome,
    if (!s.hasSeen(MenuNews.village.key)) MenuNews.village,
    if (endlessUnlocked(s) && !s.hasSeen(MenuNews.endless.key))
      MenuNews.endless,
    if (obrasUnlocked(s) && !s.hasSeen(MenuNews.obras.key)) MenuNews.obras,
    if (dailyUnlocked(s) && !s.hasSeen(MenuNews.daily.key)) MenuNews.daily,
  ];
}

enum MenuNews {
  welcome(
    'news_welcome',
    'Essa é a nossa estrada! Cada fase que você vence abre a próxima. '
        'Toque em Jogar para seguir.',
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
  );

  const MenuNews(this.key, this.text);
  final String key;
  final String text;
}
