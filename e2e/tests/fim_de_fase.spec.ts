import { expect, test } from '@playwright/test';
import { inside, openApp, snap, startLevel, waitForState } from './helpers';

// Runs on every screen size in playwright.config.ts.

async function vencer(page: import('@playwright/test').Page) {
  await startLevel(page);
  const entendi = page.getByRole('button', { name: 'Entendi!' });
  if (await entendi.isVisible().catch(() => false)) await entendi.click();
  await page.evaluate(() => (window as any).__bb.win());
  await waitForState(page, (x) => x.showOutcome === true, 'vitória');
}

test('fim de fase: o modo liberado aparece e leva direto a ele', async ({ page }, testInfo) => {
  // Winning level 4 opens the Infinito (level 5).
  await openApp(page, { level: 4, seen_news_endless: false });
  await vencer(page);
  const conhecer = page.getByRole('button', { name: 'Conhecer: Infinito' });
  await expect(conhecer).toBeVisible();
  await expect(page.getByRole('button', { name: /^Passe: / })).toBeVisible();
  await snap(page, testInfo, `fim-de-fase-${testInfo.project.name}`);

  await conhecer.click();
  await waitForState(page, (s) => s.screen === 'game' && s.mode === 'endless', 'Infinito aberto');
});

test('fim de fase: com dois modos liberados, os botões continuam na tela', async ({ page }, testInfo) => {
  // Winning level 7 opens Blitz and Duelo (level 8): the tallest card.
  await openApp(page, { level: 7 });
  await vencer(page);
  const vp = page.viewportSize()!;
  for (const nome of ['Conhecer: Blitz 60s', 'Conhecer: Duelo', 'Próxima fase']) {
    const b = page.getByRole('button', { name: nome });
    await expect(b).toBeVisible();
    expect(inside((await b.boundingBox())!, vp.width, vp.height), `"${nome}" dentro da tela`).toBe(true);
  }
  await snap(page, testInfo, `fim-de-fase-dois-modos-${testInfo.project.name}`);

  // The Passe opens over the card, and the level goes on from there.
  await page.getByRole('button', { name: /^Passe: / }).click();
  await expect(page.getByRole('heading', { name: 'Passe do Capi' })).toBeVisible();
  await page.getByRole('button', { name: 'Fechar' }).click();
  await page.getByRole('button', { name: 'Próxima fase' }).click();
  await waitForState(page, (s) => s.screen === 'game' && s.level === 8 && s.showOutcome !== true, 'fase 8');
});

test('fim de fase: numa fase sem modo novo, só o Passe aparece', async ({ page }) => {
  await openApp(page, { level: 12 });
  await vencer(page);
  await expect(page.getByRole('button', { name: /^Passe: / })).toBeVisible();
  await expect(page.getByRole('button', { name: /^Conhecer: / })).toHaveCount(0);
});
