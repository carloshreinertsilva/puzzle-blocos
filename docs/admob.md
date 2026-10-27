# AdMob: como ativar os anúncios reais

O código do AdMob já está no app (`lib/ads/admob_service.dart`). Hoje ele usa
só os **anúncios de teste do Google**. Para ligar os anúncios reais, siga os
passos abaixo, nesta ordem.

## 1. Conta e blocos de anúncio (pode ser feito já)

1. Entre em https://admob.google.com com a conta Google da empresa (CHS
   CONSULTORIA LTDA) e preencha os dados de pagamento e impostos.
2. **Apps → Adicionar app → Android**.
   - Se o app ainda não estiver aprovado na Play Store, responda que ele
     **ainda não foi publicado**. O vínculo com a loja é feito depois (passo 3).
   - Nome: CapiBlocks.
3. Crie dois **blocos de anúncios** no app:
   - **Premiado** (com recompensa), nome "Continuar e ferramentas";
   - **Intersticial**, nome "Entre fases".
4. Mande para o Claude:
   - o **ID do app**, no formato `ca-app-pub-0000000000000000~0000000000`;
   - os **2 IDs dos blocos**, no formato `ca-app-pub-0000000000000000/0000000000`.

   Eles entram em `android/app/src/main/AndroidManifest.xml` (ID do app) e em
   `lib/ads/ad_config.dart` (`prodRewarded` e `prodInterstitial`). Esses IDs
   não são segredo: ficam visíveis dentro de qualquer app publicado.
5. **Mensagem de consentimento:** em **Privacidade e mensagens → GDPR**, crie e
   publique a mensagem para o app. O app já mostra essa mensagem sozinho onde a
   lei exige (Europa e Reino Unido). Sem ela publicada, os anúncios nessas
   regiões ficam limitados.

> Nunca clique nos seus próprios anúncios reais nem peça a amigos que cliquem:
> o AdMob suspende a conta por tráfego inválido. Para testar, use o APK de
> teste do CI (`capiblocks-apk-teste`) ou registre o seu celular como
> **dispositivo de teste** no AdMob (Configurações → Dispositivos de teste).

## 2. Testar no celular (anúncios de teste)

Cada execução do CI gera o artefato **`capiblocks-apk-teste`** (GitHub →
Actions → a execução → Artifacts). Instale o `.apk` no celular. Os anúncios
aparecem com o selo "Test Ad", tanto o "Continuar" e as ferramentas quanto o
anúncio entre fases. O anúncio entre fases só aparece depois da fase 6, com o
app aberto há mais de 5 minutos.

## 3. Depois que o app for aprovado na Play Store

1. No AdMob, em **Apps → CapiBlocks → Configurações do app**, vincule o app à
   loja (procure por `com.capiblocks.app`). O AdMob faz uma revisão do app;
   até ela terminar, os anúncios ficam limitados.
2. **`app-ads.txt`:** publique o arquivo em
   `https://www.chstech.dev.br/app-ads.txt` (na raiz do site informado como
   site do desenvolvedor na Play Console), com esta linha, trocando pelo seu
   ID de editor (o número `pub-...` do ID do app):

   ```
   google.com, pub-0000000000000000, DIRECT, f08c47fec0942fa0
   ```

## 4. Play Console, no envio da versão com anúncios (1.1.0)

Sugestões; confira cada resposta na hora de enviar.

- **Conteúdo do app → Anúncios:** "Sim, meu app contém anúncios".
- **Conteúdo do app → ID de publicidade:** "Sim", com a finalidade
  **Publicidade ou marketing**. O SDK do AdMob já inclui a permissão
  `AD_ID`.
- **Segurança dos dados:** siga o guia oficial do Google para o AdMob:
  https://developers.google.com/admob/android/privacy/play-data-disclosure
  - Em resumo, o SDK **coleta e compartilha**: **Local aproximado**,
    **Informações e desempenho do app** (registros de falhas, diagnóstico),
    **IDs do dispositivo ou outros IDs** e **Atividade no app** (interações).
  - Finalidades: publicidade ou marketing, análise e prevenção de fraudes.
  - Dados criptografados em trânsito: sim.
- **Público-alvo:** mantenha 13 anos ou mais. Incluir menores de 13 anos coloca
  o app nas regras de famílias do Google, que exigem outra configuração de
  anúncios.
- A política de privacidade (`web/privacidade/index.html`) já descreve o
  AdMob; confira se ela ainda está de acordo antes de enviar.
