// Monta as capturas das lojas: a tela do jogo (e2e/loja/saida/<idioma>/)
// num celular, com uma frase em cima, em 1080x1920.
//   cd e2e && npm run loja && node ../tool/loja_montar.js
// Saem em docs/loja/play/<idioma>/ (JPEG, aceito pela Play e pela App Store).
const path = require('path');
const fs = require('fs');
const { chromium } = require(path.resolve(__dirname, '../e2e/node_modules/@playwright/test'));

const RAIZ = path.resolve(__dirname, '..');
const CRUAS = path.join(RAIZ, 'e2e/loja/saida');
const SAIDA = path.join(RAIZ, 'docs/loja/play');

// [arquivo, frase]; *palavra* sai em amarelo.
const FRASES = {
  pt: [
    ['1-combo', 'Encaixe blocos e faça *COMBOS!*'],
    ['2-filhotes', 'Salve os *filhotes* de capivara'],
    ['3-guarda-roupa', 'Vista o Capi do *seu jeito*'],
    ['4-vila', 'Construa a *Vila* do Capi'],
    ['5-natal', 'Itens novos *todo mês*'],
    ['6-modos', '*5 modos* de jogo'],
    ['7-convites', 'Jogue com os *amigos*'],
  ],
  en: [
    ['1-combo', 'Fit blocks, make *COMBOS!*'],
    ['2-filhotes', 'Rescue the *baby* capybaras'],
    ['3-guarda-roupa', 'Dress Capi *your way*'],
    ['4-vila', "Build Capi's *Village*"],
    ['5-natal', 'New items *every month*'],
    ['6-modos', '*5 game* modes'],
    ['7-convites', 'Play with *friends*'],
  ],
  es: [
    ['1-combo', '¡Encaja bloques y haz *COMBOS!*'],
    ['2-filhotes', 'Salva a los *bebés* capibara'],
    ['3-guarda-roupa', 'Viste a Capi *a tu manera*'],
    ['4-vila', 'Construye la *Aldea* de Capi'],
    ['5-natal', 'Objetos nuevos *cada mes*'],
    ['6-modos', '*5 modos* de juego'],
    ['7-convites', 'Juega con tus *amigos*'],
  ],
};

const fonte = (f) => 'data:font/ttf;base64,' + fs.readFileSync(path.join(RAIZ, 'assets/fonts', f)).toString('base64');

function pagina(frase, tela) {
  const html = frase
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/\*(.+?)\*/g, '<b>$1</b>');
  return `<!doctype html><html><head><style>
@font-face { font-family: Lilita; src: url(${fonte('LilitaOne-Regular.ttf')}); }
html, body { margin: 0; width: 1080px; height: 1920px; overflow: hidden; }
body {
  background:
    radial-gradient(900px 700px at 50% 62%, rgba(124, 92, 255, .55), transparent 70%),
    radial-gradient(600px 500px at 10% 8%, rgba(255, 201, 77, .25), transparent 70%),
    linear-gradient(170deg, #2a1f6b 0%, #1b2440 55%, #120f2e 100%);
  font-family: Lilita, sans-serif;
}
.frase {
  position: absolute; top: 70px; left: 60px; right: 60px; height: 300px;
  display: flex; align-items: center; justify-content: center; text-align: center;
  color: #fff; font-size: 98px; line-height: 1.05; letter-spacing: 1px;
  text-shadow: 0 8px 0 #12103a, 0 0 40px rgba(0,0,0,.35);
  -webkit-text-stroke: 4px #12103a; paint-order: stroke fill;
}
.frase b { color: #FFC94D; font-weight: normal; }
.celular {
  position: absolute; left: 50%; top: 420px; transform: translateX(-50%);
  width: 820px; height: 1458px; border-radius: 64px; padding: 18px;
  background: linear-gradient(160deg, #3b3f7a, #171a3a);
  box-shadow: 0 40px 90px rgba(0,0,0,.55), 0 0 0 4px rgba(255,255,255,.08) inset;
}
.celular img { width: 820px; height: 1458px; border-radius: 48px; display: block; object-fit: cover; object-position: top; }
</style></head><body>
<div class="frase"><span>${html}</span></div>
<div class="celular"><img src="data:image/png;base64,${fs.readFileSync(tela).toString('base64')}"></div>
</body></html>`;
}

