# CapiBlocks — instruções para o Claude Code

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
  (https://capiblocks.vercel.app), então `main` precisa estar sempre boa.
- Textos para o usuário e mensagens de commit/PR em português.
- **Novidade visível ao jogador nunca sai calada.** Todo PR que cria ou muda
  algo que o jogador vê acrescenta uma entrada em `lib/core/novidades.dart`
  (com o destino do botão "Ver agora" e as traduções). Ao fechar uma versão,
  as notas das lojas em `distribution/whatsnew/` saem dessa mesma lista. Veja
  `docs/novidades.md`.
- **Lojas:** o envio é pelos workflows `iOS: TestFlight` e `Android: Play
  Store` (Actions → Run workflow). Teste interno e TestFlight podem ser
  enviados sem perguntar. **Produção na Google Play só depois de o Carlos
  confirmar no chat, a cada versão** (e as notas em `distribution/whatsnew/`
  revisadas). Cada envio precisa de um número de build novo no `pubspec.yaml`
  (o do TestFlight é o número da execução do workflow). Para produção, a
  versão já testada no teste interno é promovida (`promover-para-producao`),
  sem compilar de novo.

## Pontos de atenção

- O jogo desenha num canvas: os testes do navegador encontram botões pelos
  rótulos de acessibilidade (`Semantics`) e leem o estado pela ponte de
  testes (`lib/testing/`, só com `--dart-define=TEST_BRIDGE=true`). Ao criar
  um botão novo, dê um rótulo a ele.
- Mudou a dificuldade (`lib/core/level.dart`)? Rode
  `dart run tool/simulate.dart 1 90 40` e compare com os números do README.
- O jogo fala português, inglês e espanhol. Todo texto que o jogador vê
  passa por `tr('texto em português')` (ou `trN` para plural), com a tradução
  em `lib/l10n/textos/`. O teste `test/traducoes_test.dart` falha se faltar
  inglês ou espanhol. Os testes do navegador rodam em português.
- Anúncios seguem `lib/ads/ad_policy.dart`: sem banner, nada durante a
  partida, interstitial só entre fases com intervalo longo.

## Publicação e Lojas (Google Play Store)

- **Status da Loja:** App `com.capiblocks.app` submetido na faixa de Produção no Google Play Console (em análise).
- **Titular Oficial:** CHS CONSULTORIA LTDA (marca CHS TECH, contato@chstech.dev.br, https://www.chstech.dev.br).
- **Assinatura do Android (.aab):** Upload Keystore RSA 4096-bit configurada no GitHub Actions Secrets (`CAPI_KEYSTORE_BASE64`, `CAPI_KEYSTORE_PASSWORD`, `CAPI_KEY_ALIAS`, `CAPI_KEY_PASSWORD`). Localmente os arquivos ficam em `android/upload-keystore.jks` e `android/key.properties` (ambos no `.gitignore`).
- **Materiais da Loja:** Ícone 512, banner 1024x500 e os 6 screenshots 1080x1920 ficam em `docs/loja/` e `art/loja/`.
- **Histórico detalhado do projeto:** Consulte `HISTORICO_DESENVOLVIMENTO.md` para a cronologia completa de todas as funcionalidades implementadas.
