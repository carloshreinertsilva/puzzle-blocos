import { expect, Page, test } from '@playwright/test';
import { openApp, snap, state, waitForState } from './helpers';

/** Drags every piece to its spot with the real mouse. The tray reflows
 * after each drop, so it asks for a fresh path each time. */
async function buildAll(page: Page, onPlaced?: (i: number) => Promise<void>) {
  const total = (await state(page)).obra!.pieces;
  for (let i = 0; i < total; i++) {
    const path = JSON.parse(await page.evaluate((p) => (window as any).__bb.obraDrag(p), i));
    expect(path, `peça ${i} na bandeja`).not.toBeNull();
    await page.mouse.move(path.from.x, path.from.y);
    await page.mouse.down();
    await page.mouse.move(path.from.x, path.from.y - 20, { steps: 3 });
    await page.mouse.move(path.to.x, path.to.y, { steps: 10 });
    await page.waitForTimeout(60);
    await page.mouse.up();
    await page.waitForTimeout(150);
    await waitForState(page, (x) => x.obra!.placed === i + 1, `peça ${i} encaixada`);
    await onPlaced?.(i);
  }
}

test('obras: arrastar as peças monta o desenho e dá estrelas', async ({ page }, testInfo) => {
  await openApp(page, { level: 6, stars: 0 });
  await page.getByRole('button', { name: /^Obras/ }).click();
  await waitForState(page, (x) => x.screen === 'obra', 'obra aberta');
  await page.waitForTimeout(400);
  await snap(page, testInfo, `obra-inicio-${testInfo.project.name}`);

  await buildAll(page, async (i) => {
    if (i === 1) await snap(page, testInfo, `obra-meio-${testInfo.project.name}`);
  });
  const done = await waitForState(page, (x) => x.obra!.solved, 'obra pronta');
  expect(done.obra!.stars).toBe(3);
  await expect(page.getByText('Obra 1 concluída!')).toBeVisible();
  await waitForState(page, (x) => x.stars === 3, '+3 estrelas');
  await snap(page, testInfo, `obra-fim-${testInfo.project.name}`);

  // On to obra 2.
  await page.getByRole('button', { name: 'Próxima obra' }).click();
  await expect(page.getByText('Obra 2', { exact: true })).toBeVisible();
});

test('obras: dica mostra a peça e custa uma estrela', async ({ page }) => {
  await openApp(page, { level: 6 });
  await page.getByRole('button', { name: /^Obras/ }).click();
  await waitForState(page, (x) => x.screen === 'obra', 'obra aberta');
  await page.getByRole('button', { name: 'Dica' }).click();
  await expect(page.getByText('Essa peça vai aqui, ó!')).toBeVisible();
  await page.evaluate(() => (window as any).__bb.win());
  const s = await waitForState(page, (x) => x.obra!.solved, 'obra pronta');
  expect(s.obra!.stars).toBe(2);
});

// The finger sits below the dragged piece, so on the drawing's bottom row
// it is already off the board: the drop must still count (bug from a
// player, on the lamp post).
test('obras: peças na última linha do desenho encaixam', async ({ page }) => {
  await openApp(page, { level: 6, obraLevel: 6 });
  await page.getByRole('button', { name: /^Obras/ }).click();
  await waitForState(page, (x) => x.screen === 'obra', 'obra aberta');
  await page.waitForTimeout(400);
  await buildAll(page);
  await waitForState(page, (x) => x.obra!.solved, 'obra pronta');
});
