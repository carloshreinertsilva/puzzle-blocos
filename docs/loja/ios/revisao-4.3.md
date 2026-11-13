# Apple: rejeição 4.3(a) Spam (13/11/2026) e plano de reenvio

A Apple rejeitou a versão **1.7.3 (7)** pela regra **4.3(a) Design – Spam**:
achou o app parecido demais (código, ficha ou ideia) com outros apps da loja.
As 13 compras estão "Pronto para revisão", mas presas à versão rejeitada.

A mensagem avisa sobre "revisão estendida": reenviar o mesmo app sem mudar
nada deixa as próximas revisões mais lentas e, repetido, arrisca a conta. Por
isso o reenvio vai com versão nova, ficha nova e uma resposta explicando o que
o jogo tem de próprio.

## Situação em 13/11

Feito no App Store Connect (salvo, **sem reenviar**):
- versão trocada de 1.7.3 para **1.12.2**, com o build **17**;
- subtítulo: "Quebra-cabeça de blocos" → "Monte a vila do Capi";
- texto promocional, descrição e palavras-chave novos (o Capi e a Vila
  primeiro);
- notas para a revisão, em inglês, explicando que o jogo é original;
- **7 capturas novas** do iPhone (Vila, Obra, Torre, filhotes,
  guarda-roupa, combo e modos), geradas por `e2e/loja/ios.spec.ts` e
  montadas por `tool/loja_ios.js`;
- **prévia em vídeo** de 22,8 s (886x1920, 30 qps, sem selo de loja),
  gravada por `e2e/clipes/apple.spec.ts`, também no campo **Anexo** das
  informações para a revisão.

Falta: colar a resposta abaixo na mensagem da revisão e clicar em
"Reenviar para Revisão do app" (depois do OK do Carlos).

## Passo a passo

1. **Versão:** no App Store Connect, trocar o número da versão de 1.7.3 para
   **1.12.2** e escolher o build **1.12.2 (17)**, que já está no TestFlight.
   A 1.7.3 não tem Torre, Blitz, ranking, guarda-roupa nem novidades.
2. **Ficha:** trocar textos e capturas (lista abaixo). O que a Apple vê
   primeiro precisa ser o Capi, a Vila, as Obras e a Torre, não só um
   tabuleiro 8x8.
3. **Vídeo de 30 a 60 s** da 1.12.2 mostrando os modos próprios, como prévia
   do app na ficha e como link na resposta. Ele é gravado pelo gravador de
   clipes quando a máquina estiver livre.
4. **Responder** na mensagem da revisão (texto em inglês abaixo) e clicar
   em "Reenviar para Revisão do app".
5. **Se recusarem de novo:** recorrer ao App Review Board
   (developer.apple.com/contact/app-store/?topic=appeal) com o mesmo texto e
   o vídeo.
6. **CapiMatch!:** não enviar enquanto o CapiBlocks não for aprovado. Quando
   for, ele precisa de jogabilidade, código e ficha claramente diferentes,
   porque a Apple compara os apps da mesma conta.

## Resposta à Apple (para colar em "Responda à equipe de revisão de apps")

> Hello App Review team,
>
> Thank you for the review. We would like to clarify that CapiBlocks is an
> original game, written from scratch by our small studio (CHS TECH). It is
> not built from a template, reskin or purchased source code, and we have no
> other block puzzle apps on the App Store.
>
> We have also submitted a new build (1.12.2) that better shows what the game
> offers beyond a classic block puzzle:
>
> - **Capi, our own character.** An original capybara builder who teaches
>   new players, reacts to every move and carries the piece to the right spot
>   when the player asks for a hint. All the game art, including Capi, is
>   drawn in our own code.
> - **Blueprint puzzles ("Obras").** A different puzzle type: the player
>   fills a drawing (heart, fish, castle…) exactly with a given set of
>   pieces, without clearing lines.
> - **Capi's Village.** An animated floating island that the player builds
>   piece by piece. Each building is earned by solving its own blueprint
>   puzzle.
> - **Capi's Tower.** A stacking mode where the player builds a tower from
>   the village up to the Moon, with precision streaks.
> - **Rescue levels.** Hand-tuned levels with goals such as breaking rocks,
>   collecting gems and freeing capybara pups trapped in bubbles.
> - **Blitz and Friend Duels.** A timed mode where big clears add time, and
>   duels where two friends play the same board through a shared link.
> - **Wardrobe and seasons.** Hats and outfits for Capi, plus seasonal events.
>
> A short gameplay video of the new build is attached to the review
> information and is also the app preview on the product page.
>
> We have updated the description and screenshots to make these features
> clear. If anything is still unclear, we are happy to provide more details
> or a demo.
>
> Best regards,
> Carlos Reinert – CHS TECH

