import { expect, test, type Locator, type Page } from '@playwright/test';
import { openApp } from './helpers';

// The iPhone has no back button: every window opened from the menu needs a
// visible way out, and the menu must take taps again afterwards.
async function fecharEVoltar(page: Page, marca: Locator) {
  await expect(marca.first()).toBeVisible({ timeout: 30_000 });
  await page.getByRole('button', { name: 'Fechar' }).last().click();
  await expect(marca).toHaveCount(0, { timeout: 10_000 });
  await expect(page.getByRole('button', { name: /^Jogar · Fase/ })).toBeVisible();
}

// [name, button that opens it, something only the open window shows]
const janelas: [string, string | RegExp, (p: Page) => Locator][] = [
  ['Configurações', 'Configurações', (p) => p.getByText('Política de Privacidade')],
  ['Missões', 'Missões Diárias', (p) => p.getByText('Baú do Capi')],
  ['Modos', /^Modos/, (p) => p.getByText('Modos de jogo')],
  ['Guarda-Roupa', /Guarda-Roupa/, (p) => p.getByRole('button', { name: 'Aba Cabeça' })],
  ['Mercado', /Mercado/, (p) => p.getByText(/Ofertas de hoje/)],
  // On the web (no Game Center / Play Games) Ranking shows the statistics.
  ['Estatísticas', /Ranking/, (p) => p.getByText('Pedras quebradas')],
];

test.describe('Toda janela fecha pelo botão Fechar', () => {
  for (const [nome, botao, marca] of janelas) {
    test(nome, async ({ page }) => {
      await openApp(page, { level: 40, stars: 500 });
      await page.getByRole('button', { name: botao }).first().click();
      await fecharEVoltar(page, marca(page));
    });
  }

  test('Política de Privacidade', async ({ page }) => {
    await openApp(page);
    await page.getByRole('button', { name: 'Configurações' }).click();
    await page.getByText('Política de Privacidade').click();
    await expect(page.getByText('Privacidade', { exact: true })).toBeVisible({ timeout: 30_000 });
    await page.getByRole('button', { name: 'Fechar' }).last().click();
    await expect(page.getByText('Privacidade', { exact: true })).toHaveCount(0, { timeout: 10_000 });
  });
});
