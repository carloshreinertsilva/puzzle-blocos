# A história do CapiBlocks: o Capi contra o Jacaré Trambiqueiro

Proposta de história de fundo para dar carisma ao jogo e criar apego à
família Capi. Este documento só descreve a história; nada aqui está no jogo
ainda. Cada parte de "O que muda no jogo" vira um PR próprio, com entrada em
`lib/core/novidades.dart` quando aparecer para o jogador.

## Em uma frase

O Jacaré Trambiqueiro roubou os blocos da vila e levou os filhotes do Capi
para trabalhar na obra do resort dele. O Capi, que é construtor (por isso o
capacete), refaz a estrada fase por fase para trazer cada filhote de volta.

## Tom

- **Aconchegante e cômico, nunca assustador.** O jacaré é trapalhão e vaidoso,
  não é mau. Ninguém se machuca. Os filhotes estão bem: brincam na obra do
  jacaré, mas morrem de saudade de casa.
- **Para todas as idades.** Nada de sequestro dramático, prisão ou choro
  longo. Os filhotes ficam "presos nas bolhas", como já acontece no tabuleiro.
- **Pouco texto.** Falas de no máximo duas linhas, e toda cena pode ser
  pulada. A história acompanha o jogo, não interrompe.
- **Original.** O jacaré não pode lembrar personagens conhecidos (nada de
  relógio na barriga, nem cartola de vilão de desenho clássico). Visual
  próprio, no mesmo estilo 2.5D brilhante do Capi.

## Personagens

### Capi

O herói. Capivara construtora, calma, otimista, de capacete amarelo. Não
briga: resolve construindo. É quem fala com o jogador, como já faz no
tutorial e no menu.

### Mãe Capi

A família completa: a mãe dos filhotes, companheira do Capi.

- **Papel:** ela não é levada. Ela é o "lar" para onde os filhotes
  voltam. Cuida da vila enquanto o Capi está na estrada, manda as encomendas
  das Obras e recebe cada filhote resgatado com um abraço, que é a cena
  emocional de cada capítulo.
- **Clímax:** no Capítulo 5, ela vai atrás do Capi até o resort e enfrenta o
  jacaré junto com ele na fase final.

### Os filhotes

Cinco filhotes, o mesmo número que cabe na vila ao mesmo tempo
(`Pups.max = 5` em `lib/village/scene.dart`). Cada um usa um laço de uma das
cores que já existem em `PupPainter.bows` (`lib/ui/pup.dart`), então dá para
diferenciá-los sem arte nova.

| Filhote | Laço | Jeito | Resgatado no fim do |
|---|---|---|---|
| **Pipoca** | amarelo | guloso e curioso, o primeiro a se meter em confusão | Capítulo 1 |
| **Jujuba** | rosa | falante, canta o tempo todo (até dentro da bolha) | Capítulo 2 |
| **Tico** | azul | o caçula, medroso, que aprende a ser valente | Capítulo 3 |
| **Fubá** | verde | o inventor, adora encaixar blocos como o pai | Capítulo 4 |
| **Mel** | laranja | a sonhadora, desenha a vila que quer construir | Capítulo 5 |

O laço roxo fica livre para um filhote especial de evento.

Os nomes não se traduzem (são nomes próprios), mas as falas sim.

### Jacaré Trambiqueiro (o "Trambi")

- **Quem é:** um jacaré do Pantanal, vizinho da vila, metido a empresário.
  Usa óculos escuros grandes demais e um colete com crachá escrito "DONO".
- **O que quer:** construir o "Jacarelândia Resort", o maior do Pantanal, só
  para ele. Como não sabe construir, rouba os blocos do Capi e leva os
  filhotes como "ajudantes".
- **Como age:** joga entulho no caminho (as pedras do tabuleiro), esconde as
  gemas (são o "tesouro do resort") e prende os filhotes em bolhas para eles
  não fugirem.
