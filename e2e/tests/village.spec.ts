import { expect, test } from '@playwright/test';
import { openApp, snap, state, waitForState } from './helpers';

test('vila: com estrelas, monta a obra e constrói o item; sem, o botão leva a jogar', async ({ page }, testInfo) => {
  await openApp(page, { level: 5, stars: 24 });
  await page.getByRole('button', { name: /^Vila do Capi/ }).click();
  await waitForState(page, (x) => x.screen === 'village', 'vila aberta');
  await snap(page, testInfo, `vila-vazia-${testInfo.project.name}`);

  // The market points at the cheapest item, the flower bed (18): building
  // opens its obra first.
  await page.getByRole('button', { name: 'Construir Canteiro de flores' }).click();
  await waitForState(page, (x) => x.screen === 'obra', 'obra aberta');
  expect((await state(page)).stars, 'só paga ao terminar').toBe(24);
  await page.evaluate(() => (window as any).__bb.win());
  await page.getByRole('button', { name: 'Construir na vila' }).click();
  await waitForState(page, (x) => x.screen === 'village' && x.stars === 6, 'gastou 18 estrelas');
  await expect(page.getByText(/Agora a vila tem: canteiro de flores/)).toBeVisible();

  // The fence costs 18 too: not enough, so the button says "Jogar".
  await expect(page.getByRole('button', { name: /^Cerquinha, 18 estrelas/ })).toBeVisible();
  await page.getByRole('button', { name: 'Jogar' }).click();
  await waitForState(page, (x) => x.screen === 'game' && x.level === 5, 'foi jogar');
  expect((await state(page)).stars).toBe(6);
});

test('vila: desistir da obra não gasta estrelas', async ({ page }) => {
  await openApp(page, { level: 5, stars: 24 });
  await page.getByRole('button', { name: /^Vila do Capi/ }).click();
  await page.getByRole('button', { name: /^Construir/ }).click();
  await waitForState(page, (x) => x.screen === 'obra', 'obra aberta');
  await page.getByRole('button', { name: 'Voltar' }).click();
  await waitForState(page, (x) => x.screen === 'village', 'voltou para a vila');
  expect((await state(page)).stars).toBe(24);
  await expect(page.getByRole('button', { name: /^Construir/ })).toBeVisible();
});

// The village market: the player picks what to build, in any order.
test('vila: o mercado deixa escolher o que construir', async ({ page }) => {
  await openApp(page, { level: 5, stars: 40, villageBuilt: 1 });
  await page.getByRole('button', { name: /^Vila do Capi/ }).click();
  await waitForState(page, (x) => x.screen === 'village', 'vila aberta');
  // Saves from before the market keep their first item.
  expect((await state(page)).villageItems).toEqual(['flores']);
  await expect(page.getByRole('button', { name: /^Canteiro de flores/ })).toHaveCount(0);

  // The pier is down the list: scroll the market sideways to reach it.
  const pier = page.getByRole('button', { name: /^Píer, 36 estrelas/ });
  const flowersGone = page.getByRole('button', { name: /^Cerquinha, 18 estrelas/ });
  const box = (await flowersGone.boundingBox())!;
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  for (let i = 0; i < 10 && !(await pier.isVisible()); i++) {
    await page.mouse.wheel(0, 200);
    await page.waitForTimeout(150);
  }
  await pier.click();
  await expect(page.getByText(/Já dá para construir píer/)).toBeVisible();
  await page.getByRole('button', { name: 'Construir Píer' }).click();
  await waitForState(page, (x) => x.screen === 'obra', 'obra do píer');
  await page.evaluate(() => (window as any).__bb.win());
  await page.getByRole('button', { name: 'Construir na vila' }).click();
  const s = await waitForState(page, (x) => x.screen === 'village' && x.stars === 4, 'gastou 36 estrelas');
  expect(s.villageItems).toEqual(['flores', 'pier']);
});
