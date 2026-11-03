# Notificações (Android, a partir da 1.4.0)

Tudo sem custo e sem servidor nosso (`lib/services/avisos.dart`).

## 1. Lembretes diários (no próprio celular)

- Desligados até o jogador aceitar.
  - O app pergunta uma vez, depois do primeiro presente do dia.
  - Também dá para ligar ou desligar em Configurações → Lembretes diários.
- No Android 13 ou mais novo, o Android pede a permissão de notificações.
- Toda vez que o jogo abre, ele agenda lembretes para os próximos 3 dias,
  às 19h. Quem joga todo dia nunca recebe; quem some recebe no máximo 3 e
  depois eles param.
  1. "Presente do Capi 🎁: seu presente de hoje está esperando."
  2. "O Capi sentiu sua falta 🐹: as missões de hoje já chegaram."
  3. "A vila espera por você."

## 2. Mensagens pelo Firebase (novidades, versão nova, eventos)

Todo celular com a 1.4.0 ou mais nova assina o tópico `novidades`. Para
mandar uma mensagem a todos:

1. https://console.firebase.google.com → projeto **CapiBlocks** →
   **Mensagens** (Messaging) → **Nova campanha** → **Notificações**.
2. Título e texto. Exemplo: "Saiu a versão 1.5.0! 🎉" / "Novas roupas
   para o Capi. Atualize na Play Store."
3. **Destino:** escolha **Tópico** e digite `novidades`.
4. Agende ou envie agora. É grátis no plano Spark.

Com o jogo aberto, a mensagem aparece como notificação normal (canal
"Novidades"). Quem tem versões antigas ou não deu permissão não recebe.

## 3. Aviso de atualização dentro do jogo

Quando a Play Store tem uma versão mais nova, o jogo mostra a tela do
Google "Atualização disponível" ao abrir o menu, no máximo uma vez por
dia. Só funciona em quem instalou pela Play Store.

## Play Console: Segurança dos dados

O Firebase Messaging usa um identificador do aparelho (token) para
entregar as mensagens. Na Segurança dos dados, em **IDs do dispositivo ou
outros IDs**, acrescente a finalidade **Funcionalidade do app**. Esse
item já é declarado por causa do AdMob e do Analytics.
