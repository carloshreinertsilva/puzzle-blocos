# Passe do Capi

Temporadas de 30 dias (`lib/core/passe.dart`). A temporada 1 começou em
01/11/2026.

## Como funciona

- **Pontos:** cada estrela ganha jogando (fases, obras, missões, baú, Blitz,
  Torre) vale 1 ponto do passe. Estrelas compradas ou ganhas no próprio passe
  não contam.
- **Níveis:** 30, um a cada 20 pontos (600 pontos para completar). O
  número vem do Firebase (`passe_pontos_nivel`, 10 a 40, veja
  `docs/ajustes-remotos.md`). Com 20: um jogador regular (36 a 60★ por dia)
  completa em 10 a 17 dias; um casual (14 a 30★ por dia) chega ao nível 20
  ou mais na temporada, e quem instala no meio do mês ainda alcança os
  itens dos níveis 10 e 20. (Com 30, o casual parava no nível 14.)
- **Mudar o ritmo não tira nada:** o nível é calculado dos pontos a cada
  vez e os prêmios pegos ficam marcados por nível. Baixar o número só abre
  níveis; subir pode esconder níveis ainda não alcançados, mas nada já pego
  some (`test/passe_test.dart`).
- **Trilha grátis:** estrelas e ferramentas para todos.
- **Trilha premium** (produto `passe_capi`): 141 estrelas, ferramentas e 3
  itens exclusivos do passe:

  | Nível | Item |
  |---|---|
  | 10 | Óculos Estrelados (raro) |
  | 20 | Medalha da Temporada (raro) |
  | 30 | Coroa de Estrelas (lendário) |

- **Preço:** R$ 9,90 na temporada 1 (preço de lançamento; o app mostra
  "(lançamento)"), R$ 14,90 a partir da temporada 2. O preço é mudado na
  Play Console no dia 01/12/2026.
- Os itens do passe nunca vão para o Mercado do Capi.

- **Comprar no meio da temporada** libera também os prêmios premium dos
  níveis já alcançados. A tela mostra a soma antes da compra ("Comprando
  agora, você recebe na hora: +48 estrelas, 6 ferramentas e 1 item",
  `PasseDoCapi.naHora`).
- **Vantagens do premium no dia a dia** (só na temporada comprada):
  - +1 dica grátis em cada partida (2 em vez de 1, `PasseDoCapi.dicasExtras`);
  - estrelas em dobro no Desafio diário (6★ em vez de 3,
    `PasseDoCapi.multiplicadorDesafio`). As 3 estrelas extras entram como
    estrelas compradas: **não** contam pontos do passe (senão o premium
    aceleraria o próprio passe) e **não** enchem o Cofrinho (que é vendido).

## A tela (`lib/screens/passe_sheet.dart`)

- Contagem regressiva da temporada (em dias; no último dia, em horas).
- Destaque com os itens da temporada: o Capi aparece vestindo o mais raro,
  e tocar numa miniatura prova outro ("Ver {item} no Capi").
- Convite de compra com o que vem na hora, as vantagens e o preço.
- Trilha: grátis à esquerda, premium à direita (com cadeado enquanto não
  comprado), e no meio a linha dos níveis com o Capi parado no nível que
  está sendo conquistado. Tudo rola; todos os níveis são montados de uma
  vez para os testes do navegador acharem qualquer um.
- **Nada é sorteado:** todas as recompensas aparecem na tela desde o início
  (ECA Digital).

## Onde fica no jogo

- **Missões Diárias:** botão "Passe" no topo, com o número de prêmios para
  pegar.
- **Loja:** linha "Passe do Capi".
- **Menu:** o contador do botão de Missões Diárias soma os prêmios do passe.

## Próximas temporadas

Hoje as temporadas repetem a mesma trilha. Para uma temporada nova com itens
novos:
1. desenhe os itens e coloque-os no catálogo (`lib/core/wardrobe.dart`), com
   a fonte `Passe()`;
2. troque os itens da trilha premium em `PasseDoCapi.trilha`, escolhendo a
   trilha pelo número da temporada se quiser manter as anteriores.
