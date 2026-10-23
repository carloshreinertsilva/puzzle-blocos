# Respostas Sugeridas para os Formulários da Google Play Console — CapiBlocks

> Guia passo a passo com as respostas exatas para preencher as seções de **Conteúdo do App** no Google Play Console.
> **Importante:** Estas respostas foram baseadas na arquitetura real do código do CapiBlocks e nas decisões estratégicas definidas pelo titular (**CHS CONSULTORIA LTDA**).

---

## 1. Segurança dos Dados (Data Safety)

O Google Play exige a declaração de como os dados são coletados, compartilhados e protegidos.

### 📌 Cenário A: Versão Atual (Sem AdMob Real, anúncios simulados)

Caso o aplicativo seja enviado para a loja antes da integração com o SDK oficial do Google Mobile Ads:

1. **O app coleta ou compartilha algum tipo de dado do usuário?**
   - **Resposta:** **Não**.
   - *Justificativa:* O CapiBlocks roda 100% no dispositivo. Todo o progresso (fases, estrelas, itens da vila, recordes, missões e chapéus) fica gravado em `SharedPreferences` local. Não há chamadas HTTP, SDKs de telemetria nem banco de dados em nuvem.

2. **Todos os dados de usuário coletados por esse app são criptografados em trânsito?**
   - **Resposta:** **Sim** (padrão de conformidade).

3. **Você fornece uma forma para os usuários solicitarem a exclusão dos dados?**
   - **Resposta:** **Sim**. Como os dados residem apenas no aparelho, desinstalar o app ou limpar o armazenamento nas configurações do Android apaga permanentemente todos os registros.

---

### 📌 Cenário B: Versão de Produção com Google AdMob Integrado

Quando o SDK `google_mobile_ads` for adicionado ao projeto para veicular anúncios reais:

1. **O app coleta ou compartilha dados de usuários?**
   - **Resposta:** **Sim**.
2. **Todos os dados de usuários coletados são criptografados em trânsito?**
   - **Resposta:** **Sim** (o SDK da Google transmite dados exclusivamente via HTTPS).
3. **Mecanismo de exclusão de dados:**
   - **Resposta:** **Sim** (os dados do jogo são apagados ao desinstalar; dados de anúncios são gerenciados nas configurações de anúncios da conta Google do usuário).

#### Detalhamento das categorias de dados (coletadas pelo SDK do Google AdMob):

| Categoria de Dado | Tipo de Dado | Coletado? | Compartilhado? | Finalidade | Obrigatório / Opcional |
|---|---|---|---|---|---|
| **Localização** | Localização aproximada (baseada em IP) | Sim | Sim | Publicidade / Prevenção contra fraudes | Obrigatório pelo SDK |
| **Identificadores** | IDs do dispositivo (ex.: Google Advertising ID) | Sim | Sim | Publicidade / Análise de audiência | Obrigatório pelo SDK |
| **Atividade no app** | Interações no app (visualizações de anúncios, cliques) | Sim | Sim | Análise e métricas de anúncios | Obrigatório pelo SDK |
| **Diagnóstico** | Dados de desempenho e logs de falha do SDK de anúncios | Sim | Sim | Análise e prevenção contra fraudes | Obrigatório pelo SDK |

> Para consulta oficial dos termos do Google AdMob para preenchimento:
> https://developers.google.com/admob/android/privacy/play-data-disclosure

---

## 2. Classificação de Conteúdo (Questionário IARC)

Ao preencher o questionário IARC (International Age Rating Coalition) na Play Console:

1. **E-mail do desenvolvedor:** `chs.consultoria@outlook.com`
2. **Categoria do app:** **Jogos (Games)**
3. **Violência:**
   - O jogo contém representações de violência? **Não**.
   - Há sangue, mortes ou ferimentos? **Não**.
4. **Medo / Terror:**
   - O jogo contém imagens ou sons assustadores? **Não**.
5. **Sexualidade / Nudez:**
   - O jogo contém material de teor sexual ou nudez? **Não**.
6. **Linguagem:**
   - O jogo contém linguagem potencialmente ofensiva ou palavrões? **Não**.
7. **Substâncias Controladas:**
   - Há menção ou uso de álcool, tabaco ou drogas ilícitas? **Não**.
8. **Jogos de Azar / Apostas:**
   - O jogo simula cassino, apostas com dinheiro real ou apostas virtuais? **Não** (as estrelas são recompensas gratuitas do próprio quebra-cabeça).
9. **Outros:**
   - O jogo permite que os usuários troquem mensagens ou se comuniquem diretamente? **Não** (o modo Duelo gera apenas um link com parâmetros matemáticos para ser enviado por apps de terceiros).
   - O app compartilha a localização física atual do usuário com outros? **Não**.
   - O app permite que o usuário compre produtos digitais? **Não** (por enquanto, o jogo não possui compras in-app).

### 🎯 Resultado Esperado:
- **Brasil (ClassInd):** Livre para todos os públicos (L)
- **Europa (PEGI):** PEGI 3
- **América do Norte (ESRB):** Everyone (E)

---

## 3. Público-Alvo e Conteúdo (Target Audience)

1. **Faixa etária do público-alvo:**
   - Selecione: **13 a 15 anos**, **16 a 17 anos** e **18 anos ou mais**.
   - *Por que não selecionar menores de 13 anos?* Conforme alinhado com o titular, selecionar menores de 13 anos colocaria o aplicativo sob o programa *Designed for Families* do Google, o que impõe restrições severas sobre fornecedores de anúncios, rastreamento do AdMob e formatos publicitários.

2. **Atração involuntária de crianças ("Poderia atrair crianças?"):**
   - O Google pergunta se a arte ou o mascote podem atrair crianças não intencionalmente.
   - **Opção Recomendada:** Selecionar **Sim**.
   - *Consequência:* O Google exibirá um selo informativo na ficha da loja ("Não recomendado para crianças pequenas" ou banner neutro), mas **não** forçará o aplicativo a entrar no programa restrito para famílias, protegendo a receita do Google AdMob.

---

## 4. Anúncios (App Content - Ads)

1. **Seu aplicativo contém anúncios?**
   - Se já estiver com o AdMob ativado: Marque **"Sim, meu app contém anúncios"**.
   - Se for o primeiro upload sem SDK de anúncios: Marque **"Não"** e altere para **"Sim"** quando o AdMob for liberado.
   *(A Google exibirá o rótulo "Contém anúncios" na página da loja).*

---

## 5. Acesso ao Aplicativo (App Access)

1. **Todas as funcionalidades estão disponíveis sem restrições?**
   - **Resposta:** **Sim, todas as funcionalidades estão disponíveis sem credenciais de login ou senhas.**
   - Não é necessário fornecer conta de teste ou login para os revisores do Google.

---

## 6. Notícias e Apps Governamentais

1. **O aplicativo é de notícias?** **Não**.
2. **O aplicativo é um app de rastreamento da COVID-19 ou governamental?** **Não**.
3. **O aplicativo é de serviços financeiros?** **Não**.
