import { expect, test } from '@playwright/test';
import { openApp, snap, state, waitForState } from './helpers';

test('vila: com estrelas, monta a obra e constrói o item; sem, o botão leva a jogar', async ({ page }, testInfo) => {
  await openApp(page, { level: 5, stars: 24 });
  await page.getByRole('button', { name: /^Vila do Capi/ }).click();
  await waitForState(page, (x) => x.screen === 'village', 'vila aberta');
  await snap(page, testInfo, `vila-vazia-${testInfo.project.name}`);

  // The flower bed costs 18: building opens its obra first.
  await page.getByRole('button', { name: 'Construir' }).click();
  await waitForState(page, (x) => x.screen === 'obra', 'obra aberta');
  expect((await state(page)).stars, 'só paga ao terminar').toBe(24);
  await page.evaluate(() => (window as any).__bb.win());
  await page.getByRole('button', { name: 'Construir na vila' }).click();
  await waitForState(page, (x) => x.screen === 'village' && x.stars === 6, 'gastou 18 estrelas');
  await expect(page.getByText(/Agora a vila tem: canteiro de flores/)).toBeVisible();

  // The fence costs 18 too: not enough, so the button says "Jogar".
  await expect(page.getByText('Cerquinha')).toBeVisible();
  await page.getByRole('button', { name: 'Jogar' }).click();
  await waitForState(page, (x) => x.screen === 'game' && x.level === 5, 'foi jogar');
  expect((await state(page)).stars).toBe(6);
});

test('vila: desistir da obra não gasta estrelas', async ({ page }) => {
  await openApp(page, { level: 5, stars: 24 });
  await page.getByRole('button', { name: /^Vila do Capi/ }).click();
  await page.getByRole('button', { name: 'Construir' }).click();
  await waitForState(page, (x) => x.screen === 'obra', 'obra aberta');
  await page.getByRole('button', { name: 'Voltar' }).click();
  await waitForState(page, (x) => x.screen === 'village', 'voltou para a vila');
  expect((await state(page)).stars).toBe(24);
  await expect(page.getByRole('button', { name: 'Construir' })).toBeVisible();
});
