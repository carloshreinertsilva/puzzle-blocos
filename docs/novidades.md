# Novidades para o jogador

Toda mudança que o jogador vê é anunciada dentro do jogo. Assim uma função
nova não depende de alguém descobrir sozinho.

## Como funciona

- **Cartão "O que há de novo":** na primeira vez que o jogo abre depois de uma
  atualização, o menu mostra até 3 novidades (as mais novas primeiro). Cada uma
  tem o botão **Ver agora**, que leva direto à função.
- **Bolinha no menu:** o que foi anunciado e ainda não foi aberto fica com uma
  bolinha vermelha no botão (ou o selo "NOVO" nos cartões de modo), até o
  jogador entrar.
- **Quem acabou de instalar** não vê o cartão: para ele tudo é novo.
- O cartão espera o Capi terminar as falas do menu e o presente do dia.

Código: `lib/core/novidades.dart` (a lista), `lib/screens/novidades_dialog.dart`
(o cartão) e `lib/screens/home_screen.dart` (quando aparece e as bolinhas).

## Como anunciar uma novidade

1. Em `lib/core/novidades.dart`, acrescente título, uma frase e o destino do
   botão "Ver agora" (`DestinoNovidade`) na edição da próxima versão. Se a
   última edição já foi publicada, crie uma nova (o próximo número).
2. Traduza o título e a frase em `lib/l10n/textos/menu.dart` (inglês e
   espanhol). O teste `test/novidades_ranking_test.dart` falha se faltar.
3. Se a função mora num lugar novo do menu, acrescente o destino em
   `DestinoNovidade`, em `_irPara` (home) e o ícone em `iconeDaNovidade`.
4. Ao fechar a versão, escreva as notas das lojas em `distribution/whatsnew/`
   a partir da edição dela.

Uma edição por versão publicada. No máximo 3 novidades aparecem de cada vez,
então escolha as que mais importam para o jogador.

## Estatísticas

`novidades` (o cartão apareceu, com a edição) e `novidade_aberta` (o jogador
tocou em "Ver agora", com o destino).
