import { expect, test } from '@playwright/test';
import { openApp, snap, waitForState } from './helpers';

// Capi's tip of the day: once a day, on a quiet menu, about something the
// player never used. Browser tests only see it when they ask for it.

// The balloon's button: "Ver agora" with Capi's line as its hint (not the
// news window's "Ver agora: ...").
const DICA = /^Ver agora(?!:)/;
test('dica do dia: o Capi aponta o Blitz, uma vez só', async ({ page }, testInfo) => {
  await openApp(page, {
    level: 8,
    seen_testar_dica: true,
    // Already used: the tip goes on to the next thing, the Blitz.
    seen_opened_wardrobe: true,
    seen_opened_loja: true,
    seen_opened_passe: true,
  });
  const ver = page.getByRole('button', { name: DICA });
  await expect(ver).toBeVisible({ timeout: 30_000 });
  await snap(page, testInfo, `dica-${testInfo.project.name}`);
  expect(await page.evaluate(() => localStorage.getItem('flutter.dicaTema'))).toBe('"blitz"');
  await ver.click();
  await waitForState(page, (s) => s.mode === 'blitz', 'blitz aberto pela dica');

  // Not again today, even after reopening the game.
  await page.reload();
  await page.waitForFunction(() => (window as any).__bb !== undefined);
  await expect(page.getByRole('button', { name: /^Jogar · Fase/ })).toBeVisible();
  await page.waitForTimeout(4_000);
  await expect(page.getByRole('button', { name: DICA })).toHaveCount(0);
});

test('sem pedir, a dica não aparece nos testes', async ({ page }) => {
  await openApp(page, { level: 8 });
  await page.waitForTimeout(4_000);
  await expect(page.getByRole('button', { name: DICA })).toHaveCount(0);
});
