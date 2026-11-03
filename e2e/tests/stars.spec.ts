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
  await expect(page.getByText('Desafios da fase')).toBeVisible();
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