- **Ponto fraco:** é vaidoso e atrapalhado. Os planos dele sempre desabam,
  literalmente.
- **Segredo:** no fundo ele é sozinho e queria ter amigos. No fim do Capítulo
  5 ele é desmascarado, pede desculpas meio sem jeito e vira o vizinho
  encrenqueiro da vila, que volta nos eventos.

## Prólogo (antes do tutorial)

O prólogo vem **antes do tutorial**, para o jogador se comprometer com a
história desde o primeiro toque. A lógica é: para libertar a família é
preciso passar pelas fases, e para passar pelas fases existe o tutorial.

São três quadros, cerca de 10 segundos no total. Um toque avança e
"Pular" aparece desde o primeiro quadro:

1. A vila do Capi ao entardecer. A mãe Capi e os filhotes brincam de
   empilhar blocos.
2. Um barulho no rio. Na manhã seguinte não há mais blocos nem filhotes, só
   pegadas de jacaré e um cartaz: "EM BREVE: JACARELÂNDIA RESORT".
3. O Capi põe o capacete: "O jacaré levou nossos filhotes! Para chegar até
   eles, vou reconstruir a estrada, bloco por bloco. Me ajuda?" O toque leva
   direto ao tabuleiro do tutorial.

O tutorial continua igual, com uma fala de abertura que o liga à história:
"Primeiro, deixa eu te ensinar a construir." Ao terminar, o guia do menu
mostra a estrada e diz onde está a Pipoca.

**Risco:** hoje cerca de 72% de quem abre o jogo começa o tutorial. Antes e
depois do prólogo, medir a passagem `abertura` → `tutorial_begin`. Se cair,
encurtar para dois quadros ou mostrar o terceiro quadro sobre o próprio
tabuleiro.

## Como a história explica o que já existe

| No jogo hoje | Na história |
|---|---|
| Caminho de fases no menu | A estrada que o Capi reconstrói até o resort |
| Pedras no tabuleiro | Entulho que o jacaré jogou no caminho |
| Gemas | O "tesouro do resort" que o jacaré escondeu |
| Filhotes nas bolhas (desde a fase 8) | Os filhotes que o jacaré prendeu |
| Vila do Capi (construída com estrelas) | A vila sendo reconstruída depois do roubo |
| Filhotes passeando na vila | Os filhotes resgatados de volta em casa |
| Obras | Encomendas para reconstruir a vila, peça por peça |

Por isso a história quase não exige mecânica nova: ela dá sentido ao que o
jogador já faz.

## Capítulos

As fases não têm fim (são geradas), então a história ocupa as primeiras 60 e
depois continua em temporadas. Os números abaixo são o ponto de partida e
devem ser ajustados pelos dados de saída por fase.

| Capítulo | Fases | Lugar | Final |
|---|---|---|---|
| 1 | 1 a 8 | Beira do rio | Resgate da Pipoca. A fase 8 já é a que apresenta os filhotes. |
| 2 | 9 a 20 | Campo alagado | Resgate da Jujuba |
| 3 | 21 a 32 | Mata de buritis | Resgate do Tico |
| 4 | 33 a 44 | Canteiro do resort | Resgate do Fubá |
| 5 | 45 a 60 | Jacarelândia Resort | Resgate da Mel e a virada do jacaré |

Depois da fase 60, cada temporada (`docs/temporadas/`) pode trazer um novo
plano do jacaré: um filhote de laço roxo perdido, uma obra rival, um evento
de festa junina na vila.

O Capítulo 1 é curto de propósito: o primeiro resgate precisa acontecer na
primeira sessão, para o jogador sentir a recompensa logo.

## O que muda no jogo

Em ordem de prioridade, do mais simples ao mais trabalhoso. Cada item é um PR.

1. **Meta visível no menu.** No caminho de fases, o próximo filhote aparece
   preso numa bolha na fase do resgate, com "Pipoca está na fase 8". É a
   mudança que mais deve ajudar a retenção, e é a mais barata.
