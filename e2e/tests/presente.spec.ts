import { expect, test } from '@playwright/test';
import { openApp, snap, waitForState } from './helpers';

test('presente do dia: abre sozinho uma vez e dá o prêmio do dia 1', async ({ page }, testInfo) => {
  await openApp(page, { level: 8, stars: 0, giftShown: 0 });
  const pegar = page.getByRole('button', { name: /^Pegar o presente do dia 1/ });
  await expect(pegar).toBeVisible();
  await page.waitForTimeout(300);
  await snap(page, testInfo, `presente-${testInfo.project.name}`);
  await pegar.click();
  await waitForState(page, (s) => s.stars === 5, '+5 estrelas');
  await expect(page.getByText(/^Você ganhou 5 estrelas!/).first()).toBeVisible();
  await page.getByRole('button', { name: 'Fechar' }).click();

  // Not again today, even after reopening the game.
  await page.reload();
  await page.waitForFunction(() => (window as any).__bb !== undefined);
  await expect(page.getByRole('button', { name: /^Jogar · Fase/ })).toBeVisible();
  await expect(page.getByRole('button', { name: /^Pegar o presente/ })).toHaveCount(0);
});

test('presente do dia: "Depois" deixa o presente nas Missões Diárias', async ({ page }) => {
  await openApp(page, { level: 8, stars: 0, giftShown: 0 });
  await page.getByRole('button', { name: 'Depois' }).click();
  await page.getByRole('button', { name: 'Missões Diárias' }).click();
  await page.getByRole('button', { name: 'Abrir o presente do dia' }).click();
  await page.getByRole('button', { name: /^Pegar o presente do dia 1/ }).click();
  await waitForState(page, (s) => s.stars === 5, '+5 estrelas');
});