// O banner da Play (1024x500): o Capi comemorando, o nome e uma frase.
const BANNER = {
  pt: 'Encaixe blocos, salve filhotes e construa a Vila!',
  en: 'Fit blocks, rescue baby capybaras and build the Village!',
  es: '¡Encaja bloques, salva bebés capibara y construye la Aldea!',
};

function banner(frase) {
  const capi = 'data:image/webp;base64,' + fs.readFileSync(path.join(RAIZ, 'assets/capi/poses/comemora_caramelo.webp')).toString('base64');
  const cores = ['#FF6B6B', '#FFC94D', '#51CF66', '#339AF0', '#CC5DE8', '#FF922B'];
  // Blocos soltos no fundo (posições fixas: o banner sai sempre igual).
  const blocos = [
    [40, 330, 54, 0, -12], [150, 400, 40, 2, 10], [440, 40, 36, 3, 18], [520, 400, 46, 1, -8],
    [600, 70, 30, 4, 25], [960, 60, 44, 5, -15], [980, 380, 50, 2, 12], [700, 430, 34, 0, 30],
  ].map(([x, y, t, c, r]) => `<i style="left:${x}px;top:${y}px;width:${t}px;height:${t}px;background:${cores[c]};transform:rotate(${r}deg)"></i>`).join('');
  return `<!doctype html><html><head><style>
@font-face { font-family: Lilita; src: url(${fonte('LilitaOne-Regular.ttf')}); }
@font-face { font-family: Fredoka; src: url(${fonte('Fredoka-Variable.ttf')}); }
html, body { margin: 0; width: 1024px; height: 500px; overflow: hidden; }
body {
  position: relative;
  background:
    radial-gradient(420px 380px at 76% 55%, rgba(255, 201, 77, .45), transparent 70%),
    linear-gradient(120deg, #2a1f6b 0%, #3b2f8f 50%, #1b2440 100%);
}
i { position: absolute; border-radius: 22%; box-shadow: inset 0 -6px 0 rgba(0,0,0,.18), inset 0 5px 0 rgba(255,255,255,.35); opacity: .9; }
.capi { position: absolute; right: 40px; bottom: -10px; height: 470px; filter: drop-shadow(0 18px 24px rgba(0,0,0,.45)); }
.texto { position: absolute; left: 64px; top: 0; bottom: 0; width: 560px; display: flex; flex-direction: column; justify-content: center; }
h1 { margin: 0; font-family: Lilita; font-weight: normal; font-size: 112px; line-height: 1; color: #fff;
  -webkit-text-stroke: 5px #12103a; paint-order: stroke fill; text-shadow: 0 8px 0 #12103a; }
h1 b { color: #FFC94D; font-weight: normal; }
p { margin: 18px 0 0; font-family: Fredoka; font-weight: 600; font-size: 34px; line-height: 1.2; color: #fff; text-shadow: 0 3px 0 rgba(0,0,0,.35); }
</style></head><body>${blocos}
<img class="capi" src="${capi}">
<div class="texto"><h1>Capi<b>Blocks</b></h1><p>${frase}</p></div>
</body></html>`;
}

(async () => {
  const browser = await chromium.launch();
  const bpage = await browser.newPage({ viewport: { width: 1024, height: 500 } });
  for (const [idioma, frase] of Object.entries(BANNER)) {
    fs.mkdirSync(path.join(SAIDA, idioma), { recursive: true });
    await bpage.setContent(banner(frase));
    await bpage.evaluate(() => document.fonts.ready);
    await bpage.screenshot({ path: path.join(SAIDA, idioma, 'banner-1024x500.png') });
    console.log(`${idioma}/banner-1024x500.png`);
  }
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
  for (const [idioma, lista] of Object.entries(FRASES)) {
    const pasta = path.join(SAIDA, idioma);
    fs.mkdirSync(pasta, { recursive: true });
    for (const [nome, frase] of lista) {
      const tela = path.join(CRUAS, idioma, `${nome}.png`);
      if (!fs.existsSync(tela)) throw new Error(`Falta ${tela} (rode npm run loja em e2e/).`);
      await page.setContent(pagina(frase, tela));
      await page.evaluate(() => document.fonts.ready);
      await page.screenshot({ path: path.join(pasta, `${nome}.jpg`), type: 'jpeg', quality: 90 });
      console.log(`${idioma}/${nome}.jpg`);
    }
  }
  await browser.close();
})();
