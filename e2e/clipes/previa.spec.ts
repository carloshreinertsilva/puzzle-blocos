/**
 * Prévia do cartão final e da logo de abertura sem abrir o jogo (rápida,
 * para ajustar o visual; precisa do build em ../build/web_test):
 *   npx playwright test -c playwright.clipes.config.ts previa
 * As imagens ficam em clipes/saida/previa-*.png.
 */
import { test } from '@playwright/test';
import { join } from 'node:path';
import { marcaParaPrevia, CAMADA_PARA_PREVIA } from './gravador';

test('previa', async ({ page }) => {
  // Uma página vazia no mesmo endereço do jogo: a fonte e o Capi carregam
  // dos assets do build, sem abrir o jogo.
  await page.route('**/previa.html', (r) =>
    r.fulfill({ contentType: 'text/html', body: '<body style="margin:0;background:#3b4a8a"></body>' }),
  );
  await page.goto('/previa.html');
  await page.evaluate(CAMADA_PARA_PREVIA);
  for (const appStore of [false, true]) {
    await page.evaluate((m) => (window as any).__clipe.marca(m), marcaParaPrevia(appStore));
    await page.evaluate(() => (window as any).__clipe.fonte);
    const pose = { x: 0, y: 0, dedo: 0, escala: 1, html: '', legenda: 0, convite: 'Acertou? Então vem <b>jogar</b>!' };
    await page.evaluate((c) => (window as any).__clipe.desenhar(c), { ...pose, intro: -1, fim: 2 });
    await page.screenshot({ path: join(__dirname, 'saida', `previa-fim${appStore ? '-iphone' : ''}.png`) });
  }
  await page.evaluate((c) => (window as any).__clipe.desenhar(c), {
    x: 0, y: 0, dedo: 0, escala: 1, html: '', legenda: 0, convite: '', intro: 0.6, fim: -1,
  });
  await page.screenshot({ path: join(__dirname, 'saida', 'previa-abertura.png') });
});
