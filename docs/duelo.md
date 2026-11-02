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

## Falta para o link abrir o app (App Links)

O Android só abre o app se o site provar que o app é dele, com o arquivo
`web/.well-known/assetlinks.json` (publicado em
`https://capiblocks.vercel.app/.well-known/assetlinks.json`). O arquivo
precisa da **impressão digital SHA-256 da chave de assinatura do app**:

1. Play Console → CapiBlocks → **Testar e lançar → Configuração →
   Integridade do app** (ou "Assinatura de apps").
2. Copie os dois valores **SHA-256**: o do "Certificado da chave de
   assinatura do app" e o do "Certificado da chave de upload".
3. Mande para o Claude, que cria o arquivo. Não são segredo: servem só para
   o Android conferir quem assinou o app.

Enquanto o arquivo não existe, o link abre a página com o convite, que já
leva à Play Store ou ao jogo no navegador.
