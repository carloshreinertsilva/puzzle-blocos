# Clipes do jogo para as redes sociais

Vídeos verticais curtos (1080x1920, MP4, 60 quadros por segundo), prontos para Reels, TikTok e
YouTube Shorts. O jogo roda no navegador e joga sozinho; nada aqui roda no CI.

```bash
cd e2e
npm run build            # o jogo com a ponte de testes (uma vez)
npm run clipes           # grava todos
npm run clipes -- -g natal   # só um
FPS=30 npm run clipes        # a 30 qps (grava duas vezes mais rápido)
```

Precisa do `ffmpeg` instalado. O tempo do jogo anda quadro a quadro (o
navegador de testes não desenha 60 qps sozinho), então cada clipe leva uns
3 a 4 minutos para gravar, mas sai liso. Os vídeos ficam em `e2e/clipes/saida/`:

| Clipe | O que mostra |
| --- | --- |
| `combo.mp4` | Um combo de 3 linhas e 3 colunas de uma vez ("Lendário!") e algumas jogadas |
| `partida.mp4` | Uma fase do começo, jogada pelo robô |
| `natal.mp4` | O Capi de Natal no menu e um combo no Infinito |
| `blitz.mp4` | O Blitz 60s aberto pelo menu, jogado em ritmo rápido |
| `blitz-final.mp4` | Os últimos segundos de um Blitz, com um combo lendário no fim |
| `torre.mp4` | A Torre do Capi: sequência de acertos, as Nuvens, o recorde batido e a torre inteira no fim |
| `desafio.mp4` | "Você consegue?": o tabuleiro para, contagem 3-2-1 e a peça que limpa 2 linhas e 3 colunas |
| `combos.mp4` | Três combos grandes seguidos, numerados para o pessoal votar no melhor |
| `blitz-bonus.mp4` | O relógio do Blitz ganhando "+5s" a cada limpeza grande (1.12.0) |
| `blitz-10s.mp4` | O tempo do Blitz acaba, o "+10 segundos" salva a partida (1.12.0; o anúncio de teste fica fora) |
| `dica.mp4` | A lâmpada da dica pisca quando o jogador trava e mostra a jogada |

**Marca em todos os clipes.** No primeiro segundo a logo do CapiBlocks entra
no meio da tela com um pulo e um brilho e sobe sumindo; o jogo já aparece
por trás, então o gancho não espera a marca. No fim, um cartão de convite de
3 segundos: a logo, o Capi comemorando, o convite do clipe, "Grátis no
Android", os selos das lojas e "link na bio". Os arquivos ficam em
`clipes/marca/`: `icone.png` (o ícone do jogo) e, quando forem baixados das
páginas de marca do Google e da Apple, `google-play.png` e `app-store.png`
(sem eles, o cartão escreve o nome da loja). O selo da App Store só pode
aparecer com o app já na loja: até a Apple aprovar, fica desligado
(`LOJAS` em `gravador.ts`, ou `APP_STORE=1` para ligar).

Os 7 clipes da semana gravam de uma vez com `npm run clipes:semana`
(calendário, textos e horários em `docs/divulgacao/semana-1.md`).

Cada clipe abre com uma legenda curta no alto (o gancho dos primeiros
segundos) e mostra um dedo onde a tela é tocada, para quem assiste ver de
onde a peça sai. Ao lado de cada MP4 fica um `.txt` com uma sugestão de
texto e hashtags para o post. A legenda usa a fonte do jogo, que não tem
emoji: emoji só no texto do post.

Os vídeos saem sem som: nas redes, coloque uma música em alta pelo próprio
app (TikTok/Instagram), que ajuda o alcance. Para um clipe novo, copie um dos
`test(...)` de `clipes.spec.ts`; o tabuleiro preparado (`COMBO`) usa as
letras dos testes (`.` vazio, `b` bloco, `g` gema, `r` pedra).
