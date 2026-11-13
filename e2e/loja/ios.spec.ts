import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { test, type Page } from '@playwright/test';
import { loadScenario, openApp, state, waitForState } from '../tests/helpers';

/**
 * Telas cruas para as capturas da App Store (iPhone), em português, na
 * ordem da ficha: primeiro o que é só do CapiBlocks (Vila, Obras, Torre,
 * filhotes, o Capi), o tabuleiro comum por último.
 *   npm run build && npx playwright test -c playwright.loja.config.ts ios
 *   node ../tool/loja_ios.js
 * Telas em e2e/loja/saida/ios/; as capturas montadas em docs/loja/ios/.
 */

// Proporção da tela do iPhone de 6,9" dentro da moldura de tool/loja_ios.js.
test.use({ viewport: { width: 392, height: 763 }, deviceScaleFactor: 3 });

const json = (v: unknown) => JSON.stringify(v);

async function foto(page: Page, nome: string) {
  const pasta = join(__dirname, 'saida', 'ios');
  mkdirSync(pasta, { recursive: true });
  await page.screenshot({ path: join(pasta, `${nome}.png`) });
}

async function arrastar(page: Page, slot: number, row: number, col: number) {
  const path = JSON.parse(await page.evaluate(([s, r, c]) => (window as any).__bb.dragPath(s, r, c), [slot, row, col]));
  await page.mouse.move(path.from.x, path.from.y);
  await page.mouse.down();
  await page.mouse.move(path.to.x, path.to.y, { steps: 10 });
  await page.waitForTimeout(80);
  return () => page.mouse.up();
}

async function fecharApresentacoes(page: Page) {
  for (let i = 0; i < 6; i++) {
    const s = await state(page);
    if (s.screen === 'game' && s.intros!.length === 0) break;
    const ok = page.getByRole('button', { name: 'Entendi!' });
    if (await ok.isVisible()) await ok.click();
    await page.waitForTimeout(500);
  }
}

test('1 vila', async ({ page }) => {
  await openApp(page, { level: 60, villageBuilt: 99, pupsSaved: 12, stars: 340 });
  await page.getByRole('button', { name: /^Vila do Capi/ }).click();
  await waitForState(page, (s) => s.screen === 'village', 'vila');
  await page.waitForTimeout(3000);
  await foto(page, '1-vila');
});

test('2 obra', async ({ page }) => {
  await openApp(page, { level: 30, stars: 340, obraLevel: 9 });
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: /^Obras/ }).click();
  await waitForState(page, (s) => s.screen === 'obra', 'obra aberta');
  await page.waitForTimeout(800);
  const total = (await state(page)).obra!.pieces;
  // Uns dois terços montados: o desenho já aparece, e ainda há peças.
  const montar = Math.max(2, Math.round(total * 0.65));
  for (let i = 0; i < montar; i++) {
    const path = JSON.parse(await page.evaluate((p) => (window as any).__bb.obraDrag(p), i));
    if (!path) break;
    await page.mouse.move(path.from.x, path.from.y);
    await page.mouse.down();
    await page.mouse.move(path.from.x, path.from.y - 20, { steps: 3 });
    await page.mouse.move(path.to.x, path.to.y, { steps: 10 });
    await page.waitForTimeout(60);
    await page.mouse.up();
    await waitForState(page, (x) => x.obra!.placed === i + 1, `peça ${i}`);
    await page.waitForTimeout(200);
  }
  await page.waitForTimeout(1200);
  await foto(page, '2-obra');
});

test('3 torre', async ({ page }) => {
  await openApp(page, { level: 30, seen_opened_tower: true, towerBestHeight: 40, stars: 340 });
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: /^Torre do Capi/ }).click();
  await waitForState(page, (s) => s.screen === 'tower', 'torre aberta');
  await page.waitForTimeout(1000);
  for (let i = 0; i < 22; i++) {
    await page.evaluate(() => (window as any).__bb.placeTower(true));
    await page.waitForTimeout(650);
  }
  await page.waitForTimeout(500);
  await foto(page, '3-torre');
});

test('4 filhotes', async ({ page }) => {
  await openApp(page, { level: 8, stars: 40, seen_pups: true });
  await page.getByRole('button', { name: /^Jogar · Fase/ }).click();
  await waitForState(page, (s) => s.screen === 'game', 'fase');
  await fecharApresentacoes(page);
  await page.waitForTimeout(2800);
  await loadScenario(page, {
    board: ['..bb....', '.bpbb...', '..bb.pb.', '.bb.bb..', '.b..bp..', '..pb..b.', '........', '........'],
    tray: ['o20', 'v30', 'l40'],
  });
  await page.waitForTimeout(300);
  for (const [slot, r, c] of [[0, 6, 3], [1, 5, 0]]) {
    await (await arrastar(page, slot, r, c))();
    await page.waitForTimeout(600);
  }
  await page.waitForTimeout(1500);
  await foto(page, '4-filhotes');
});

test('5 guarda-roupa', async ({ page }) => {
  await openApp(page, {
    level: 30,
    stars: 340,
    equippedHat: json('crown'),
    equipped_costas: json('capa_real'),
    equipped_rosto: json('oculos_coracao'),
    unlockedHats: json(['helmet', 'crown', 'capa_real', 'oculos_coracao', 'touca', 'chef', 'pirate', 'wizard', 'party']),
  });
  await page.getByRole('button', { name: 'Guarda-Roupa' }).click();
  await page.waitForTimeout(2000);
  await foto(page, '5-guarda-roupa');
});

test('6 combo', async ({ page }) => {
  await page.clock.install();
  await openApp(page, { level: 30, stars: 340 });
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: 'Infinito' }).click();
  await waitForState(page, (s) => s.screen === 'game' && s.kind === 'endless', 'infinito');
  await fecharApresentacoes(page);
  await page.waitForTimeout(2500);
  await loadScenario(page, {
    board: ['.bb.b..b', '.bbb..b.', '.bb..g..', 'bgb.b..b', 'bbbb.b..', '...bbb..', '...bgb..', '...bbgbb'],
    tray: ['i31', 'o20', 'o30'],
  });
  await page.waitForTimeout(400);
  for (const [slot, r, c] of [[0, 0, 0], [1, 5, 6]]) {
    await (await arrastar(page, slot, r, c))();
    await page.waitForTimeout(1200);
  }
  // A foto sai no meio da comemoração do combo grande.
  const soltar = await arrastar(page, 2, 5, 0);
  // O relógio da página corre sozinho: tenta parar um pouco à frente.
  for (let folga = 50; ; folga *= 4) {
    const agora = await page.evaluate(() => Date.now());
    try {
      await page.clock.pauseAt(agora + folga);
      break;
    } catch (e) {
      if (folga > 5000) throw e;
    }
  }
  await soltar();
  for (let i = 0; i < 26; i++) {
    await page.clock.runFor(1000 / 60);
    for (let k = 0; k < 3; k++) await page.clock.runFor(0);
  }
  await page.waitForTimeout(300);
  await foto(page, '6-combo');
});

test('7 modos', async ({ page }) => {
  await openApp(page, { level: 30, stars: 340 });
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.waitForTimeout(1500);
  await foto(page, '7-modos');
});
