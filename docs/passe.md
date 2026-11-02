# Passe do Capi

Temporadas de 30 dias (`lib/core/passe.dart`). A temporada 1 começou em
01/11/2026.

## Como funciona

- **Pontos:** cada estrela ganha jogando (fases, obras, missões, baú, Blitz,
  Torre) vale 1 ponto do passe. Estrelas compradas ou ganhas no próprio passe
  não contam.
- **Níveis:** 30, um a cada 30 pontos (900 pontos para completar). Um
  jogador regular completa em umas 3 semanas; um casual, na temporada
  inteira.
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
  níveis já alcançados.
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
