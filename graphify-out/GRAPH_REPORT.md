# Graph Report - puzzle-blocos  (2026-10-21)

## Corpus Check
- 77 files · ~36,490 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 33 file(s) not represented in the graph (top: .xml 7, (none) 6, .plist 4)

## Summary
- 1137 nodes · 1456 edges · 63 communities (49 shown, 14 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `639ec105`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Efeitos visuais e partículas
- Cena Flame do jogo
- package:flutter/material.dart
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
- capi_carrier.dart
- State
- Gerador de peças
- Pacote dos testes e2e
- Solver (peças jogáveis)
- Manifesto web
- sound_web.dart
- Gerador de sons
- village_screen.dart
- Configuração Vercel
- Pintores do menu
- Componentes de texto e luz
- TrayPiece
- App Android
- capi.dart
- Princípios de dificuldade
- Script de build Vercel
- home_screen.dart
- main.dart
- serve.py
- Bloco a Bloco — instruções para o Claude Code
- flutter_bootstrap.js
- tutorial.dart
- root.dart
- hint_hand.dart
- village.dart
- board.dart
- static const
- onboarding_test.dart
- feedback.dart
- PuzzleGame
- bridge_web.dart
- sound_player.dart
- sound_native.dart
- GameController

## God Nodes (most connected - your core abstractions)
1. `state()` - 10 edges
2. `Bloco a Bloco (block puzzle game)` - 10 edges
3. `waitForState()` - 9 edges
4. `@playwright/test` - 8 edges
5. `puzzle_blocos package manifest` - 7 edges
6. `openApp()` - 6 edges
7. `playMove()` - 6 edges
8. `snap()` - 6 edges
9. `PositionComponent` - 6 edges
10. `AppServices` - 6 edges

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

## Communities (63 total, 14 thin omitted)

### Community 0 - "Efeitos visuais e partículas"
Cohesion: 0.04
Nodes (45): age, area, burst, c1, cellSize, color, colors, confetti (+37 more)

### Community 1 - "Cena Flame do jogo"
Cohesion: 0.04
Nodes (36): activeDrag, _announce, _announcePending, _avgCell, backgroundColor, boardRect, boardView, _celebrate (+28 more)

### Community 2 - "package:flutter/material.dart"
Cohesion: 0.15
Nodes (10): AppServices, build, createState, services, showModalBottomSheet, showSettings, showModalBottomSheet, showStats (+2 more)

### Community 3 - "Tela de partida e cartões"
Cohesion: 0.04
Nodes (51): Intro, best, _bodyStyle, build, _busy, canRevive, color, controller (+43 more)

### Community 4 - "Progresso salvo e estatísticas"
Cohesion: 0.05
Nodes (36): addStars, adsRemoved, bestCombo, bestScore, completeDaily, dailyDone, dailyStreak, dayKey (+28 more)

### Community 5 - "Tabuleiro e células"
Cohesion: 0.05
Nodes (40): after, at, before, block, Board, canPlace, Cell, _cells (+32 more)

### Community 6 - "Sessão de jogo (regras)"
Cohesion: 0.05
Nodes (35): bestCombo, bestLines, _bits, board, boardClearBonus, boardCleared, canPlace, combo (+27 more)

### Community 7 - "Controlador do jogo"
Cohesion: 0.03
Nodes (59): _afterTutorialMove, _awardLevelStars, bestScore, canRevive, capiCheer, capiLine, CapiReaction, capiSays (+51 more)

### Community 8 - "Gerador de fases"
Cohesion: 0.06
Nodes (31): blockColorCount, build, buildBoard, _compose, _cycle, daily, difficulty, gemChance (+23 more)

### Community 9 - "Paleta de cores"
Cohesion: 0.05
Nodes (34): bit, count, daily, doubleClearUntil, earned, forEndless, has, Mission (+26 more)

### Community 10 - "Menu: caminho de fases"
Cohesion: 0.06
Nodes (26): badge, _blocks, build, _card, child, _clock, color, config (+18 more)

### Community 11 - "Desenhos de tabuleiro"
Cohesion: 0.07
Nodes (18): boardPatterns, flipH, flipV, last, transpose, main, shape, attempts (+10 more)

### Community 12 - "Política de anúncios"
Cohesion: 0.05
Nodes (33): AdPolicy, canShowInterstitial, firstLevel, minInterval, sessionGrace, AdService, betweenLevels, build (+25 more)

### Community 13 - "Arrastar peças da bandeja"
Cohesion: 0.08
Nodes (19): _appear, _appearDelay, _center, _dragging, _finger, _grow, layout, _lift (+11 more)

### Community 14 - "Botões e widgets"
Cohesion: 0.06
Nodes (27): animate, big, _body, build, _c, _capi, child, color (+19 more)

### Community 15 - "Arte dos blocos"
Cohesion: 0.06
Nodes (25): block, BlockArt, BlockPainter, blocks, BlockSprites, cell, _cellSize, dispose (+17 more)

### Community 16 - "CI e dependências"
Cohesion: 0.12
Nodes (23): CI Workflow (GitHub Actions), Playwright e2e job (screen-size matrix), Flutter job (format, analyze, unit tests, web_test build), web_test build artifact, Dart analyzer config (flutter_lints, excludes), iOS Launch Screen Assets, assets/audio/, flame dependency (+15 more)

### Community 17 - "Testes Playwright"
Cohesion: 0.19
Nodes (21): CHECKER, bestMove(), Box, dragPiece(), fits(), GameState, inside(), linesAfter() (+13 more)

### Community 18 - "App iOS (Swift)"
Cohesion: 0.11
Nodes (6): Flutter, AppDelegate, SceneDelegate, RunnerTests, UIKit, XCTest

### Community 19 - "Ponte de testes"
Cohesion: 0.10
Nodes (14): _cell, controller, dragPath, game, install, instance, kTestBridge, load (+6 more)

### Community 20 - "Prévia de encaixe no tabuleiro"
Cohesion: 0.11
Nodes (15): _clock, col, cols, _glow, inLine, piece, PlacementPreview, pop (+7 more)

### Community 21 - "HUD e cartões da partida"
Cohesion: 0.08
Nodes (23): _AnimatedScore, _CapiPopUp, _DailyWinCard, _GoalChip, _Goals, _Hud, _IntroCard, _LoseCard (+15 more)

### Community 22 - "Formas das peças"
Cohesion: 0.12
Nodes (14): allShapes, color, cols, id, name, rowMasks, rows, Shape (+6 more)

### Community 23 - "capi_carrier.dart"
Cohesion: 0.17
Nodes (8): _bubble, _bubbleText, _drawBubble, _drawPiece, _loop, render, _t, update

### Community 24 - "State"
Cohesion: 0.12
Nodes (22): _FakeAd, _FakeAdState, GameScreen, _GameScreenState, HomeScreen, _HomeScreenState, Root, _RootState (+14 more)

### Community 25 - "Gerador de peças"
Cohesion: 0.13
Nodes (12): _attempts, deal, _fallback, _lerp, _lineHelper, _pick, PieceGenerator, rng (+4 more)

### Community 26 - "Pacote dos testes e2e"
Cohesion: 0.14
Nodes (13): description, devDependencies, @playwright/test, @types/node, typescript, name, private, scripts (+5 more)

### Community 27 - "Solver (peças jogáveis)"
Cohesion: 0.20
Nodes (8): apply, bestLines, budget, canPlaceAll, fits, _search, Solver, _spent

### Community 28 - "Manifesto web"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 29 - "sound_web.dart"
Cohesion: 0.18
Nodes (6): _buffers, _context, _ctx, _decode, loadAll, play

### Community 30 - "Gerador de sons"
Cohesion: 0.33
Nodes (3): save(), seq(), tone()

### Community 31 - "village_screen.dart"
Cohesion: 0.10
Nodes (17): _Bubble, _build, _built, createState, dispose, _done, _idleLine, initState (+9 more)

### Community 32 - "Configuração Vercel"
Cohesion: 0.29
Nodes (6): buildCommand, framework, headers, installCommand, outputDirectory, $schema

### Community 33 - "Pintores do menu"
Cohesion: 0.29
Nodes (6): _BubblePainter, CapiPainter, _FloatingPainter, _RoadPainter, _BlockLogoPainter, _GlyphPainter

### Community 34 - "Componentes de texto e luz"
Cohesion: 0.40
Nodes (5): LightBurst, PopText, PraiseBanner, VanishingCell, PositionComponent

### Community 35 - "TrayPiece"
Cohesion: 0.28
Nodes (6): BoardView, CapiCarrier, ScreenFlash, Sparks, HintHand, TrayPiece

### Community 37 - "capi.dart"
Cohesion: 0.06
Nodes (29): action, _arm, _block, _bob, _bodyBottom, _bodyTop, build, CapiMood (+21 more)

### Community 40 - "home_screen.dart"
Cohesion: 0.10
Nodes (14): build, _capiLine, createState, _dismissCapi, _hint, _locked, _news, _open (+6 more)

### Community 41 - "main.dart"
Cohesion: 0.13
Nodes (9): AdCoordinator, ads, App, build, feedback, main, services, setPreferredOrientations (+1 more)

### Community 48 - "Bloco a Bloco — instruções para o Claude Code"
Cohesion: 0.50
Nodes (3): CapiBlocks — instruções para o Claude Code, Fluxo de trabalho, Pontos de atenção

### Community 50 - "tutorial.dart"
Cohesion: 0.17
Nodes (10): board, done, needLines, piece, retry, say, steps, target (+2 more)

### Community 51 - "root.dart"
Cohesion: 0.20
Nodes (4): _advance, build, createState, services

### Community 52 - "hint_hand.dart"
Cohesion: 0.22
Nodes (4): _loop, render, _t, update

### Community 53 - "village.dart"
Cohesion: 0.12
Nodes (13): asset, background, capiFeet, cost, drawn, id, items, name (+5 more)

### Community 55 - "static const"
Cohesion: 0.22
Nodes (6): body, bodyText, display, displayText, Fonts, textDrop

### Community 56 - "onboarding_test.dart"
Cohesion: 0.14
Nodes (5): main, main, main, main, main

### Community 57 - "feedback.dart"
Cohesion: 0.11
Nodes (15): clear, click, _files, GameFeedback, lose, pick, place, _play (+7 more)

### Community 59 - "bridge_web.dart"
Cohesion: 0.22
Nodes (3): installJsBridge, api, installJsBridge

### Community 60 - "sound_player.dart"
Cohesion: 0.25
Nodes (5): PlatformSoundPlayer, loadAll, play, SoundPlayer, PlatformSoundPlayer

## Knowledge Gaps
- **724 isolated node(s):** `@types/node`, `typescript`, `XCTest`, `minInterval`, `firstLevel` (+719 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 852 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ProgressStore` connect `feedback.dart` to `main.dart`, `Política de anúncios`, `Progresso salvo e estatísticas`, `Controlador do jogo`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **What connects `@types/node`, `typescript`, `XCTest` to the rest of the system?**
  _724 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Efeitos visuais e partículas` be split into smaller, more focused modules?**
  _Cohesion score 0.0425531914893617 - nodes in this community are weakly interconnected._
- **Why does `GameController` connect `GameController` to `Ponte de testes`, `Cena Flame do jogo`, `Tela de partida e cartões`, `Controlador do jogo`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Should `Cena Flame do jogo` be split into smaller, more focused modules?**
  _Cohesion score 0.043478260869565216 - nodes in this community are weakly interconnected._
- **Why does `TrayPiece` connect `TrayPiece` to `Cena Flame do jogo`, `Componentes de texto e luz`, `Arrastar peças da bandeja`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Should `Tela de partida e cartões` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._