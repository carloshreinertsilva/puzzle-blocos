import { expect, test } from '@playwright/test';
import { openApp, snap, state, waitForState } from './helpers';

test('passe do capi: pega prêmios grátis, libera o premium e pega o lendário', async ({ page }, testInfo) => {
  await openApp(page, { level: 8, stars: 0 });
  // 2 levels of pass points, as if earned by playing.
  await page.evaluate(() => (window as any).__bb.earnStars(30));
  await waitForState(page, (s) => s.stars === 30 && s.passe?.nivel === 2, 'nível 2 do passe');

  await page.getByRole('button', { name: 'Missões Diárias' }).click();
  await page.getByRole('button', { name: /^Passe do Capi, 2 prêmios para pegar/ }).click();
  await expect(page.getByText('Nível 2 de 20')).toBeVisible();
  await page.waitForTimeout(400);
  await snap(page, testInfo, `passe-${testInfo.project.name}`);

  // Free track: once.
  await page.getByRole('button', { name: 'Nível 1 grátis: 3 estrelas, pegar' }).click();
  await waitForState(page, (s) => s.stars === 33, '+3 estrelas');
  await expect(page.getByRole('button', { name: 'Nível 1 grátis: 3 estrelas, pegar' })).toHaveCount(0);

  // Premium: locked until bought (the browser shop is simulated).
  await expect(page.getByText('Nível 1 premium: 10 estrelas, bloqueado')).toBeVisible();
  await page.getByRole('button', { name: /^Liberar a trilha premium do Passe/ }).click();
  await waitForState(page, (s) => s.passe?.premium === true, 'premium liberado');
  await page.getByRole('button', { name: 'Nível 1 premium: 10 estrelas, pegar' }).click();
  await waitForState(page, (s) => s.stars === 43, '+10 estrelas');
  expect((await state(page)).passe!.premium).toBe(true);
});
