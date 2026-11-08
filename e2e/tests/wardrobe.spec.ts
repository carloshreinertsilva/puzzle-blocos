import { expect, test, type Page } from '@playwright/test';
import { openApp, snap, state, waitForState } from './helpers';

/** Opens the wardrobe screen from the menu. */
async function abrirGuardaRoupa(page: Page) {
  await page.getByRole('button', { name: 'Guarda-Roupa' }).click();
  await expect(page.getByRole('heading', { name: 'Guarda-Roupa do Capi' })).toBeVisible({ timeout: 30_000 });
  await page.waitForTimeout(400); // the screen's fade-in
}

test('guarda-roupa: compra com estrelas, veste e continua vestido', async ({ page }, testInfo) => {
  await openApp(page, { level: 8, stars: 120 });
  await abrirGuardaRoupa(page);
  await snap(page, testInfo, `guarda-roupa-${testInfo.project.name}`);

  // Every kind of clothes is on screen, without scrolling.
  for (const tipo of ['Cabeça', 'Rosto', 'Pescoço', 'Costas', 'Pelagem']) {
    await expect(page.getByRole('button', { name: new RegExp(`^${tipo}: \\d+ de \\d+$`) })).toBeInViewport();
  }

  // A hat, bought with stars (40, or less when it is one of today's offers).
  await page.getByRole('button', { name: /^Touca de Inverno/ }).click();
  await page.getByRole('button', { name: /^Comprar Touca de Inverno por \d+ estrelas$/ }).click();
  await waitForState(page, (s) => s.equippedHat === 'touca' && s.stars! <= 80, 'touca comprada');
  const depoisDaTouca = (await state(page)).stars!;

  // Sunglasses, in the face category.
  await page.getByRole('button', { name: /^Rosto: / }).click();
  await page.getByRole('button', { name: /^Óculos de Sol/ }).click();
  await page.getByRole('button', { name: /^Comprar Óculos de Sol por \d+ estrelas$/ }).click();
  await waitForState(page, (s) => s.stars! < depoisDaTouca, 'óculos comprados');
  const depoisDosOculos = (await state(page)).stars!;
  await snap(page, testInfo, `guarda-roupa-vestido-${testInfo.project.name}`);

  // Back to the menu and in again: still wearing both.
  await page.getByRole('button', { name: 'Voltar' }).click();
  await expect(page.getByRole('heading', { name: 'Guarda-Roupa do Capi' })).toHaveCount(0);
  await abrirGuardaRoupa(page);
  await expect(page.getByRole('button', { name: /^Touca de Inverno, comum, em uso/ })).toBeVisible();
  await page.getByRole('button', { name: /^Rosto: / }).click();
  await expect(page.getByRole('button', { name: /^Óculos de Sol, comum, em uso/ })).toBeVisible();
  const rosto = await page.evaluate(() => localStorage.getItem('flutter.equipped_rosto'));
  expect(rosto).toContain('oculos_sol');

  // Collections show the progress, and close.
  await page.getByRole('button', { name: 'Coleções' }).click();
  await expect(page.getByText(/Coleção Inverno: 1 de 3/)).toBeVisible();
  await page.getByRole('button', { name: 'Fechar' }).click();
  await expect(page.getByText(/Coleção Inverno: 1 de 3/)).toHaveCount(0);
  expect((await state(page)).stars).toBe(depoisDosOculos);
});

test('guarda-roupa: um item que já é seu se veste e se tira', async ({ page }) => {
  await openApp(page, { level: 8, unlockedHats: '["helmet","oculos_sol"]' });
  await abrirGuardaRoupa(page);
  await page.getByRole('button', { name: /^Rosto: / }).click();
  await page.getByRole('button', { name: /^Óculos de Sol, comum, seu/ }).click();
  await page.getByRole('button', { name: 'Vestir Óculos de Sol' }).click();
  await expect(page.getByRole('button', { name: /^Óculos de Sol, comum, em uso/ })).toBeVisible();
  await page.getByRole('button', { name: 'Tirar Óculos de Sol' }).click();
  await expect(page.getByRole('button', { name: /^Óculos de Sol, comum, seu/ })).toBeVisible();
});

test('guarda-roupa: sem estrelas suficientes, não compra', async ({ page }) => {
  await openApp(page, { level: 8, stars: 10 });
  await abrirGuardaRoupa(page);
  await page.getByRole('button', { name: /^Chapéu de Chef/ }).click();
  // The live region also announces it, so the text shows up twice.
  await expect(page.getByText(/^Faltam \d+ estrelas para comprar\.$|^Oferta do dia: \d+ estrelas\. Faltam/).first()).toBeVisible();
  await expect(page.getByRole('button', { name: /^Comprar/ })).toHaveCount(0);
});

test('guarda-roupa: um item raro também sai com 5 vídeos', async ({ page }) => {
  await openApp(page, { level: 8, stars: 0 });
  await abrirGuardaRoupa(page);
  await page.getByRole('button', { name: /^Chapéu de Chef/ }).click();
  for (let i = 0; i < 5; i++) {
    await page.getByRole('button', { name: `Ver vídeo para ganhar Chapéu de Chef: ${i} de 5` }).click();
    if (i < 4) {
      await expect(page.getByRole('button', { name: `Ver vídeo para ganhar Chapéu de Chef: ${i + 1} de 5` })).toBeVisible({ timeout: 10_000 });
    }
  }
  await waitForState(page, (s) => s.equippedHat === 'chef', 'chef ganho com vídeos');
});

test('ofertas do dia: na loja, compra o lendário do dia', async ({ page }) => {
  await openApp(page, { level: 8, stars: 0 });
  await page.getByRole('button', { name: 'Loja' }).click();
  await expect(page.getByText('Ofertas do dia').first()).toBeVisible({ timeout: 30_000 });
  const before = (await state(page)).unlockedHats ?? [];
  // The browser shop is simulated: the purchase goes through at once.
  await page.getByRole('button', { name: /^Comprar .* por R\$/ }).first().click();
  await expect
    .poll(async () => ((await state(page)).unlockedHats ?? []).length)
    .toBe(before.length + 1);
});
