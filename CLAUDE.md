# Bloco a Bloco — instruções para o Claude Code

Jogo de blocos em Flutter + Flame. Visão geral, dificuldade e anúncios: veja
o `README.md`.

## Fluxo de trabalho

- **Nada vai direto para `main`.** Toda mudança vai numa branch
  (`claude/<assunto>`) e entra por pull request.
- Antes de abrir o PR: `dart format lib test tool`, `flutter analyze` e
  `flutter test`. Se a mudança mexe na tela ou na jogabilidade, rode também
  os testes do navegador (`e2e/`, veja o README).
- O PR só é mesclado com o **CI verde** (GitHub Actions: Flutter + Playwright
  nos 4 tamanhos de tela). A `main` publica sozinha na Vercel
  (https://puzzle-blocos.vercel.app), então `main` precisa estar sempre boa.
- Textos para o usuário e mensagens de commit/PR em português.

## Pontos de atenção

- O jogo desenha num canvas: os testes do navegador encontram botões pelos
  rótulos de acessibilidade (`Semantics`) e leem o estado pela ponte de
  testes (`lib/testing/`, só com `--dart-define=TEST_BRIDGE=true`). Ao criar
  um botão novo, dê um rótulo a ele.
- Mudou a dificuldade (`lib/core/level.dart`)? Rode
  `dart run tool/simulate.dart 1 90 40` e compare com os números do README.
- Anúncios seguem `lib/ads/ad_policy.dart`: sem banner, nada durante a
  partida, interstitial só entre fases com intervalo longo.
