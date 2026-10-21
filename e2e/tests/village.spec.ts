import { expect, test } from '@playwright/test';
import { openApp, snap, state, waitForState } from './helpers';

test('vila: com estrelas, constrói o próximo item; sem, o botão leva a jogar', async ({ page }, testInfo) => {
  await openApp(page, { level: 5, stars: 4 });
  await page.getByRole('button', { name: 'Vila do Capi' }).click();
  await waitForState(page, (x) => x.screen === 'village', 'vila aberta');
  await snap(page, testInfo, `vila-vazia-${testInfo.project.name}`);

  // The flower bed costs 3: build it, one star left.
  await page.getByRole('button', { name: 'Construir' }).click();
  await waitForState(page, (x) => x.stars === 1, 'gastou 3 estrelas');
  await expect(page.getByText(/Agora a vila tem: canteiro de flores/)).toBeVisible();

  // The fence costs 3 too: not enough, so the button says "Jogar".
  await expect(page.getByText('Cerquinha')).toBeVisible();
  await page.getByRole('button', { name: 'Jogar' }).click();
  await waitForState(page, (x) => x.screen === 'game' && x.level === 5, 'foi jogar');
  expect((await state(page)).stars).toBe(1);
});
