# Histórico Completo de Desenvolvimento — CapiBlocks

> **Projeto:** CapiBlocks: Blocos e Capivaras (`com.capiblocks.app`)  
> **Desenvolvedor Titular:** CHS CONSULTORIA LTDA (Marca: CHS TECH)  
> **Website Institucional:** [https://www.chstech.dev.br](https://www.chstech.dev.br)  
> **Ambiente Web do Jogo:** [https://capiblocks.vercel.app](https://capiblocks.vercel.app)  
> **E-mail de Suporte e Contato:** `contato@chstech.dev.br`  
> **Status Atual:** Publicado na Google Play Store — **Em Análise (In Review)** 🚀

---

## 1. Visão Geral do Projeto e Mecânicas Desenvolvidas

O **CapiBlocks** é um jogo casual de quebra-cabeça de blocos desenvolvido em **Flutter + Flame**, desenhado para proporcionar uma experiência fluida, relaxante e rica em progressão, com o mascote **Capi** (uma capivara construtora carismática).

### 🧩 Núcleo de Jogabilidade (Gameplay Core)
- **Tabuleiro 8x8 Clássico:** Encaixe de peças geométricas com detecção de linhas e colunas completas, liberação de espaço e sistema de pontuação com combos e elogios animados (*"Muito bem!"*, *"Incrível!"*, *"Espetacular!"*).
- **Gerador Procedural Infinito (`LevelGenerator`):**
  - Fases infinitas geradas deterministicamente via algoritmo matemático (`seed = n * 7919 + 17`), garantindo que qualquer fase seja idêntica para todos os jogadores no mundo sem precisar baixar arquivos da internet.
  - **Curva de Dificuldade Dente de Serra (*Sawtooth*):** Ciclos de 6 fases com progressão gradual (4 fases de subida, 1 fase difícil no pico e 1 fase de alívio relaxante), evitando fadiga e frustração do jogador.
  - **4 Metas Combinadas:** Pontuação alvo, pedras quebráveis (1 e 2 vidas), gemas coloridas colecionáveis e resgate de filhotes de capivara presos em bolhas.
  - **Desenhos Iniciais no Tabuleiro (`boardPatterns`):** Tabuleiros temáticos gerados no início das partidas para acelerar a dinâmica de limpeza.

### 🏝️ Vila do Capi em 2.5D (Metagame Isométrico)
- Ilha flutuante isométrica renderizada em tempo real com profundidade 2.5D.
- 12 construções desbloqueáveis com as estrelas conquistadas nas fases: canteiro de flores, cerca de madeira, banco de praça, pé de acerola, casinha de telhado vermelho, lago com barquinho, roda-gigante animada, etc.
- Interatividade: Toques no Capi e nos filhotes disparam reações com balões de fala, risadas e animações táteis.

### 📐 Modo Obra (Quebra-Cabeça Geométrico)
- Liberado após a fase 6.
- O jogador recebe plantas arquitetônicas azuis (*blueprints*) e precisa encaixar todas as peças geométricas fornecidas para preencher a silhueta da construção sem deixar vãos.

### ⚡ Modos Rápidos e Competitivos
- **Modo Blitz (60s):** Partida acelerada contra o relógio com multiplicadores de combo e bônus de segundos extras a cada limpeza de linha.
- **Modo Duelo:** Desafio com amigos através de link direto compartilhável, gerando exatamente o mesmo tabuleiro e sequência de peças para comparar pontuações.
- **Torre do Capi (2.5D):** Minijogo de empilhamento de blocos oscilantes com física de fatiamento de sobras e o Mini Capi escalando os andares com efeito *"Perfeito! xN"*.

### 🛠️ Ferramentas do Capi
- **Martelo:** Quebra 1 bloco ou pedra isolada no tabuleiro.
- **Girar:** Gira uma peça da bandeja antes de posicioná-la.
- **Trocar (Reroll):** Troca as 3 peças da bandeja por novas opções.
- **Pá 3x3:** Limpa uma área inteira de 9 blocos para salvar partidas apertadas.

### 👒 Missões Diárias, Baú e Coleção de Chapéus
- Sistema de 3 missões geradas por dia com controle de sequências (*streaks*).
- Abertura do **Baú de Tesouros do Capi** com recompensa de estrelas.
- **Guarda-Roupa do Capi:** Carrossel de chapéus cosméticos colecionáveis que alteram o visual do Capi no jogo e na vila (Capacete de Obra, Coroa Real, Chapéu de Chef, Tricórnio Pirata, Chapéu de Festa, Chapéu de Mago).

---

## 2. Presença Digital e Identidade da Empresa

Para viabilizar a publicação profissional nas lojas e cumprir as exigências da Google e da Apple:

1. **Titularidade Jurídica:**
   - **Razão Social:** CHS CONSULTORIA LTDA
   - **Nome Fantasia / Marca Tecnológica:** CHS TECH
   - **Localidade:** Joinville, SC - Brasil
2. **Site Institucional no Ar:**
   - Criamos e publicamos o site responsivo em [https://www.chstech.dev.br](https://www.chstech.dev.br).
   - Apresenta as informações corporativas oficiais, portfólio de tecnologia, conformidade e links de suporte.
3. **E-mail Profissional Próprio:**
   - Domínio `chstech.dev.br` registrado no Registro.br e conectado via DNS à Cloudflare.
   - Ativação do **Email Routing** da Cloudflare: `contato@chstech.dev.br` com encaminhamento automático para a caixa principal.
4. **Política de Privacidade Publicada e Homologada:**
   - Publicada em página dedicada: [https://capiblocks.vercel.app/privacidade/](https://capiblocks.vercel.app/privacidade/).
   - 100% alinhada com a LGPD e exigências da Google Play Store (sem rastreamento invasivo, jogo offline e armazenamento estritamente local).

---

## 3. Materiais Visuais e de Marketing (Google Play Store)

Todos os ativos de marketing foram produzidos sob medida para atender rigorosamente às diretrizes visuais da Play Store:

1. **Ícone Oficial (512x512):** [docs/loja/icone-512.png](file:///c:/Users/carlos/Desktop/Pessoal/Capiblocks/docs/loja/icone-512.png)
   - Capi com capacete de obra segurando um bloco dourado com fundo gradiente contrastante.
2. **Gráfico de Recursos / Banner (1024x500):** [docs/loja/banner-1024x500.png](file:///c:/Users/carlos/Desktop/Pessoal/Capiblocks/docs/loja/banner-1024x500.png)
   - Composição horizontal equilibrada, ilha 2.5D ao centro, logo estilizado, Capi construtor e blocos coloridos flutuantes.
3. **6 Capturas de Tela do Smartphone (1080x1920 - 9:16):**
   - Refatoração do script [tool/loja_capturas.js](file:///c:/Users/carlos/Desktop/Pessoal/Capiblocks/tool/loja_capturas.js) em Playwright.
   - Tipografia oficial do jogo (`Lilita One`) aplicada nos títulos superiores com contorno escuro e relevo 3D.
   - Moldura de smartphone dedicada sem sobrepor os cabeçalhos das telas.
   - Tabuleiros reais em ação:
     - `screenshot-1-partida.png`: Partida clássica com combo *"Muito bem!"* e gemas.
     - `screenshot-2-vila.png`: Vila do Capi 2.5D com botão *"Construir"* e custos desimpedidos.
     - `screenshot-3-filhotes.png`: Fase 8 com filhotes de capivara nas bolhas e blocos coloridos.
     - `screenshot-4-obra.png`: Modo Obra (*"Estrela"*) com peças já posicionadas na planta.
     - `screenshot-5-modos.png`: Torre do Capi em 2.5D com 6 andares empilhados e selo *"Perfeito! x6"*.
     - `screenshot-6-chapeus.png`: Guarda-Roupa do Capi com a Coroa Real equipada e chapéus desbloqueados.

---

## 4. Polimento Técnico e Preparação de Produção

### A. Política de Privacidade In-App (Offline & Web)
- Criado o componente [lib/ui/privacy_dialog.dart](file:///c:/Users/carlos/Desktop/Pessoal/Capiblocks/lib/ui/privacy_dialog.dart).
- Permite que jogadores e revisores da Google leiam a íntegra dos termos legais dentro do aplicativo mesmo sem internet, com botão para abrir a versão online.

### B. Nuvem & Conquistas (removido na v1.0.1)
- A versão 1.0.0 tinha um cartão "Nuvem & Conquistas" nas configurações que **simulava** a conexão com o Google Play Games e a sincronização: nada era salvo fora do aparelho.
- Na v1.0.1 o cartão e o serviço simulado foram removidos, para não prometer um backup que não existe.
- Para voltar, é preciso integrar de verdade o Play Games Services (Saved Games), com login real e testes.

### C. Estrutura de Anúncios Google AdMob
- **v1.1.0: AdMob integrado** (`google_mobile_ads`, só Android), em `lib/ads/admob_service.dart`:
  - mensagem de consentimento do Google (UMP) antes de pedir anúncios, e o botão "Privacidade dos anúncios" nas configurações quando a lei exige;
  - um vídeo com recompensa e um intersticial ficam carregados; se o vídeo não carregar em 8 s, o jogador vê "Nenhum vídeo disponível agora";
  - intersticial que não carregou é pulado, sem esperar, e não conta no intervalo da política;
  - só anúncios com classificação até PG;
  - versões de depuração usam os IDs de teste do Google; a versão da loja usa os IDs reais de `lib/ads/ad_config.dart` e, enquanto eles estiverem vazios, não mostra anúncios;
  - o CI gera também um APK com anúncios de teste (`capiblocks-apk-teste`) para conferir no celular;
  - passo a passo para os IDs reais, o `app-ads.txt` e os formulários da Play Console: `docs/admob.md`.
- **v1.1.0: estatísticas de uso** (Firebase Analytics, só Android), em `lib/services/analytics.dart`:
  - eventos anônimos de partidas, modos, ferramentas, anúncios, obras e torre;
  - desligados enquanto `lib/services/firebase_config.dart` estiver vazio;
  - o jogador pode desligar em Configurações → Estatísticas de uso;
  - política de privacidade (página e app) atualizada;
  - passo a passo e respostas da Play Console: `docs/estatisticas.md`.
- Antes disso:
  - Na v1.0.0, a versão publicada usava o simulador `DebugAdService`: aparecia uma tela preta escrita "Anúncio (teste)" entre fases e ao pedir ferramentas.
  - Na v1.0.1 a versão publicada usa o `NoAdService`:
    - sem anúncios entre fases;
    - o "Continuar" vira uma chance extra grátis por partida;
    - a oferta "ferramenta grátis com vídeo" fica escondida.
  - O simulador continua só nas versões de teste e depuração.
- Criado [lib/ads/ad_config.dart](file:///c:/Users/carlos/Desktop/Pessoal/Capiblocks/lib/ads/ad_config.dart) com os IDs de teste oficiais da Google para Intersticiais e Recompensados (evitando qualquer penalização por tráfego inválido na fase de testes).
- Inserido o metadado `APPLICATION_ID` em [android/app/src/main/AndroidManifest.xml](file:///c:/Users/carlos/Desktop/Pessoal/Capiblocks/android/app/src/main/AndroidManifest.xml).

### D. Chave de Assinatura Privada (*Upload Keystore*)
- Gerado o keystore RSA 4096-bit corporativo `android/upload-keystore.jks` emitido para **CHS CONSULTORIA LTDA** com validade até **2054** (10.000 dias).
- Configurado `android/key.properties` e proteção rigorosa no `android/.gitignore` (chaves nunca sobem para o GitHub público).
- Segredos configurados no GitHub Secrets do repositório:
  - `CAPI_KEYSTORE_BASE64`
  - `CAPI_KEYSTORE_PASSWORD`
  - `CAPI_KEY_ALIAS`
  - `CAPI_KEY_PASSWORD`
- Pipeline de compilação em [.github/workflows/ci.yml](file:///c:/Users/carlos/Desktop/Pessoal/Capiblocks/.github/workflows/ci.yml) compilou e assinou com sucesso o arquivo final de distribuição:
  👉 **`build_release/app-release.aab`** (51.9 MB).

---

## 5. Publicação no Google Play Console

1. **Conta de Desenvolvedor Organizacional:**
   - Conta corporativa da **CHS CONSULTORIA LTDA** aprovada com identificador D-U-N-S e verificação de identidade oficial da Google.
2. **Criação do Aplicativo:**
   - **Nome:** `CapiBlocks: Blocos e Capivaras`
   - **Pacote:** `com.capiblocks.app`
   - **Tipo:** Jogo / Quebra-cabeça (Gratuito)
3. **Formulários e Conformidade (100% Concluídos):**
   - **Acesso ao app:** Sem restrições (jogo aberto sem login obrigatório).
   - **Anúncios:** Declarado "Sim, contém anúncios".
   - **Classificação de Conteúdo (IARC):** Questionário preenchido resultando em selo **Livre / Todos os Públicos** (PEGI 3, ESRB E).
   - **Público-Alvo:** 13 anos ou mais (protegendo a monetização futura e evitando amarras burocráticas infantis).
   - **Segurança dos Dados (Data Safety):** Declarado que não há coleta nem compartilhamento externo de dados.
   - **ID de Publicidade:** Selecionado "Não" para o build de lançamento v1.0.0.
4. **Ficha da Loja Principal:**
   - Nome, breve descrição (70 caracteres) e descrição completa estruturada com emojis.
   - Upload do ícone de 512px, banner de 1024x500 e os 6 screenshots de 1080x1920.
5. **Faixa de Produção:**
   - Adicionados todos os países e regiões.
   - Upload bem-sucedido do arquivo assinado `app-release.aab`.
   - **Situação no Console:** 12 alterações enviadas para revisão.
   - **Status Atual:** **Em Análise (In Review)** pela equipe de engenharia e políticas da Google.

---

## 6. Próximos Passos (Pós-Aprovação na Loja)

1. **Acompanhar a Aprovação:** Prazo médio da Google de 2 a 5 dias úteis.
2. **Ativar o Google AdMob:** Com o app ativo na Play Store, seguir `docs/admob.md` (IDs reais, `app-ads.txt`, formulários da Play Console) e publicar a v1.1.0.
3. **Internacionalização da Ficha:** Adicionar traduções da página da loja para **Inglês** e **Espanhol** para impulsionar downloads globais.
4. **Preparação para a Apple App Store:** Replicar a publicação para o ecossistema iOS (App Store Connect / TestFlight).
