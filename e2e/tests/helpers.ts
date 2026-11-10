import { expect, type Page, type TestInfo } from '@playwright/test';

/** What the game reports through `window.__bb.state()` (test builds only). */
export type Piece = { id: string; rows: number; cols: number; cells: [number, number][] };
export type Box = { x: number; y: number; w: number; h: number };
export type GameState = {
  screen: 'home' | 'game' | 'village' | 'obra' | 'tower';
  stars?: number;
  villageItems?: string[];
  obra?: {
    id: string;
    pieces: number;
    placed: number;
    solved: boolean;
    stars: number;
    undos: number;
    hints: number;
    hint: number | null;
  };
  mode?: 'levels' | 'endless' | 'daily' | 'blitz' | 'duel';
  level?: number;
  kind?: 'level' | 'endless' | 'daily' | 'blitz' | 'duel';
  blitzSecondsLeft?: number;
  duelSeed?: number;
  duelTargetScore?: number | null;
  duelRivalName?: string | null;
  duelWon?: boolean;
  status?: 'playing' | 'won' | 'lost';
  showOutcome?: boolean;
  paused?: boolean;
  intros?: string[];
  score?: number;
  revived?: boolean;
  liveStarBits?: number;
  goals?: {
    targetScore: number;
    gemsTarget: number;
    gems: number;
    rocksLeft: number;
    pupsLeft: number;
    pupsSaved: number;
  };
  board?: string[];
  tray?: (Piece | null)[];
  praises?: string[];
  tutorialStep?: number;
  capi?: string;
  hint?: [number, number, number];
  hintOffer?: boolean;
  geometry?: {
    board: { left: number; top: number; size: number; cell: number };
    slots: Box[];
        viewport: { w: number; h: number; top: number };
  };
  tools?: {
    hammer: number;
    rotate: number;
    reroll: number;
    shovel: number;
  };
  activeTool?: string;
  tower?: {
    height: number;
    placedFloors: number;
    bestHeight: number;
    combo: number;
    gameOver: boolean;
    playing: boolean;
    starsGained: number;
    floors: number;
    zone: string;
    canContinue: boolean;
    offset: number;
    room: number;
  };
  equippedHat?: string;
  passe?: { nivel: number; premium: boolean };
  unlockedHats?: string[];
  dailyChestAvailable?: boolean;
  dailyChestClaimed?: boolean;
  missions?: {
    index: number;
    type: string;
    target: number;
    progress: number;
    claimed: boolean;
    completed: boolean;
  }[];
};

type Saved = Record<string, string | number | boolean>;

/** A returning player: tutorial done, menu unlocked, Capi's news seen. */
const VETERAN: Saved = {
  seen_tutorial: true,
  seen_menu: true,
  seen_news_welcome: true,
  seen_news_village: true,
  seen_news_endless: true,
  seen_news_obras: true,
  seen_news_daily: true,
  seen_news_blitz: true,
  seen_news_duel: true,
  seen_news_tower: true,
};

/** Opens the game on the menu, with optional saved progress
 * (shared_preferences keys) on top of a returning player's. */
export async function openApp(page: Page, saved: Saved = {}) {
  // The daily gift already opened by itself today (a test can still open it).
  const d = new Date();
  const today = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
  await openFresh(page, { ...VETERAN, giftShown: today, ...saved });
  // With the daily gift opening by itself, the menu waits behind it.
  const first = saved.giftShown === 0 ? /^Pegar o presente do dia/ : /^Jogar · Fase/;
  await expect(page.getByRole('button', { name: first })).toBeVisible();
}

/** Opens the game with only [saved] stored: a new player by default. */
export async function openFresh(page: Page, saved: Saved = {}) {
  if (Object.keys(saved).length > 0) {
    // O progresso é gravado numa página estática da mesma origem, sem o jogo
    // rodando, e só depois o jogo abre. Antes ele era gravado com o jogo já
    // carregando (goto('/') + reload): às vezes esse primeiro jogo lia o
    // progresso recém-gravado e, antes do reload, já abria o presente do dia
    // e marcava giftShown com a data de hoje; o jogo recarregado então não
    // abria mais o presente sozinho.
    await page.goto('/favicon.png');
    await page.evaluate((s) => {
      for (const [k, v] of Object.entries(s)) localStorage.setItem(`flutter.${k}`, String(v));
    }, saved);
  }
  await page.goto('/');
  await page.waitForFunction(() => (window as any).__bb !== undefined, null, { timeout: 30_000 });
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
  await expect
    .poll(async () => check(await state(page)), { message, timeout, intervals: [50, 100, 200, 400] })
    .toBe(true);
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
  await page.mouse.move(path.to.x, path.to.y, { steps: 8 });
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
