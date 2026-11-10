import { writeFileSync } from 'node:fs';
import { test, type Page } from '@playwright/test';
import { bestMove, loadScenario, openApp, state, waitForState, type GameState } from '../tests/helpers';
import { FPS, Gravador } from './gravador';

/**
 * Clipes curtos do jogo para Reels, TikTok e Shorts (1080x1920, 60 qps).
 * Rodar: `npm run build && npm run clipes` (ou só um: `npm run clipes -- -g combo`;
 * a 30 qps, mais rápido de gravar: `FPS=30 npm run clipes`).
 * Os vídeos ficam em e2e/clipes/saida/.
 */

test.setTimeout(20 * 60_000);
test.beforeEach(async ({ page }) => Gravador.prepararRelogio(page));

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

/** Uma jogada, arrastando a peça como um dedo, e o que vem depois. */
async function jogar(
  g: Gravador,
  page: Page,
  m: { slot: number; row: number; col: number },
  depoisMs = 650,
  arrastarMs = 520,
) {
  const path = JSON.parse(
    await page.evaluate(([s, r, c]) => (window as any).__bb.dragPath(s, r, c), [m.slot, m.row, m.col]),
  );
  if (!path) throw new Error(`Peça ${m.slot} não existe.`);
  const antes = JSON.stringify((await state(page)).board);
  await g.arrastar(path.from, path.to, arrastarMs);
  await g.ate(async () => {
    const s = await state(page);
    return s.status !== 'playing' || JSON.stringify(s.board) !== antes;
  });
  await g.esperar(depoisMs);
}

/** Jogadas automáticas (as melhores que o robô acha) por até [n] lances. */
async function jogarSozinho(g: Gravador, page: Page, n: number, depoisMs = 650, arrastarMs = 520) {
  for (let i = 0; i < n; i++) {
    const s = await state(page);
    if (s.status !== 'playing') break;
    const m = bestMove(s);
    if (!m) break;
    await jogar(g, page, m, depoisMs, arrastarMs);
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
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: 'Infinito' }).click();
  await waitForState(page, (s) => s.screen === 'game' && s.kind === 'endless', 'infinito aberto');
  await fecharApresentacoes(page);
  // Espera o letreiro "Modo infinito" sumir.
  await page.waitForTimeout(2200);
}

const naTela = (page: Page, cond: (s: GameState) => boolean) => async () => cond(await state(page));

/** Sugestão de texto para o post de cada clipe (fica ao lado do MP4). */
const POSTS: Record<string, string> = {
  combo: 'Esse combo foi LENDÁRIO 🤯🧩 Você consegue? #capiblocks #jogodeblocos #capivara #puzzle #jogosmobile',
  partida: 'Só mais uma fase… 🦫🧩 Joga grátis: capiblocks.vercel.app #capiblocks #capivara #jogodeblocos #jogosmobile',
  natal: 'O Capi já entrou no clima de Natal 🎄🦫 #capiblocks #capivara #natal #jogosmobile',
  blitz: 'Quantos pontos você faz em 60 segundos? ⏱️ Comenta aí! #capiblocks #blitz #desafio #jogodeblocos',
  torre: 'Até onde a torre do Capi chega? 🏗️🦫 #capiblocks #capivara #jogosmobile #satisfatorio',
};

async function gravar(page: Page, nome: string, cena: (g: Gravador) => Promise<void>) {
  const g = new Gravador(page, nome);
  const t0 = Date.now();
  await g.comecar();
  await cena(g);
  const mp4 = await g.terminar();
  if (POSTS[nome]) writeFileSync(mp4.replace(/\.mp4$/, '.txt'), `${POSTS[nome]}\n`);
  console.log(`Clipe (${FPS} qps, ${Math.round((Date.now() - t0) / 1000)} s para gravar): ${mp4}`);
}

/** Volta ao menu pela pausa (fora do vídeo). */
async function voltarAoMenu(page: Page) {
  await page.getByRole('button', { name: 'Pausar' }).click();
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (s) => s.screen === 'home', 'menu');
  await page.waitForTimeout(1500);
}

test('combo', async ({ page }) => {
  await openApp(page, { level: 30 });
  await abrirInfinito(page);
  await loadScenario(page, COMBO);
  await page.waitForTimeout(400);
  await gravar(page, 'combo', async (g) => {
    g.legenda('Espera o <b>combo</b> no final', 2400);
    await g.esperar(600);
    for (const m of JOGADAS_COMBO) await jogar(g, page, m, 900);
    await g.esperar(1000);
    await jogarSozinho(g, page, 4);
  });
});

