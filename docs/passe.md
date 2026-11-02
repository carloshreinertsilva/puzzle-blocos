# Passe do Capi

Temporadas de 30 dias (`lib/core/passe.dart`). A temporada 1 começou em
01/11/2026.

## Como funciona

- **Pontos:** cada estrela ganha jogando (fases, obras, missões, baú, Blitz,
  Torre) vale 1 ponto do passe. Estrelas compradas ou ganhas no próprio passe
  não contam.
- **Níveis:** 20, um a cada 12 pontos (240 pontos para completar). Um
  jogador ativo, que ganha uns 15 a 25 estrelas por dia, completa em duas a
  três semanas.
- **Trilha grátis:** estrelas e ferramentas para todos.
- **Trilha premium** (produto `passe_capi`, R$ 9,90 por temporada): 140
  estrelas, ferramentas e os 4 itens lendários do passe:

  | Nível | Item lendário |
  |---|---|
  | 5 | Máscara de Herói |
  | 10 | Asinhas de Anjo |
  | 15 | Pelagem Arco-Íris |
  | 20 | Coroa de Estrelas |

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
