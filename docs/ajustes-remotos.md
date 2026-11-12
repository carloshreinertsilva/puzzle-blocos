# Ajustes sem versão nova (Firebase Remote Config)

Alguns números do jogo mudam pelo console do Firebase, sem publicar versão
(`lib/services/ajustes.dart` e `lib/services/config_remota.dart`). Funciona
no Android e no iOS; na web valem os números de fábrica.

## O que dá para mudar

| Chave | O que é | De fábrica | Limites |
|---|---|---|---|
| `anuncio_intervalo_min` | minutos entre anúncios de tela cheia | 6 | 3 a 30 |
| `anuncio_fase_inicial` | fase a partir da qual há anúncio entre fases | 6 | 3 a 50 |
| `anuncio_carencia_min` | minutos sem anúncio entre fases depois de abrir o app | 5 | 2 a 30 |
| `dobrar_por_dia` | vitórias por dia que podem dobrar as estrelas com vídeo | 10 | 0 a 20 |
| `versao_minima` | número de build mais antigo que ainda pode jogar | 0 (nenhum) | — |

Um valor fora dos limites é trazido para o limite mais próximo: um erro de
digitação no console nunca enche o jogo de anúncios.

## Como mudar

1. Firebase → projeto **CapiBlocks** → **Remote Config**.
2. **Adicionar parâmetro**, com a chave da tabela e um número inteiro.
3. **Publicar alterações**.

O jogo busca os valores quando abre e passa a usá-los **na abertura
seguinte**. Assim nenhum número muda no meio de uma sessão, e demora até
umas horas para todos os jogadores receberem.

## Teste A/B

Firebase → **A/B Testing** → **Criar experimento → Remote Config**. Escolha
a chave (por exemplo `anuncio_intervalo_min` com 6 e 4), a porcentagem de
jogadores e as metas. Sugestão de metas: retenção de 1 e 7 dias como
principal e os eventos `interstitial_ad`, `reward_ad` e `ad_revenue`
(`docs/estatisticas.md`) como secundárias. Uma mudança só fica se a receita
subir sem derrubar a retenção.

## Como adicionar um número novo

1. Campo, chave, valor de fábrica e limites em `Ajustes`.
2. Use `Ajustes.atuais.<campo>` onde o número é lido.
3. Uma linha na tabela acima e um caso em `test/ajustes_test.dart`.
