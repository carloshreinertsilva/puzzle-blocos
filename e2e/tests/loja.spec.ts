import { expect, test } from '@playwright/test';
import { openApp, startLevel, state, waitForState } from './helpers';

// The browser tests use the simulated shop: purchases go through at once.
test.describe('Loja do Capi', () => {
  test('compra estrelas e remove os anúncios', async ({ page }) => {
    await openApp(page, { stars: 5 });
    await page.getByRole('button', { name: 'Loja' }).click();
    await expect(page.getByText('Loja do Capi')).toBeVisible();

    await page.getByRole('button', { name: /^Comprar 150 estrelas por/ }).click();
    await expect.poll(async () => (await state(page)).stars).toBe(155);

    await page.getByRole('button', { name: /^Comprar Remover anúncios por/ }).click();
    await expect(page.getByText('Sem anúncios entre fases', { exact: true })).toBeVisible();
    // The VIP top hat came with it.
    const chapeus = await page.evaluate(() => localStorage.getItem('flutter.unlockedHats') ?? '');
    expect(chapeus).toContain('vip');
  });

  test('dobrar as estrelas da fase com um vídeo', async ({ page }) => {
    await openApp(page, { level: 2, stars: 0 });
    await startLevel(page);
    await page.evaluate(() => (window as any).__bb.win());
    const s = await waitForState(page, (x) => x.showOutcome === true, 'vitória');
    expect(s.starsGained).toBeGreaterThan(0);
    await page.getByRole('button', { name: /^Dobrar: \+\d com vídeo/ }).click();
    await expect(page.getByText(/^Estrelas dobradas/)).toBeVisible({ timeout: 10_000 });
    await expect.poll(async () => (await state(page)).stars).toBe(2 * s.starsGained);
  });

  test('baú bônus do dia: +5 estrelas com um vídeo, uma vez', async ({ page }) => {
    await openApp(page, { level: 8, stars: 0 });
    await page.getByRole('button', { name: 'Missões Diárias' }).click();
    const bau = page.getByRole('button', { name: /^Abrir baú bônus: \+5 estrelas/ });
    await bau.click();
    await expect.poll(async () => (await state(page)).stars, { timeout: 10_000 }).toBe(5);
    // Once a day: the button is gone.
    await expect(bau).toHaveCount(0);
  });
});
