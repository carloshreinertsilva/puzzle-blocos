import { expect, test } from '@playwright/test';
import { openApp, state, waitForState } from './helpers';

test.describe('Missões Diárias e Guarda-Roupa de Chapéus', () => {
  test('abre guarda-roupa, visualiza chapéus e equipa um chapéu desbloqueado', async ({ page }) => {
    // Inicia na fase 8 com o chapéu 'crown' já desbloqueado no progresso
    await openApp(page, {
      level: 8,
      unlockedHats: '["helmet","crown","party"]',
      equippedHat: 'helmet',
    });

    const sInitial = await state(page);
    expect(sInitial.equippedHat).toBe('helmet');

    // Clica no botão de Guarda-Roupa no cabeçalho do menu
    const wardrobeBtn = page.getByRole('button', { name: 'Guarda-Roupa' });
    await expect(wardrobeBtn).toBeVisible();
    await wardrobeBtn.click();

    // Diálogo de guarda-roupa deve estar aberto
    await expect(page.getByText('Guarda-Roupa do Capi')).toBeVisible();

    // Seleciona a Coroa Real
    const crownCard = page.getByRole('button', { name: /Coroa Real/i });
    await expect(crownCard).toBeVisible();
    await crownCard.click();

    // Clica em Equipar
    const equipBtn = page.getByRole('button', { name: /Equipar Coroa Real/i });
    await expect(equipBtn).toBeVisible();
    await equipBtn.click();

    // Confere que agora está marcado como em uso
    await expect(page.getByText(/Chapéu Atualmente Equipado/i)).toBeVisible();

    // Fecha o guarda-roupa
    await page.getByRole('button', { name: 'Fechar' }).click();
    await expect(page.getByText('Guarda-Roupa do Capi')).toHaveCount(0);

    // O estado do jogo deve refletir a coroa equipada
    const sAfter = await state(page);
    expect(sAfter.equippedHat).toBe('crown');
  });

  test('abre missões diárias, visualiza as 3 tarefas e resgata recompensa', async ({ page }) => {
    await openApp(page, { level: 8 });

    const s = await state(page);
    expect(s.missions).toBeDefined();
    expect(s.missions!.length).toBe(3);
    const m0 = s.missions![0];

    // Avança o progresso da primeira missão antes de abrir o diálogo
    await page.evaluate((target) => (window as any).__bb.progressDailyMission(0, target), m0.target);

    // Clica no botão de Missões Diárias no menu
    const missionsBtn = page.getByRole('button', { name: 'Missões Diárias' });
    await expect(missionsBtn).toBeVisible();
    await missionsBtn.click();

    // Confere diálogo aberto e presença do Baú
    await expect(page.getByText('Missões Diárias')).toBeVisible();
    await expect(page.getByText('Baú do Capi')).toBeVisible();

    // O botão de resgate da missão completada deve estar visível
    const claimBtn = page.getByRole('button', { name: /^Resgatar/ });
    await expect(claimBtn).toBeVisible();
    await claimBtn.click();

    // Confere que foi marcada como concluída
    await expect(page.getByText('Concluída')).toBeVisible();

    // Fecha o diálogo
    await page.getByRole('button', { name: 'Fechar' }).click();
    await expect(page.getByText('Missões Diárias')).toHaveCount(0);
  });
});
