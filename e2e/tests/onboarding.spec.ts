import { expect, test, type Page, type TestInfo } from '@playwright/test';
import { dragPiece, inside, openFresh, snap, state, waitForState } from './helpers';

/** A capture in the report and as a file (test-results/…/<name>.png). */
async function foto(page: Page, testInfo: TestInfo, name: string) {
  await page.screenshot({ path: testInfo.outputPath(`${name}.png`) });
  await snap(page, testInfo, name);
}

test('primeira vez: tutorial com o Capi e direto para o menu, com o guia', async ({ page }, testInfo) => {
  // The whole first minute: tutorial, guide and the first level.
  test.setTimeout(240_000);
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

  // Straight to the menu (no levels in between), with Capi's guide.
  await waitForState(page, (x) => x.screen === 'home', 'menu');
  const pular = page.getByRole('button', { name: 'Pular', exact: true });
  const continuar = page.getByRole('button', { name: 'Continuar' });
  const vw = page.viewportSize()!.width;
  const vh = page.viewportSize()!.height;

  // a) The village.
  await expect(page.getByText(/constrói a minha vila/)).toBeVisible();
  await expect(pular).toBeVisible();
  expect(inside((await pular.boundingBox())!, vw, vh)).toBe(true);
  expect(inside((await continuar.boundingBox())!, vw, vh)).toBe(true);
  // While the guide is up, the menu underneath can't be reached.
  await expect(page.getByRole('button', { name: /^Jogar · Fase/ })).toHaveCount(0);
  await page.waitForTimeout(400);
  await foto(page, testInfo, `guia-a-vila-${testInfo.project.name}`);

  // b) The wardrobe, with the gift on Capi.
  await continuar.click();
  await expect(page.getByText(/Um presente pra você: Óculos de Sol/)).toBeVisible();
  expect((await state(page)).unlockedHats).toContain('oculos_sol');
  expect(inside((await continuar.boundingBox())!, vw, vh)).toBe(true);
  await page.waitForTimeout(400);
  await foto(page, testInfo, `guia-b-guarda-roupa-${testInfo.project.name}`);

  // c) The levels.
  await continuar.click();
  await expect(page.getByText('Vamos para a fase 1?')).toBeVisible();
  // The last step's button says "Bora!"; "Pular" sits inside the balloon.
  const bora = page.getByRole('button', { name: 'Bora!' });
  expect(inside((await bora.boundingBox())!, vw, vh)).toBe(true);
  expect(inside((await pular.boundingBox())!, vw, vh)).toBe(true);
  await page.waitForTimeout(400);
  await foto(page, testInfo, `guia-c-jogar-${testInfo.project.name}`);

  // Then the menu is free.
  await bora.click();
  await expect(pular).toHaveCount(0);
  await startLevel1(page);
});

async function startLevel1(page: Page) {
  await page.getByRole('button', { name: /^Jogar · Fase 1/ }).click();
  const s = await waitForState(page, (x) => x.screen === 'game' && x.mode === 'levels', 'fase 1');
  expect(s.level).toBe(1);
}

test('"Pular" encerra o tutorial e o guia; o guia não volta', async ({ page }) => {
  await openFresh(page);
  await page.getByRole('button', { name: 'Pular tutorial' }).click();
  await page.getByRole('button', { name: 'Bora!' }).click();
  await waitForState(page, (x) => x.screen === 'home', 'menu');
  await expect(page.getByText(/constrói a minha vila/)).toBeVisible();
  await page.getByRole('button', { name: 'Pular', exact: true }).click();
  await expect(page.getByRole('button', { name: /^Jogar · Fase 1/ })).toBeVisible();
  // The gift came anyway.
  expect((await state(page)).unlockedHats).toContain('oculos_sol');

  // Opening the game again: the menu (with the daily gift, which waited for
  // the guide), without the guide.
  await page.reload();
  await page.waitForFunction(() => (window as any).__bb !== undefined, null, { timeout: 30_000 });
  await expect(
    page
      .getByRole('button', { name: /^Pegar o presente do dia/ })
      .or(page.getByRole('button', { name: /^Jogar · Fase 1/ })),
  ).toBeVisible();
  await expect(page.getByText(/constrói a minha vila/)).toHaveCount(0);
});

test('quem estava no meio das fases de introdução vai para o menu', async ({ page }) => {
  // A player from before, between levels 1 and 3, never saw the menu.
  await openFresh(page, { seen_tutorial: true, level: 3 });
  await waitForState(page, (x) => x.screen === 'home', 'menu');
  await expect(page.getByText(/constrói a minha vila/)).toBeVisible();
  await page.getByRole('button', { name: 'Continuar' }).click();
  await page.getByRole('button', { name: 'Continuar' }).click();
  await expect(page.getByText('Vamos para a fase 3?')).toBeVisible();
  await page.getByRole('button', { name: 'Bora!' }).click();
  await expect(page.getByRole('button', { name: /^Jogar · Fase 3/ })).toBeVisible();
});

test('modo liberado: o Capi aponta o cartão; modos travados avisam a fase', async ({ page }, testInfo) => {
  // The daily gift already opened by itself today.
  const d = new Date();
  const giftShown = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
  await openFresh(page, { seen_tutorial: true, seen_menu: true, seen_guia_menu: true, giftShown, level: 4 });
  await expect(page.getByRole('button', { name: /^Jogar · Fase 4/ })).toBeVisible();
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: 'Infinito' }).click();
  await expect(page.getByText(/fase 5 que eu libero o Infinito/)).toBeVisible();
  await page.getByRole('button', { name: 'Beleza!' }).click();
  expect((await state(page)).screen).toBe('home');

  await openFresh(page, { seen_tutorial: true, seen_menu: true, seen_guia_menu: true, giftShown, level: 5 });
  await expect(page.getByText(/Liberei o modo Infinito/)).toBeVisible();
  await page.waitForTimeout(400);
  await snap(page, testInfo, `menu-modo-liberado-${testInfo.project.name}`);
  await page.getByRole('button', { name: 'Bora!' }).click();
  await expect(page.getByRole('button', { name: /^Jogar · Fase 5/ })).toBeVisible();
});
