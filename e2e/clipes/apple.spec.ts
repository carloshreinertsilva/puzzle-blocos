import { writeFileSync } from 'node:fs';
import { test, type Page } from '@playwright/test';
import { loadScenario, openApp, state, waitForState, type GameState } from '../tests/helpers';
import { FPS, Gravador } from './gravador';

/**
 * Um passeio pelo jogo: o que é só do CapiBlocks (a Vila, as Obras, a
 * Torre, o guarda-roupa do Capi) e um combo no fim. Grava duas versões:
 *
 * - `previa-apple`: a prévia em vídeo da App Store (886x1920, 30 qps, de
 *   15 a 30 s), também anexada à revisão. Sem selo de loja nem preço no
 *   cartão final (regra da Apple). Antes de subir, ganha um áudio mudo
 *   (docs/loja/ios/revisao-4.3.md).
 *     FPS=30 npx playwright test -c playwright.clipes.config.ts apple -g previa
 * - `tour`: o mesmo passeio para Reels e TikTok (1080x1920, 60 qps), com o
 *   cartão de convite das redes.
 *     npx playwright test -c playwright.clipes.config.ts apple -g tour
 *
 * Saem em e2e/clipes/saida/.
 */

test.setTimeout(30 * 60_000);
test.beforeEach(async ({ page }) => Gravador.prepararRelogio(page));

const COMBO = {
  board: ['.bb.b..b', '.bbb..b.', '.bb..g..', 'bgb.b..b', 'bbbb.b..', '...bbb..', '...bgb..', '...bbgbb'],
  tray: ['i31', 'o20', 'o30'],
};
const JOGADAS_COMBO = [
  { slot: 0, row: 0, col: 0 },
  { slot: 1, row: 5, col: 6 },
  { slot: 2, row: 5, col: 0 },
];

const naTela = (page: Page, cond: (s: GameState) => boolean) => async () => cond(await state(page));

/**
 * Toca num botão com o relógio parado. O click() do Playwright espera o
 * botão ficar parado entre dois quadros, o que não acontece com o relógio
 * parado; aqui o mouse toca direto no lugar do botão.
 */
async function toque(page: Page, nome: string | RegExp) {
  const box = await page.getByRole('button', { name: nome }).first().boundingBox();
  if (!box) throw new Error(`Botão ${nome} fora da tela.`);
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
}

/** Um toque fora do vídeo (corte): o jogo anda até [cond] valer. */
async function cortar(g: Gravador, page: Page, nome: string | RegExp, cond: (s: GameState) => boolean) {
  await toque(page, nome);
  await g.pular(6000, naTela(page, cond));
}

type Formato = { largura: number; altura: number; semLojas: boolean };
/** Altura de cada legenda na tela (muda com a proporção da tela). */
type Alturas = { obra: string; torre: string; combo: string };

