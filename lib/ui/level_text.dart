import '../core/level.dart';
import 'palette.dart';

/// What the player has to do, in one line ("Colete 8 gemas e faça 900
/// pontos").
String goalSummary(LevelConfig level) {
  if (level.isEndless) return 'Até onde você consegue ir?';
  if (level.isBlitz) return 'Pontue o máximo em 60 segundos!';
  if (level.isDuel) {
    return 'Supere a meta de ${formatInt(level.targetScore)} pontos!';
  }
  final parts = [
    if (level.hasRockGoal) 'quebre todas as pedras',
    if (level.gemsTarget > 0) 'colete ${level.gemsTarget} gemas',
    if (level.hasPupGoal) 'resgate os ${level.pupCount} filhotes',
    if (level.targetScore > 0) 'faça ${formatInt(level.targetScore)} pontos',
  ];
  final text = parts.length > 1
      ? '${parts.sublist(0, parts.length - 1).join(', ')} e ${parts.last}'
      : parts.first;
  return text[0].toUpperCase() + text.substring(1);
}

String levelTitle(LevelConfig level) => switch (level.kind) {
  LevelKind.endless => 'Modo infinito',
  LevelKind.daily => 'Desafio diário',
  LevelKind.blitz => 'Blitz 60s',
  LevelKind.duel => 'Duelo',
  LevelKind.level => 'Fase ${level.number}',
};
