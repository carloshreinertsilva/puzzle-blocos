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

async function setHeadline(page, text, highlightWord) {
  await page.evaluate(
    ({ title, highlight }) => {
      let el = document.getElementById('store-banner-header');
      if (!el) {
        el = document.createElement('div');
        el.id = 'store-banner-header';
        document.body.appendChild(el);
      }
      const rendered = highlight
        ? title.replace(highlight, `<span style="color: #FFC94D;">${highlight}</span>`)
        : title;
      el.innerHTML = `
      <div style="
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 78px;
        background: linear-gradient(180deg, rgba(20, 24, 66, 0.96) 0%, rgba(31, 22, 84, 0.90) 80%, rgba(31, 22, 84, 0) 100%);
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 8px 16px 12px;
        box-sizing: border-box;
        z-index: 99999999;
        pointer-events: none;
        text-align: center;
      ">
        <div style="
          font-family: 'Lilita One', 'Fredoka', -apple-system, sans-serif;
          font-size: 18px;
          line-height: 1.25;
          font-weight: 900;
          color: #FFFFFF;
          text-shadow: 0 2px 8px rgba(0,0,0,0.85), 0 0 12px rgba(255,201,77,0.3);
          letter-spacing: 0.3px;
        ">
          ${rendered}
        </div>
      </div>
    `;
    },
    { title: text, highlight: highlightWord },
  );
}

async function openWithState(page, saved = {}) {
  await page.goto(BASE_URL + '/');
  const allSaved = { ...VETERAN, ...saved };
  await page.evaluate((s) => {
    for (const [k, v] of Object.entries(s)) {
      localStorage.setItem(`flutter.${k}`, String(v));
    }
  }, allSaved);
  await page.reload();
  await page.waitForFunction(() => window.__bb !== undefined, null, { timeout: 30000 });
  await page.waitForTimeout(600);
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

async function saveCapture(page, name, headline, highlight) {
  await setHeadline(page, headline, highlight);
  await page.waitForTimeout(400);
  const rootDir = path.resolve(__dirname, '..');
  const outDocs = path.join(rootDir, 'docs', 'loja', `${name}.png`);
  const outArt = path.join(rootDir, 'art', 'loja', `${name}.png`);
  await page.screenshot({ path: outDocs });
  fs.copyFileSync(outDocs, outArt);
  console.log(`Saved: ${outDocs} (1080x1920)`);
}

async function main() {
  console.log('Starting local web server...');
  const rootDir = path.resolve(__dirname, '..');
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

    const context = await browser.newContext({
      viewport: { width: 360, height: 640 },
      deviceScaleFactor: 3, // 360*3=1080, 640*3=1920
      locale: 'pt-BR',
    });

    const page = await context.newPage();

    // 1. Partida Clássica com combos
    console.log('Capturing Screenshot 1: Partida com combos...');
    await openWithState(page, { level: 5 });
    await page.getByRole('button', { name: /^Jogar · Fase/ }).click();
    await waitForScreen(page, 'game');
    await page.waitForTimeout(1200);
    await saveCapture(
      page,
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
    await page.waitForTimeout(1500);
    await saveCapture(
      page,
      'screenshot-2-vila',
      'Construa e explore a ilha flutuante do Capi em 2.5D!',
      'ilha flutuante do Capi',
    );

    // 3. Resgate de Filhotes
    console.log('Capturing Screenshot 3: Filhotes de Capivara...');
    await openWithState(page, { level: 8 });
    await page.getByRole('button', { name: /^Jogar · Fase/ }).click();
    await waitForScreen(page, 'game');
    await page.waitForTimeout(1200);
    await saveCapture(
      page,
      'screenshot-3-filhotes',
      'Resgate os filhotes de capivara presos em bolhas!',
      'Resgate os filhotes',
    );

    // 4. Modo Obra
    console.log('Capturing Screenshot 4: Modo Obra...');
    await openWithState(page, { level: 8, stars: 20, obraLevel: 3 });
    await page.getByRole('button', { name: /^Obras/ }).click();
    await waitForScreen(page, 'obra');
    await page.waitForTimeout(1400);
    await saveCapture(
      page,
      'screenshot-4-obra',
      'Modo Obra: quebra-cabeças geométricos de encaixe perfeito!',
      'Modo Obra',
    );

    // 5. Torre do Capi 2.5D
    console.log('Capturing Screenshot 5: Torre do Capi...');
    await openWithState(page, { level: 10, seen_opened_tower: true });
    await page.getByRole('button', { name: /^Torre do Capi/ }).click();
    await waitForScreen(page, 'tower');
    await page.waitForTimeout(1200);
    await page.evaluate(() => {
      if (window.__bb && window.__bb.placeTower) {
        window.__bb.placeTower(true);
        window.__bb.placeTower(true);
      }
    });
    await page.waitForTimeout(600);
    await saveCapture(
      page,
      'screenshot-5-modos',
      'Torre do Capi e Blitz: modos rápidos e cheios de ritmo!',
      'Torre do Capi e Blitz',
    );

    // 6. Chapéus e Missões
    console.log('Capturing Screenshot 6: Chapéus e Missões...');
    await openWithState(page, {
      level: 8,
      unlockedHats: '["helmet","crown","party","chef","pirate"]',
      equippedHat: 'crown',
    });
    const wardrobeBtn = page.getByRole('button', { name: 'Guarda-Roupa' });
    await wardrobeBtn.click();
    await page.waitForTimeout(1200);
    await saveCapture(
      page,
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