async function passeio(page: Page, nome: string, formato: Formato, alturas: Alturas, convite: string) {
  page.setDefaultTimeout(20_000);
  await openApp(page, {
    level: 60,
    stars: 340,
    villageBuilt: 99,
    pupsSaved: 12,
    obraLevel: 9,
    seen_opened_tower: true,
    seen_opened_blitz: true,
    towerBestHeight: 40,
    equippedHat: JSON.stringify('crown'),
    equipped_costas: JSON.stringify('capa_real'),
    equipped_rosto: JSON.stringify('oculos_coracao'),
    unlockedHats: JSON.stringify(['helmet', 'crown', 'capa_real', 'oculos_coracao', 'touca', 'chef', 'pirate', 'wizard', 'party']),
  });
  // O Infinito uma vez fora do vídeo, para os cartões de novidade não aparecerem.
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: 'Infinito' }).click();
  await waitForState(page, (s) => s.screen === 'game', 'infinito');
  for (let i = 0; i < 6; i++) {
    const ok = page.getByRole('button', { name: 'Entendi!' });
    if (await ok.isVisible()) await ok.click();
    await page.waitForTimeout(400);
  }
  await page.getByRole('button', { name: 'Pausar' }).click();
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (s) => s.screen === 'home', 'menu');
  await page.waitForTimeout(1500);

  const g = new Gravador(page, nome, undefined, formato);
  const t0 = Date.now();
  await g.comecar();

  // 1. O menu com o Capi e a logo.
  g.legenda('Ajude o <b>Capi</b> a construir!', 2200);
  await g.esperar(1900);

  // 2. A Vila.
  await g.tocar(page.getByRole('button', { name: /^Vila do Capi/ }), 0);
  await g.ate(naTela(page, (s) => s.screen === 'village'));
  g.legenda('Construa a <b>Vila</b> do Capi', 3000);
  await g.esperar(3200);

  // 3. Uma Obra sendo montada.
  await cortar(g, page, 'Voltar', (s) => s.screen === 'home');
  await toque(page, 'Modos');
  await g.pular(1200);
  await cortar(g, page, /^Obras/, (s) => s.screen === 'obra');
  await g.pular(600);
  g.legenda('Monte cada <b>obra</b>', 3600, alturas.obra);
  const total = (await state(page)).obra!.pieces;
  for (let i = 0; i < Math.min(total, 6); i++) {
    const path = JSON.parse(await page.evaluate((p) => (window as any).__bb.obraDrag(p), i));
    if (!path) break;
    await g.arrastar(path.from, path.to, 380);
    await g.ate(naTela(page, (s) => s.obra!.placed === i + 1), 2000);
    await g.esperar(120);
  }
  await g.esperar(300);

  // 4. A Torre.
  await cortar(g, page, 'Voltar', (s) => s.screen === 'home');
  await toque(page, 'Modos');
  await g.pular(1200);
  await cortar(g, page, /^Torre do Capi/, (s) => s.screen === 'tower');
  await g.pular(800);
  g.legenda('Empilhe a <b>Torre</b> até a Lua', 3200, alturas.torre);
  const tela = page.viewportSize()!;
  for (let i = 0; i < 7; i++) {
    await g.esperar(250);
    await g.apertar(tela.width / 2, tela.height * 0.54, async () => {
      await page.evaluate(() => (window as any).__bb.placeTower(true));
      await g.esperar(120);
    });
  }
  await g.esperar(500);

  // 5. O guarda-roupa.
  await cortar(g, page, 'Voltar', (s) => s.screen === 'home');
  await toque(page, 'Guarda-Roupa');
  await g.pular(1500);
  g.legenda('Vista o Capi do <b>seu jeito</b>', 2400);
  await g.esperar(2400);

  // 6. Um combo no Infinito. O guarda-roupa abre por cima do menu: depois
  // do Voltar, espera ele sair.
  await toque(page, 'Voltar');
  await g.pular(1500);
  await toque(page, 'Modos');
  await g.pular(1200);
  await cortar(g, page, 'Infinito', (s) => s.screen === 'game' && s.kind === 'endless');
  await g.pular(2600);
  await loadScenario(page, COMBO);
  await g.pular(300);
  g.legenda('E faça <b>combos</b> incríveis!', 2600, alturas.combo);
  for (const m of JOGADAS_COMBO) {
    const path = JSON.parse(await page.evaluate(([s, r, c]) => (window as any).__bb.dragPath(s, r, c), [m.slot, m.row, m.col]));
    const antes = JSON.stringify((await state(page)).board);
    await g.arrastar(path.from, path.to, 360);
    await g.ate(naTela(page, (s) => JSON.stringify(s.board) !== antes));
    await g.esperar(m.slot === 2 ? 1700 : 250);
  }

  const mp4 = await g.terminar(convite, 2600);
  console.log(`${nome} (${FPS} qps, ${Math.round((Date.now() - t0) / 1000)} s para gravar): ${mp4}`);
  return mp4;
}

test.describe('previa-apple', () => {
  // 443x960 a 2x = 886x1920, o tamanho da prévia para iPhone de 6,5" e 6,9".
  test.use({ viewport: { width: 443, height: 960 }, deviceScaleFactor: 2 });
  test('previa-apple', async ({ page }) => {
    await passeio(
      page,
      'previa-apple',
      { largura: 886, altura: 1920, semLojas: true },
      { obra: '60%', torre: '30%', combo: '9%' },
      'Vem jogar com o <b>Capi</b>!',
    );
  });
});

test.describe('tour', () => {
  // O tamanho dos clipes das redes (360x640 a 3x, do playwright.clipes.config).
  test('tour', async ({ page }) => {
    const mp4 = await passeio(
      page,
      'tour',
      { largura: 1080, altura: 1920, semLojas: false },
      // Na tela 9:16 o tabuleiro e o Capi sobem: as legendas vão para baixo.
      { obra: '80%', torre: '62%', combo: '66%' },
      'Qual modo você <b>jogaria primeiro</b>?',
    );
    writeFileSync(
      mp4.replace(/\.mp4$/, '.txt'),
      'Vila, obras, torre até a Lua, roupinhas e muito combo: tudo isso num jogo de blocos com uma capivara 🦫🧩 ' +
        'Qual modo você jogaria primeiro? Link na bio! #capiblocks #capivara #jogodeblocos #jogosmobile #puzzle\n',
    );
  });
});