test('partida', async ({ page }) => {
  await openApp(page, { level: 14 });
  // Abre a fase uma vez fora do vídeo, para as novidades da fase não
  // aparecerem na gravação, e volta ao menu.
  await page.getByRole('button', { name: /^Jogar · Fase/ }).click();
  await waitForState(page, (s) => s.screen === 'game', 'fase aberta');
  await fecharApresentacoes(page);
  await page.getByRole('button', { name: 'Pausar' }).click();
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (s) => s.screen === 'home', 'menu');
  await page.waitForTimeout(1500);
  await gravar(page, 'partida', async (g) => {
    // A legenda some antes do letreiro da fase aparecer.
    g.legenda('O jogo de blocos <b>da capivara</b>', 2000);
    await g.esperar(2300);
    await g.tocar(page.getByRole('button', { name: /^Jogar · Fase/ }));
    await g.ate(naTela(page, (s) => s.screen === 'game' && s.status === 'playing' && s.intros!.length === 0));
    await g.esperar(1500);
    await jogarSozinho(g, page, 14);
    await g.esperar(1500);
  });
});

// O Capi de Natal no menu (na partida ele usa o capacete de obra) e depois
// um combo no Infinito. No navegador, os textos ficam guardados em JSON.
const NATAL = {
  level: 30,
  equippedHat: JSON.stringify('gorro_natal'),
  equipped_pescoco: JSON.stringify('cachecol_natal'),
  unlockedHats: JSON.stringify(['helmet', 'gorro_natal', 'cachecol_natal']),
};

test('natal', async ({ page }) => {
  await openApp(page, NATAL);
  // Abre o Infinito uma vez fora do vídeo, para o letreiro e as novidades
  // não aparecerem na gravação, e volta ao menu.
  await abrirInfinito(page);
  await page.getByRole('button', { name: 'Pausar' }).click();
  await page.getByRole('button', { name: 'Menu' }).click();
  await waitForState(page, (s) => s.screen === 'home', 'menu');
  await page.waitForTimeout(1500);
  await gravar(page, 'natal', async (g) => {
    g.legenda('O Capi entrou no <b>clima de Natal</b>', 2600);
    await g.esperar(2800);
    await g.tocar(page.getByRole('button', { name: 'Modos' }), 600);
    await g.tocar(page.getByRole('button', { name: 'Infinito' }));
    await g.ate(naTela(page, (s) => s.screen === 'game' && s.kind === 'endless' && s.status === 'playing'));
    await loadScenario(page, COMBO);
    await g.esperar(1800);
    for (const m of JOGADAS_COMBO) await jogar(g, page, m, 900);
  });
});

test('blitz', async ({ page }) => {
  await openApp(page, { level: 30, seen_opened_blitz: true });
  // Abre o Blitz uma vez fora do vídeo, para as novidades não aparecerem.
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: /^Blitz 60s/ }).click();
  await waitForState(page, (s) => s.mode === 'blitz', 'blitz aberto');
  await fecharApresentacoes(page);
  await voltarAoMenu(page);
  await gravar(page, 'blitz', async (g) => {
    g.legenda('Desafio: <b>60 segundos</b>', 2600);
    await g.esperar(700);
    await g.tocar(page.getByRole('button', { name: 'Modos' }), 500);
    await g.tocar(page.getByRole('button', { name: /^Blitz 60s/ }));
    await g.ate(naTela(page, (s) => s.mode === 'blitz' && s.status === 'playing' && s.intros!.length === 0));
    await g.esperar(600);
    // Ritmo de Blitz: peças rápidas, quase sem pausa.
    await jogarSozinho(g, page, 22, 220, 360);
    await g.esperar(800);
  });
});

test('torre', async ({ page }) => {
  await openApp(page, { level: 30, seen_opened_tower: true, towerBestHeight: 12 });
  await gravar(page, 'torre', async (g) => {
    g.legenda('Empilha <b>sem errar</b>', 2400);
    await g.esperar(700);
    await g.tocar(page.getByRole('button', { name: 'Modos' }), 500);
    await g.tocar(page.getByRole('button', { name: /^Torre do Capi/ }));
    await g.ate(naTela(page, (s) => s.screen === 'tower' && !!s.tower?.playing));
    await g.esperar(900);
    // O botão de pôr o bloco recebe o toque do dedo; o andar cai pela ponte
    // (perfeito ou quase), que acerta o tempo sem depender da sorte.
    const botao = await page.getByRole('button', { name: 'Colocar Bloco' }).boundingBox();
    const x = botao!.x + botao!.width / 2;
    const y = botao!.y + botao!.height / 2;
    const andares = [true, true, true, false, true, true, true, true, false, true, true, true];
    for (const perfeito of andares) {
      await g.apertar(x, y, async () => {
        await page.evaluate((p) => (window as any).__bb.placeTower(p), perfeito);
        await g.esperar(120);
      });
      await g.esperar(650);
    }
    // O último erra feio: a torre acaba e aparece o resultado.
    await g.apertar(x, y, async () => {
      await page.evaluate(() => (window as any).__bb.missTower());
      await g.esperar(120);
    });
    await g.ate(naTela(page, (s) => s.tower?.gameOver === true));
    await g.esperar(2200);
  });
});
