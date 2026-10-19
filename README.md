# Bloco a Bloco

Jogo de quebra-cabeça de blocos para Android e iOS (Flutter + Flame). O nome
é provisório: troque `appTitle` em `lib/ui/palette.dart` e o nome exibido em
`android/app/src/main/AndroidManifest.xml` e `ios/Runner/Info.plist`.

Tabuleiro 8x8, três peças por rodada, linhas e colunas completas somem. Além
do **modo infinito**, há um **modo de fases** com metas (pontos, quebrar
pedras, coletar gemas) e dificuldade crescente.

## Como rodar

```sh
flutter pub get
flutter run              # celular ou emulador conectado
flutter test             # testes das regras, do gerador e da política de anúncios
flutter build apk        # Android
flutter build ipa        # iOS (precisa de macOS + Xcode)
```

Para ver no navegador: `flutter run -d chrome`.

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

Para conferir a curva depois de mexer em `lib/core/level.dart`:

```sh
dart run tool/simulate.dart 1 90 40   # fases 1 a 90, 40 tentativas cada
```

Na calibragem atual, o robô (mais fraco que uma pessoa e sem o ajuste
invisível) vence cerca de 96% das fases 1–15 e 50% das fases 76–90; fases
normais ~70%, difíceis ~50% e de alívio ~80%.

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
