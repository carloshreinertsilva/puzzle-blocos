# Loja do Capi (compras dentro do app)

Desde a v1.2.0 o jogo vende pelo Google Play Billing (`lib/shop/`). Nada é
sorteio pago (ECA Digital): o jogador sempre vê o que está comprando.

## Produtos para cadastrar na Play Console

**Monetizar → Produtos → Produtos no app → Criar produto.** O ID precisa ser
exatamente o da tabela, e cada produto precisa ser **ativado** depois de
criado.

| ID do produto | Nome | Descrição | Preço (BRL) |
|---|---|---|---|
| `remover_anuncios` | Remover anúncios | Sem anúncios entre fases, para sempre. De presente: a Cartola VIP. | R$ 19,90 (US$ 3,99) |
| `pacote_inicial` | Pacote Inicial | Sem anúncios entre fases + 300 estrelas + o Capacete Fundador. | R$ 24,90 (US$ 4,99) |
| `estrelas_150` | 150 estrelas | 150 estrelas para a vila, ferramentas e chapéus. | R$ 4,90 |
| `estrelas_400` | 400 estrelas | 400 estrelas para a vila, ferramentas e chapéus. | R$ 9,90 |
| `estrelas_1000` | 1.000 estrelas | 1.000 estrelas para a vila, ferramentas e chapéus. | R$ 19,90 |
| `kit_ferramentas` | Kit de ferramentas | 3 martelos, 3 pás e 3 trocas de peças. | R$ 4,90 |
| `passe_capi` | Passe do Capi premium | Trilha premium da temporada: 1 lendário exclusivo, 2 raros exclusivos, 140 estrelas e ferramentas. | R$ 9,90 na temporada 1 (lançamento); R$ 14,90 a partir de 01/12/2026 |
| `lendario_mascara_heroi` | Máscara de Herói | Item lendário do Capi. | R$ 9,90 (US$ 1,99) |
| `lendario_asinhas` | Asinhas de Anjo | Item lendário do Capi. | R$ 9,90 (US$ 1,99) |
| `lendario_arco_iris` | Pelagem Arco-Íris | Item lendário do Capi. | R$ 9,90 (US$ 1,99) |
| `lendario_galaxia` | Pelagem Galáxia | Item lendário do Capi. | R$ 9,90 (US$ 1,99) |
| `lendario_colar_diamante` | Colar de Diamante | Item lendário do Capi. | R$ 9,90 (US$ 1,99) |
| `lendario_jetpack` | Mochila a Jato | Item lendário do Capi. | R$ 9,90 (US$ 1,99) |

- Os preços em outros países podem ser convertidos automaticamente pela
  Play Console.
- No jogo, o preço mostrado vem da Play Store; os valores acima só aparecem
  enquanto a loja não responde.
- Os lendários (`lendario_*`) aparecem um por dia no **Mercado do Capi**
  (guarda-roupa, aba Mercado). São **compras únicas** e voltam com
  "Restaurar compras".
- Remover anúncios e o Pacote Inicial são **compras únicas**: voltam com
  "Restaurar compras" num celular novo. Estrelas e o kit podem ser
  comprados várias vezes.
- O Passe do Capi premium vale para a **temporada em que foi comprado**
  (30 dias). Na Play Console ele é um produto comum, como as estrelas: o app
  consome a compra, e o jogador pode comprar de novo na temporada seguinte.
  Regras e prêmios: `lib/core/passe.dart` e `docs/passe.md`.
- O Pacote Inicial aparece só nos **3 primeiros dias** desde que o jogador
  abriu a versão com a loja, e só para quem ainda vê anúncios.

## Antes da primeira venda

1. **Perfil de pagamentos sem pendências** (Play Console → Configurações →
   Perfil de pagamentos). Sem isso a Play Console não deixa criar produtos.
2. **Programa de taxa de serviço de 15%** (Play Console → Configurações →
   Programa de taxa de serviço): o Google fica com 15% em vez de 30% no
   primeiro US$ 1 milhão por ano.
3. **Testadores de licença** (Play Console → Configurações → Teste de
   licença): o e-mail do Carlos. Testadores compram sem cobrança de
   verdade, para conferir antes de lançar.
4. Na **Segurança dos dados**, nada muda: o pagamento é todo do Google e o
   app não envia dados de compra a servidores próprios. As compras ficam
   salvas só no aparelho.

## Como funciona no código

- `lib/shop/produtos.dart`: o catálogo e a entrega (`Entrega.aplicar`).
  Uma compra única entrega o conteúdo uma vez só; um consumível, uma vez
  por compra (o ID da compra fica salvo), mesmo que a loja o reenvie.
- `lib/shop/loja_play.dart`: Google Play Billing (`in_app_purchase`).
  Escuta as compras desde a abertura do jogo e, no Android, consulta o
  Google a cada abertura: é assim que chega um Pix aprovado com o jogo
  fechado. Só entrega o que já foi pago (restaurar marca tudo como
  "restaurada", até Pix não pago, então vale o estado real da compra) e só
  depois confirma ao Google (sem a confirmação o Google estorna em 3 dias).
  Consumíveis são consumidos pelo jogo, depois da entrega, e não pelo
  consumo automático do plugin, que se perde se o jogo fechar antes.
- `LojaSimulada`: nos testes do navegador e na web em depuração, a compra
  passa na hora. A versão web publicada não tem loja.
- Ainda não há servidor para validar as compras; a validação é a do
  Google Play no aparelho. Se um dia houver fraude, o próximo passo é
  validar no Supabase.
