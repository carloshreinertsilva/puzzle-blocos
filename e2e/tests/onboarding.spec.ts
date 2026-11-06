import { expect, test } from '@playwright/test';
import { dragPiece, inside, openFresh, snap, state, waitForState } from './helpers';

test('primeira vez: tutorial com o Capi e direto para a fase 1, sem menu', async ({ page }, testInfo) => {
  await openFresh(page);
  await expect(page.getByText(/Eu sou o Capi/)).toBeVisible();
  await snap(page, testInfo, `tutorial-${testInfo.project.name}`);

  for (let step = 0; step < 3; step++) {
    const s = await waitForState(page, (x) => x.tutorialStep === step && x.hint !== undefined, `passo ${step + 1}`);
    const [slot, row, col] = s.hint!;
    await dragPiece(page, slot, row, col);
  }
  await waitForState(page, (x) => x.tutorialStep === 3, 'tutorial concluído');
  const go = page.getByRole('button', { name: 'Bora!' });
  await expect(go).toBeVisible();
  expect(inside((await go.boundingBox())!, page.viewportSize()!.width, page.viewportSize()!.height)).toBe(true);
  await go.click();

  const s = await waitForState(page, (x) => x.screen === 'game' && x.mode === 'levels' && x.status === 'playing', 'fase 1');
  expect(s.level).toBe(1);
  // While onboarding there is no way to the menu yet.
  await page.getByRole('button', { name: 'Pausar' }).click();
  await expect(page.getByRole('button', { name: 'Continuar' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Menu' })).toHaveCount(0);
});

test('"Pular" encerra o tutorial', async ({ page }) => {
  await openFresh(page);
  await page.getByRole('button', { name: 'Pular tutorial' }).click();
  await page.getByRole('button', { name: 'Bora!' }).click();
  await waitForState(page, (x) => x.mode === 'levels' && x.level === 1, 'fase 1');
});

test('depois da fase 3 o menu aparece com o Capi; modos liberam por fase', async ({ page }, testInfo) => {
  await openFresh(page, { seen_tutorial: true, level: 3 });
  await waitForState(page, (x) => x.screen === 'game' && x.level === 3, 'fase 3 sem menu');
  await page.getByRole('button', { name: 'Entendi!' }).click();
  await page.evaluate(() => (window as any).__bb.win());
  await page.getByRole('button', { name: 'Próxima fase' }).click();

  await waitForState(page, (x) => x.screen === 'home', 'menu');
  await expect(page.getByText(/Essa é a nossa estrada/)).toBeVisible();
  await snap(page, testInfo, `menu-capi-${testInfo.project.name}`);
  await page.getByRole('button', { name: 'Bora!' }).click();
  // Then Capi introduces his village.
  await expect(page.getByText(/constrói a minha vila/)).toBeVisible();
  await page.getByRole('button', { name: 'Bora!' }).click();
  await expect(page.getByRole('button', { name: /^Jogar · Fase 4/ })).toBeVisible();

  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: 'Infinito' }).click();
  await expect(page.getByText(/fase 5 que eu libero o Infinito/)).toBeVisible();
  await page.getByRole('button', { name: 'Beleza!' }).click();
  expect((await state(page)).screen).toBe('home');
});
