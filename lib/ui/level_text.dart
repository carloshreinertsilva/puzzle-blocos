import '../core/level.dart';
import '../l10n/idioma.dart';
import 'palette.dart';

/// What the player has to do, in one line ("Colete 8 gemas e faça 900
/// pontos").
String goalSummary(LevelConfig level) {
  if (level.isEndless) return tr('Até onde você consegue ir?');
  if (level.isBlitz) return tr('Pontue o máximo em 60 segundos!');
  if (level.isDuel) {
    return tr('Supere a meta de {n} pontos!', {
      'n': formatInt(level.targetScore),
    });
  }
  final parts = [
    if (level.hasRockGoal) tr('quebre todas as pedras'),
    if (level.gemsTarget > 0) tr('colete {n} gemas', {'n': level.gemsTarget}),
    if (level.hasPupGoal) tr('resgate os {n} filhotes', {'n': level.pupCount}),
    if (level.targetScore > 0)
      tr('faça {n} pontos', {'n': formatInt(level.targetScore)}),
  ];
  final text = parts.length > 1
      ? tr('{lista} e {ultimo}', {
          'lista': parts.sublist(0, parts.length - 1).join(', '),
          'ultimo': parts.last,
        })
      : parts.first;
  return text[0].toUpperCase() + text.substring(1);
}

String levelTitle(LevelConfig level) => switch (level.kind) {
  LevelKind.endless => tr('Modo infinito'),
  LevelKind.daily => tr('Desafio diário'),
  LevelKind.blitz => tr('Blitz 60s'),
  LevelKind.duel => tr('Duelo'),
  LevelKind.level => tr('Fase {n}', {'n': level.number}),
};
