import { expect, test } from '@playwright/test';
import { inside, openApp, overlap, snap, startLevel, state, waitForState } from './helpers';

// Runs on every screen size in playwright.config.ts.

test('menu: todos os botões cabem na tela e não se sobrepõem', async ({ page }, testInfo) => {
  await openApp(page, { level: 7, bestScore: 12345 });
  const vp = page.viewportSize()!;
  const buttons = await page.getByRole('button').all();
  const boxes = [];
  for (const b of buttons) {
    const box = await b.boundingBox();
    const name = (await b.textContent())?.trim() ?? '?';
    expect(box, `botão "${name}" tem tamanho`).not.toBeNull();
    expect(inside(box!, vp.width, vp.height), `botão "${name}" dentro da tela`).toBe(true);
    expect(Math.min(box!.width, box!.height), `botão "${name}" com área de toque >= 44px`).toBeGreaterThanOrEqual(44);
    boxes.push({ name, box: box! });
  }
  for (let i = 0; i < boxes.length; i++) {
    for (let j = i + 1; j < boxes.length; j++) {
      expect(overlap(boxes[i].box, boxes[j].box), `"${boxes[i].name}" x "${boxes[j].name}"`).toBe(false);
    }
  }
  await snap(page, testInfo, `menu-${testInfo.project.name}`);
});

test('jogo: tabuleiro e peças inteiros na tela, abaixo do placar', async ({ page }, testInfo) => {
  await openApp(page);
  await startLevel(page);
  await page.waitForTimeout(600); // pieces slide in
  const s = await state(page);
  const g = s.geometry!;
  const vp = page.viewportSize()!;
  const board = { x: g.board.left, y: g.board.top, width: g.board.size, height: g.board.size };

  expect(inside(board, vp.width, vp.height), 'tabuleiro dentro da tela').toBe(true);
  expect(g.board.cell, 'casas com pelo menos 32px').toBeGreaterThanOrEqual(32);
  const pause = (await page.getByRole('button', { name: 'Pausar' }).boundingBox())!;
  expect(pause.y + pause.height, 'placar acima do tabuleiro').toBeLessThanOrEqual(board.y);
  for (const [i, slot] of g.slots.entries()) {
    const box = { x: slot.x, y: slot.y, width: slot.w, height: slot.h };
    expect(inside(box, vp.width, vp.height), `bandeja ${i} dentro da tela`).toBe(true);
    expect(overlap(box, board), `bandeja ${i} não cobre o tabuleiro`).toBe(false);
  }
  await snap(page, testInfo, `jogo-${testInfo.project.name}`);
});

test('cartões (novidade, derrota) cabem na tela', async ({ page }, testInfo) => {
  await openApp(page, { level: 3 });
  await page.getByRole('button', { name: /^Jogar · Fase 3/ }).click();
  const vp = page.viewportSize()!;
  const ok = page.getByRole('button', { name: 'Entendi!' });
  await expect(ok).toBeVisible();
  expect(inside((await ok.boundingBox())!, vp.width, vp.height), 'botão do cartão dentro da tela').toBe(true);
  await snap(page, testInfo, `novidade-${testInfo.project.name}`);
  await ok.click();
  await waitForState(page, (s) => s.status === 'playing', 'jogando');
});
