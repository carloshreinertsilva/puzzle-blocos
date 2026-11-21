# Apple: rejeição 2.1(b), compras não encontradas (21/11/2026)

Depois da 4.3 (veja `revisao-4.3.md`), a Apple seguiu com a revisão da
**1.12.2 (17)** e parou na regra **2.1(b) Information Needed**: o revisor,
num iPhone 17 Pro Max, não achou nenhuma das 13 compras. A captura que ele
mandou mostra a primeira fase do jogo, em inglês.

## O que aconteceu

- O contrato de apps pagos está ativo (5/11/2026 a 5/11/2027) e os IDs das
  compras no App Store Connect são os mesmos de `lib/shop/produtos.dart`.
- Até a 1.15.1, o botão da loja no menu só aparecia **depois que a App Store
  devolvia os produtos**. No ambiente de teste da revisão a consulta pode
  falhar ou demorar (compras que nunca foram aprovadas). Nesse caso o botão
  sumia, e o Passe e o Mercado diziam "ainda não está à venda no iPhone".
  Ou seja: o revisor não tinha caminho nenhum até as compras.
- Quem acabou de instalar começa direto na Fase 1 (o tutorial), então o
  revisor também precisa saber como chegar ao menu.

## O que mudou na 1.15.2 (build 25 no TestFlight)

- O botão **Loja** fica sempre no menu do celular (`LojaService.existe`).
- Ao abrir a loja ou o Passe, se os produtos não vieram, o jogo pergunta de
  novo à loja; comprar também pergunta de novo antes de desistir. A loja
  mostra "Conectando à loja..." e, se a loja do celular não responder,
  "Tentar de novo". Os itens continuam listados com os preços de referência.

## Reenvio

1. Mandar a 1.15.2 ao TestFlight (execução 25 do workflow, então build 25).
2. No App Store Connect, trocar o número da versão de 1.12.2 para **1.15.2**
   e escolher o build **25**.
3. Colar a resposta abaixo em "Responda à equipe de revisão de apps" e
   reenviar.

## Resposta à Apple

> Hello App Review team,
>
> Thank you for the review. We found the cause: in build 17, the Shop button
> only appeared after the App Store returned the product list. When the
> sandbox did not answer in time, the button was hidden, so there was no way
> to reach the In-App Purchases. We have submitted build 1.15.2 (25), where
> the Shop is always on the main menu and asks the App Store again when it is
> opened. There are no storefront or device restrictions on the purchases.
>
> **Steps to find the In-App Purchases:**
>
> 1. A new player starts directly in Level 1 (the tutorial). Tap the
>    **pause** button (top-left) and then **Menu** to go to the main menu.
> 2. On the main menu, tap the **Shop** button in the top bar (right of
>    "Daily Missions", with a storefront icon). "Capi's Shop" opens with:
>    - **Pacote Inicial** (Starter Pack), shown during the first 3 days after
>      installing;
>    - **Remover anúncios** (Remove Ads);
>    - **Passe do Capi premium** (Capi Pass premium track), which opens the
>      Capi Pass;
>    - **150 / 400 / 1.000 estrelas** (star packs);
>    - **Kit de ferramentas** (Tool Kit).
> 3. **Legendary outfits** (Máscara de Herói, Asinhas de Anjo, Pelagem
>    Arco-Íris, Pelagem Galáxia, Mochila a Jato, Colar de Diamante): these
>    six are sold **one per day, by design**. Each day the game offers a
>    single legendary item, the same for every player, in a fixed rotation
>    (no randomness), so only one of the six can be bought on a given day.
>    Today's item appears as **"Legendary of the day"** in the **"Today's
>    deals"** section of the Shop, and on that item in the Wardrobe. The
>    offer changes at midnight, device time. To review the other five, move
>    the iPhone's date forward one day at a time (Settings → General → Date &
>    Time, with "Set Automatically" off) and reopen the Shop: after six days the rotation starts again.
> 4. The **Capi Pass** can also be opened from its card on the main menu;
>    the premium track is bought from there.
>
> Thank you, and please let us know if anything else is needed.
>
> Best regards,
> Carlos Reinert – CHS TECH

Tradução (só para conferência): achamos a causa. No build 17 o botão da loja
só aparecia depois que a App Store devolvia os produtos; quando o ambiente de
teste não respondia a tempo, o botão sumia. No build 1.15.2 (29) a loja fica
sempre no menu e pergunta de novo à App Store quando é aberta. Não há
restrição por país nem por aparelho. Passo a passo: sair da Fase 1 pela pausa
→ Menu; tocar em Loja no topo do menu; lá estão o Pacote Inicial (3 primeiros
dias), Remover anúncios, Passe premium, pacotes de estrelas e o Kit. Os
lendários são vendidos um por dia, de propósito: o mesmo para todos, em ordem
fixa e sem sorteio, então só um dos seis pode ser comprado em cada dia. O do
dia aparece em "Ofertas de hoje" (e no guarda-roupa, no próprio item) e muda à
meia-noite do aparelho; para ver os outros cinco, o revisor adianta a data do
iPhone um dia de cada vez e abre a loja de novo. O Passe também abre pelo cartão no menu.
