import { test, type Page } from '@playwright/test';
import { bestMove, loadScenario, openApp, state, waitForState } from '../tests/helpers';
import { Gravador } from './gravador';

/**
 * Clipes curtos do jogo para Reels, TikTok e Shorts (1080x1920).
 * Rodar: `npm run build && npm run clipes` (ou só um: `npm run clipes -- -g combo`).
 * Os vídeos ficam em e2e/clipes/saida/.
 */

// Um tabuleiro preparado para um combo grande: as duas primeiras peças
// completam o desenho e o quadradão 3x3 limpa 3 linhas e 3 colunas de uma vez.
const COMBO = {
  board: [
    '.bb.b..b',
    '.bbb..b.',
    '.bb..g..',
    'bgb.b..b',
    'bbbb.b..',
    '...bbb..',
    '...bgb..',
    '...bbgbb',
  ],
  tray: ['i31', 'o20', 'o30'],
};
const JOGADAS_COMBO = [
  { slot: 0, row: 0, col: 0 },
  { slot: 1, row: 5, col: 6 },
  { slot: 2, row: 5, col: 0 },
];

/** Arrasta a peça devagar, como uma pessoa (fica bonito no vídeo). */
async function arrastar(page: Page, slot: number, row: number, col: number) {
  const path = JSON.parse(
    await page.evaluate(([s, r, c]) => (window as any).__bb.dragPath(s, r, c), [slot, row, col]),
  );
  if (!path) throw new Error(`Peça ${slot} não existe.`);
  await page.mouse.move(path.from.x, path.from.y);
  await page.mouse.down();
  await page.waitForTimeout(120);
  await page.mouse.move(path.to.x, path.to.y, { steps: 28 });
  await page.waitForTimeout(160);
  await page.mouse.up();
}

/** Uma jogada e espera o tabuleiro mudar (e as animações). */
async function jogar(page: Page, m: { slot: number; row: number; col: number }, pausa = 650) {
  const antes = JSON.stringify((await state(page)).board);
  await arrastar(page, m.slot, m.row, m.col);
  await waitForState(page, (s) => s.status !== 'playing' || JSON.stringify(s.board) !== antes, 'peça colocada', 10_000);
  await page.waitForTimeout(pausa);
}

/** Jogadas automáticas (as melhores que o robô acha) por até [n] lances. */
async function jogarSozinho(page: Page, n: number) {
  for (let i = 0; i < n; i++) {
    const s = await state(page);
    if (s.status !== 'playing') break;
    const m = bestMove(s);
    if (!m) break;
    await jogar(page, m);
  }
}

/** Fecha os cartões de novidade ("Entendi!") até a partida poder ser jogada. */
async function fecharApresentacoes(page: Page) {
  for (let i = 0; i < 6; i++) {
    const s = await state(page);
    if (s.screen === 'game' && s.intros!.length === 0 && s.status === 'playing') break;
    const ok = page.getByRole('button', { name: 'Entendi!' });
    if (await ok.isVisible()) await ok.click();
    await page.waitForTimeout(500);
  }
  await waitForState(page, (s) => s.intros!.length === 0 && s.status === 'playing', 'partida pronta');
}

/** O modo Infinito (sem metas, nada termina a partida no meio do combo). */
async function abrirInfinito(page: Page) {
  await openApp(page, { level: 30 });
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: 'Infinito' }).click();
  await waitForState(page, (s) => s.screen === 'game' && s.kind === 'endless', 'infinito aberto');
  await fecharApresentacoes(page);
  // Espera o letreiro "Modo infinito" sumir.
  await page.waitForTimeout(2200);
}

async function gravar(page: Page, nome: string, cena: () => Promise<void>) {
  const g = new Gravador(page, nome);
  await g.comecar();
  await cena();
  console.log(`Clipe: ${await g.terminar()}`);
}

test('combo', async ({ page }) => {
  await abrirInfinito(page);
  await loadScenario(page, COMBO);
  await page.waitForTimeout(400);
  await gravar(page, 'combo', async () => {
    await page.waitForTimeout(700);
    for (const m of JOGADAS_COMBO) await jogar(page, m, 900);
    await page.waitForTimeout(1200);
    await jogarSozinho(page, 4);
  });
});

test('partida', async ({ page }) => {
  await openApp(page, { level: 14 });
  await page.waitForTimeout(1500);
  await gravar(page, 'partida', async () => {
    await page.waitForTimeout(800);
    await page.getByRole('button', { name: /^Jogar · Fase/ }).click();
    await waitForState(page, (s) => s.screen === 'game', 'fase aberta');
    await fecharApresentacoes(page);
    await page.waitForTimeout(1200);
    await jogarSozinho(page, 14);
    await page.waitForTimeout(1500);
  });
});

// O Capi de Natal no menu (na partida ele usa o capacete de obra) e depois
// um combo no Infinito.
// No navegador, os textos ficam guardados em JSON (com aspas).
const NATAL = {
  level: 30,
  equippedHat: JSON.stringify('gorro_natal'),
  equipped_pescoco: JSON.stringify('cachecol_natal'),
  unlockedHats: JSON.stringify(['helmet', 'gorro_natal', 'cachecol_natal']),
};

test('natal', async ({ page }) => {
  await openApp(page, NATAL);
  await page.waitForTimeout(1500);
  await gravar(page, 'natal', async () => {
    await page.waitForTimeout(2800);
    await page.getByRole('button', { name: 'Modos' }).click();
    await page.waitForTimeout(700);
    await page.getByRole('button', { name: 'Infinito' }).click();
    await waitForState(page, (s) => s.screen === 'game' && s.kind === 'endless', 'infinito aberto');
    await fecharApresentacoes(page);
    await loadScenario(page, COMBO);
    await page.waitForTimeout(1600);
    for (const m of JOGADAS_COMBO) await jogar(page, m, 900);
    await page.waitForTimeout(1500);
  });
});
