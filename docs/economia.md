# Economia do CapiBlocks (estrelas e preços)

Valores combinados com o dono em 02/11/2026, para a versão 1.3.0.

## Quanto se ganha por dia (estimativa)

| Perfil | Sem vídeo | Com vídeos |
|---|---|---|
| Casual (~10 min: 5 fases, 2 missões) | ~14★ | ~30★ |
| Regular (~25 min: 10 fases, missões, baú, desafio) | ~36★ | ~60★ |
| Ativo (~1 h: 20 fases, Blitz, Torre, obras) | ~77★ | ~105★ |

- Vencer uma fase dá 1 a 3★, a obra 1 a 3★ e o desafio diário 3★.
- Blitz e Torre dão até 6★ por dia cada.
- As missões dão 1 ou 2★ cada, e o baú diário 5★ mais 1 item.
- Com vídeo: "dobrar" as estrelas da fase (**até 10 por dia**,
  `dobrarPorDia` em `lib/screens/game_screen.dart`) e o baú bônus (+5★,
  1 por dia).

## Onde se gastam

| O quê | Preço | Total |
|---|---|---|
| Vila (12 construções) | 18 a 72★ | 438★ |
| Guarda-roupa, comuns (9) | 40★ | 360★ |
| Guarda-roupa, raros (8) | 150★ **ou 5 vídeos** (até 5 vídeos de guarda-roupa por dia) | 1.200★ |
| Épicos (5) | só como prêmio de coleção | |
| Lendários | só pagos: Passe ou Mercado | |
| Ferramentas | 4 a 8★ por uso | |

Completar a vila e o guarda-roupa com estrelas custa uns **2.000★**: cerca
de 5 semanas para um jogador regular com vídeos. O pacote de 1.000★ compra
metade disso.

## Mercado do Capi

Muda todo dia à meia-noite, na mesma ordem para todos (sem sorteio,
`lib/core/mercado.dart`):
- 1 lendário por R$ 9,90 (6 em rotação);
- 1 comum e 1 raro por estrelas, com 20% de desconto.

## Dinheiro (Google Play)

Os preços valem o que estiver na Play Console; a tabela completa está em
`docs/loja.md`.
