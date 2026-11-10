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
| `torre.mp4` | A Torre do Capi subindo andar por andar até errar |

Cada clipe abre com uma legenda curta no alto (o gancho dos primeiros
segundos) e mostra um dedo onde a tela é tocada, para quem assiste ver de
onde a peça sai. Ao lado de cada MP4 fica um `.txt` com uma sugestão de
texto e hashtags para o post. A legenda usa a fonte do jogo, que não tem
emoji: emoji só no texto do post.

Os vídeos saem sem som: nas redes, coloque uma música em alta pelo próprio
app (TikTok/Instagram), que ajuda o alcance. Para um clipe novo, copie um dos
`test(...)` de `clipes.spec.ts`; o tabuleiro preparado (`COMBO`) usa as
letras dos testes (`.` vazio, `b` bloco, `g` gema, `r` pedra).
