import { expect, test } from '@playwright/test';
import { openApp, snap, state, waitForState } from './helpers';

test('baú diário: suspense, abre com um toque e revela o item', async ({ page }, testInfo) => {
  await openApp(page, { level: 8, stars: 0, equippedHat: 'party' });
  const s = await state(page);
  for (const m of s.missions!) {
    await page.evaluate(([i, t]) => (window as any).__bb.progressDailyMission(i, t), [m.index, m.target]);
  }
  await page.getByRole('button', { name: 'Missões Diárias' }).click();
  await page.getByRole('button', { name: 'Abrir Baú do Capi' }).click();

  // Suspense: Capi walks up, the chest shakes.
  await page.waitForTimeout(1500);
  await snap(page, testInfo, `bau-suspense-${testInfo.project.name}`);
  await page.getByRole('button', { name: 'Abrir o baú' }).click();

  // The prize shows, with the stars.
  await expect(page.getByText(/^Novo item: .* e \+5 estrelas!$/).first()).toBeVisible({ timeout: 5_000 });
  await page.waitForTimeout(400);
  await snap(page, testInfo, `bau-aberto-${testInfo.project.name}`);
  await waitForState(page, (x) => x.stars === 5 && (x.unlockedHats ?? []).length === 2, 'item e estrelas');
  await page.getByRole('button', { name: 'Maravilha!' }).click();
  await expect(page.getByRole('button', { name: 'Maravilha!' })).toHaveCount(0);
});
