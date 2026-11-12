import { expect, test, type Page } from '@playwright/test';
import { openApp, snap, state } from './helpers';

// Nos testes o ranking fica na memória, com três rivais em cada placar
// (lib/testing/test_bridge.dart); nos celulares ele fica no Firebase.

/** Abre o ranking; sem nome escolhido, a janela do nome vem por cima. */
async function abrirRanking(page: Page, { comNome = true } = {}) {
  await page.getByRole('button', { name: /^Ranking/ }).click();
  const pronto = comNome
    ? page.getByRole('button', { name: 'Ranking: Torre do Capi' })
    : page.getByRole('textbox', { name: 'Nome no ranking' });
  await expect(pronto).toBeVisible({ timeout: 30_000 });
}

/** Uma linha da lista: as dos outros jogadores são um grupo (com o botão de
 * denunciar dentro); a do próprio jogador é só o texto. */
const linha = (page: Page, texto: string) =>
  page.getByRole('group', { name: texto, exact: true }).or(page.getByText(texto, { exact: true })).first();

async function digitarNome(page: Page, nome: string) {
  const campo = page.getByRole('textbox', { name: 'Nome no ranking' });
  // Apaga letra por letra (o nome tem no máximo 16) e confere o que ficou:
  // selecionar tudo com o teclado falhava de vez em quando, e o nome novo
  // ia para o fim do antigo.
  await expect(async () => {
    await campo.click();
    await campo.press('End');
    for (let i = 0; i < 18; i++) await campo.press('Backspace');
    await campo.pressSequentially(nome, { delay: 30 });
    await expect(campo).toHaveValue(nome, { timeout: 1500 });
  }).toPass({ timeout: 20_000 });
  await page.getByRole('button', { name: 'Salvar meu nome no ranking' }).click();
}

test.describe('Ranking do jogo', () => {
  test('escolhe o nome (com filtro), entra nas listas e vê a própria posição', async ({ page }, testInfo) => {
    await openApp(page, { level: 21, towerBestHeight: 30, bestScore: 4000 });
    await abrirRanking(page, { comNome: false });

    // Na primeira vez o jogo pede o nome; palavrão e nome curto não passam.
    await expect(page.getByText('Seu nome no ranking')).toBeVisible();
    await digitarNome(page, 'M3rd4');
    await expect(page.getByText('Esse nome não pode. Escolha outro, por favor.').first()).toBeVisible();
    await digitarNome(page, 'Zé');
    await expect(page.getByText('O nome precisa de pelo menos 3 letras.').first()).toBeVisible();
    await digitarNome(page, 'Carlos');
    await expect(page.getByText('Seu nome no ranking')).toHaveCount(0);

    // O recorde de sempre (30 andares) fica atrás só da Bia (40).
    await page.getByRole('button', { name: 'Sempre' }).click();
    await expect(linha(page, '1º lugar: Bia Blocos, 40 andares')).toBeVisible();
    await expect(linha(page, '2º lugar: Carlos, 30 andares')).toBeVisible();
    await expect(linha(page, '2º lugar: Você, 30 andares')).toBeVisible();
    await snap(page, testInfo, `ranking-${testInfo.project.name}`);
    const s = await state(page);
    expect(s.ranking!.nome).toBe('Carlos');
    expect(s.ranking!.linhas).toMatchObject({ torre_geral: 30, infinito_geral: 4000, fases_geral: 20 });

    // Outro placar, e a semana (em que ainda não jogou).
    await page.getByRole('button', { name: 'Ranking: Fases' }).click();
    await expect(linha(page, '2º lugar: Zeca, 48 fases')).toBeVisible();
    await expect(linha(page, '4º lugar: Você, 20 fases')).toBeVisible();
    await page.getByRole('button', { name: 'Esta semana' }).click();
    await expect(page.getByText('Jogue esta semana para entrar na lista!')).toBeVisible();

    await page.getByRole('button', { name: 'Voltar' }).click();
    await expect(page.getByRole('button', { name: /^Jogar · Fase/ })).toBeVisible();
  });

  test('denunciar um nome tira a linha da lista', async ({ page }) => {
    await openApp(page, { level: 21, rankingNome: JSON.stringify('Carlos') });
    await abrirRanking(page);
    await page.getByRole('button', { name: 'Sempre' }).click();
    await expect(linha(page, '2º lugar: Zeca, 24 andares')).toBeVisible();
    await page.getByRole('button', { name: 'Denunciar o nome Zeca' }).click();
    await page.getByRole('button', { name: 'Denunciar', exact: true }).click();
    await expect(page.getByRole('group', { name: /Zeca/ })).toHaveCount(0);
    await expect(linha(page, '2º lugar: Lia_22, 12 andares')).toBeVisible();
    expect((await state(page)).ranking!.denuncias).toBe(1);
  });
});
