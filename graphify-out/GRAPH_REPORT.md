# Graph Report - puzzle-blocos  (2026-10-20)

## Corpus Check
- 61 files · ~24,786 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 30 file(s) not represented in the graph (top: .xml 7, (none) 6, .plist 4)

## Summary
- 902 nodes · 1112 edges · 50 communities (36 shown, 14 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b006a8d0`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Efeitos visuais e partículas
- Cena Flame do jogo
- Telas e navegação
- Tela de partida e cartões
- Progresso salvo e estatísticas
- Tabuleiro e células
- Sessão de jogo (regras)
- Controlador do jogo
- Gerador de fases
- Paleta de cores
- Menu: caminho de fases
- Desenhos de tabuleiro
- Política de anúncios
- Arrastar peças da bandeja
- Botões e widgets
- Arte dos blocos
- CI e dependências
- Testes Playwright
- App iOS (Swift)
- Ponte de testes
- Prévia de encaixe no tabuleiro
- HUD e cartões da partida
- Formas das peças
- Sons e vibração
- State
- Gerador de peças
- Pacote dos testes e2e
- Solver (peças jogáveis)
- Manifesto web
- sound_web.dart
- Gerador de sons
- Textos das fases
- Configuração Vercel
- Pintores do menu
- Componentes de texto e luz
- Componentes arrastáveis
- App Android
- Clarão e faíscas
- Princípios de dificuldade
- Script de build Vercel
- Controlador (base)
- Jogo Flame (base)
- serve.py
- Bloco a Bloco — instruções para o Claude Code

## God Nodes (most connected - your core abstractions)
1. `Bloco a Bloco (block puzzle game)` - 10 edges
2. `state()` - 7 edges
3. `puzzle_blocos package manifest` - 7 edges
4. `waitForState()` - 6 edges
5. `playMove()` - 6 edges
6. `PositionComponent` - 6 edges
7. `Flutter job (format, analyze, unit tests, web_test build)` - 6 edges
8. `@playwright/test` - 5 edges
9. `AppDelegate` - 5 edges
10. `GameController` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Flutter job (format, analyze, unit tests, web_test build)` --references--> `Dart analyzer config (flutter_lints, excludes)`  [INFERRED]
  .github/workflows/ci.yml → analysis_options.yaml
- `Flutter job (format, analyze, unit tests, web_test build)` --references--> `puzzle_blocos package manifest`  [INFERRED]
  .github/workflows/ci.yml → pubspec.yaml
- `Flutter job (format, analyze, unit tests, web_test build)` --implements--> `TEST_BRIDGE web test bridge`  [EXTRACTED]
  .github/workflows/ci.yml → README.md
- `TEST_BRIDGE web test bridge` --references--> `Flutter web HTML shell (Bloco a Bloco)`  [INFERRED]
  README.md → web/index.html
- `Vercel web deployment` --references--> `Flutter web HTML shell (Bloco a Bloco)`  [INFERRED]
  README.md → web/index.html

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **CI pipeline: Flutter build with test bridge feeding Playwright e2e** — _github_workflows_ci_flutter_job, _github_workflows_ci_web_test_artifact, _github_workflows_ci_e2e_job, readme_test_bridge [EXTRACTED 1.00]
- **Difficulty design principles** — readme_solver_always_playable, readme_sawtooth_difficulty, readme_invisible_adjustment, readme_deterministic_levels, readme_level_simulator [EXTRACTED 1.00]

## Communities (50 total, 14 thin omitted)

### Community 0 - "Efeitos visuais e partículas"
Cohesion: 0.04
Nodes (45): age, area, burst, c1, cellSize, color, colors, confetti (+37 more)

### Community 1 - "Cena Flame do jogo"
Cohesion: 0.05
Nodes (36): activeDrag, _announce, _announcePending, _avgCell, backgroundColor, boardRect, boardView, _celebrate (+28 more)

### Community 2 - "Telas e navegação"
Cohesion: 0.06
Nodes (26): ads, App, AppServices, build, feedback, main, services, setPreferredOrientations (+18 more)

### Community 3 - "Tela de partida e cartões"
Cohesion: 0.05
Nodes (40): best, _bodyStyle, build, _busy, canRevive, color, controller, createState (+32 more)

### Community 4 - "Progresso salvo e estatísticas"
Cohesion: 0.05
Nodes (30): adsRemoved, bestCombo, bestScore, completeDaily, dailyDone, dailyStreak, dayKey, failStreakFor (+22 more)

### Community 5 - "Tabuleiro e células"
Cohesion: 0.05
Nodes (40): after, at, before, block, Board, canPlace, Cell, _cells (+32 more)

### Community 6 - "Sessão de jogo (regras)"
Cohesion: 0.05
Nodes (33): _bits, board, boardClearBonus, boardCleared, canPlace, combo, comboGrace, _deal (+25 more)

### Community 7 - "Controlador do jogo"
Cohesion: 0.06
Nodes (30): bestScore, canRevive, _counted, debugLoad, dismissIntro, dispose, endless, feedback (+22 more)

### Community 8 - "Gerador de fases"
Cohesion: 0.06
Nodes (31): blockColorCount, build, buildBoard, _compose, _cycle, daily, difficulty, gemChance (+23 more)

### Community 9 - "Paleta de cores"
Cohesion: 0.06
Nodes (30): accent, accentDeep, appTitle, backgroundGradient, bgBottom, bgTop, blocks, danger (+22 more)

### Community 10 - "Menu: caminho de fases"
Cohesion: 0.06
Nodes (26): badge, _blocks, build, _card, child, _clock, color, config (+18 more)

### Community 11 - "Desenhos de tabuleiro"
Cohesion: 0.07
Nodes (18): boardPatterns, flipH, flipV, last, transpose, main, shape, attempts (+10 more)

### Community 12 - "Política de anúncios"
Cohesion: 0.07
Nodes (24): AdPolicy, canShowInterstitial, firstLevel, minInterval, sessionGrace, AdCoordinator, AdService, betweenLevels (+16 more)

### Community 13 - "Arrastar peças da bandeja"
Cohesion: 0.07
Nodes (19): _appear, _appearDelay, _center, _dragging, _finger, _grow, layout, _lift (+11 more)

### Community 14 - "Botões e widgets"
Cohesion: 0.08
Nodes (19): big, _body, build, child, color, colors, createState, _down (+11 more)

### Community 15 - "Arte dos blocos"
Cohesion: 0.08
Nodes (21): block, BlockArt, BlockPainter, blocks, BlockSprites, cell, _cellSize, dispose (+13 more)

### Community 16 - "CI e dependências"
Cohesion: 0.12
Nodes (23): CI Workflow (GitHub Actions), Playwright e2e job (screen-size matrix), Flutter job (format, analyze, unit tests, web_test build), web_test build artifact, Dart analyzer config (flutter_lints, excludes), iOS Launch Screen Assets, assets/audio/, flame dependency (+15 more)

### Community 17 - "Testes Playwright"
Cohesion: 0.19
Nodes (18): CHECKER, bestMove(), Box, dragPiece(), fits(), GameState, inside(), linesAfter() (+10 more)

### Community 18 - "App iOS (Swift)"
Cohesion: 0.11
Nodes (6): Flutter, AppDelegate, SceneDelegate, RunnerTests, UIKit, XCTest

### Community 19 - "Ponte de testes"
Cohesion: 0.10
Nodes (13): _cell, controller, dragPath, game, install, instance, kTestBridge, load (+5 more)

### Community 20 - "Prévia de encaixe no tabuleiro"
Cohesion: 0.10
Nodes (15): _clock, col, cols, _glow, inLine, piece, PlacementPreview, pop (+7 more)

### Community 21 - "HUD e cartões da partida"
Cohesion: 0.10
Nodes (19): _AnimatedScore, _DailyWinCard, _GoalChip, _Goals, _Hud, _IntroCard, _LoseCard, _PauseCard (+11 more)

### Community 22 - "Formas das peças"
Cohesion: 0.12
Nodes (14): allShapes, color, cols, id, name, rowMasks, rows, Shape (+6 more)

### Community 23 - "Sons e vibração"
Cohesion: 0.11
Nodes (15): clear, click, _files, GameFeedback, lose, pick, place, _play (+7 more)

### Community 24 - "State"
Cohesion: 0.25
Nodes (8): GameScreen, _GameScreenState, FloatingBlocks, _FloatingBlocksState, LevelPath, _LevelPathState, ChunkyButton, _ChunkyButtonState

### Community 25 - "Gerador de peças"
Cohesion: 0.13
Nodes (12): _attempts, deal, _fallback, _lerp, _lineHelper, _pick, PieceGenerator, rng (+4 more)

### Community 26 - "Pacote dos testes e2e"
Cohesion: 0.14
Nodes (13): description, devDependencies, @playwright/test, @types/node, typescript, name, private, scripts (+5 more)

### Community 27 - "Solver (peças jogáveis)"
Cohesion: 0.18
Nodes (8): apply, bestLines, budget, canPlaceAll, fits, _search, Solver, _spent

### Community 28 - "Manifesto web"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 29 - "sound_web.dart"
Cohesion: 0.06
Nodes (16): loadAll, PlatformSoundPlayer, play, loadAll, play, SoundPlayer, _buffers, _context (+8 more)

### Community 30 - "Gerador de sons"
Cohesion: 0.33
Nodes (3): save(), seq(), tone()

### Community 31 - "Textos das fases"
Cohesion: 0.29
Nodes (4): goalSummary, levelTitle, parts, text

### Community 32 - "Configuração Vercel"
Cohesion: 0.29
Nodes (6): buildCommand, framework, headers, installCommand, outputDirectory, $schema

### Community 33 - "Pintores do menu"
Cohesion: 0.40
Nodes (4): _FloatingPainter, _RoadPainter, _BlockLogoPainter, _GlyphPainter

### Community 34 - "Componentes de texto e luz"
Cohesion: 0.40
Nodes (5): LightBurst, PopText, PraiseBanner, VanishingCell, PositionComponent

### Community 48 - "Bloco a Bloco — instruções para o Claude Code"
Cohesion: 0.50
Nodes (3): Bloco a Bloco — instruções para o Claude Code, Fluxo de trabalho, Pontos de atenção

## Knowledge Gaps
- **545 isolated node(s):** `@types/node`, `typescript`, `XCTest`, `minInterval`, `firstLevel` (+540 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 667 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ProgressStore` connect `Sons e vibração` to `Telas e navegação`, `Política de anúncios`, `Progresso salvo e estatísticas`, `Controlador do jogo`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Bloco a Bloco (block puzzle game)` (e.g. with `flame dependency` and `Flutter web HTML shell (Bloco a Bloco)`) actually correct?**
  _`Bloco a Bloco (block puzzle game)` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `@types/node`, `typescript`, `XCTest` to the rest of the system?**
  _545 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Efeitos visuais e partículas` be split into smaller, more focused modules?**
  _Cohesion score 0.041666666666666664 - nodes in this community are weakly interconnected._
- **Why does `GameController` connect `Controlador (base)` to `Ponte de testes`, `Cena Flame do jogo`, `Tela de partida e cartões`, `Controlador do jogo`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Should `Cena Flame do jogo` be split into smaller, more focused modules?**
  _Cohesion score 0.045454545454545456 - nodes in this community are weakly interconnected._
- **Should `Telas e navegação` be split into smaller, more focused modules?**
  _Cohesion score 0.05603864734299517 - nodes in this community are weakly interconnected._