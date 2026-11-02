import { expect, test } from '@playwright/test';
import { openApp, snap, state, waitForState } from './helpers';

test('guarda-roupa: compra com estrelas, veste e continua vestido', async ({ page }, testInfo) => {
  await openApp(page, { level: 8, stars: 120 });
  await page.getByRole('button', { name: 'Guarda-Roupa' }).click();
  await expect(page.getByRole('dialog')).toBeVisible();
  await page.waitForTimeout(400); // the dialog's opening animation
  await snap(page, testInfo, `guarda-roupa-${testInfo.project.name}`);

  // A hat, bought with stars.
  await page.getByRole('button', { name: /^Touca de Inverno/ }).click();
  await page.getByRole('button', { name: 'Comprar Touca de Inverno por 40 estrelas' }).click();
  await waitForState(page, (s) => s.equippedHat === 'touca' && s.stars === 80, 'touca comprada');

  // Sunglasses, in the face tab.
  await page.getByRole('button', { name: 'Aba Rosto' }).click();
  await page.getByRole('button', { name: /^Óculos de Sol/ }).click();
  await page.getByRole('button', { name: 'Comprar Óculos de Sol por 40 estrelas' }).click();
  await waitForState(page, (s) => s.stars === 40, 'óculos comprados');
  await snap(page, testInfo, `guarda-roupa-vestido-${testInfo.project.name}`);

  // Closed and opened again: still wearing both.
  await page.getByRole('button', { name: 'Fechar' }).click();
  await expect(page.getByRole('dialog')).toHaveCount(0);
  await page.getByRole('button', { name: 'Guarda-Roupa' }).click();
  await expect(page.getByRole('button', { name: /^Touca de Inverno, comum, em uso/ })).toBeVisible();
  await page.getByRole('button', { name: 'Aba Rosto' }).click();
  await expect(page.getByRole('button', { name: /^Óculos de Sol, comum, em uso/ })).toBeVisible();
  const rosto = await page.evaluate(() => localStorage.getItem('flutter.equipped_rosto'));
  expect(rosto).toContain('oculos_sol');

  // Collections show the progress.
  await page.getByRole('button', { name: 'Aba Coleções' }).click();
  await expect(page.getByText(/Coleção Inverno: 1 de 3/)).toBeVisible();
  expect((await state(page)).stars).toBe(40);
});

test('guarda-roupa: sem estrelas suficientes, não compra', async ({ page }) => {
  await openApp(page, { level: 8, stars: 10 });
  await page.getByRole('button', { name: 'Guarda-Roupa' }).click();
  await expect(page.getByRole('dialog')).toBeVisible();
  await page.waitForTimeout(400); // the dialog's opening animation
  await page.getByRole('button', { name: /^Chapéu de Chef/ }).click();
  // The live region also announces it, so the text shows up twice.
  await expect(page.getByText('Faltam 140 estrelas para comprar.').first()).toBeVisible();
  await expect(page.getByRole('button', { name: /^Comprar/ })).toHaveCount(0);
});

test('guarda-roupa: um item raro também sai com 5 vídeos', async ({ page }) => {
  await openApp(page, { level: 8, stars: 0 });
  await page.getByRole('button', { name: 'Guarda-Roupa' }).click();
  await expect(page.getByRole('dialog')).toBeVisible();
  await page.waitForTimeout(400); // the dialog's opening animation
  await page.getByRole('button', { name: /^Chapéu de Chef/ }).click();
  for (let i = 0; i < 5; i++) {
    await page.getByRole('button', { name: `Ver vídeo para ganhar Chapéu de Chef: ${i} de 5` }).click();
    if (i < 4) {
      await expect(page.getByRole('button', { name: `Ver vídeo para ganhar Chapéu de Chef: ${i + 1} de 5` })).toBeVisible({ timeout: 10_000 });
    }
  }
  await waitForState(page, (s) => s.equippedHat === 'chef', 'chef ganho com vídeos');
});

test('mercado do capi: compra o lendário do dia', async ({ page }) => {
  await openApp(page, { level: 8, stars: 0 });
  await page.getByRole('button', { name: 'Guarda-Roupa' }).click();
  await expect(page.getByRole('dialog')).toBeVisible();
  await page.waitForTimeout(400);
  await page.getByRole('button', { name: 'Aba Mercado' }).click();
  await expect(page.getByText(/^Ofertas de hoje/).first()).toBeVisible();
  const before = (await state(page)).unlockedHats ?? [];
  // The browser shop is simulated: the purchase goes through at once.
  await page.getByRole('button', { name: /^Comprar .* por R\$/ }).click();
  await expect
    .poll(async () => ((await state(page)).unlockedHats ?? []).length)
    .toBe(before.length + 1);
});
