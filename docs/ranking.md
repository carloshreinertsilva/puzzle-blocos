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
- **O nome é obrigatório:** enquanto o jogador não tem um, o menu pede o
  nome toda vez que abre (janela sem "Agora não", que não fecha no voltar),
  e nenhuma partida começa pelo menu antes disso. A tela do Ranking também
  pede, do mesmo jeito. Só o duelo continua com "Agora não" (lá o nome é o
  que o amigo vê). Assim todo jogador entra no ranking desde a primeira
  partida. Código: `_garantirNome` em `lib/screens/home_screen.dart` e
  `pedirNomeObrigatorio` em `lib/ui/nome_dialog.dart`.
- **Quando a linha é enviada:** ao abrir o menu (quem já tinha recordes
  entra no próximo login), no fim de cada partida que conta no ranking
  (Fases vencidas, Infinito, Blitz e Torre, mesmo sem voltar ao menu), ao
  voltar de uma partida para o menu, ao salvar o nome e ao abrir a tela do
  Ranking. Só vai o que mudou desde o último envio, e os envios esperam um
  pelo outro (`RankingSync.enviar` em `lib/services/ranking_servidor.dart`).
- **Código:** `lib/core/ranking.dart` (o que o celular decide),
  `lib/services/ranking_servidor.dart` (Firebase) e
  `lib/screens/ranking_screen.dart` (a tela). Regras em `firestore.rules`,
  testadas em `tool/firestore/` (`npm test`).

## O ranking fora da tela do ranking

- **No menu:** o cartão Ranking mostra a melhor posição do jogador na semana
  ("14º na semana"), com uma seta verde se ele subiu ou vermelha se caiu desde
  a última vez que abriu o ranking.
- **No fim da partida** (Infinito, Blitz e Torre): "Você está em 14º no ranking
  da semana. Faltam 230 pontos para subir de posição!".
- Não aparece nome de outro jogador nesses lugares, só a posição.
- Código: `lib/services/ranking_resumo.dart` e `lib/ui/posicao_ranking.dart`.
  Cada posição custa 2 leituras no Firestore e fica guardada por 4 minutos.

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

O plano gratuito do Firestore dá 50 mil leituras e 20 mil gravações por
dia. Abrir um placar lê no máximo 25 linhas e a lista fica guardada por 4
minutos no celular; a pontuação só é enviada quando muda.

Com o nome obrigatório, **todo jogador grava no Firestore**, não só quem
abria o Ranking. Cada partida com recorde novo da semana grava até 2 linhas
(a da semana e, se for recorde de sempre, a de sempre); uma fase vencida
sempre muda a linha da semana das Fases. Conta grosseira: 20 mil gravações
por dia dão para uns 2 a 3 mil jogadores ativos por dia jogando várias
partidas. Se passar disso, o Firestore recusa as gravações até o dia
seguinte (o jogo continua funcionando; a linha vai no próximo envio).
Dá para acompanhar o uso em **Firestore Database → Uso**.
