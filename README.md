# CapiBlocks

Jogo de quebra-cabeça de blocos para Android e iOS (Flutter + Flame), com o
Capi, a capivara construtora, como mascote. O nome aparece em `appTitle`
(`lib/ui/palette.dart`), `web/index.html`, `web/manifest.json`,
`android/app/src/main/AndroidManifest.xml` e `ios/Runner/Info.plist`; o
pacote Dart e o repositório continuam `puzzle_blocos`.

Tabuleiro 8x8, três peças por rodada, linhas e colunas completas somem. Modos:

- **Fases**, com metas (pontos, quebrar pedras, coletar gemas), tabuleiros que
  começam com desenhos e dificuldade crescente; o menu mostra o caminho de fases.
- **Desafio diário**, igual para todo mundo no mesmo dia, com sequência de dias.
- **Infinito**, com recorde.

Começo do jogo (`lib/game/onboarding.dart`, `lib/game/tutorial.dart`): quem
abre pela primeira vez cai direto no tabuleiro, e o **Capi** (capivara
construtora, mascote; desenho provisório em `lib/ui/capi.dart`) ensina em 3
passos com balão de fala e uma mãozinha.

Arte do Capi e do ícone em `art/` (arquivos-mestre `.vectorcraft`, feitos no
VectorCraft da ArtCraft, e as exportações PNG/SVG). O Capi do jogo é
desenhado em código (`lib/ui/capi.dart`) seguindo essa arte. Quando o
jogador fica 10 s parado, o Capi leva a peça sugerida até o lugar
(`lib/game/capi_carrier.dart`). Depois vêm as fases 1 a 3 seguidas,
sem menu; o menu aparece ao vencer a fase 3. Infinito libera na fase 5 e o
Desafio diário na fase 7.

Jogadas que limpam linhas ganham elogios em níveis ("Boa!" → "Incrível!" →
"Espetacular!" → "Lendário!"), com raios de luz, clarão, confete e som. Fontes:
Lilita One e Fredoka (licença OFL, em `assets/fonts/`).

Versão web publicada a cada push em https://capiblocks.vercel.app (Vercel,
`vercel.json` + `tool/vercel_build.sh`). Para testar só os efeitos de elogio:
`flutter run -d chrome --dart-define=DEMO_PRAISE=true`.

## Como rodar

```sh
flutter pub get
flutter run              # celular ou emulador conectado
flutter test             # testes das regras, do gerador e da política de anúncios
flutter build apk        # Android
flutter build ipa        # iOS (precisa de macOS + Xcode)
```

Para ver no navegador: `flutter run -d chrome`.

## Testes automáticos

- `flutter test`: regras, gerador de peças e fases, política de anúncios.
- `e2e/` (Playwright): o jogo rodando no navegador, com arrastos reais, em 4
  tamanhos de tela (iPhone SE, iPhone Pro Max, Android pequeno, tablet). Usa
  uma versão web com a ponte de testes (`--dart-define=TEST_BRIDGE=true`):

  ```sh
  cd e2e && npm ci && npm run build && npx playwright test
  npx playwright show-report   # relatório com capturas
  ```

- **GitHub Actions** (`.github/workflows/ci.yml`) roda tudo a cada envio para
  `main` e em cada pull request: formatação, análise, testes de unidade e um
  job do Playwright por tamanho de tela. O relatório de cada tamanho fica nos
  artefatos da execução.

## Grafo do projeto (graphify)

`graphify-out/` guarda um mapa do código e da documentação (graphify 0.9.92):
`graph.json` (consultas), `GRAPH_REPORT.md` (resumo) e `graph.html` (abra no
navegador). O Claude Code consulta esse mapa antes de ler arquivos, gastando
menos tokens.

```sh
graphify query "Solver canPlaceAll PieceGenerator"   # termos do código (em inglês)
graphify update .                                     # atualizar depois de mudar o código (grátis)
```

