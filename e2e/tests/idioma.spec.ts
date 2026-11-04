import { expect, test } from '@playwright/test';
import { openApp, waitForState } from './helpers';

// The game speaks Portuguese, English and Spanish: the saved choice wins,
// and the settings switch it on the spot.
test('idioma: inglês e espanhol pelas Configurações', async ({ page }) => {
  await openApp(page, { level: 5 });
  await page.getByRole('button', { name: 'Configurações' }).click();
  await page.getByRole('button', { name: /^Idioma/ }).click();
  await page.getByRole('button', { name: 'English' }).click();
  await expect(page.getByRole('button', { name: /^Play · Level 5/ })).toBeVisible();
  await expect(page.getByText("Capi's Village").first()).toBeVisible();

  await page.getByRole('button', { name: 'Settings' }).click();
  await page.getByRole('button', { name: /^Language/ }).click();
  await page.getByRole('button', { name: 'Español' }).click();
  await expect(page.getByRole('button', { name: /^Jugar · Nivel 5/ })).toBeVisible();

  // The choice is remembered.
  await page.reload();
  await page.waitForFunction(() => (window as any).__bb !== undefined);
  await expect(page.getByRole('button', { name: /^Jugar · Nivel 5/ })).toBeVisible();
  await page.getByRole('button', { name: /^Jugar · Nivel 5/ }).click();
  await waitForState(page, (x) => x.screen === 'game', 'fase em espanhol');
  await expect(page.getByText('Nivel 5').first()).toBeVisible();
});
