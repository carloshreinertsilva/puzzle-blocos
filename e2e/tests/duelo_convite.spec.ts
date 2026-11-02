import { expect, test } from '@playwright/test';
import { state, waitForState } from './helpers';

async function abrir(page: import('@playwright/test').Page, url: string) {
  await page.goto(url);
  await page.waitForFunction(() => (window as any).__bb !== undefined, null, { timeout: 30_000 });
}

test('o link novo /duelo abre o desafio e volta ao endereço simples', async ({ page }) => {
  await abrir(page, '/duelo?s=7777&p=300');
  await waitForState(page, (s) => s.mode === 'duel', 'entrou no duelo');
  const s = await state(page);
  expect(s.duelSeed).toBe(7777);
  expect(s.duelTargetScore).toBe(300);
  // Fora do Android, nada de convite: joga direto.
  await expect(page.getByRole('dialog', { name: 'Desafio no CapiBlocks' })).toBeHidden();
  expect(new URL(page.url()).pathname).toBe('/');
});

test.describe('no Android sem o app', () => {
  test.use({
    userAgent:
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36',
  });

  test('o convite oferece a Play Store ou jogar no navegador', async ({ page }) => {
    await abrir(page, '/duelo?s=4242&p=1500&m=blitz');
    const convite = page.getByRole('dialog', { name: 'Desafio no CapiBlocks' });
    await expect(convite).toBeVisible();
    await expect(convite.getByText('1.500')).toBeVisible();
    await expect(convite.getByRole('link', { name: 'Baixar o app grátis' })).toHaveAttribute(
      'href',
      /play\.google\.com\/store\/apps\/details\?id=com\.capiblocks\.app/,
    );
    await convite.getByRole('button', { name: 'Jogar aqui no navegador' }).click();
    await expect(convite).toBeHidden();
    await waitForState(page, (s) => s.mode === 'blitz', 'entrou no desafio de Blitz');
  });
});
