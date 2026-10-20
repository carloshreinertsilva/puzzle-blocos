import { expect, type Page, type TestInfo } from '@playwright/test';

/** What the game reports through `window.__bb.state()` (test builds only). */
export type Piece = { id: string; rows: number; cols: number; cells: [number, number][] };
export type Box = { x: number; y: number; w: number; h: number };
export type GameState = {
  screen: 'home' | 'game';
  mode?: 'levels' | 'endless' | 'daily';
  level?: number;
  kind?: 'level' | 'endless' | 'daily';
  status?: 'playing' | 'won' | 'lost';
  showOutcome?: boolean;
  paused?: boolean;
  intros?: string[];
  score?: number;
  revived?: boolean;
  goals?: { targetScore: number; gemsTarget: number; gems: number; rocksLeft: number };
  board?: string[];
  tray?: (Piece | null)[];
  praises?: string[];
  geometry?: {
    board: { left: number; top: number; size: number; cell: number };
    slots: Box[];
    viewport: { w: number; h: number; top: number };
  };
};

/** Opens the game with optional saved progress (shared_preferences keys). */
export async function openApp(page: Page, saved: Record<string, string | number | boolean> = {}) {
  await page.goto('/');
  if (Object.keys(saved).length > 0) {
    await page.evaluate((s) => {
      for (const [k, v] of Object.entries(s)) localStorage.setItem(`flutter.${k}`, String(v));
    }, saved);
    await page.reload();
  }
  await page.waitForFunction(() => (window as any).__bb !== undefined, null, { timeout: 30_000 });
  await expect(page.getByRole('button', { name: /^Jogar · Fase/ })).toBeVisible();
}

export async function state(page: Page): Promise<GameState> {
  return JSON.parse(await page.evaluate(() => (window as any).__bb.state()));
}

export async function waitForState(
  page: Page,
  check: (s: GameState) => boolean,
  message: string,
  timeout = 15_000,
) {
  await expect.poll(async () => check(await state(page)), { message, timeout }).toBe(true);
  return state(page);
}

/** Starts a level from the menu and waits until it can be played. */
export async function startLevel(page: Page) {
  await page.getByRole('button', { name: /^Jogar · Fase/ }).click();
  return waitForState(page, (s) => s.screen === 'game' && s.status === 'playing', 'fase aberta');
}

/** Sets up a board/tray scenario: board as 8 strings of . b g r R; tray as shape ids. */
export async function loadScenario(page: Page, scenario: { board?: string[]; tray?: (string | null)[] }) {
  const ok = await page.evaluate((json) => (window as any).__bb.load(json), JSON.stringify(scenario));
  expect(ok, 'cenário carregado').toBe(true);
}

/** Drags tray piece [slot] onto (row, col) with real mouse events. */
export async function dragPiece(page: Page, slot: number, row: number, col: number) {
  const path = JSON.parse(
    await page.evaluate(([s, r, c]) => (window as any).__bb.dragPath(s, r, c), [slot, row, col]),
  );
  expect(path, `peça ${slot} existe`).not.toBeNull();
  await page.mouse.move(path.from.x, path.from.y);
  await page.mouse.down();
  await page.mouse.move(path.to.x, path.to.y, { steps: 12 });
  await page.waitForTimeout(80);
  await page.mouse.up();
}

const SIZE = 8;

function fits(board: string[], p: Piece, r: number, c: number) {
  if (r < 0 || c < 0 || r + p.rows > SIZE || c + p.cols > SIZE) return false;
  return p.cells.every(([dr, dc]) => board[r + dr][c + dc] === '.');
}

function linesAfter(board: string[], p: Piece, r: number, c: number) {
  const grid = board.map((row) => row.split(''));
  for (const [dr, dc] of p.cells) grid[r + dr][c + dc] = 'b';
  let lines = 0;
  for (let i = 0; i < SIZE; i++) {
    if (grid[i].every((x) => x !== '.')) lines++;
    if (grid.every((row) => row[i] !== '.')) lines++;
  }
  return lines;
}

/** A simple greedy move: most lines cleared, then the snuggest fit. */
export function bestMove(s: GameState): { slot: number; row: number; col: number } | null {
  const board = s.board!;
  let best: { slot: number; row: number; col: number } | null = null;
  let bestScore = -Infinity;
  s.tray!.forEach((p, slot) => {
    if (!p) return;
    for (let r = 0; r < SIZE; r++) {
      for (let c = 0; c < SIZE; c++) {
        if (!fits(board, p, r, c)) continue;
        let touching = 0;
        for (const [dr, dc] of p.cells) {
          for (const [nr, nc] of [[r + dr - 1, c + dc], [r + dr + 1, c + dc], [r + dr, c + dc - 1], [r + dr, c + dc + 1]]) {
            if (nr < 0 || nc < 0 || nr >= SIZE || nc >= SIZE || board[nr][nc] !== '.') touching++;
          }
        }
        const score = linesAfter(board, p, r, c) * 1000 + touching * 10 + p.cells.length;
        if (score > bestScore) {
          bestScore = score;
          best = { slot, row: r, col: c };
        }
      }
    }
  });
  return best;
}

/** Plays one greedy move and waits for the board to change. */
export async function playMove(page: Page) {
  const before = await state(page);
  const move = bestMove(before);
  if (!move) return false;
  await dragPiece(page, move.slot, move.row, move.col);
  await waitForState(
    page,
    (s) => s.status !== 'playing' || JSON.stringify(s.board) !== JSON.stringify(before.board),
    `peça ${move.slot} colocada em (${move.row}, ${move.col})`,
    8_000,
  );
  return true;
}

/** Attaches a full-page screenshot to the report. */
export async function snap(page: Page, testInfo: TestInfo, name: string) {
  await testInfo.attach(name, { body: await page.screenshot(), contentType: 'image/png' });
}

/** True when [a] sits fully inside the viewport. */
export function inside(a: { x: number; y: number; width: number; height: number }, vw: number, vh: number) {
  return a.x >= -0.5 && a.y >= -0.5 && a.x + a.width <= vw + 0.5 && a.y + a.height <= vh + 0.5;
}

export function overlap(
  a: { x: number; y: number; width: number; height: number },
  b: { x: number; y: number; width: number; height: number },
) {
  return a.x < b.x + b.width - 0.5 && b.x < a.x + a.width - 0.5 && a.y < b.y + b.height - 0.5 && b.y < a.y + a.height - 0.5;
}
