import { expect, test } from '@playwright/test';
import { dragPiece, openApp, openFresh, state, waitForState } from './helpers';

test.describe('Modo Blitz 60s e Duelo', () => {
  test('modo Blitz abre pelo menu e roda cronômetro', async ({ page }) => {
    // Jogador na fase 10 já tem o Blitz liberado
    await openApp(page, { level: 10, seen_opened_blitz: true });

    // Localiza e clica no cartão do Blitz 60s
    const blitzCard = page.getByRole('button', { name: /^Blitz 60s/ });
    await expect(blitzCard).toBeVisible();
    await blitzCard.click();

    // Espera entrar na tela de jogo com o modo Blitz
    await waitForState(page, (s) => s.mode === 'blitz', 'entrou no modo blitz');

    const sInitial = await state(page);
    expect(sInitial.mode).toBe('blitz');
    expect(sInitial.blitzSecondsLeft).toBeLessThanOrEqual(60);
    expect(sInitial.blitzSecondsLeft).toBeGreaterThan(0);

    // O cronômetro deve estar visível no HUD (exato: 60s, 59s, etc)
    await expect(page.getByText(/^\d+s$/)).toBeVisible();

    // Joga uma peça no tabuleiro
    await dragPiece(page, 0, 0, 0);

    const sAfter = await state(page);
    expect(sAfter.score).toBeGreaterThan(0);
  });

  test('modo Duelo abre por link com semente e meta do rival', async ({ page }) => {
    // Abre direto pelo link compartilhado ?duelo=7777&p=300
    await page.goto('/?duelo=7777&p=300');

    await page.waitForFunction(
      () => (window as any).__bb !== undefined,
      null,
      { timeout: 30_000 },
    );

    await waitForState(page, (s) => s.mode === 'duel', 'entrou no duelo via URL');

    const s = await state(page);
    expect(s.mode).toBe('duel');
    expect(s.duelSeed).toBe(7777);
    expect(s.duelTargetScore).toBe(300);

    // O HUD deve mostrar a meta do rival
    await expect(page.getByText(/Meta do Rival: 300/i)).toBeVisible();

    // Vence a partida via debug da ponte
    await page.evaluate(() => (window as any).__bb.win());

    // Confere cartão final de desfecho do Duelo
    await expect(page.getByText(/Você Venceu o Duelo!/i)).toBeVisible();
    await expect(page.getByRole('button', { name: 'Compartilhar Duelo' })).toBeVisible();
  });
});
