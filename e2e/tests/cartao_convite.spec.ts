import { expect, test } from '@playwright/test';
import { openApp, snap, startLevel, waitForState } from './helpers';

// Back on the menu after a level won, Capi now and then asks the player to
// bring friends (core/cartao_convite.dart). Browser tests only see the card
// when they ask for it.

test('cartão do convite: depois de vencer, o Capi chama amigos', async ({ page }, testInfo) => {
  await openApp(page, { level: 12, seen_testar_convite: true });
  await startLevel(page);
  const entendi = page.getByRole('button', { name: 'Entendi!' });
  if (await entendi.isVisible().catch(() => false)) await entendi.click();
  await page.evaluate(() => (window as any).__bb.win());
  await waitForState(page, (x) => x.showOutcome === true, 'vitória');
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (x) => x.screen === 'home', 'menu');

  const convidar = page.getByRole('button', { name: 'Convidar', exact: true });
  const agoraNao = page.getByRole('button', { name: 'Agora não', exact: true });
  await expect(convidar).toBeVisible({ timeout: 20_000 });
  await expect(agoraNao).toBeVisible();
  // The first of the three pictures: the rewards for whoever invites.
  await expect(page.getByText('Convide e ganhe prêmios').first()).toBeVisible();
  await snap(page, testInfo, `cartao-convite-${testInfo.project.name}`);

  await agoraNao.click();
  await expect(convidar).toHaveCount(0);
  expect(await page.evaluate(() => localStorage.getItem('flutter.conviteCartaoRecusas'))).toBe('1');
});

test('sem pedir, o cartão do convite não aparece nos testes', async ({ page }) => {
  await openApp(page, { level: 12 });
  await startLevel(page);
  const entendi = page.getByRole('button', { name: 'Entendi!' });
  if (await entendi.isVisible().catch(() => false)) await entendi.click();
  await page.evaluate(() => (window as any).__bb.win());
  await waitForState(page, (x) => x.showOutcome === true, 'vitória');
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (x) => x.screen === 'home', 'menu');
  await page.waitForTimeout(3_000);
  await expect(page.getByRole('button', { name: 'Convidar', exact: true })).toHaveCount(0);
});
