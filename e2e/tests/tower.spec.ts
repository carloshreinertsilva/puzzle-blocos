import { expect, test } from '@playwright/test';
import { openApp, state, waitForState } from './helpers';

test.describe('Torre do Capi em 2.5D', () => {
  test('abre pelo menu, empilha blocos e finaliza com resultado', async ({ page }) => {
    // Jogador veterano na fase 10 tem a Torre liberada
    await openApp(page, { level: 10, seen_opened_tower: true });

    // Localiza e clica no cartão da Torre do Capi
    const towerCard = page.getByRole('button', { name: /^Torre do Capi/ });
    await expect(towerCard).toBeVisible();
    await towerCard.click();

    // Espera entrar na tela da Torre
    await waitForState(page, (s) => s.screen === 'tower', 'entrou na tela da torre');

    const sInitial = await state(page);
    expect(sInitial.screen).toBe('tower');
    expect(sInitial.tower).toBeDefined();
    expect(sInitial.tower.playing).toBe(true);

    // O botão semântico de toque deve estar acessível
    const placeButton = page.getByRole('button', { name: 'Colocar Bloco' });
    await expect(placeButton).toBeVisible();

    // Coloca 3 andares perfeitos via ponte determinística
    await page.evaluate(() => (window as any).__bb.placeTower(true));
    await page.evaluate(() => (window as any).__bb.placeTower(true));
    await page.evaluate(() => (window as any).__bb.placeTower(true));

    const sAfter = await state(page);
    expect(sAfter.tower.placedFloors).toBeGreaterThanOrEqual(3);
    expect(sAfter.tower.combo).toBeGreaterThanOrEqual(2);

    // Clica no botão na tela para colocar mais um bloco
    await placeButton.click();

    // Provoca um erro para testar a finalização da subida
    // Erra completamente o bloco com offset grande
    await page.evaluate(() => (window as any).__bb.placeTower(false, 9.0));

    // Aguarda o estado e o diálogo ou resultado de Game Over
    await waitForState(page, (s) => s.tower?.gameOver === true, 'fim de jogo na torre');
    await expect(page.getByText(/Fim da Subida!/i)).toBeVisible();
    await expect(page.getByRole('button', { name: 'Subir de Novo' })).toBeVisible();
    
    // Clica em voltar ao menu
    const menuBtn = page.getByRole('button', { name: 'Voltar ao Menu' });
    await expect(menuBtn).toBeVisible();
    await menuBtn.click();

    // Volta com segurança para o menu inicial
    await waitForState(page, (s) => s.screen === 'home', 'voltou ao menu inicial');
  });
});
