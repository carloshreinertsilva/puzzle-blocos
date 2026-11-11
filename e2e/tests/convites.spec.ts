import { expect, test } from '@playwright/test';
import { openApp, state, waitForState } from './helpers';

test.describe('Convidar amigos', () => {
  test('a janela mostra os prêmios, o código e aceita o convite de um amigo', async ({ page }) => {
    await openApp(page, { stars: 10 });
    await page.getByRole('button', { name: 'Convidar amigos' }).click();
    await expect(page.getByText(/^Seu código: [A-Z2-9]{6}$/).first()).toBeVisible({ timeout: 30_000 });
    // The reward steps.
    await expect(page.getByText('1 amigo: 50 estrelas')).toBeVisible();
    await expect(page.getByText('3 amigos: Faixa de Embaixador')).toBeAttached();
    await expect(page.getByText('5 amigos: Coroa de Amizade')).toBeAttached();
    await expect(page.getByRole('button', { name: 'Compartilhar convite' })).toBeVisible();

    // One's own code doesn't count.
    const meu = ((await page.getByText(/^Seu código: /).first().textContent()) ?? '').replace('Seu código: ', '');
    const digitar = async (texto: string) => {
      const campo = page.getByRole('textbox', { name: 'Código do convite' });
      await campo.click();
      await campo.press('Control+A');
      await campo.press('Backspace');
      await campo.pressSequentially(texto, { delay: 40 });
      await expect(campo).toHaveValue(new RegExp(texto, 'i'));
    };
    await digitar(meu);
    await page.getByRole('button', { name: 'Usar código do convite' }).click();
    await expect(page.getByText('Esse é o seu código: mande para um amigo!').first()).toBeVisible();

    // A friend's code: the gift, once.
    await digitar('abc234');
    await page.getByRole('button', { name: 'Usar código do convite' }).click();
    await waitForState(page, (s) => s.stars === 60, '+50 estrelas do convite');
    expect((await state(page)).unlockedHats).toContain('laco_amizade');
    await expect(page.getByText('Ganhou um convite? Digite o código:')).toHaveCount(0);

    await page.getByRole('button', { name: 'Fechar' }).last().click();
    await expect(page.getByRole('button', { name: /^Jogar · Fase/ })).toBeVisible();
  });

  test('um link de convite abre o presente', async ({ page }) => {
    await openApp(page, { stars: 0 });
    // Past the menu's opening (gift of the day, etc.).
    await page.waitForTimeout(1500);
    // The link reaches Flutter as a route (as an Android App Link does).
    await page.evaluate(() => (window as any).__bb.abrirRota('/convite?c=DEF567'));
    await page.getByRole('button', { name: 'Pegar presente' }).click({ timeout: 30_000 });
    await waitForState(page, (s) => s.stars === 50, 'presente do link');
    await page.getByRole('button', { name: 'Jogar' }).click();
    await expect(page.getByRole('button', { name: /^Jogar · Fase/ })).toBeVisible();
  });
});
