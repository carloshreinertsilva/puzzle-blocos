import { expect, test } from '@playwright/test';
import { loadScenario, openApp, playMove, snap, startLevel, state, waitForState } from './helpers';

// Board where no 2x2 piece fits and no line can be completed by one: a loss.
const CHECKER = Array.from({ length: 8 }, (_, r) => (r % 2 ? '.b.b.b.b' : 'b.b.b.b.'));

test('fase 1: joga peças de verdade, limpa linhas, vê elogios, vence e vai para a fase 2', async ({ page }, testInfo) => {
  // A whole level is 20-60 real drags; without a GPU (CI) each takes ~3 s.
  test.setTimeout(480_000);
  await openApp(page);
  let s = await startLevel(page);
  expect(s.level).toBe(1);
  expect(s.geometry, 'geometria da tela').toBeDefined();

  // Plays greedy moves; on a (rare) loss, retries the level.
  for (let attempt = 0; attempt < 3; attempt++) {
    for (let moves = 0; moves < 80; moves++) {
      s = await state(page);
      if (s.status !== 'playing') break;
      if (!(await playMove(page))) break;
    }
    s = await state(page);
    if (s.status === 'won') break;
    await expect(page.getByRole('button', { name: 'Jogar de novo' })).toBeVisible();
    await page.getByRole('button', { name: 'Jogar de novo' }).click();
    await waitForState(page, (x) => x.status === 'playing' && x.score === 0, 'nova tentativa');
  }

  expect(s.status, 'venceu a fase 1').toBe('won');
  expect(s.score!).toBeGreaterThanOrEqual(s.goals!.targetScore);
  expect(s.praises!.length, 'apareceu pelo menos um elogio').toBeGreaterThan(0);

  const next = page.getByRole('button', { name: 'Próxima fase' });
  await expect(next).toBeVisible();
  await snap(page, testInfo, 'vitoria');
  await next.click();
  // Before level 6 there is never an ad between levels.
  await waitForState(page, (x) => x.level === 2 && x.status === 'playing' && x.score === 0, 'fase 2 aberta', 8_000);
});

test('perder: "Continuar" (vídeo) devolve o jogo uma vez; na segunda derrota só resta jogar de novo', async ({ page }, testInfo) => {
  await openApp(page);
  await startLevel(page);

  await loadScenario(page, { board: CHECKER, tray: ['o20', 'o20', 'o20'] });
  await waitForState(page, (s) => s.status === 'lost' && s.showOutcome === true, 'derrota');
  const revive = page.getByRole('button', { name: 'Continuar' });
  await expect(revive).toBeVisible();
  await snap(page, testInfo, 'derrota');

  await revive.click(); // test ad screen, then the reward
  const s = await waitForState(page, (x) => x.status === 'playing' && x.revived === true, 'reviveu', 10_000);
  expect(s.tray!.some((p) => p !== null), 'recebeu peças novas').toBe(true);
  await expect(revive).toBeHidden();

  await loadScenario(page, { board: CHECKER, tray: ['o20', 'o20', 'o20'] });
  await waitForState(page, (x) => x.status === 'lost' && x.showOutcome === true, 'segunda derrota');
  await expect(page.getByRole('button', { name: 'Jogar de novo' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Continuar' })).toHaveCount(0);
});

test('fase 3 apresenta as pedras uma única vez', async ({ page }) => {
  await openApp(page, { level: 3 });
  await page.getByRole('button', { name: /^Jogar · Fase 3/ }).click();
  await waitForState(page, (s) => s.screen === 'game', 'tela de jogo');
  expect((await state(page)).intros).toEqual(['rocks']);
  const ok = page.getByRole('button', { name: 'Entendi!' });
  await expect(ok).toBeVisible();
  await ok.click();
  await waitForState(page, (s) => s.intros!.length === 0 && s.status === 'playing', 'cartão fechado');

  // Back to the menu and in again: the card does not come back.
  await page.getByRole('button', { name: 'Pausar' }).click();
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (s) => s.screen === 'home', 'menu');
  await page.getByRole('button', { name: /^Jogar · Fase 3/ }).click();
  await waitForState(page, (s) => s.screen === 'game' && s.status === 'playing', 'fase 3 de novo');
  expect((await state(page)).intros).toEqual([]);
});

test('pausa: continuar, reiniciar e voltar ao menu', async ({ page }) => {
  await openApp(page);
  await startLevel(page);
  await playMove(page);
  expect((await state(page)).score).toBeGreaterThan(0);

  await page.getByRole('button', { name: 'Pausar' }).click();
  await waitForState(page, (s) => s.paused === true, 'pausado');
  await page.getByRole('button', { name: 'Continuar' }).click();
  await waitForState(page, (s) => s.paused === false, 'continuou');
  await expect(page.getByRole('button', { name: 'Continuar' })).toHaveCount(0);

  await page.getByRole('button', { name: 'Pausar' }).click();
  await page.getByRole('button', { name: 'Reiniciar' }).click();
  await waitForState(page, (s) => s.paused === false && s.score === 0, 'reiniciou');
  // O cartão de pausa some com uma animação; espere ele sair antes de pausar
  // de novo, senão há dois botões "Menu" na tela por um instante.
  await expect(page.getByRole('button', { name: 'Reiniciar' })).toHaveCount(0);

  await page.getByRole('button', { name: 'Pausar' }).click();
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (s) => s.screen === 'home', 'voltou ao menu');
  await expect(page.getByRole('button', { name: /^Jogar · Fase 1/ })).toBeVisible();
});

test('desafio diário abre com duas metas', async ({ page }) => {
  await openApp(page);
  await page.getByRole('button', { name: 'Desafio diário' }).click();
  const s = await waitForState(page, (x) => x.screen === 'game' && x.kind === 'daily', 'desafio aberto');
  const g = s.goals!;
  const goals = [g.targetScore > 0, g.gemsTarget > 0, g.rocksLeft > 0].filter(Boolean).length;
  expect(goals).toBe(2);
});

test('modo infinito: pontua e não tem metas', async ({ page }) => {
  await openApp(page);
  await page.getByRole('button', { name: 'Infinito' }).click();
  let s = await waitForState(page, (x) => x.screen === 'game' && x.kind === 'endless' && x.status === 'playing', 'infinito aberto');
  expect(s.goals!.targetScore).toBe(0);
  for (let i = 0; i < 4; i++) await playMove(page);
  s = await state(page);
  expect(s.score!).toBeGreaterThan(0);
});

test('estatísticas e configurações abrem a partir do menu', async ({ page }) => {
  await openApp(page, { linesCleared: 42, bestCombo: 3 });
  await page.getByRole('button', { name: 'Estatísticas' }).click();
  await expect(page.getByText('42 Linhas limpas')).toBeVisible();
  await expect(page.getByText('x3 Maior combo')).toBeVisible();
  await expect(page.getByText('Estatísticas'), 'título lido uma vez só').toHaveCount(1);
  await page.keyboard.press('Escape');
  await page.getByRole('button', { name: 'Configurações' }).click();
  await expect(page.getByRole('switch', { name: 'Sons' })).toBeVisible();
  await expect(page.getByRole('switch', { name: 'Vibração' })).toBeVisible();
});