Tradução (só para conferência): agradecemos a revisão; o CapiBlocks é um jogo
original, escrito do zero pelo nosso estúdio, sem modelo, reskin nem código
comprado, e não temos outros jogos de blocos na loja. Enviamos a 1.12.2, que
mostra melhor o que o jogo tem além do quebra-cabeça de blocos clássico: o
Capi como personagem próprio, as Obras (preencher um desenho com as peças), a
Vila construída obra a obra, a Torre até a Lua, as fases com pedras, gemas e
filhotes, o Blitz e os duelos com amigos, e o guarda-roupa e as temporadas.
Segue um vídeo, e a ficha foi atualizada.

## Ficha da App Store: o que mudar

**Subtítulo** (até 30 caracteres): `Capi builds his village` em inglês, ou
`Monte a vila do Capi` em português, no lugar de qualquer subtítulo que fale
só de blocos, como os outros jogos do gênero.

**Primeiras linhas da descrição** (é o que a Apple e o jogador leem
primeiro). Abrir com o personagem e os modos próprios, não com "jogo de
blocos clássico":

> Help Capi, the builder capybara, raise his floating village! Solve
> blueprint puzzles to build every house, stack Capi's Tower up to the Moon,
> free capybara pups trapped in bubbles and race the clock in Blitz.

Em seguida, os modos em tópicos (Vila, Obras, Torre, Fases, Blitz, Duelo
com amigos, Desafio diário, Infinito) e, por último, a regra básica de
encaixar peças.

**Capturas (6.9" e 6.3"), nesta ordem:**

1. A Vila do Capi montada, com o título "Build Capi's village".
2. Uma Obra pela metade, com o título "Fill the blueprint".
3. A Torre do Capi alta, com o título "Stack to the Moon".
4. Uma fase com filhotes nas bolhas, com o título "Rescue the pups".
5. O guarda-roupa do Capi, com o título "Dress up Capi".
6. Uma partida com um combo grande e o Capi comemorando, com o título "Satisfying combos".

O tabuleiro comum vai para o fim. As capturas atuais (`docs/loja/ios/`)
começam pelo menu e pelo tabuleiro, que é o que mais parece com os outros
jogos.

**Palavras-chave:** tirar termos genéricos copiados do gênero ("block blast",
"tetris" e afins, se houver) e usar capivara/capybara, village, builder,
puzzle, tower, pet.

**Prévia em vídeo (opcional, ajuda muito):** os mesmos 30 s do vídeo da
resposta, em 886x1920.

## Vídeo de demonstração (roteiro, 45 s)

Gravado com o gravador de clipes (`e2e/clipes/`), na 1.12.2, sem som:

1. (0–5 s) A logo e o Capi acenando no menu.
2. (5–13 s) A Vila: a câmera passeia e um item novo cai do céu.
3. (13–21 s) Uma Obra sendo completada até o desenho aparecer.
4. (21–29 s) A Torre subindo, com sequência de acertos.
5. (29–36 s) Uma fase com filhotes soltos das bolhas.
6. (36–42 s) O Blitz ganhando "+5s" e o guarda-roupa.
7. (42–45 s) O cartão final com a logo.

Para a resposta, o vídeo pode ir como link não listado do YouTube ou do
Google Drive.
