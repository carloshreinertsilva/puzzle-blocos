import { expect, test } from '@playwright/test';
import { openApp, playMove, startLevel, state, waitForState } from './helpers';

// Relato de jogador: uma peça ficou parada no meio do tabuleiro, "no dedo",
// e o jogo não aceitava mais nenhum arrasto. Acontece quando o celular não
// avisa que o dedo saiu da tela. O próximo toque devolve a peça à bandeja.
test('peça presa no arrasto volta à bandeja no próximo toque e o jogo segue', async ({ page }) => {
  await openApp(page);
  await startLevel(page);
  await waitForState(page, (x) => (x.tray ?? []).every((p) => p != null), 'bandeja cheia');

  expect(await page.evaluate(() => (window as any).__bb.prenderArrasto(0))).toBe(true);
  const antes = await state(page);
  expect(antes.arrastando).toBe(0);

  // Um toque qualquer no tabuleiro (célula da linha 4, coluna 0).
  const b = antes.geometry!.board;
  await page.mouse.click(b.left + b.cell * 0.5, b.top + b.cell * 4.5);
  const s = await waitForState(page, (x) => x.arrastando == null, 'peça solta');
  expect(s.tray, 'a peça voltou à bandeja').toEqual(antes.tray);
  expect(s.board, 'nada foi colocado').toEqual(antes.board);

  // E dá para jogar de novo.
  expect(await playMove(page)).toBe(true);
});