2. **Resgate com nome.** Ao vencer a última fase do capítulo, um cartão
   especial: o filhote sai da bolha, abraça o Capi e vai para a vila. Na vila,
   ele passa a ter nome e laço próprios.
3. **Prólogo e cenas entre capítulos.** Três quadros no começo e dois ou três
   no fim de cada capítulo, sempre com "Pular". Usam as poses que o Capi já
   tem, mais a arte do jacaré.
4. **Fase do jacaré** (a última de cada capítulo). O jacaré aparece ao lado do
   tabuleiro, reage às jogadas e tem uma regra especial leve. Por exemplo, o
   filhote do capítulo fica numa bolha que precisa de duas linhas para soltar.
   A dificuldade segue `lib/core/level.dart` e precisa passar por
   `tool/simulate.dart`.
5. **Ligações com o resto do jogo:**
   - o guia do menu passa a dizer "Me ajuda a buscar a Pipoca?";
   - cada filhote resgatado libera um item no Guarda-Roupa (por exemplo, o
     laço dele como acessório do Capi);
   - os lembretes ganham motivo ("A Jujuba está te esperando na fase 20");
   - os eventos de temporada trazem o jacaré de volta.
6. **Divulgação.** O jacaré rende posts, teaser e campanha ("Ajude o Capi a
   salvar os filhotes"), além de dar um rosto para os anúncios.

## Arte necessária

Toda a arte da história é **2D**, no mesmo estilo das ilustrações atuais do
Capi e do filhote (pintadas, com volume de 2.5D). As ilustrações saem do
**Gemini**. O Tripo fica para o Capi 3D que já está em andamento.

- **Jacaré Trambiqueiro:** poses neutra, rindo, assustado e pedindo
  desculpas.
- **Mãe Capi:** poses neutra, abraçando um filhote e acenando.
- **Filhotes com nome:** a arte atual (`assets/capi/filhote.webp`) com o laço
  de cada cor. Talvez um acessório próprio por filhote no futuro.
- **Prólogo:** os três quadros.
- **Cenas de capítulo:** fundos simples por capítulo (rio, campo, mata,
  canteiro, resort).
- **Cartaz "Jacarelândia Resort"** para o prólogo e para o menu.

### Como manter o estilo igual

- Em todo pedido ao Gemini, anexe como referência `assets/capi/filhote.webp`
  e uma pose do Capi de `assets/capi/poses/`.
- Use sempre o mesmo texto de estilo:

  > Ilustração 2D para jogo mobile infantil, estilo cartoon fofo e
  > arredondado, com volume suave (aparência 2.5D), contornos marrons finos,
  > sombras macias, brilho leve no topo das formas, cores quentes e
  > saturadas. Mesmo estilo e proporções das imagens de referência. Sem
  > texto, sem marca d'água.

- Personagens soltos vão em fundo transparente (PNG) e depois são
  convertidos para `.webp`, como as poses atuais.
- Guarde as fontes em `art/historia/` e só as versões finais em `assets/`.

## Medição

Eventos novos no Analytics, documentados em `docs/estatisticas.md`:

- `historia_cena {cena, pulou}`
- `capitulo_inicio {capitulo}`
- `filhote_resgatado {filhote, capitulo}`

O que acompanhar:

- quantos novos jogadores chegam à fase 8 (o primeiro resgate);
- a retenção D1 e D7 antes e depois;
- quantos pulam as cenas. Se a maioria pular, as cenas ficam ainda mais
  curtas.

## Decidido

- Nomes: Pipoca, Jujuba, Tico, Fubá, Mel e o Jacaré Trambiqueiro.
- A família tem a Mãe Capi. Ela não é levada: fica na vila, recebe os
  filhotes e entra na fase final do Capítulo 5 com o Capi.
- O prólogo vem antes do tutorial.
- Toda a arte da história é 2D, gerada no Gemini.
