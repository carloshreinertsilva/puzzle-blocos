# Graph Report - puzzle-blocos  (2026-10-23)

## Corpus Check
- 112 files · ~85,087 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 44 file(s) not represented in the graph (top: .vectorcraft 14, .xml 7, (none) 6)

## Summary
- 1821 nodes · 2412 edges · 91 communities (71 shown, 20 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1e1aa02d`
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
- simulate.dart
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
- SingleTickerProviderStateMixin
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
- scene.dart
- board.dart
- static const
- village.dart
- feedback.dart
- PuzzleGame
- bridge_web.dart
- sound_player.dart
- sound_native.dart
- obra_screen.dart
- items.dart
- iso.dart
- missions.dart
- level_text.dart
- dart:math
- obra_controller.dart
- pup.dart
- blueprint.dart
- pup_rescue.dart
- tower_controller.dart
- generate_blitz_duel_art.js
- daily_missions.dart
- onboarding.dart
- tower_screen.dart
- tool_painter.dart
- tower_painter.dart
- daily_missions_dialog.dart
- State
- missions_hats_painters.dart
- ../services/progress_store.dart
- blitz_duel_painter.dart
- dart:ui
- web_url.dart
- web_url_web.dart
- GameController
- GameScreen
- _ToolsSheet
- web_url_stub.dart

## God Nodes (most connected - your core abstractions)
1. `state()` - 15 edges
2. `waitForState()` - 14 edges
3. `@playwright/test` - 13 edges
4. `ItemArt` - 13 edges
5. `openApp()` - 11 edges
6. `AppServices` - 10 edges
7. `ProgressStore` - 10 edges
8. `Bloco a Bloco (block puzzle game)` - 10 edges
9. `snap()` - 7 edges
10. `puzzle_blocos package manifest` - 7 edges

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

## Communities (91 total, 20 thin omitted)

### Community 0 - "Efeitos visuais e partículas"
Cohesion: 0.04
Nodes (45): age, area, burst, c1, cellSize, color, colors, confetti (+37 more)

### Community 1 - "Cena Flame do jogo"
Cohesion: 0.04
Nodes (39): activeDrag, _announce, _announcePending, _avgCell, backgroundColor, boardRect, boardView, _celebrate (+31 more)

### Community 2 - "package:flutter/material.dart"
Cohesion: 0.10
Nodes (20): AppServices, build, createState, services, showModalBottomSheet, showSettings, showModalBottomSheet, showStats (+12 more)

### Community 3 - "Tela de partida e cartões"
Cohesion: 0.03
Nodes (67): best, _bodyStyle, build, _buildToolCard, _buildToolModeOverlay, _busy, canRevive, color (+59 more)

### Community 4 - "Progresso salvo e estatísticas"
Cohesion: 0.03
Nodes (74): actionPrompt, addStars, addStarsCapped, addTool, adsRemoved, bestCombo, bestScore, blitzBestScore (+66 more)

### Community 5 - "Tabuleiro e células"
Cohesion: 0.04
Nodes (45): after, at, before, block, Board, breakArea3x3, breakCell, canPlace (+37 more)

### Community 6 - "Sessão de jogo (regras)"
Cohesion: 0.04
Nodes (43): bestCombo, bestLines, _bits, board, boardClearBonus, boardCleared, canBreakCell, canPlace (+35 more)

### Community 7 - "Controlador do jogo"
Cohesion: 0.02
Nodes (82): activeToolMode, _afterTutorialMove, _awardLevelStars, bestScore, blitzSecondsLeft, _blitzTimer, cancelToolMode, canRevive (+74 more)

### Community 8 - "Gerador de fases"
Cohesion: 0.05
Nodes (37): blockColorCount, build, buildBoard, _compose, _cycle, daily, difficulty, gemChance (+29 more)

### Community 9 - "Paleta de cores"
Cohesion: 0.08
Nodes (24): accent, accentDeep, appTitle, backgroundGradient, bgBottom, bgTop, blocks, danger (+16 more)

### Community 10 - "Menu: caminho de fases"
Cohesion: 0.06
Nodes (31): badge, _blocks, build, _card, child, _clock, color, compact (+23 more)

### Community 11 - "simulate.dart"
Cohesion: 0.05
Nodes (29): GameFeedback, ProgressStore, main, main, covered, expectSolved, main, main (+21 more)

### Community 12 - "Política de anúncios"
Cohesion: 0.07
Nodes (25): AdPolicy, canShowInterstitial, firstLevel, minInterval, sessionGrace, AdService, betweenLevels, build (+17 more)

### Community 13 - "Arrastar peças da bandeja"
Cohesion: 0.08
Nodes (19): _appear, _appearDelay, _center, _dragging, _finger, _grow, layout, _lift (+11 more)

### Community 14 - "Botões e widgets"
Cohesion: 0.06
Nodes (33): animate, badge, big, _body, build, _c, _capi, child (+25 more)

### Community 15 - "Arte dos blocos"
Cohesion: 0.08
Nodes (22): block, BlockArt, BlockPainter, blocks, BlockSprites, cell, _cellSize, dispose (+14 more)

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
Cohesion: 0.06
Nodes (25): addTool, _cell, claimDailyChest, controller, dragPath, equipHat, game, install (+17 more)

### Community 20 - "Prévia de encaixe no tabuleiro"
Cohesion: 0.11
Nodes (15): _clock, col, cols, _glow, inLine, piece, PlacementPreview, pop (+7 more)

### Community 21 - "HUD e cartões da partida"
Cohesion: 0.08
Nodes (25): _ActiveToolBanner, _AnimatedScore, _BlitzTimerChip, _BlitzWinCard, _CapiPopUp, _DailyWinCard, _DuelOutcomeCard, _DuelTargetChip (+17 more)

### Community 22 - "Formas das peças"
Cohesion: 0.12
Nodes (15): allShapes, color, cols, id, name, rotateShape, rowMasks, rows (+7 more)

### Community 23 - "capi_carrier.dart"
Cohesion: 0.17
Nodes (8): _bubble, _bubbleText, _drawBubble, _drawPiece, _loop, render, _t, update

### Community 24 - "SingleTickerProviderStateMixin"
Cohesion: 0.22
Nodes (8): ObraScreen, _ObraScreenState, FloatingBlocks, _FloatingBlocksState, LevelPath, _LevelPathState, StarRow, _StarRowState

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
Cohesion: 0.20
Nodes (6): _buffers, _context, _ctx, _decode, loadAll, play

### Community 30 - "Gerador de sons"
Cohesion: 0.33
Nodes (3): save(), seq(), tone()

### Community 31 - "village_screen.dart"
Cohesion: 0.06
Nodes (26): _Bubble, _build, _built, _cache, _capiLines, _clock, createState, dispose (+18 more)

### Community 32 - "Configuração Vercel"
Cohesion: 0.29
Nodes (6): buildCommand, framework, headers, installCommand, outputDirectory, $schema

### Community 33 - "Pintores do menu"
Cohesion: 0.14
Nodes (13): _BlueprintPainter, _PiecePainter, _BubblePainter, CapiPainter, _FloatingPainter, _RoadPainter, PupPainter, ShovelPainter (+5 more)

### Community 34 - "Componentes de texto e luz"
Cohesion: 0.40
Nodes (5): LightBurst, PopText, PraiseBanner, VanishingCell, PositionComponent

### Community 35 - "TrayPiece"
Cohesion: 0.24
Nodes (7): BoardView, CapiCarrier, ScreenFlash, Sparks, HintHand, PupRescue, TrayPiece

### Community 37 - "capi.dart"
Cohesion: 0.06
Nodes (32): action, _arm, _block, _bob, _bodyBottom, _bodyTop, build, Capi (+24 more)

### Community 40 - "home_screen.dart"
Cohesion: 0.06
Nodes (23): _blitzCard, build, _capiLine, createState, _dismissCapi, _duelCard, _hint, _locked (+15 more)

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
Cohesion: 0.14
Nodes (8): _advance, build, _challengeOpen, createState, initState, Root, _RootState, services

### Community 52 - "hint_hand.dart"
Cohesion: 0.25
Nodes (4): _loop, render, _t, update

### Community 53 - "scene.dart"
Cohesion: 0.02
Nodes (91): alt, at, bank, _base, bounds, build, _buildBurst, building (+83 more)

### Community 55 - "static const"
Cohesion: 0.22
Nodes (6): body, bodyText, display, displayText, Fonts, textDrop

### Community 56 - "village.dart"
Cohesion: 0.17
Nodes (10): capiSpot, cost, id, island, items, name, next, spot (+2 more)

### Community 57 - "feedback.dart"
Cohesion: 0.12
Nodes (13): clear, click, _files, lose, pick, place, _play, praise (+5 more)

### Community 59 - "bridge_web.dart"
Cohesion: 0.22
Nodes (3): installJsBridge, api, installJsBridge

### Community 60 - "sound_player.dart"
Cohesion: 0.25
Nodes (5): PlatformSoundPlayer, loadAll, play, SoundPlayer, PlatformSoundPlayer

### Community 62 - "obra_screen.dart"
Cohesion: 0.06
Nodes (32): _anchor, _board, _boardCell, _boardKey, _body, build, _card, _cellAt (+24 more)

### Community 63 - "items.dart"
Cohesion: 0.06
Nodes (41): _aFrame, animated, _bark, _Bench, _Boat, _brick, _canopy, _colors (+33 more)

### Community 64 - "iso.dart"
Cohesion: 0.06
Nodes (28): at, ball, beam, box, boxShadow, canvas, cone, cylinder (+20 more)

### Community 65 - "missions.dart"
Cohesion: 0.18
Nodes (10): bit, count, daily, doubleClearUntil, earned, forEndless, has, Mission (+2 more)

### Community 66 - "level_text.dart"
Cohesion: 0.29
Nodes (4): goalSummary, levelTitle, parts, text

### Community 67 - "dart:math"
Cohesion: 0.29
Nodes (5): boardPatterns, flipH, flipV, last, transpose

### Community 68 - "obra_controller.dart"
Cohesion: 0.10
Nodes (16): blueprint, canPlace, cellsOf, debugSolve, filled, hints, line, pieceAt (+8 more)

### Community 69 - "pup.dart"
Cohesion: 0.11
Nodes (17): body, bow, bows, build, face, _fur, _furBottom, _furTop (+9 more)

### Community 70 - "blueprint.dart"
Cohesion: 0.11
Nodes (15): Blueprint, Blueprints, blueprintStars, cells, colors, forItem, help, id (+7 more)

### Community 71 - "pup_rescue.dart"
Cohesion: 0.17
Nodes (9): cell, delay, from, _heart, _life, render, _t, to (+1 more)

### Community 72 - "tower_controller.dart"
Cohesion: 0.04
Nodes (47): baseSize, bestHeight, blockDz, blocks, cameraZ, colorIndex, combo, currentDx (+39 more)

### Community 73 - "generate_blitz_duel_art.js"
Cohesion: 0.07
Nodes (25): artDir, blitzDir, dueloDir, { execSync }, fs, jobs, path, artDir (+17 more)

### Community 74 - "daily_missions.dart"
Cohesion: 0.07
Nodes (23): chestStarsReward, claimChest, claimMission, _createMission, DailyMission, DailyMissionsManager, DailyMissionType, description (+15 more)

### Community 75 - "onboarding.dart"
Cohesion: 0.10
Nodes (20): blitzAt, blitzUnlocked, dailyAt, dailyUnlocked, duelAt, duelUnlocked, endlessAt, endlessUnlocked (+12 more)

### Community 76 - "tower_screen.dart"
Cohesion: 0.12
Nodes (13): build, _controller, createState, dispose, _exit, initState, _lastTick, _onTap (+5 more)

### Community 77 - "tool_painter.dart"
Cohesion: 0.13
Nodes (14): CapiTool, build, _drawOrbitBlock, HammerPainter, _outlineColor, paint, RerollPainter, RotatePainter (+6 more)

### Community 78 - "tower_painter.dart"
Cohesion: 0.13
Nodes (12): build, controller, _drawFloorLabel, _drawIsoBox, _drawMiniCapi, paint, shouldRepaint, size (+4 more)

### Community 79 - "daily_missions_dialog.dart"
Cohesion: 0.17
Nodes (8): build, _buildMissionCard, _claimChest, _claimMission, createState, services, show, _today

### Community 80 - "State"
Cohesion: 0.23
Nodes (10): DailyMissionsDialog, _DailyMissionsDialogState, HomeScreen, _HomeScreenState, _Settings, _SettingsState, VillageScreen, _VillageScreenState (+2 more)

### Community 81 - "missions_hats_painters.dart"
Cohesion: 0.18
Nodes (8): build, ChestIcon, hat, HatPreviewItem, HatWardrobeIcon, MissionsIcon, open, size

### Community 82 - "../services/progress_store.dart"
Cohesion: 0.22
Nodes (7): CapiHat, description, fromId, id, isEquipped, isUnlocked, label

### Community 83 - "blitz_duel_painter.dart"
Cohesion: 0.22
Nodes (8): BlitzIcon, BlitzIconPainter, build, DuelIcon, DuelIconPainter, paint, shouldRepaint, size

## Knowledge Gaps
- **1240 isolated node(s):** `@types/node`, `typescript`, `XCTest`, `minInterval`, `firstLevel` (+1235 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1405 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **20 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ProgressStore` connect `simulate.dart` to `Tela de partida e cartões`, `Progresso salvo e estatísticas`, `Controlador do jogo`, `tower_controller.dart`, `main.dart`, `Política de anúncios`, `Ponte de testes`, `feedback.dart`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **What connects `@types/node`, `typescript`, `XCTest` to the rest of the system?**
  _1240 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Efeitos visuais e partículas` be split into smaller, more focused modules?**
  _Cohesion score 0.043478260869565216 - nodes in this community are weakly interconnected._
- **Why does `PlatformSoundPlayer` connect `sound_player.dart` to `sound_web.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Should `Cena Flame do jogo` be split into smaller, more focused modules?**
  _Cohesion score 0.04081632653061224 - nodes in this community are weakly interconnected._
- **Should `package:flutter/material.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.09523809523809523 - nodes in this community are weakly interconnected._
- **Should `Tela de partida e cartões` be split into smaller, more focused modules?**
  _Cohesion score 0.028169014084507043 - nodes in this community are weakly interconnected._