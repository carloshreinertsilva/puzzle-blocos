# Ranking do jogo

O CapiBlocks tem um ranking próprio, guardado no Firebase (projeto
`capiblocks`, plano gratuito), igual no Android e no iPhone. Na web ele não
aparece: o botão Ranking mostra as estatísticas do jogador.

- **Placares:** Torre do Capi (andares), Infinito (pontos), Blitz 60s
  (pontos) e Fases (fases concluídas).
- **Listas:** a da semana (recomeça toda segunda-feira, 00:00 UTC; nas
  Fases conta quantas o jogador venceu na semana) e a de sempre (os
  recordes).
- **Nome:** o jogador escolhe (3 a 16 letras). Passa por um filtro de
  palavrões (`lib/core/nome_filtro.dart`) e pode ser denunciado.
- **Código:** `lib/core/ranking.dart` (o que o celular decide),
  `lib/services/ranking_servidor.dart` (Firebase) e
  `lib/screens/ranking_screen.dart` (a tela). Regras em `firestore.rules`,
  testadas em `tool/firestore/` (`npm test`).

## Moderação (pelo console do Firebase)

Tudo em **Firestore Database → Dados**:

- **Denúncias:** coleção `denuncias`. Cada documento tem o `nome`
  denunciado, o `uid` do jogador, o `quadro` e quem denunciou (`por`).
- **Esconder um jogador de todas as listas:** no documento
  `config/ranking`, acrescente o `uid` dele ao campo `ocultos` (lista de
  textos). Vale para todos os jogadores na próxima vez que abrirem o jogo.
- **Proibir mais uma palavra nos nomes:** acrescente-a ao campo `palavras`
  do mesmo documento `config/ranking` (em minúsculas, sem acento).
- **Apagar a linha de um jogador:** em
  `rankings/<quadro>/jogadores/<uid>` (por exemplo `torre_geral`).

Se `config/ranking` ainda não existir, crie o documento com os campos
`ocultos` e `palavras` (os dois do tipo lista), vazios.

## Custos

O plano gratuito do Firestore dá 50 mil leituras por dia. Abrir um placar
lê no máximo 25 linhas e a lista fica guardada por 4 minutos no celular; a
pontuação só é enviada quando muda. Dá para acompanhar o uso em **Firestore
Database → Uso**.
