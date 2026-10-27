# Graph Report - puzzle-blocos  (2026-10-27)

## Corpus Check
- 124 files · ~94,235 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 44 file(s) not represented in the graph (top: .vectorcraft 14, .xml 7, (none) 6)

## Summary
- 1933 nodes · 2541 edges · 102 communities (84 shown, 18 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `47e5780a`
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
- 1. Visão Geral do Projeto e Mecânicas Desenvolvidas
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
- MainActivity.kt
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
- ad_config.dart
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
- loja_capturas.js
- web_url.dart
- web_url_web.dart
- GameController
- Respostas Sugeridas para os Formulários da Google Play Console — CapiBlocks
- 1. Dados Básicos da Ficha
- web_url_stub.dart
- settings_sheet.dart
- privacy_dialog.dart
- generate_banner.js
- generate_hats_missions_art.js
- generate_tool_art.js
- ref_path
- generate_tower_art.js
- Publicação Android (Google Play)
- TowerController

## God Nodes (most connected - your core abstractions)
1. `state()` - 15 edges
2. `@playwright/test` - 14 edges
3. `waitForState()` - 14 edges
4. `ItemArt` - 13 edges
5. `openApp()` - 12 edges
6. `AppServices` - 10 edges
7. `ProgressStore` - 10 edges
8. `Bloco a Bloco (block puzzle game)` - 10 edges
9. `snap()` - 7 edges
10. `main()` - 7 edges

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

## Communities (102 total, 18 thin omitted)

### Community 0 - "Efeitos visuais e partículas"
Cohesion: 0.04
Nodes (45): age, area, burst, c1, cellSize, color, colors, confetti (+37 more)

### Community 1 - "Cena Flame do jogo"
Cohesion: 0.04
Nodes (39): activeDrag, _announce, _announcePending, _avgCell, backgroundColor, boardRect, boardView, _celebrate (+31 more)

### Community 2 - "package:flutter/material.dart"
Cohesion: 0.11
Nodes (14): showModalBottomSheet, showStats, store, tiles, build, createState, _cycleMood, _equip (+6 more)

### Community 3 - "Tela de partida e cartões"
Cohesion: 0.03
Nodes (69): best, _bodyStyle, build, _buildToolCard, _buildToolModeOverlay, _busy, canRevive, color (+61 more)

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
Nodes (29): badge, _blocks, build, _card, child, _clock, color, compact (+21 more)

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
Nodes (34): animate, badge, big, _body, build, _c, _capi, CardPanel (+26 more)

### Community 15 - "Arte dos blocos"
Cohesion: 0.08
Nodes (22): block, BlockArt, BlockPainter, blocks, BlockSprites, cell, _cellSize, dispose (+14 more)

### Community 16 - "CI e dependências"
Cohesion: 0.12
Nodes (23): CI Workflow (GitHub Actions), Playwright e2e job (screen-size matrix), Flutter job (format, analyze, unit tests, web_test build), web_test build artifact, Dart analyzer config (flutter_lints, excludes), iOS Launch Screen Assets, assets/audio/, flame dependency (+15 more)

### Community 17 - "Testes Playwright"
Cohesion: 0.18
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
Cohesion: 0.12
Nodes (12): _bubble, _bubbleText, _drawBubble, _drawPiece, _loop, render, _t, update (+4 more)

### Community 24 - "1. Visão Geral do Projeto e Mecânicas Desenvolvidas"
Cohesion: 0.11
Nodes (17): 1. Visão Geral do Projeto e Mecânicas Desenvolvidas, 2. Presença Digital e Identidade da Empresa, 3. Materiais Visuais e de Marketing (Google Play Store), 4. Polimento Técnico e Preparação de Produção, 5. Publicação no Google Play Console, 6. Próximos Passos (Pós-Aprovação na Loja), A. Política de Privacidade In-App (Offline & Web), B. Nuvem & Conquistas (removido na v1.0.1) (+9 more)

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
Cohesion: 0.25
Nodes (7): buildCommand, cleanUrls, framework, headers, installCommand, outputDirectory, $schema

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
Nodes (31): action, _arm, _block, _bob, _bodyBottom, _bodyTop, build, CapiSays (+23 more)

### Community 40 - "home_screen.dart"
Cohesion: 0.07
Nodes (23): _blitzCard, build, _capiLine, createState, _dismissCapi, _duelCard, _hint, _locked (+15 more)

### Community 41 - "main.dart"
Cohesion: 0.13
Nodes (9): AdCoordinator, ads, App, build, feedback, main, services, setPreferredOrientations (+1 more)

### Community 48 - "Bloco a Bloco — instruções para o Claude Code"
Cohesion: 0.40
Nodes (4): CapiBlocks — instruções para o Claude Code, Fluxo de trabalho, Pontos de atenção, Publicação e Lojas (Google Play Store)

### Community 50 - "tutorial.dart"
Cohesion: 0.17
Nodes (10): board, done, needLines, piece, retry, say, steps, target (+2 more)

### Community 51 - "root.dart"
Cohesion: 0.15
Nodes (6): _advance, build, _challengeOpen, createState, initState, services

### Community 52 - "ad_config.dart"
Cohesion: 0.14
Nodes (10): AdConfig, prodAndroidInterstitial, prodAndroidRewarded, prodIosInterstitial, prodIosRewarded, testAndroidInterstitial, testAndroidRewarded, testIosInterstitial (+2 more)

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
Cohesion: 0.11
Nodes (16): blueprint, canPlace, cellsOf, debugSolve, filled, hints, line, pieceAt (+8 more)

### Community 69 - "pup.dart"
Cohesion: 0.11
Nodes (17): body, bow, bows, build, face, _fur, _furBottom, _furTop (+9 more)

### Community 70 - "blueprint.dart"
Cohesion: 0.11
Nodes (15): Blueprint, Blueprints, blueprintStars, cells, colors, forItem, help, id (+7 more)

### Community 71 - "pup_rescue.dart"
Cohesion: 0.12
Nodes (10): cell, delay, from, _heart, _life, render, _t, to (+2 more)

### Community 72 - "tower_controller.dart"
Cohesion: 0.04
Nodes (43): baseSize, bestHeight, blockDz, blocks, cameraZ, colorIndex, combo, currentDx (+35 more)

### Community 73 - "generate_blitz_duel_art.js"
Cohesion: 0.25
Nodes (7): artDir, blitzDir, dueloDir, { execSync }, fs, jobs, path

### Community 74 - "daily_missions.dart"
Cohesion: 0.07
Nodes (23): chestStarsReward, claimChest, claimMission, _createMission, DailyMission, DailyMissionsManager, DailyMissionType, description (+15 more)

### Community 75 - "onboarding.dart"
Cohesion: 0.10
Nodes (20): blitzAt, blitzUnlocked, dailyAt, dailyUnlocked, duelAt, duelUnlocked, endlessAt, endlessUnlocked (+12 more)

### Community 76 - "tower_screen.dart"
Cohesion: 0.12
Nodes (11): build, _controller, createState, dispose, _exit, initState, _lastTick, _onTap (+3 more)

### Community 77 - "tool_painter.dart"
Cohesion: 0.13
Nodes (14): CapiTool, build, _drawOrbitBlock, HammerPainter, _outlineColor, paint, RerollPainter, RotatePainter (+6 more)

### Community 78 - "tower_painter.dart"
Cohesion: 0.13
Nodes (12): build, controller, _drawFloorLabel, _drawIsoBox, _drawMiniCapi, paint, shouldRepaint, size (+4 more)

### Community 79 - "daily_missions_dialog.dart"
Cohesion: 0.13
Nodes (9): build, _buildMissionCard, _claimChest, _claimMission, createState, services, show, _today (+1 more)

### Community 80 - "State"
Cohesion: 0.10
Nodes (30): _FakeAd, _FakeAdState, DailyMissionsDialog, _DailyMissionsDialogState, GameScreen, _GameScreenState, _ToolsSheet, _ToolsSheetState (+22 more)

### Community 81 - "missions_hats_painters.dart"
Cohesion: 0.18
Nodes (8): build, ChestIcon, hat, HatPreviewItem, HatWardrobeIcon, MissionsIcon, open, size

### Community 82 - "../services/progress_store.dart"
Cohesion: 0.22
Nodes (7): CapiHat, description, fromId, id, isEquipped, isUnlocked, label

### Community 83 - "blitz_duel_painter.dart"
Cohesion: 0.22
Nodes (8): BlitzIcon, BlitzIconPainter, build, DuelIcon, DuelIconPainter, paint, shouldRepaint, size

### Community 84 - "loja_capturas.js"
Cohesion: 0.23
Nodes (12): { chromium }, composeAndSave(), dragObraPiece(), dragTrayPiece(), fs, main(), openWithState(), path (+4 more)

### Community 86 - "web_url_web.dart"
Cohesion: 0.40
Nodes (3): clearUrlQuery, openExternalUrl, path

### Community 88 - "Respostas Sugeridas para os Formulários da Google Play Console — CapiBlocks"
Cohesion: 0.17
Nodes (11): 1. Segurança dos Dados (Data Safety), 2. Classificação de Conteúdo (Questionário IARC), 3. Público-Alvo e Conteúdo (Target Audience), 4. Anúncios (App Content - Ads), 5. Acesso ao Aplicativo (App Access), 6. Notícias e Apps Governamentais, 📌 Cenário A: Versão Atual (Sem AdMob Real, anúncios simulados), 📌 Cenário B: Versão de Produção com Google AdMob Integrado (+3 more)

### Community 89 - "1. Dados Básicos da Ficha"
Cohesion: 0.17
Nodes (11): 1. Dados Básicos da Ficha, 2. Descrição Completa, 3. O que Destacar e o que Evitar, Categoria e Classificação, Contato de Suporte na Loja, Descrição Curta, Nome do Aplicativo, ✅ O que foi destacado: (+3 more)

### Community 91 - "settings_sheet.dart"
Cohesion: 0.20
Nodes (7): AppServices, build, createState, _openPrivacy, services, showModalBottomSheet, showSettings

### Community 92 - "privacy_dialog.dart"
Cohesion: 0.20
Nodes (6): build, onOpenWeb, _PrivacySheet, _section, showModalBottomSheet, showPrivacyDialog

### Community 93 - "generate_banner.js"
Cohesion: 0.25
Nodes (3): { chromium }, fs, path

### Community 94 - "generate_hats_missions_art.js"
Cohesion: 0.25
Nodes (7): artDir, { execSync }, fs, hatsDir, jobs, missionsDir, path

### Community 95 - "generate_tool_art.js"
Cohesion: 0.29
Nodes (5): { execSync }, files, fs, path, toolsDir

### Community 96 - "ref_path"
Cohesion: 0.29
Nodes (3): { chromium }, fs, path

### Community 97 - "generate_tower_art.js"
Cohesion: 0.29
Nodes (6): artDir, { execSync }, fs, jobs, path, towerDir

### Community 98 - "Publicação Android (Google Play)"
Cohesion: 0.33
Nodes (5): Build no seu computador (opcional), Chave de envio (upload key), Identificador do app, Publicação Android (Google Play), Versão

### Community 99 - "TowerController"
Cohesion: 0.50
Nodes (4): place, reset, TowerBlock, TowerController

## Knowledge Gaps
- **1263 isolated node(s):** `@types/node`, `typescript`, `XCTest`, `AdConfig`, `useTestAds` (+1258 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1486 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **18 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ProgressStore` connect `simulate.dart` to `Tela de partida e cartões`, `Progresso salvo e estatísticas`, `Controlador do jogo`, `tower_controller.dart`, `main.dart`, `Política de anúncios`, `Ponte de testes`, `feedback.dart`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **What connects `@types/node`, `typescript`, `XCTest` to the rest of the system?**
  _1263 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Efeitos visuais e partículas` be split into smaller, more focused modules?**
  _Cohesion score 0.043478260869565216 - nodes in this community are weakly interconnected._
- **Why does `CapiTool` connect `tool_painter.dart` to `Tela de partida e cartões`, `Progresso salvo e estatísticas`, `Controlador do jogo`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Should `Cena Flame do jogo` be split into smaller, more focused modules?**
  _Cohesion score 0.04081632653061224 - nodes in this community are weakly interconnected._
- **Why does `GameFeedback` connect `simulate.dart` to `tower_controller.dart`, `main.dart`, `feedback.dart`, `Controlador do jogo`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Should `package:flutter/material.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.11052631578947368 - nodes in this community are weakly interconnected._