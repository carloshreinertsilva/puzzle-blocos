import { expect, test } from '@playwright/test';
import { openApp, startLevel, state, waitForState } from './helpers';

// The browser tests use the simulated shop: purchases go through at once.
test.describe('Loja do Capi', () => {
  test('compra estrelas e remove os anúncios', async ({ page }) => {
    await openApp(page, { stars: 5 });
    await page.getByRole('button', { name: 'Loja' }).click();
    await expect(page.getByText('Loja do Capi')).toBeVisible({ timeout: 30_000 });

    await page.getByRole('button', { name: /^Comprar 150 estrelas por/ }).click();
    await expect.poll(async () => (await state(page)).stars).toBe(155);

    await page.getByRole('button', { name: /^Comprar Remover anúncios por/ }).click();
    // Saved: no more ads between levels, and the VIP top hat came with it.
    await expect
      .poll(() => page.evaluate(() => localStorage.getItem('flutter.adsRemoved')), { timeout: 15_000 })
      .toBe('true');
    const chapeus = await page.evaluate(() => localStorage.getItem('flutter.unlockedHats') ?? '');
    expect(chapeus).toContain('vip');
    // The shop no longer offers it.
    await expect(page.getByRole('button', { name: /^Comprar Remover anúncios por/ })).toHaveCount(0);
  });

  test('a loja fecha pelo botão Fechar', async ({ page }) => {
    await openApp(page, { stars: 5 });
    await page.getByRole('button', { name: 'Loja' }).click();
    await expect(page.getByText('Loja do Capi')).toBeVisible({ timeout: 30_000 });
    await page.getByRole('button', { name: 'Fechar' }).click();
    await expect(page.getByText('Loja do Capi')).toHaveCount(0, { timeout: 10_000 });
    // Back on the menu, which takes taps again.
    await expect(page.getByRole('button', { name: /^Jogar · Fase/ })).toBeVisible();
  });

  test('o balão da Loja não tapa os botões do menu', async ({ page }) => {
    await openApp(page, { stars: 5 });
    // The balloon shows at 4 s and shrinks away at 8 s: buttons still work
    // while it is up and after it is gone.
    await page.waitForTimeout(5_000);
    await page.getByRole('button', { name: 'Configurações' }).click({ timeout: 10_000 });
    await expect(page.getByText('Política de Privacidade')).toBeVisible({ timeout: 30_000 });
    await page.getByRole('button', { name: 'Fechar' }).click();
    await page.waitForTimeout(5_000);
    await page.getByRole('button', { name: 'Loja' }).click({ timeout: 10_000 });
    await expect(page.getByText('Loja do Capi')).toBeVisible({ timeout: 30_000 });
  });

  test('dobrar as estrelas da fase com um vídeo', async ({ page }) => {
    await openApp(page, { level: 2, stars: 0 });
    await startLevel(page);
    await page.evaluate(() => (window as any).__bb.win());
    const s = await waitForState(page, (x) => x.showOutcome === true, 'vitória');
    expect(s.starsGained).toBeGreaterThan(0);
    await page.getByRole('button', { name: /^Dobrar: \+\d com vídeo/ }).click();
    await expect(page.getByText(/^Estrelas dobradas/)).toBeVisible({ timeout: 10_000 });
    // The video is clearly paid off.
    await expect(page.getByText(`+${s.starsGained} ★ pelo vídeo!`).first()).toBeVisible();
    await expect.poll(async () => (await state(page)).stars).toBe(2 * s.starsGained);
  });

  test('baú bônus do dia: +5 estrelas com um vídeo, uma vez', async ({ page }) => {
    await openApp(page, { level: 8, stars: 0 });
    await page.getByRole('button', { name: 'Missões Diárias' }).click();
    const bau = page.getByRole('button', { name: /^Abrir baú bônus: \+5 estrelas/ });
    await bau.click();
    await expect.poll(async () => (await state(page)).stars, { timeout: 10_000 }).toBe(5);
    await expect(page.getByText('+5 ★ do baú extra!').first()).toBeVisible();
    // Once a day: the button is gone.
    await expect(bau).toHaveCount(0);
  });
});
