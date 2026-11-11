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

Estrelas (`lib/core/missions.dart`): cada fase tem 3 desafios (vencer; limpar
2 linhas de uma vez até a fase 10, depois um combo x3; vencer sem usar o
"Continuar"), e cada desafio vale uma estrela. Fases já vencidas podem ser
jogadas de novo pelo caminho do menu para pegar as que faltam. O Desafio
diário vale 3 estrelas e o Infinito 1 a cada 2.500 pontos (até 4 por
partida). As estrelas são a moeda da Vila do Capi.

Filhotes (a partir da fase 8): filhotes de capivara presos em bolhas nos
blocos; limpar a linha ou a coluna de cada um solta o filhote (meta da fase).
Cada filhote fica num lugar próprio (linha e coluna só dele). Os filhotes
salvos (`pupsSaved`) passeiam pela ilha da vila. Desenho em `lib/ui/pup.dart`.

Modo Obra (`lib/core/blueprint.dart`, `lib/screens/obra_screen.dart`): um
quebra-cabeça de encaixe. Uma planta com um desenho (coração, peixe,
castelo...) e um punhado de peças: é preciso encaixar todas e preencher o
desenho exatamente, sem limpar linhas. Cada obra é gerada cortando o desenho
em peças, então sempre tem solução; a dica do Capi resolve o resto a partir
do que já está montado. Estrelas: 3 sem desfazer nem dica, 2 com pouca ajuda,
1 ao terminar. O modo Obras libera na fase 6 (obras numeradas, cada uma vale
até 3 estrelas). Na vila, cada item agora é construído montando a obra dele
(o desenho do próprio item); as estrelas só são gastas quando a obra fica
pronta.

Vila do Capi (`lib/core/village.dart`, `lib/village/`,
`lib/screens/village_screen.dart`): uma ilha flutuante em perspectiva
isométrica, desenhada em código (sem imagens), que ganha 12 coisas sempre na
mesma ordem (canteiro de flores, cerquinha, banco, pé de acerola, barquinho,
horta, poste, píer, casinha, balanço, fonte e roda-gigante), pagas com
estrelas — 73 no total, o que dá para completar por volta da fase 25. Quase
tudo se mexe: roda-gigante girando, balanço, fumaça da chaminé, chafariz,
barquinho, cachoeira, borboletas, nuvens. Cada item cai do céu ao ser
construído, e tocar num item (ou no Capi) faz ele pular e o Capi comentar; dá
para dar zoom com pinça. Abre pelo cartão "Vila do Capi" no menu ou tocando no
contador de estrelas. `lib/village/iso.dart` tem a projeção e as formas 3D
(caixa, cilindro, bola, prisma) com luz vindo da esquerda e sombras.

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
  `main` e em cada pull request: formatação, análise, testes de unidade e o
  Playwright nos 4 tamanhos de tela (o relatório fica nos artefatos da
  execução). O job do Android gera o `.aab` e abre o jogo num emulador
  (`tool/android_abre.sh`); por ser o mais caro em minutos, não roda em PRs
  de rascunho, só quando o PR fica pronto para revisão e na `main`.

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
| `lib/ads/` | Política de anúncios, serviço do AdMob (Android) e simulador para testes |
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

## Economia de estrelas

Fontes com limite, para os minijogos rápidos não virarem fábrica de
estrelas: Blitz e Torre pagam no máximo 6 estrelas por dia cada
(`ProgressStore.addStarsCapped`); um desafio de amigo (link) paga 3 estrelas
uma única vez por semente, e duelos começados no menu são treino (sem
estrelas). As missões diárias e o baú têm sequência de dias própria,
separada da do Desafio diário.

## Publicação Android

Identificador `com.capiblocks.app` (não muda depois do primeiro envio). O CI
gera o pacote da Play Store (`.aab`) na `main` e nos PRs prontos, assinado com a chave de
envio guardada nos segredos do GitHub. Como criar a chave e cadastrar os
segredos: `docs/publicacao-android.md`.

## Anúncios

Sem banner; a tela de jogo fica limpa. Só dois tipos (`lib/ads/ad_policy.dart`):

- **Com recompensa**, sempre escolha do jogador: "Continuar" depois de
  perder (uma vez por tentativa) e ganhar uma ferramenta.
- **Entre fases**, só ao avançar de uma fase vencida para a próxima, e apenas
  se: já passou da fase 6, o app está aberto há mais de 5 minutos e o último
  anúncio de tela cheia (de qualquer tipo) foi há mais de 6 minutos. O horário
  fica salvo, então fechar e abrir o app não zera o intervalo.

Os números vêm de `Ajustes` (`lib/services/ajustes.dart`) e mudam pelo Firebase
Remote Config, sem versão nova: `docs/ajustes-remotos.md`.

Qual serviço o app usa (`lib/main.dart`):

| Versão | Anúncios |
|---|---|
| Android, depuração ou `--dart-define=ADMOB_TEST=true` | AdMob com os anúncios de teste do Google |
| Android, versão da loja | AdMob com os IDs reais de `lib/ads/ad_config.dart`; enquanto estiverem vazios, nenhum anúncio |
| Web (Vercel) | nenhum anúncio |
| Testes do navegador e web em depuração | tela preta de teste (`DebugAdService`) |

Antes de pedir anúncios, o app mostra a mensagem de consentimento do Google
(UMP) onde a lei exige; nesses lugares as configurações ganham o botão
"Privacidade dos anúncios". Só anúncios com classificação até PG. Passo a
passo para ativar os anúncios reais: `docs/admob.md`.

## Próximas etapas

1. Ativar os IDs reais do AdMob (`docs/admob.md`); no iOS, falta a
   configuração do AdMob e a permissão de rastreamento.
2. Ligar o Firebase Analytics, já no código (`docs/estatisticas.md`), e
   depois o Remote Config (intervalos de anúncio e dificuldade ajustáveis sem
   atualizar o app).
3. Compra "Remover anúncios".
4. Ícone, tela de abertura, identificador final do app
   (`com.puzzleblocos.puzzle_blocos` é provisório) e páginas nas lojas.
5. Lançamento discreto só no Brasil, medir retenção e ajustar.

## Licença

Código visível apenas para consulta: todos os direitos reservados à CHS
CONSULTORIA LTDA (veja `LICENSE`).
