# Estatísticas de uso (Firebase Analytics)

O app Android registra eventos anônimos de uso (`lib/services/analytics.dart`).
Projeto do Firebase: **CapiBlocks** (`capiblocks`, número 731810631964), plano
grátis (Spark), conta cewmusica@gmail.com. App Android `com.capiblocks.app`.
AdMob e Google Play ainda não vinculados (opcional).

## Como foi ligado

1. Em https://console.firebase.google.com, crie o projeto **CapiBlocks** com a
   conta Google da empresa. O Google Analytics é ativado durante a criação.
2. **Adicionar app → Android**, com o pacote `com.capiblocks.app`.
3. Baixe o `google-services.json` e mande para o Claude. Dele saem os 4
   valores de `lib/services/firebase_config.dart`: `api_key`,
   `mobilesdk_app_id`, `project_number` e `project_id`. Esses valores não são
   segredo: ficam dentro de qualquer app publicado.

## O que é registrado

| Evento | Quando | Dados |
|---|---|---|
| `level_start` | começa uma partida | modo, fase |
| `level_end` | a partida termina | modo, fase, venceu (1/0), pontos, usou "Continuar" (1/0), progresso (0 a 100), jogadas, segundos, tentativa |
| `revive` | usou "Continuar" | modo, fase |
| `tool_use` | usou uma ferramenta | ferramenta |
| `ad_offer` | apareceu uma oferta de vídeo: Continuar, dobrar estrelas, baú extra, continuar na Torre | onde, modo, fase, progresso |
| `reward_ad` | pediu um vídeo com recompensa | onde, ganhou (1/0) |
| `ad_revenue` | um anúncio foi exibido e o AdMob estimou quanto pagou | tipo, onde, valor, moeda |
| `interstitial_ad` | apareceu um anúncio entre fases | fase |
| `obra_end` | terminou uma obra | obra, estrelas |
| `tower_end` | caiu a Torre do Capi | altura, maior combo |
| `screen_open` | abriu vila, torre, obras, guarda-roupa ou missões | tela |
| `tutorial_complete` | terminou as fases de introdução | — |

O Firebase também mede sozinho: primeira abertura, sessões, retenção (quantos
voltam no dia 1, 7 e 30), país e modelo do aparelho.

Perguntas que esses dados respondem:
- Em qual fase os jogadores desistem? (`level_end` com `success = 0` por fase)
- Quantos voltam no dia seguinte? (relatório de retenção)
- Quais modos são jogados? (`level_start` por modo, `screen_open`)
- Os vídeos com recompensa são usados? (`reward_ad`)
- De cada 100 jogadores que veem uma oferta, quantos aceitam? (`reward_ad`
  dividido por `ad_offer`, por lugar)
- Quem perde perto da meta aceita mais o "Continuar"? (`ad_offer` e
  `level_end` por faixa de progresso)
- Quanto rende cada tipo de anúncio e cada oferta? (`ad_revenue`)

`progresso` é a parte da meta já cumprida (média das metas da fase); no
Infinito e no Blitz, é a parte do recorde. `tentativa` é 1 mais as derrotas
seguidas na fase. Se o AdMob for vinculado ao Firebase, ele passa a registrar
sozinho o evento `ad_impression` com a receita: nesse caso use um dos dois,
não some.

Os números de anúncios mudam sem versão nova: veja `docs/ajustes-remotos.md`.

O jogador pode desligar as estatísticas em **Configurações → Estatísticas de
uso**. Os dados não alimentam a personalização de anúncios.

## Play Console (junto com o envio da 1.1.0)

Some estes itens às respostas do AdMob em `docs/admob.md`, conferindo o guia
oficial: https://firebase.google.com/docs/android/play-data-disclosure

- **Atividade no app → Interações no app:** coletado; finalidade **análise**.
- **Informações e desempenho do app → Diagnóstico:** coletado; finalidade
  **análise**.
- **IDs do dispositivo ou outros:** coletado (ID da instância do app);
  finalidade **análise**.
- O usuário pode desativar a coleta? **Sim** (Configurações).
