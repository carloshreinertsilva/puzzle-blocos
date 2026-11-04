import { expect, test } from '@playwright/test';
import { openApp, snap, startLevel, state, waitForState } from './helpers';

test('estrelas: vencer mostra as estrelas e os desafios; a fase antiga pode ser rejogada', async ({ page }, testInfo) => {
  await openApp(page, { level: 2 });
  await startLevel(page);
  await page.evaluate(() => (window as any).__bb.win());
  const s = await waitForState(page, (x) => x.showOutcome === true, 'vitória');
  // Won without "Continuar": at least two stars.
  expect(s.starsGained).toBeGreaterThanOrEqual(2);
  await expect(page.getByText('Vencer a fase')).toBeVisible();
  await expect(page.getByText(/\+\d estrelas/)).toBeVisible();
  await snap(page, testInfo, `estrelas-${testInfo.project.name}`);

  // On to level 3, then back to the menu.
  await page.getByRole('button', { name: 'Próxima fase' }).click();
  await page.getByRole('button', { name: 'Entendi!' }).click();
  await page.getByRole('button', { name: 'Pausar' }).click();
  await expect(page.getByText('Desafios da fase', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (x) => x.screen === 'home', 'menu');
  expect((await state(page)).stars).toBe(s.starsGained);

  // Level 2 again, from the road: a replay, with "Jogar de novo" at the end.
  await page.getByRole('button', { name: /^Fase 2, \d de 3 estrelas/ }).click();
  await waitForState(page, (x) => x.screen === 'game' && x.level === 2 && x.replay === true, 'fase 2 de novo');
  await page.evaluate(() => (window as any).__bb.win());
  await waitForState(page, (x) => x.showOutcome === true, 'vitória de novo');
  await expect(page.getByRole('button', { name: 'Jogar de novo' })).toBeVisible();
});

test('vitória: dá para voltar ao menu em vez de seguir para a próxima fase', async ({ page }) => {
  await openApp(page, { level: 2 });
  await startLevel(page);
  const entendi = page.getByRole('button', { name: 'Entendi!' });
  if (await entendi.isVisible().catch(() => false)) await entendi.click();
  await page.evaluate(() => (window as any).__bb.win());
  await waitForState(page, (x) => x.showOutcome === true, 'vitória');
  await expect(page.getByRole('button', { name: 'Próxima fase' })).toBeVisible();
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (x) => x.screen === 'home', 'menu');
});

// The three stars are no surprise: the level shows them as it starts, and
// they stay at the top, lighting up as each challenge is met.
test('estrelas: os desafios aparecem no começo e ficam no topo da fase', async ({ page }) => {
  await openApp(page, { level: 2 });
  await startLevel(page);
  const entendi = page.getByRole('button', { name: 'Entendi!' });
  if (await entendi.isVisible().catch(() => false)) await entendi.click();
  await expect(page.getByText(/^Desafios da fase: Vencer a fase/).first()).toBeVisible();
  const strip = page.getByRole('button', { name: /^Estrelas da fase: 1 de 3/ });
  await expect(strip).toBeVisible();
  // Nothing done yet but keeping the second chance unused.
  expect((await state(page)).liveStarBits).toBe(4);
  // It goes away by itself, and a tap on the stars brings it back.
  await expect(page.getByText(/^Desafios da fase: Vencer a fase/)).toHaveCount(0, { timeout: 8000 });
  await strip.click();
  await expect(page.getByText(/^Desafios da fase: Vencer a fase/).first()).toBeVisible();
});

// The road scrolls back to every level played: an old level with stars
// missing can be found and played again.
test('estrada: rolar até uma fase antiga e buscar as estrelas que faltaram', async ({ page }) => {
  await openApp(page, { level: 12, stars_3: 3 });
  const old = page.getByRole('button', { name: 'Fase 3, 2 de 3 estrelas' });
  await expect(old).toHaveCount(0); // far below, off screen
  const vp = page.viewportSize()!;
  await page.mouse.move(vp.width * 0.65, vp.height * 0.3);
  for (let i = 0; i < 20 && !(await old.isVisible().catch(() => false)); i++) {
    await page.mouse.wheel(0, 150);
    await page.waitForTimeout(120);
  }
  await page.waitForTimeout(500); // the road settles
  const b = (await old.boundingBox())!;
  await page.mouse.click(b.x + b.width / 2, b.y + b.height / 2);
  await waitForState(page, (x) => x.screen === 'game' && x.level === 3 && x.replay === true, 'fase 3 de novo');
});