`.graphifyignore` deixa de fora ícones, sons, skills de terceiros e pastas
geradas.

## Como o jogo está organizado

| Pasta | O que tem |
|---|---|
| `lib/core/` | Regras puras, sem interface: tabuleiro, peças, gerador de peças, gerador de fases, sessão de jogo |
| `lib/game/` | Cena Flame: tabuleiro, arrastar e soltar, encaixe, animações, partículas |
| `lib/screens/` | Telas Flutter: menu, partida (HUD e cartões de vitória/derrota/pausa), configurações |
| `lib/ads/` | Política de anúncios e o serviço de anúncios (hoje um simulador de teste) |
| `lib/services/` | Progresso salvo no aparelho, sons e vibração |
| `tool/` | `gen_sounds.py` gera os efeitos sonoros; `simulate.dart` joga as fases com um robô |

## Dificuldade

- **Peças sempre jogáveis.** Antes de entregar as três peças, o jogo confere
  (`Solver`) que existe uma ordem de jogadas em que todas cabem. A derrota
  sempre vem das jogadas anteriores, nunca de um sorteio impossível.
- **Dente de serra.** A dificuldade sobe por quatro fases, chega numa fase
  **DIFÍCIL**, e a seguinte é de **alívio**. No geral, sobe devagar ao longo
  das fases.
- **Ajuste invisível.** Cada derrota seguida na mesma fase deixa a próxima
  tentativa um pouco mais gentil (peças menores e peças que completam linhas).
  Tabuleiro muito cheio também alivia o sorteio.
- **Fases são fixas.** A fase 37 é igual para todo mundo (gerada a partir do
  número), o que permite comparar e ajustar.
- **Começo animado.** Fases de pontos (e parte das de gemas) começam com um
  desenho (coração, seta, escada…) cheio de linhas quase completas, então as
  primeiras jogadas já limpam linhas. Os desenhos mais leves vêm primeiro.
- **Novidades aos poucos.** Pedras, gemas, pedras reforçadas e fases com duas
  metas aparecem com um cartão "Novidade!" na primeira vez.

Para conferir a curva depois de mexer em `lib/core/level.dart`:

```sh
dart run tool/simulate.dart 1 90 40   # fases 1 a 90, 40 tentativas cada
```

Na calibragem atual, o robô (mais fraco que uma pessoa e sem o ajuste
invisível) vence cerca de 90% das fases 1–15 e 40% das fases 76–90; fases
normais ~60%, difíceis ~40% e de alívio ~75%. Uma fase vencida leva em média
~18 jogadas no começo e ~29 no geral.

## Anúncios

Sem banner; a tela de jogo fica limpa. Só dois tipos (`lib/ads/ad_policy.dart`):

- **Com recompensa**, sempre escolha do jogador: hoje, "Continuar" depois de
  perder (uma vez por tentativa).
- **Entre fases**, só ao avançar de uma fase vencida para a próxima, e apenas
  se: já passou da fase 6, o app está aberto há mais de 5 minutos e o último
  anúncio de tela cheia (de qualquer tipo) foi há mais de 6 minutos. O horário
  fica salvo, então fechar e abrir o app não zera o intervalo.

Os números ficam em `AdPolicy` e podem ir para o Firebase Remote Config depois.
Por enquanto `DebugAdService` mostra uma tela preta de teste no lugar do
anúncio; a próxima etapa é trocá-lo pelo AdMob.

## Próximas etapas

1. AdMob (anúncio com recompensa + entre fases) com consentimento de
   privacidade (LGPD/GDPR) e, no iOS, a permissão de rastreamento.
2. Firebase Analytics e Remote Config (intervalos de anúncio e dificuldade
   ajustáveis sem atualizar o app).
3. Compra "Remover anúncios".
4. Ícone, tela de abertura, identificador final do app
   (`com.puzzleblocos.puzzle_blocos` é provisório) e páginas nas lojas.
5. Lançamento discreto só no Brasil, medir retenção e ajustar.
