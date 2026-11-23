# Notificações (Android desde a 1.4.0; lembretes no iPhone desde a 1.16.0)

Tudo sem custo e sem servidor nosso (`lib/services/avisos.dart`).

| | Android | iPhone |
|---|---|---|
| Lembretes diários (no próprio celular) | sim | sim (1.16.0) |
| Mensagens pelo Firebase, avisos de duelo | sim | não |
| Aviso de atualização dentro do jogo | sim | não |

No iPhone, mensagens do Firebase e avisos de duelo exigiriam push remoto
(chave APNs e capacidade "Push Notifications" na conta da Apple), que não
está configurado. Os lembretes são notificações locais: não precisam disso.

## 1. Lembretes diários (no próprio celular)

- Desligados até o jogador aceitar.
  - O app pergunta uma única vez, depois do primeiro presente do dia (no
    Android e no iPhone). Quem recusou não é perguntado de novo.
  - Também dá para ligar ou desligar em Configurações → Lembretes diários
    (aparece nos dois).
- Ao aceitar, o celular pede a permissão de notificações (Android 13 ou
  mais novo; no iPhone, sempre). Se o jogador negar ali, o interruptor fica
  desligado. No iPhone o sistema só pergunta uma vez: depois de um "não",
  só nos Ajustes do iPhone → CapiBlocks → Notificações.
- **Cadência:** quem some recebe um lembrete às 19h (hora do celular) no
  1º, 2º, 4º e 7º dia de ausência, e depois eles param. Nunca mais de um
  por dia. Abrir o jogo (e também sair dele) reagenda tudo a partir de
  amanhã, então quem joga todo dia nunca recebe.
  - Por quê: o presente diário e as sequências se perdem depois de um dia,
    então os dois primeiros lembretes vêm seguidos. Depois disso o que
    traz de volta é a lembrança, não a urgência: espaçar (4º e 7º dia) evita
    que o jogador desligue tudo ou desinstale. Depois de uma semana, parar.
- **Textos concretos** (`lib/core/lembretes.dart`, função
  `escolherLembretes`, testada em `test/lembretes_test.dart`). Na hora de
  agendar o jogo olha o que o jogador tem a perder ou a ganhar em cada dia,
  e cada assunto aparece no máximo uma vez, nesta ordem:
  1. **Sequência do presente** (só amanhã, se pegou o de hoje): "Dia 4 do
     presente 🎁 — Hoje tem 1 pá esperando. Se faltar, volta ao dia 1." No
     7º dia: "Dia 7: o maior presente 🎁" (30 estrelas).
  2. **Sequência do Desafio diário** (só amanhã, se jogou hoje e a
     sequência tem 2 dias ou mais): "Sequência de 5 dias em risco 🔥".
  3. **Passe do Capi**: prêmios prontos ("2 prêmios do Passe esperando ⭐",
     com "A temporada acaba em 3 dias" perto do fim do mês) ou um prêmio a
     10 pontos ou menos. Nada sobre o Passe se o lembrete cair já na
     temporada seguinte.
  4. **Vila**: as estrelas já pagam uma construção ("Você já tem estrelas
     para construir o banquinho.").
  5. **Presente do dia**: "Seu presente de hoje: 5 estrelas. Vem pegar!"
  6. Sem nada especial: textos gerais ("O Capi sentiu sua falta 🐹", "A
     vila espera por você", "Faz uma semana! 🐹").
- Tocar num lembrete abre o jogo e registra `lembrete_aberto` (tipo e dia)
  nas estatísticas.

### iPhone: o que foi preciso

- `ios/Runner/AppDelegate.swift`: o app passa a ser o delegado do
  `UNUserNotificationCenter` (pedido do flutter_local_notifications 22.3.3),
  para os lembretes chegarem também com o jogo aberto.
- O plugin é iniciado sem pedir permissão (`DarwinInitializationSettings`
  com os pedidos desligados): a pergunta do iOS só aparece quando o jogador
  diz "Quero!".
- Nada no `Info.plist` e nenhuma capacidade nova: notificação local não
  precisa.

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
