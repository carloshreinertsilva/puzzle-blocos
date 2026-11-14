# Divulgação: semana 1 (14 a 20 de novembro)

Um clipe por dia no TikTok, Instagram Reels e YouTube Shorts (o mesmo MP4
vertical nos três), com cenas da versão atual do jogo (1.12.x: bônus de
tempo e +10 segundos no Blitz, lâmpada de dica, Torre nova).

Todo clipe abre com a logo do CapiBlocks pulsando por cima do jogo e fecha
com o cartão de convite (logo, o Capi comemorando, o convite, "Grátis no
Android", selo da loja e "link na bio"). Como funciona: `e2e/clipes/README.md`.

## Como gravar

Com a máquina livre (cada clipe leva uns 3 a 4 minutos a 60 qps):

```bash
cd e2e
npm run build            # o jogo com a ponte de testes
npm run clipes:semana    # os 7 da semana (nesta máquina: -c playwright.clipes.local.config.ts)
```

Os vídeos e os textos (`.txt`) ficam em `e2e/clipes/saida/`. Para refazer só
um: `npm run clipes -- -g dica`.

## Calendário

Horários de pico no Brasil: almoço (12h) ou noite (19h às 21h). Poste no
mesmo horário todos os dias, para o algoritmo e o público acostumarem.

| Dia | Clipe | Formato | Horário |
|---|---|---|---|
| Sáb 14/11 | `desafio` | Pergunta: puxa comentários | 12h |
| Dom 15/11 | `combos` | Satisfatório, votação 1-2-3 | 19h30 |
| Seg 16/11 | `blitz-bonus` | Novidade da 1.12: combo dá tempo | 19h30 |
| Ter 17/11 | `dica` | Para quem está começando | 19h30 |
| Qua 18/11 | `blitz-10s` | Suspense: "o tempo acabou… ou não?" | 19h30 |
| Qui 19/11 | `torre` | Satisfatório: da vila até a Lua | 19h30 |
| Sex 20/11 | `natal` | Esquenta de dezembro | 19h30 |

Reserva (já existem e ganham a logo e o cartão ao regravar): `combo`,
`partida`, `blitz`, `blitz-final`.

## Roteiros

Duração de cada um: 15 a 30 segundos, já contando a logo (1,5 s) e o
cartão final (3 s). A legenda do alto é o gancho; o texto do post vai na
descrição.

**1. `desafio`: "Onde você colocaria uma peça pra limpar TUDO?"**
Tabuleiro quase cheio no Infinito. A pergunta fica 3 s no ar, contagem
"Pensa rápido… 3, 2, 1", "Aqui!" e o dedo arrasta o retângulo 2x3 para o
canto: 2 linhas e 3 colunas somem de uma vez. Fecha com "Acertou? Comenta
aí!". Convite final: "Acertou? Então vem jogar!".
Por que: perguntas puxam comentários, e comentário é o que mais dá alcance.
Responda os comentários nas primeiras horas.

**2. `combos`: "Só combos satisfatórios"**
Três tabuleiros preparados, numerados na tela: 4 linhas com a peça em pé, o
retângulo que limpa 5 linhas e o combo lendário de 3 jogadas. Fecha com
"Qual foi o melhor? 1, 2 ou 3?". Coloque uma música em alta no app.

**3. `blitz-bonus`: "No Blitz, combo vale tempo extra"**
Entra no Blitz pelo menu, algumas jogadas rápidas e duas limpezas grandes:
o relógio pisca verde e solta "+5s". Legendas: "4 linhas de uma vez = +5
segundos" e "E esse? Olha o relógio!".

**4. `dica`: "Travou na fase? Calma…"**
Uma fase do começo, duas jogadas, o jogador para (a espera vira um corte),
a lâmpada pisca, o dedo toca e a jogada aparece. Fecha com "Agora é com
você!". Mostra que o jogo ajuda quem está começando.

**5. `blitz-10s`: "O tempo acabou… ou não?"**
Últimos 3 segundos do Blitz, o cartão final aparece com "+10 segundos", o
dedo toca, corte (o vídeo de anúncio não entra) e a partida volta com
"+10 segundos!" e um combo de 4 linhas.

**6. `torre`: "Empilha sem errar"**
A Torre nova: acertos em sequência, as Nuvens, o recorde batido e a torre
inteira no fim.

**7. `natal`: "O Capi entrou no clima de Natal"**
O Capi de gorro e cachecol no menu e um combo no Infinito. Bom para puxar a
temporada de dezembro.

## Textos dos posts

Saem prontos no `.txt` ao lado de cada vídeo (os mesmos de `CLIPES` em
`e2e/clipes/clipes.spec.ts`). Em todos: "link na bio" e as hashtags
`#capiblocks #capivara #jogodeblocos #jogosmobile`, mais 1 ou 2 do formato
(`#desafio`, `#satisfatorio`, `#blitz`, `#natal`).

## Antes de postar

- **Bio de cada rede** com o link da Play Store (ou um link único que leve
  às duas lojas quando o iPhone sair) e uma frase: "O jogo de blocos da
  capivara. Grátis!".
- **Música:** escolha uma em alta dentro do próprio app (TikTok/Instagram);
  os vídeos saem sem som de propósito.
- **Capa:** no TikTok e no Reels, escolha o quadro com a legenda do gancho.
- **iPhone:** quando a Apple aprovar, ligue o selo da App Store
  (`APP_STORE=1`) e regrave; até lá o cartão diz "Grátis no Android".
- **Envio ao TikTok:** o script `tool/tiktok.py` (PR #85, ainda não
  mesclado) manda o vídeo como rascunho para a conta @_capiblocks; a
  publicação é feita no app, onde se escolhe a música.

## Depois da semana

Anote, para cada clipe, visualizações, tempo médio assistido, curtidas,
comentários e visitas ao perfil (TikTok Studio e Insights do Instagram).
Os dois formatos que forem melhor ganham mais versões na semana 2.
