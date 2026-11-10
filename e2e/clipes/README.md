# Clipes do jogo para as redes sociais

Vídeos verticais curtos (1080x1920, MP4), prontos para Reels, TikTok e
YouTube Shorts. O jogo roda no navegador e joga sozinho; nada aqui roda no CI.

```bash
cd e2e
npm run build            # o jogo com a ponte de testes (uma vez)
npm run clipes           # grava todos
npm run clipes -- -g natal   # só um
```

Precisa do `ffmpeg` instalado. Os vídeos ficam em `e2e/clipes/saida/`:

| Clipe | O que mostra |
| --- | --- |
| `combo.mp4` | Um combo de 3 linhas e 3 colunas de uma vez ("Lendário!") e algumas jogadas |
| `partida.mp4` | Uma fase do começo, jogada pelo robô |
| `natal.mp4` | O Capi de Natal no menu e um combo no Infinito |

Os vídeos saem sem som: nas redes, coloque uma música em alta pelo próprio
app (TikTok/Instagram), que ajuda o alcance. Para um clipe novo, copie um dos
`test(...)` de `clipes.spec.ts`; o tabuleiro preparado (`COMBO`) usa as
letras dos testes (`.` vazio, `b` bloco, `g` gema, `r` pedra).
