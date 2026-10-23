const path = require('path');
const fs = require('fs');
const { chromium } = require(path.resolve(__dirname, '../e2e/node_modules/@playwright/test'));
const { spawn } = require('child_process');

const PORT = 8795;
const BASE_URL = `http://127.0.0.1:${PORT}`;

const VETERAN = {
  seen_tutorial: true,
  seen_menu: true,
  seen_news_welcome: true,
  seen_news_village: true,
  seen_news_endless: true,
  seen_news_obras: true,
  seen_news_daily: true,
  seen_news_blitz: true,
  seen_news_duel: true,
  seen_news_tower: true,
  // Mechanics intros already seen so popups don't block the board
  seen_rocks: true,
  seen_toughRocks: true,
  seen_gems: true,
  seen_pups: true,
  seen_doubleGoal: true,
};

async function waitServer() {
  for (let i = 0; i < 40; i++) {
    try {
      const res = await fetch(BASE_URL);
      if (res.ok) return;
    } catch (e) {
      // wait
    }
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error('Server did not start in time');
}

async function openWithState(page, saved = {}) {
  await page.goto('about:blank');
  await page.goto(BASE_URL + '/');
  const allSaved = { ...VETERAN, ...saved };
  await page.evaluate((s) => {
    localStorage.clear();
    for (const [k, v] of Object.entries(s)) {
      localStorage.setItem(`flutter.${k}`, String(v));
    }
    delete window.__bb;
  }, allSaved);
  await page.reload();
  await page.waitForFunction(() => window.__bb !== undefined, null, { timeout: 30000 });
  await page.waitForTimeout(900);
}

async function waitForScreen(page, screenName, timeout = 15000) {
  await page.waitForFunction(
    (name) => {
      if (!window.__bb || !window.__bb.state) return false;
      try {
        const s = JSON.parse(window.__bb.state());
        return s.screen === name;
      } catch (e) {
        return false;
      }
    },
    screenName,
    { timeout },
  );
}

async function dragTrayPiece(page, slot, row, col) {
  const drag = await page.evaluate(
    ([s, r, c]) => JSON.parse(window.__bb.dragPath(s, r, c)),
    [slot, row, col],
  );
  if (!drag) return;
  await page.mouse.move(drag.from.x, drag.from.y);
  await page.mouse.down();
  await page.mouse.move(drag.to.x, drag.to.y, { steps: 10 });
  await page.waitForTimeout(80);
  await page.mouse.up();
  await page.waitForTimeout(350);
}

async function dragObraPiece(page, pieceIndex) {
  const drag = await page.evaluate(
    (idx) => JSON.parse(window.__bb.obraDrag(idx)),
    pieceIndex,
  );
  if (!drag) return;
  await page.mouse.move(drag.from.x, drag.from.y);
  await page.mouse.down();
  await page.mouse.move(drag.to.x, drag.to.y, { steps: 12 });
  await page.waitForTimeout(100);
  await page.mouse.up();
  await page.waitForTimeout(300);
}

async function composeAndSave(composerPage, gamePage, fontBase64, name, headline, highlightWord) {
  const rawBuffer = await gamePage.screenshot({ type: 'png' });
  const screenBase64 = rawBuffer.toString('base64');

  const renderedHeadline = highlightWord
    ? headline.replace(
        highlightWord,
        `<span class="highlight">${highlightWord}</span>`,
      )
    : headline;

  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<style>
  @font-face {
    font-family: 'GameLilita';
    src: url('data:font/ttf;base64,${fontBase64}') format('truetype');
    font-weight: normal;
    font-style: normal;
  }
  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }
  body {
    width: 1080px;
    height: 1920px;
    overflow: hidden;
    background: linear-gradient(180deg, #151944 0%, #1E1752 45%, #2A1650 100%);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: space-between;
    padding: 36px 44px 40px;
    position: relative;
  }
  /* Subtle ambient glow behind the caption and frame */
  .glow-top {
    position: absolute;
    top: -60px;
    left: 50%;
    transform: translateX(-50%);
    width: 900px;
    height: 340px;
    background: radial-gradient(circle, rgba(255, 201, 77, 0.18) 0%, rgba(76, 110, 245, 0.10) 50%, transparent 75%);
    pointer-events: none;
  }
  .caption-box {
    width: 100%;
    min-height: 185px;
    display: flex;
    align-items: center;
    justify-content: center;
    text-align: center;
    padding: 4px 12px 18px;
    z-index: 2;
  }
  .caption-text {
    font-family: 'GameLilita', cursive, sans-serif;
    font-size: 56px;
    line-height: 1.16;
    color: #F4F1FF;
    letter-spacing: 0.8px;
    -webkit-text-stroke: 8px #0E102E;
    paint-order: stroke fill;
    filter: drop-shadow(0 6px 0 #090A1F) drop-shadow(0 10px 18px rgba(0, 0, 0, 0.55));
  }
  .caption-text .highlight {
    color: #FFC94D;
  }
  .phone-frame {
    width: 984px;
    height: 1640px;
    border-radius: 42px;
    padding: 12px;
    background: linear-gradient(180deg, #353E88 0%, #231D54 100%);
    box-shadow:
      0 24px 60px rgba(0, 0, 0, 0.65),
      0 0 0 2px rgba(255, 255, 255, 0.14) inset;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 2;
    overflow: hidden;
  }
  .screen-inner {
    width: 100%;
    height: 100%;
    border-radius: 32px;
    overflow: hidden;
    background: #1C2155;
    position: relative;
  }
  .screen-inner img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }
</style>
</head>
<body>
  <div class="glow-top"></div>
  <div class="caption-box">
    <div class="caption-text">${renderedHeadline}</div>
  </div>
  <div class="phone-frame">
    <div class="screen-inner">
      <img src="data:image/png;base64,${screenBase64}" alt="Screen" />
    </div>
  </div>
</body>
</html>`;

  await composerPage.setContent(html, { waitUntil: 'load' });
  await composerPage.waitForTimeout(150);

  const rootDir = path.resolve(__dirname, '..');
  const outDocs = path.join(rootDir, 'docs', 'loja', `${name}.png`);
  const outArt = path.join(rootDir, 'art', 'loja', `${name}.png`);
  await composerPage.screenshot({ path: outDocs });
  fs.copyFileSync(outDocs, outArt);
  console.log(`Saved: ${outDocs} (1080x1920)`);
}

async function main() {
  console.log('Starting local web server...');
  const rootDir = path.resolve(__dirname, '..');
  const fontPath = path.join(rootDir, 'assets', 'fonts', 'LilitaOne-Regular.ttf');
  const fontBase64 = fs.readFileSync(fontPath).toString('base64');

  const server = spawn('python', ['e2e/serve.py', String(PORT), 'build/web_test'], {
    cwd: rootDir,
    stdio: 'inherit',
  });

  process.on('exit', () => server.kill());
  process.on('SIGINT', () => {
    server.kill();
    process.exit();
  });

  try {
    await waitServer();
    console.log('Server is running on ' + BASE_URL);

    fs.mkdirSync(path.join(rootDir, 'docs/loja'), { recursive: true });
    fs.mkdirSync(path.join(rootDir, 'art/loja'), { recursive: true });

    const browser = await chromium.launch({
      args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader'],
    });

    // Game context: 420x700 (3:5 ratio matching the inner phone frame 960x1616) at 2.5x scale
    const gameContext = await browser.newContext({
      viewport: { width: 420, height: 707 },
      deviceScaleFactor: 2.5,
      locale: 'pt-BR',
    });
    const page = await gameContext.newPage();

    // Composer context: exact 1080x1920 for Google Play Store
    const composerContext = await browser.newContext({
      viewport: { width: 1080, height: 1920 },
      deviceScaleFactor: 1,
      locale: 'pt-BR',
    });
    const composerPage = await composerContext.newPage();

    // 1. Partida Clássica com combos e gemas no tabuleiro (sem popup bloqueando!)
    console.log('Capturing Screenshot 1: Partida com combos...');
    await openWithState(page, { level: 5, stars: 14 });
    await page.getByRole('button', { name: /^Jogar · Fase/ }).click();
    await waitForScreen(page, 'game');
    // Aguarda o letreiro inicial "Fase 5 / Colete 9 gemas" desaparecer completamente
    await page.waitForTimeout(2800);
    // Carrega um tabuleiro rico com blocos, gemas e uma linha quase pronta
    await page.evaluate(() => {
      window.__bb.load(
        JSON.stringify({
          board: [
            '..bb..g.',
            '.bbb.bb.',
            'bbgbb..b',
            'bbbbbb..',
            '.b.g.bb.',
            '..bbb...',
            '.g..bb..',
            '...b....',
          ],
          tray: ['i20', 'o20', 't40'],
        }),
      );
    });
    await page.waitForTimeout(250);
    // Arrasta uma peça o20 para (6, 2) para variar as cores no tabuleiro e depois i20 para (3, 6) limpando a linha!
    await dragTrayPiece(page, 1, 6, 2);
    await dragTrayPiece(page, 0, 3, 6);
    await page.waitForTimeout(350);
    await composeAndSave(
      composerPage,
      page,
      fontBase64,
      'screenshot-1-partida',
      'Encaixe blocos, limpe linhas e faça combos incríveis!',
      'faça combos incríveis!',
    );

    // 2. Vila do Capi em 2.5D
    console.log('Capturing Screenshot 2: Vila do Capi...');
    await openWithState(page, {
      level: 25,
      stars: 18,
      pupsSaved: 6,
      villageBuilt: 10,
    });
    await page.getByRole('button', { name: /^Vila do Capi/ }).click();
    await waitForScreen(page, 'village');
    await page.waitForTimeout(2000);
    await composeAndSave(
      composerPage,
      page,
      fontBase64,
      'screenshot-2-vila',
      'Construa e explore a ilha flutuante do Capi em 2.5D!',
      'ilha flutuante do Capi',
    );

    // 3. Resgate de Filhotes no tabuleiro real (sem modal tampando!)
    console.log('Capturing Screenshot 3: Filhotes de Capivara...');
    await openWithState(page, { level: 8, stars: 16 });
    await page.getByRole('button', { name: /^Jogar · Fase/ }).click();
    await waitForScreen(page, 'game');
    // Aguarda o letreiro inicial "Fase 8 / Resgate os 5 filhotes" desaparecer completamente
    await page.waitForTimeout(2800);
    await page.evaluate(() => {
      window.__bb.load(
        JSON.stringify({
          board: [
            '..bb....',
            '.bpbb...',
            '..bb.pb.',
            '.bb.bb..',
            '.b..bp..',
            '..pb..b.',
            '........',
            '........',
          ],
          tray: ['o20', 'v30', 'l40'],
        }),
      );
    });
    await page.waitForTimeout(250);
    // Coloca duas peças coloridas no tabuleiro para enriquecer o visual junto aos filhotes nas bolhas
    await dragTrayPiece(page, 0, 6, 3);
    await dragTrayPiece(page, 1, 5, 0);
    await page.waitForTimeout(400);
    await composeAndSave(
      composerPage,
      page,
      fontBase64,
      'screenshot-3-filhotes',
      'Resgate os filhotes de capivara presos em bolhas!',
      'Resgate os filhotes',
    );

    // 4. Modo Obra (com algumas peças já encaixadas no desenho!)
    console.log('Capturing Screenshot 4: Modo Obra...');
    await openWithState(page, { level: 8, stars: 20, obraLevel: 4 });
    await page.getByRole('button', { name: /^Obras/ }).click();
    await waitForScreen(page, 'obra');
    await page.waitForTimeout(800);
    // Encaixa 3 peças na planta azul para mostrar a obra em construção
    await dragObraPiece(page, 0);
    await dragObraPiece(page, 1);
    await dragObraPiece(page, 2);
    await page.waitForTimeout(500);
    await composeAndSave(
      composerPage,
      page,
      fontBase64,
      'screenshot-4-obra',
      'Modo Obra: quebra-cabeças geométricos de encaixe!',
      'Modo Obra:',
    );

    // 5. Torre do Capi 2.5D (com torre alta de 6 andares e combo!)
    console.log('Capturing Screenshot 5: Torre do Capi...');
    await openWithState(page, {
      level: 10,
      stars: 24,
      towerBestHeight: 19,
      seen_opened_tower: true,
    });
    await page.getByRole('button', { name: /^Torre do Capi/ }).click();
    await waitForScreen(page, 'tower');
    await page.waitForTimeout(800);
    await page.evaluate(() => {
      if (window.__bb && window.__bb.placeTower) {
        for (let i = 0; i < 6; i++) {
          window.__bb.placeTower(true);
        }
      }
    });
    await page.waitForTimeout(500);
    await composeAndSave(
      composerPage,
      page,
      fontBase64,
      'screenshot-5-modos',
      'Torre do Capi e Blitz: modos rápidos e cheios de ritmo!',
      'Torre do Capi e Blitz:',
    );

    // 6. Chapéus e Missões (com vários chapéus desbloqueados e Coroa Real equipada!)
    console.log('Capturing Screenshot 6: Chapéus e Missões...');
    await openWithState(page, {
      level: 12,
      stars: 28,
    });
    await page.evaluate(async () => {
      if (window.__bb) {
        await window.__bb.unlockHat('crown');
        await window.__bb.unlockHat('party');
        await window.__bb.unlockHat('chef');
        await window.__bb.unlockHat('pirate');
        await window.__bb.equipHat('crown');
      }
    });
    await page.waitForTimeout(300);
    const wardrobeBtn = page.getByRole('button', { name: 'Guarda-Roupa' });
    await wardrobeBtn.click();
    await page.waitForTimeout(900);
    // Seleciona a Coroa Real no carrossel para exibi-la no destaque
    const crownCard = page.getByRole('button', { name: /Coroa Real/i });
    if (await crownCard.isVisible()) {
      await crownCard.click();
      await page.waitForTimeout(400);
    }
    await composeAndSave(
      composerPage,
      page,
      fontBase64,
      'screenshot-6-chapeus',
      'Missões diárias, baú de tesouros e chapéus colecionáveis!',
      'chapéus colecionáveis!',
    );

    await browser.close();
    console.log('All 6 screenshots captured successfully!');
  } finally {
    server.kill();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
