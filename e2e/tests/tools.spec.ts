import { expect, test } from '@playwright/test';
import {
  loadScenario,
  openApp,
  startLevel,
  state,
  waitForState,
} from './helpers';

test.describe('Ferramentas do Capi', () => {
  test('abre e fecha a mochila de ferramentas', async ({ page }) => {
    await openApp(page);
    await startLevel(page);

    // Clica no botão de ferramentas no topo
    await page.getByRole('button', { name: 'Ferramentas' }).click();

    // Confere que a folha abriu com as 4 ferramentas
    await expect(page.getByText('Ferramentas do Capi')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Usar Martelo' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Usar Girar' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Usar Trocar' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Usar Pá 3x3' })).toBeVisible();

    // Fecha a folha
    await page.getByRole('button', { name: 'Fechar' }).click();
    await expect(page.getByText('Ferramentas do Capi')).not.toBeVisible();
  });

  test('usa o martelo para quebrar uma célula', async ({ page }) => {
    await openApp(page);
    await startLevel(page);

    // Monta cenário com um bloco em (3, 3)
    await loadScenario(page, {
      board: [
        '........',
        '........',
        '........',
        '...b....',
        '........',
        '........',
        '........',
        '........',
      ],
      tray: ['dot0', 'dot0', 'dot0'],
    });

    const sBefore = await state(page);
    expect(sBefore.board![3][3]).toBe('b');
    const hammerBefore = sBefore.tools?.hammer ?? 2;

    // Abre ferramentas e usa Martelo
    await page.getByRole('button', { name: 'Ferramentas' }).click();
    await page.getByRole('button', { name: 'Usar Martelo' }).click();

    // Clica na célula (3, 3)
    await page.getByRole('button', { name: 'Quebrar célula 3 3' }).click();

    // Confere que a célula foi esvaziada e o martelo consumido
    await waitForState(
      page,
      (s) => s.board?.[3][3] === '.' && (s.tools?.hammer ?? 0) === hammerBefore - 1,
      'célula quebrada pelo martelo',
    );
  });

  test('gira uma peça da bandeja', async ({ page }) => {
    await openApp(page);
    await startLevel(page);

    // Carrega um i2 horizontal na bandeja
    await loadScenario(page, {
      board: [
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ],
      tray: ['i20', 'dot0', 'dot0'],
    });

    const sBefore = await state(page);
    expect(sBefore.tray![0]?.id).toBe('i20');
    const rotateBefore = sBefore.tools?.rotate ?? 2;

    // Abre ferramentas e usa Girar
    await page.getByRole('button', { name: 'Ferramentas' }).click();
    await page.getByRole('button', { name: 'Usar Girar' }).click();

    // Clica no slot 0 da bandeja
    await page.getByRole('button', { name: 'Girar peça 0' }).click();

    // Confere que a peça girou para i21 (vertical) e o giro foi consumido
    await waitForState(
      page,
      (s) => s.tray?.[0]?.id === 'i21' && (s.tools?.rotate ?? 0) === rotateBefore - 1,
      'peça girada',
    );
  });

  test('troca as peças da bandeja', async ({ page }) => {
    await openApp(page);
    await startLevel(page);

    const sBefore = await state(page);
    const rerollBefore = sBefore.tools?.reroll ?? 2;

    // Abre ferramentas e clica em Trocar
    await page.getByRole('button', { name: 'Ferramentas' }).click();
    await page.getByRole('button', { name: 'Usar Trocar' }).click();

    // Confere que o reroll foi consumido
    await waitForState(
      page,
      (s) => (s.tools?.reroll ?? 0) === rerollBefore - 1,
      'bandeja trocada',
    );
  });

  test('usa a pá para limpar uma área 3x3', async ({ page }) => {
    await openApp(page);
    await startLevel(page);

    // Preenche um quadrado 3x3 de blocos no centro
    await loadScenario(page, {
      board: [
        '........',
        '........',
        '..bbb...',
        '..bbb...',
        '..bbb...',
        '........',
        '........',
        '........',
      ],
      tray: ['dot0', 'dot0', 'dot0'],
    });

    const sBefore = await state(page);
    expect(sBefore.board![3][3]).toBe('b');
    const shovelBefore = sBefore.tools?.shovel ?? 1;

    // Abre ferramentas e usa Pá 3x3
    await page.getByRole('button', { name: 'Ferramentas' }).click();
    await page.getByRole('button', { name: 'Usar Pá 3x3' }).click();

    // Clica no centro da área (3, 3)
    await page.getByRole('button', { name: 'Limpar área 3x3 3 3' }).click();

    // Confere que toda a área 3x3 ficou vazia
    await waitForState(
      page,
      (s) =>
        s.board?.[2].slice(2, 5) === '...' &&
        s.board?.[3].slice(2, 5) === '...' &&
        s.board?.[4].slice(2, 5) === '...' &&
        (s.tools?.shovel ?? 0) === shovelBefore - 1,
      'área 3x3 limpa pela pá',
    );
  });

  test('cancela o modo da ferramenta sem gastar', async ({ page }) => {
    await openApp(page);
    await startLevel(page);

    const sBefore = await state(page);
    const hammerBefore = sBefore.tools?.hammer ?? 2;

    // Abre ferramentas e escolhe Martelo
    await page.getByRole('button', { name: 'Ferramentas' }).click();
    await page.getByRole('button', { name: 'Usar Martelo' }).click();

    // Clica em Cancelar
    await page.getByRole('button', { name: 'Cancelar' }).click();

    // Confere que nenhum martelo foi gasto
    const sAfter = await state(page);
    expect(sAfter.tools?.hammer).toBe(hammerBefore);
    expect(sAfter.activeTool).toBeUndefined();
  });
});
