const { chromium } = require('../e2e/node_modules/playwright');
const fs = require('fs');
const path = require('path');

async function main() {
  const capiBase64 = fs.readFileSync('art/capi.png').toString('base64');

  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@600;700;800;900&family=Lilita+One&display=swap" rel="stylesheet">
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      user-select: none;
    }
    body {
      width: 1024px;
      height: 500px;
      overflow: hidden;
      font-family: 'Fredoka', -apple-system, BlinkMacSystemFont, sans-serif;
      background: #14173e;
    }
    .banner {
      position: relative;
      width: 1024px;
      height: 500px;
      overflow: hidden;
      background: linear-gradient(135deg, #121538 0%, #1a1544 50%, #28113f 100%);
    }

    /* Ambient Lighting */
    .glow-left {
      position: absolute;
      left: 5%;
      top: 15%;
      width: 500px;
      height: 400px;
      background: radial-gradient(circle, rgba(76, 110, 245, 0.25) 0%, rgba(76, 110, 245, 0.04) 55%, transparent 75%);
      pointer-events: none;
    }
    .glow-right {
      position: absolute;
      right: 0%;
      top: 5%;
      width: 550px;
      height: 480px;
      background: radial-gradient(circle, rgba(255, 180, 40, 0.28) 0%, rgba(255, 130, 20, 0.08) 50%, transparent 75%);
      pointer-events: none;
    }

    /* Subtle background grid (puzzle feel) */
    .bg-grid {
      position: absolute;
      left: 30px;
      top: 30px;
      display: grid;
      grid-template-columns: repeat(7, 42px);
      grid-template-rows: repeat(7, 42px);
      gap: 6px;
      opacity: 0.08;
      transform: rotate(-3deg);
      pointer-events: none;
    }
    .grid-cell {
      width: 42px;
      height: 42px;
      border-radius: 9px;
      background: rgba(255, 255, 255, 0.35);
      border: 1px solid rgba(255, 255, 255, 0.5);
    }
    .grid-cell.on {
      background: rgba(255, 212, 59, 0.8);
      border-color: #ffd43b;
    }

    /* Sparkles */
    .sparkle {
      position: absolute;
      color: #fde047;
      filter: drop-shadow(0 0 6px #fde047);
      pointer-events: none;
    }

    /* Content Layout */
    .content {
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 50px 0 70px;
      z-index: 2;
    }

    /* Left Side: Brand and Clean Message */
    .left-side {
      max-width: 500px;
      display: flex;
      flex-direction: column;
      align-items: flex-start;
    }

    /* Top Badge with 3 Stars */
    .top-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 7px 18px;
      border-radius: 24px;
      background: rgba(255, 201, 77, 0.12);
      border: 1.5px solid rgba(255, 201, 77, 0.38);
      color: #fde047;
      font-size: 13.5px;
      font-weight: 800;
      letter-spacing: 2px;
      text-transform: uppercase;
      margin-bottom: 18px;
      filter: drop-shadow(0 2px 8px rgba(0,0,0,0.3));
    }
    .star-group {
      display: flex;
      align-items: center;
      gap: 3px;
      margin-right: 4px;
    }
    .star {
      width: 16px;
      height: 16px;
      fill: #ffd43b;
    }
    .star.big {
      width: 20px;
      height: 20px;
      fill: #ffe066;
    }

    /* Main Logo */
    .logo-container {
      margin-bottom: 18px;
    }
    .main-logo {
      font-family: 'Lilita One', 'Fredoka', cursive;
      font-size: 96px;
      line-height: 0.95;
      letter-spacing: 0.5px;
      white-space: nowrap;
    }
    .logo-capi {
      color: #ffd43b;
      background: linear-gradient(180deg, #fffbeb 0%, #fde047 30%, #f59f00 85%, #d97706 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      filter: drop-shadow(0 3px 0 #854d0e) drop-shadow(0 6px 0 #451a03) drop-shadow(0 14px 18px rgba(0,0,0,0.7));
    }
    .logo-blocks {
      color: #ffffff;
      background: linear-gradient(180deg, #ffffff 0%, #f1f5f9 35%, #cbd5e1 85%, #94a3b8 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      filter: drop-shadow(0 3px 0 #334155) drop-shadow(0 6px 0 #0f172a) drop-shadow(0 14px 18px rgba(0,0,0,0.7));
    }

    /* Single, Punchy Subtitle */
    .subtitle {
      font-size: 22px;
      font-weight: 700;
      color: #f8fafc;
      line-height: 1.4;
      text-shadow: 0 2px 10px rgba(0,0,0,0.7);
      margin-bottom: 22px;
      max-width: 480px;
    }
    .subtitle strong {
      color: #38bdf8;
      font-weight: 800;
    }

    /* 3 Floating Puzzle Blocks under Subtitle (Game Aesthetic) */
    .blocks-tray {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .puzzle-piece {
      display: flex;
      box-shadow: 0 8px 16px rgba(0,0,0,0.45);
      border-radius: 10px;
    }
    .block {
      width: 32px;
      height: 32px;
      border-radius: 8px;
      position: relative;
      box-shadow: inset 0 2.5px 3px rgba(255,255,255,0.6), inset 0 -2.5px 3px rgba(0,0,0,0.35);
    }
    .b-coral  { background: linear-gradient(180deg, #ff8787 0%, #fa5252 100%); border: 2px solid #c92a2a; }
    .b-yellow { background: linear-gradient(180deg, #ffe066 0%, #fcc419 100%); border: 2px solid #e67700; }
    .b-green  { background: linear-gradient(180deg, #69db7c 0%, #40c057 100%); border: 2px solid #2f9e44; }
    .b-teal   { background: linear-gradient(180deg, #3bc9db 0%, #15aabf 100%); border: 2px solid #0c8599; }
    .b-purple { background: linear-gradient(180deg, #da77f2 0%, #be4bdb 100%); border: 2px solid #862e9c; }

    .tray-label {
      font-size: 15px;
      font-weight: 700;
      color: #cbd5e1;
      text-shadow: 0 2px 6px rgba(0,0,0,0.6);
      margin-left: 6px;
    }

    /* Right Side: The Official Capi Mascot on a Grounded Pedestal */
    .right-side {
      position: relative;
      width: 440px;
      height: 500px;
      display: flex;
      align-items: flex-end;
      justify-content: center;
    }

    /* Pedestal Base of Puzzle Blocks where Capi rests */
    .pedestal-base {
      position: absolute;
      bottom: 0px;
      right: 20px;
      display: flex;
      gap: 6px;
      z-index: 1;
      filter: drop-shadow(0 15px 25px rgba(0,0,0,0.8));
    }
    .p-cube {
      width: 72px;
      height: 54px;
      border-radius: 12px 12px 4px 4px;
      box-shadow: inset 0 3px 5px rgba(255,255,255,0.5), inset 0 -4px 6px rgba(0,0,0,0.4);
    }

    /* Official Capi Mascot Image */
    .capi-img {
      position: relative;
      width: 420px;
      height: 420px;
      object-fit: contain;
      z-index: 2;
      margin-bottom: 25px;
      filter: drop-shadow(0 16px 24px rgba(10, 5, 25, 0.75)) drop-shadow(0 0 30px rgba(255, 180, 40, 0.25));
    }

    /* Floating Bonus Gem */
    .bonus-gem {
      position: absolute;
      top: 50px;
      right: 25px;
      width: 60px;
      height: 60px;
      border-radius: 16px;
      background: linear-gradient(135deg, #67e8f9 0%, #06b6d4 50%, #0891b2 100%);
      border: 3px solid #e0f2fe;
      box-shadow: inset 0 3px 6px rgba(255,255,255,0.8), 0 10px 24px rgba(0,0,0,0.5), 0 0 28px rgba(6, 182, 212, 0.7);
      transform: rotate(15deg);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 3;
    }
    .bonus-gem::after {
      content: '★';
      font-size: 28px;
      color: #ffffff;
      text-shadow: 0 0 10px #ffffff;
    }

    /* Floating Heart near Capi */
    .bonus-heart {
      position: absolute;
      top: 130px;
      left: 10px;
      font-size: 32px;
      filter: drop-shadow(0 0 12px #f43f5e);
      transform: rotate(-12deg);
      z-index: 3;
    }
  </style>
</head>
<body>
  <div class="banner">
    <!-- Glows -->
    <div class="glow-left"></div>
    <div class="glow-right"></div>

    <!-- Background Board Grid -->
    <div class="bg-grid">
      <div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell on"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div>
      <div class="grid-cell"></div><div class="grid-cell on"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell on"></div><div class="grid-cell"></div><div class="grid-cell"></div>
      <div class="grid-cell on"></div><div class="grid-cell on"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div>
      <div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div>
      <div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell on"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div>
      <div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div>
      <div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div><div class="grid-cell"></div>
    </div>

    <!-- Sparkles -->
    <div class="sparkle" style="top: 55px; left: 450px; font-size: 22px;">✦</div>
    <div class="sparkle" style="top: 140px; left: 480px; font-size: 14px;">✦</div>
    <div class="sparkle" style="top: 60px; right: 430px; font-size: 18px;">✦</div>
    <div class="sparkle" style="bottom: 70px; left: 60px; font-size: 16px;">✦</div>

    <div class="content">
      <!-- Left Side: Brand and Clean Message -->
      <div class="left-side">
        <!-- Badge -->
        <div class="top-badge">
          <div class="star-group">
            <svg class="star" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
            <svg class="star big" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
            <svg class="star" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
          </div>
          O Jogo da Capivara
        </div>

        <!-- Logo -->
        <div class="logo-container">
          <h1 class="main-logo">
            <span class="logo-capi">Capi</span><span class="logo-blocks">Blocks</span>
          </h1>
        </div>

        <!-- Single clear subtitle -->
        <p class="subtitle">
          Encaixe blocos coloridos, salve filhotes e construa a <strong>Ilha do Capi</strong>!
        </p>

        <!-- Tray of Puzzle Blocks (Visual gameplay connection) -->
        <div class="blocks-tray">
          <div class="puzzle-piece">
            <div class="block b-coral"></div>
            <div class="block b-yellow"></div>
            <div class="block b-green"></div>
            <div class="block b-teal"></div>
            <div class="block b-purple"></div>
          </div>
          <span class="tray-label">Quebra-cabeça casual relaxante</span>
        </div>
      </div>

      <!-- Right Side: Official Mascot Integrated with Game Blocks -->
      <div class="right-side">
        <!-- Pedestal base of blocks -->
        <div class="pedestal-base">
          <div class="p-cube b-green"></div>
          <div class="p-cube b-yellow"></div>
          <div class="p-cube b-teal"></div>
          <div class="p-cube b-purple"></div>
          <div class="p-cube b-coral"></div>
        </div>

        <!-- Official Capi Image -->
        <img class="capi-img" src="data:image/png;base64,${capiBase64}" alt="Capi a Capivara" />

        <!-- Floating Elements (Gem & Heart) -->
        <div class="bonus-gem"></div>
        <div class="bonus-heart">💖</div>
      </div>
    </div>
  </div>
</body>
</html>`;

  fs.writeFileSync('tool/temp_banner.html', html, 'utf8');

  console.log('Rendering banner with Playwright...');
  const browser = await chromium.launch({
    args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader']
  });
  const page = await browser.newPage({
    viewport: { width: 1024, height: 500 },
    deviceScaleFactor: 1
  });

  await page.setContent(html, { waitUntil: 'networkidle' });
  await page.waitForTimeout(600);

  const out1 = 'art/loja/banner-1024x500.png';
  const out2 = 'docs/loja/banner-1024x500.png';

  await page.screenshot({ path: out1 });
  fs.copyFileSync(out1, out2);
  await browser.close();

  console.log('SUCCESS: Banner 1024x500 re-generated successfully!');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
