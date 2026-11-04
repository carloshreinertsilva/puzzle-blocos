import { expect, test } from '@playwright/test';
import { openApp } from './helpers';

test.describe('Política de Privacidade', () => {
  test('página estática em /privacidade/ carrega com dados corretos e visual do jogo', async ({ page }) => {
    const res = await page.goto('/privacidade/');
    expect(res?.status()).toBe(200);

    // Confere título da página e da aba
    await expect(page).toHaveTitle(/Política de Privacidade — CapiBlocks/);
    await expect(page.getByRole('heading', { level: 1, name: 'Política de Privacidade' })).toBeVisible();

    // Confere dados da empresa responsável e e-mails
    await expect(page.getByText(/CHS CONSULTORIA LTDA/i).first()).toBeVisible();
    await expect(page.getByText(/contato@chstech.dev.br/i).first()).toBeVisible();

    // Confere link de retorno ao jogo
    const backLink = page.getByRole('link', { name: /Voltar ao jogo/i });
    await expect(backLink).toBeVisible();
    expect(await backLink.getAttribute('href')).toBe('/');
  });

  test('página de exclusão de dados em /excluir-dados/ mostra os passos e o contato', async ({ page }) => {
    const res = await page.goto('/excluir-dados/');
    expect(res?.status()).toBe(200);
    await expect(page).toHaveTitle(/Excluir seus dados — CapiBlocks/);
    await expect(page.getByRole('heading', { level: 1, name: 'Excluir seus dados' })).toBeVisible();
    await expect(page.getByText(/CHS CONSULTORIA LTDA/).first()).toBeVisible();
    await expect(page.getByText(/Excluir dados ocultos do app/)).toBeVisible();
    await expect(page.getByRole('heading', { name: /O que é mantido/ })).toBeVisible();
    await expect(page.getByRole('link', { name: 'contato@chstech.dev.br' }).first()).toBeVisible();
  });

  test('menu de configurações do app exibe link acessível para a política', async ({ page }) => {
    await openApp(page, { level: 5 });

    // Clica no botão de configurações no cabeçalho
    const settingsBtn = page.getByRole('button', { name: 'Configurações' });
    await expect(settingsBtn).toBeVisible();
    await settingsBtn.click();

    // Diálogo de configurações deve conter o botão da Política de Privacidade
    const privacyBtn = page.getByRole('button', { name: 'Política de Privacidade' }).first();
    await expect(privacyBtn).toBeVisible();
  });
});
