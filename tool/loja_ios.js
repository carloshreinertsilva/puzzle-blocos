// Monta as capturas da App Store (iPhone): a tela do jogo
// (e2e/loja/saida/ios/) numa moldura, com uma frase em cima.
//   cd e2e && npx playwright test -c playwright.loja.config.ts ios
//   node ../tool/loja_ios.js
// Saem em docs/loja/ios/ (6,9": 1320x2868) e docs/loja/ios/6.3/ (1206x2622).
const path = require('path');
const fs = require('fs');
const { chromium } = require(path.resolve(__dirname, '../e2e/node_modules/@playwright/test'));

const RAIZ = path.resolve(__dirname, '..');
const CRUAS = path.join(RAIZ, 'e2e/loja/saida/ios');
const SAIDA = path.join(RAIZ, 'docs/loja/ios');

// [arquivo, frase]; *palavra* sai em amarelo.
const FRASES = [
  ['1-vila', 'Construa a *Vila* do Capi'],
  ['2-obra', 'Monte cada *obra* com as peças certas'],
  ['3-torre', 'Empilhe a *Torre* até a Lua'],
  ['4-filhotes', 'Resgate os *filhotes* de capivara'],
  ['5-guarda-roupa', 'Vista o Capi do *seu jeito*'],
  ['6-combo', 'Encaixe blocos e faça *COMBOS!*'],
  ['7-modos', '*7 modos* de jogo'],
];

const TAMANHOS = [
  ['', 1320, 2868],
  ['6.3', 1206, 2622],
];

const fonte = (f) => 'data:font/ttf;base64,' + fs.readFileSync(path.join(RAIZ, 'assets/fonts', f)).toString('base64');

function pagina(frase, tela, w, h) {
  const k = w / 1320;
  const texto = frase.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/\*(.+?)\*/g, '<b>$1</b>');
  return `<!doctype html><html><head><style>
@font-face { font-family: L; src: url(${fonte('LilitaOne-Regular.ttf')}); }
* { margin: 0; padding: 0; box-sizing: border-box; }
body { width: ${w}px; height: ${h}px; overflow: hidden;
  background: radial-gradient(ellipse at 50% 0%, #3b2d7a 0%, #1e1752 45%, #120f38 100%);
  display: flex; flex-direction: column; align-items: center; }
.frase { height: ${Math.round(470 * k)}px; display: flex; align-items: center; justify-content: center;
  padding: 0 ${Math.round(70 * k)}px; text-align: center; font-family: L; font-size: ${Math.round(96 * k)}px;
  line-height: 1.12; color: #f4f1ff; -webkit-text-stroke: ${Math.round(12 * k)}px #0e102e; paint-order: stroke fill;
  filter: drop-shadow(0 ${Math.round(8 * k)}px 0 #090a1f); }
.frase b { color: #ffc94d; font-weight: normal; }
.moldura { width: ${Math.round(1200 * k)}px; height: ${Math.round(2313 * k)}px; border-radius: ${Math.round(90 * k)}px;
  padding: ${Math.round(12 * k)}px; background: linear-gradient(180deg, #4a55b0, #2a2266);
  box-shadow: 0 ${Math.round(30 * k)}px ${Math.round(80 * k)}px rgba(0,0,0,.6); }
.moldura img { width: 100%; height: 100%; border-radius: ${Math.round(80 * k)}px; object-fit: cover; display: block; }
</style></head><body><div class="frase"><div>${texto}</div></div>
<div class="moldura"><img src="data:image/png;base64,${tela}"></div></body></html>`;
}

(async () => {
  const browser = await chromium.launch();
  for (const [pasta, w, h] of TAMANHOS) {
    const destino = path.join(SAIDA, pasta);
    fs.mkdirSync(destino, { recursive: true });
    const page = await browser.newPage({ viewport: { width: w, height: h } });
    for (const [nome, frase] of FRASES) {
      const crua = path.join(CRUAS, `${nome}.png`);
      if (!fs.existsSync(crua)) {
        console.log(`falta ${crua}`);
        continue;
      }
      await page.setContent(pagina(frase, fs.readFileSync(crua).toString('base64'), w, h));
      await page.evaluate(() => document.fonts.ready);
      await page.screenshot({ path: path.join(destino, `${nome}.png`) });
      console.log(`${pasta || '6.9'} ${nome}`);
    }
    await page.close();
  }
  await browser.close();
})();
