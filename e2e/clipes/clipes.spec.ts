import { writeFileSync } from 'node:fs';
import { test, type Page } from '@playwright/test';
import { bestMove, dragPiece, loadScenario, openApp, state, waitForState, type GameState } from '../tests/helpers';
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
  partida: 'Só mais uma fase… 🦫🧩 Baixe grátis: procure CapiBlocks na Play Store #capiblocks #capivara #jogodeblocos #jogosmobile',
  natal: 'O Capi já entrou no clima de Natal 🎄🦫 #capiblocks #capivara #natal #jogosmobile',
  blitz: 'Quantos pontos você faz em 60 segundos? ⏱️ Comenta aí! #capiblocks #blitz #desafio #jogodeblocos',
  torre: 'Até onde a torre do Capi chega? 🏗️🦫 #capiblocks #capivara #jogosmobile #satisfatorio',
  'blitz-final': 'Últimos segundos do Blitz… e o combo salvou! 😱⏱️🧩 #capiblocks #blitz #combo #jogodeblocos #capivara',
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

// O fim de um Blitz: o relógio é adiantado fora do vídeo até sobrarem uns
// 14 segundos; no vídeo, jogadas apressadas até quase zerar e, no fim, o
// tabuleiro do combo grande (os combos devolvem segundos ao relógio).
test('blitz-final', async ({ page }) => {
  await openApp(page, { level: 30, seen_opened_blitz: true });
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: /^Blitz 60s/ }).click();
  await waitForState(page, (s) => s.mode === 'blitz', 'blitz aberto');
  await fecharApresentacoes(page);
  // Joga um pouco fora do vídeo, para o tabuleiro não começar vazio, e
  // adianta o relógio até sobrarem uns 7 segundos.
  for (let i = 0; i < 6; i++) {
    const m = bestMove(await state(page));
    if (m) await dragPiece(page, m.slot, m.row, m.col);
  }
  const resto = (await state(page)).blitzSecondsLeft ?? 60;
  if (resto > 7) await page.clock.runFor((resto - 7) * 1000);
  await waitForState(page, (s) => (s.blitzSecondsLeft ?? 60) <= 7, 'blitz no fim');
  const segundos = (await state(page)).blitzSecondsLeft;
  await gravar(page, 'blitz-final', async (g) => {
    g.legenda(`Faltam <b>${segundos} segundos</b>…`, 2200);
    await g.esperar(500);
    for (let i = 0; i < 30; i++) {
      const s = await state(page);
      if (s.status !== 'playing' || (s.blitzSecondsLeft ?? 0) <= 3) break;
      const m = bestMove(s);
      if (!m) break;
      await jogar(g, page, m, 120, 300);
    }
    // O tabuleiro do combo entra já nos últimos segundos (o relógio do
    // Blitz para enquanto o cenário é carregado, então não dá para esperar).
    await loadScenario(page, COMBO);
    await g.esperar(300);
    g.legenda('Nos últimos segundos… <b>COMBO!</b>', 3200);
    for (const m of JOGADAS_COMBO) await jogar(g, page, m, 260, 320);
    await g.esperar(2600);
  });
});

// A Torre do Capi: da vila até passar do recorde e o pôr do sol, com
// acertos em sequência, cortes, um "por um fio" e o fim com a torre inteira.
test('torre', async ({ page }) => {
  await openApp(page, { level: 30, seen_opened_tower: true, towerBestHeight: 12, stars: 340 });
  await page.getByRole('button', { name: 'Modos' }).click();
  await page.getByRole('button', { name: /^Torre do Capi/ }).click();
  await waitForState(page, (s) => s.screen === 'tower', 'torre aberta');
  const torre = async () => (await state(page)).tower!;
  // O que o robô faz em cada andar: P = perfeito, c = corte, f = por um fio.
  const plano = 'PPPcPPPPPPPPPPcPPPfPPPPP';
  await gravar(page, 'torre', async (g) => {
    g.legenda('Empilha <b>sem errar</b>', 2400);
    await g.esperar(700);
    for (const jogada of plano) {
      for (let q = 0; q < 400; q++) {
        await g.quadro();
        const t = await torre();
        const longe = Math.abs(t.offset);
        if (jogada === 'P' && longe < 0.45) {
          // Encaixe perfeito (a ponte ajusta os últimos milímetros).
          await g.apertar(180, 420, () =>
            page.evaluate(() => (window as any).__bb.placeTower(true)),
          );
          break;
        }
        const alvo = jogada === 'c' ? [0.45, 0.95] : [t.room * 0.62, t.room * 0.9];
        if (jogada !== 'P' && longe > alvo[0] && longe < alvo[1]) {
          await g.apertar(180, 420, () => page.mouse.click(180, 420));
          break;
        }
      }
      await g.esperar(260);
    }
    // Erra de propósito: o bloco passa direto.
    for (let q = 0; q < 400; q++) {
      await g.quadro();
      const t = await torre();
      if (Math.abs(t.offset) > t.room + 0.3) {
        await g.apertar(180, 420, () => page.mouse.click(180, 420));
        break;
      }
    }
    await g.esperar(4200);
  });
});
