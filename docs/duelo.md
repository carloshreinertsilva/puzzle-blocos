# Duelo por link

Quem vence ou termina uma partida de Duelo ou Blitz toca em "Desafiar Amigo"
/ "Compartilhar Duelo":

- **No celular** abre a janela de compartilhar do Android (WhatsApp,
  Instagram...) com a mensagem e o link. **Na web** a mensagem é copiada.
- O link é `https://capiblocks.vercel.app/duelo?s=<semente>&p=<pontos>`
  (`&m=blitz` no Blitz). Links antigos (`/?duelo=...`) continuam valendo.
  Código: `lib/services/duelo_link.dart`.

Quem recebe o link:

| Situação | O que acontece |
|---|---|
| Android **com** o app e o App Links verificado | O link abre direto no app, no mesmo tabuleiro (`App.onGenerateRoute`). |
| Android **sem** o app | Abre a página do jogo com o convite "Você foi desafiado!": **Baixar o app grátis** (Play Store) ou **Jogar aqui no navegador** (`web/index.html`). |
| iPhone ou computador | Abre o jogo no navegador, direto no desafio. |

## Link abrindo o app (App Links)

O Android só abre o app se o site provar que o app é dele, com o arquivo
`web/.well-known/assetlinks.json` (publicado em
`https://capiblocks.vercel.app/.well-known/assetlinks.json`). Ele traz as
impressões digitais SHA-256 das duas chaves, tiradas da Play Console
(**Configuração → Integridade do app**):

- chave de assinatura do app (Google Play), usada no app baixado da loja;
- chave de upload, usada nos APKs de teste do CI.

Não são segredo: servem só para o Android conferir quem assinou o app. Se a
chave mudar, atualize o arquivo. Num celular sem a versão com App Links
(1.2.0 ou mais nova), o link abre a página com o convite, que leva à Play
Store ou ao jogo no navegador.
