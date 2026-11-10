import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { test, type Page } from '@playwright/test';
import { loadScenario, openApp, playMove, state, waitForState } from '../tests/helpers';

/**
 * Telas do jogo para as capturas das lojas, em português, inglês e espanhol.
 * Rodar: `npm run build && npm run loja`. Saem em e2e/loja/saida/<idioma>/.
 */

type Idioma = 'pt' | 'en' | 'es';
const IDIOMAS: Idioma[] = ['pt', 'en', 'es'];

// Os rótulos dos botões em cada idioma (lib/l10n/textos/).
const B: Record<Idioma, Record<string, string>> = {
  pt: { modos: 'Modos', infinito: 'Infinito', roupa: 'Guarda-Roupa', vila: 'Vila do Capi', ok: 'Entendi!', jogar: 'Jogar · Fase', convidar: 'Convidar amigos' },
  en: { modos: 'Modes', infinito: 'Endless', roupa: 'Wardrobe', vila: "Capi's Village", ok: 'Got it!', jogar: 'Play · Level', convidar: 'Invite friends' },
  es: { modos: 'Modos', infinito: 'Infinito', roupa: 'Armario', vila: 'Aldea de Capi', ok: '¡Entendido!', jogar: 'Jugar · Nivel', convidar: 'Invitar amigos' },
};

const COMBO = {
  board: ['.bb.b..b', '.bbb..b.', '.bb..g..', 'bgb.b..b', 'bbbb.b..', '...bbb..', '...bgb..', '...bbgbb'],
  tray: ['i31', 'o20', 'o30'],
};

const json = (v: unknown) => JSON.stringify(v);

async function abrir(page: Page, idioma: Idioma, extras: Record<string, unknown> = {}) {
  await openApp(page, { idioma: json(idioma), stars: 1250, ...extras }).catch(async () => {
    // Fora do português, o botão do menu tem outro nome: só espera a ponte.
  });
  await page.waitForFunction(() => (window as any).__bb !== undefined);
  await page.getByRole('button', { name: new RegExp(`^${B[idioma].jogar}`) }).waitFor();
  await page.waitForTimeout(1200);
}

async function fecharNovidades(page: Page, idioma: Idioma) {
  for (let i = 0; i < 6; i++) {
    const s = await state(page);
    if (s.screen === 'game' && s.intros!.length === 0) break;
    const ok = page.getByRole('button', { name: B[idioma].ok });
    if (await ok.isVisible()) await ok.click();
    await page.waitForTimeout(500);
  }
}

async function foto(page: Page, idioma: Idioma, nome: string) {
  const pasta = join(__dirname, 'saida', idioma);
  mkdirSync(pasta, { recursive: true });
  await page.screenshot({ path: join(pasta, `${nome}.png`) });
}

async function arrastar(page: Page, slot: number, row: number, col: number) {
  const path = JSON.parse(await page.evaluate(([s, r, c]) => (window as any).__bb.dragPath(s, r, c), [slot, row, col]));
  await page.mouse.move(path.from.x, path.from.y);
  await page.mouse.down();
  await page.mouse.move(path.to.x, path.to.y, { steps: 10 });
  await page.waitForTimeout(80);
  return () => page.mouse.up();
}

for (const idioma of IDIOMAS) {
  test.describe(idioma, () => {
    test('1 combo', async ({ page }) => {
      await page.clock.install();
      await abrir(page, idioma, { level: 30 });
      await page.getByRole('button', { name: B[idioma].modos }).click();
      await page.getByRole('button', { name: B[idioma].infinito }).click();
      await waitForState(page, (s) => s.screen === 'game' && s.kind === 'endless', 'infinito');
      await fecharNovidades(page, idioma);
      await page.waitForTimeout(2500);
      await loadScenario(page, COMBO);
      await page.waitForTimeout(400);
      for (const [slot, r, c] of [[0, 0, 0], [1, 5, 6]]) {
        await (await arrastar(page, slot, r, c))();
        await page.waitForTimeout(1200);
      }
      // O combo grande: a foto sai no meio da comemoração.
      const soltar = await arrastar(page, 2, 5, 0);
      const agora = await page.evaluate(() => Date.now());
      await page.clock.pauseAt(agora + 5);
      await soltar();
      for (let i = 0; i < 26; i++) {
        await page.clock.runFor(1000 / 60);
        for (let k = 0; k < 3; k++) await page.clock.runFor(0);
      }
      await page.waitForTimeout(300);
      await foto(page, idioma, '1-combo');
    });

    test('2 filhotes', async ({ page }) => {
      await abrir(page, idioma, { level: 8 });
      await page.getByRole('button', { name: new RegExp(`^${B[idioma].jogar}`) }).click();
      await waitForState(page, (s) => s.screen === 'game', 'fase');
      await fecharNovidades(page, idioma);
      await page.waitForTimeout(1500);
      // Umas jogadas: o quadro das estrelas some e o tabuleiro fica colorido.
      for (let i = 0; i < 4; i++) await playMove(page);
      await page.waitForTimeout(2500);
      await foto(page, idioma, '2-filhotes');
    });

    test('3 guarda-roupa', async ({ page }) => {
      await abrir(page, idioma, {
        level: 30,
        equippedHat: json('crown'),
        equipped_costas: json('capa_real'),
        equipped_rosto: json('oculos_coracao'),
        unlockedHats: json(['helmet', 'crown', 'capa_real', 'oculos_coracao', 'touca', 'chef', 'pirate', 'wizard', 'party']),
      });
      await page.getByRole('button', { name: B[idioma].roupa }).click();
      await page.waitForTimeout(2000);
      await foto(page, idioma, '3-guarda-roupa');
    });

    test('4 vila', async ({ page }) => {
      await abrir(page, idioma, { level: 60, villageBuilt: 99 });
      await page.getByRole('button', { name: new RegExp(`^${B[idioma].vila}`) }).click();
      await waitForState(page, (s) => s.screen === 'village', 'vila');
      await page.waitForTimeout(2500);
      await foto(page, idioma, '4-vila');
    });

    test('5 natal', async ({ page }) => {
      await abrir(page, idioma, {
        level: 30,
        equippedHat: json('gorro_natal'),
        equipped_pescoco: json('cachecol_natal'),
        unlockedHats: json(['helmet', 'gorro_natal', 'cachecol_natal']),
      });
      await page.waitForTimeout(1500);
      await foto(page, idioma, '5-natal');
    });

    test('6 modos', async ({ page }) => {
      await abrir(page, idioma, { level: 30 });
      await page.getByRole('button', { name: B[idioma].modos }).click();
      await page.waitForTimeout(1500);
      await foto(page, idioma, '6-modos');
    });

    test('7 convites', async ({ page }) => {
      await abrir(page, idioma, { level: 30 });
      await page.getByRole('button', { name: B[idioma].convidar }).click();
      await page.waitForTimeout(1800);
      await foto(page, idioma, '7-convites');
    });
  });
}
