import { expect, test, type Page } from '@playwright/test';
import { loadScenario, openApp, state, waitForState } from './helpers';

const CHECKER = Array.from({ length: 8 }, (_, r) => (r % 2 ? '.b.b.b.b' : 'b.b.b.b.'));

// Nos testes os duelos ficam na memória (lib/testing/test_bridge.dart), com
// um desafio da Bia pronto (id testeBia, 300 pontos); nos celulares e no
// site eles ficam no Firebase.

/** O campo começa vazio. Sobre a partida cada tecla demora (o jogo continua
 * desenhando), então nada de apagar letra por letra: só digita. */
async function digitarNome(page: Page, nome: string) {
  const campo = page.getByRole('textbox', { name: 'Nome no ranking' });
  await campo.click();
  await campo.pressSequentially(nome, { delay: 30 });
  await expect(campo).toHaveValue(nome);
  await page.getByRole('button', { name: 'Salvar meu nome no ranking' }).click();
}

test.describe('Retorno do duelo e placar dos duelos', () => {
  test('quem recebe o desafio joga, diz o nome e o resultado volta para a Bia', async ({ page }) => {
    await openApp(page, { level: 10 });
    await page.goto('/duelo?s=7777&p=300&d=testeBia&n=Bia');
    await page.waitForFunction(() => (window as any).__bb !== undefined, null, { timeout: 30_000 });
    const s = await waitForState(page, (x) => x.mode === 'duel' && x.status === 'playing', 'desafio da Bia');
    expect(s.duelRivalName).toBe('Bia');
    await expect(page.getByText(/Meta do Bia: 300/)).toBeVisible();

    await page.evaluate(() => (window as any).__bb.win());
    await expect(page.getByText('Seu nome no duelo')).toBeVisible({ timeout: 10_000 });
    await digitarNome(page, 'Zeca');

    await expect(page.getByText('Você venceu!', { exact: true })).toBeVisible();
    await expect(
      page.getByText('Bia vai saber do seu resultado. Você 1 × 0 Bia'),
    ).toBeVisible({ timeout: 10_000 });
    const d = (await state(page)).duelos;
    expect(d.respostas).toEqual([{ duelo: 'testeBia', nome: 'Zeca', pontos: expect.any(Number) }]);
    expect(d.placar).toEqual([{ nome: 'Bia', v: 1, d: 0 }]);
  });

  test('quem desafiou fica sabendo ao voltar ao menu e vê o placar no Duelo', async ({ page }) => {
    await openApp(page, { level: 10, seen_opened_duel: true, rankingNome: JSON.stringify('Ana') });
    await page.getByRole('button', { name: 'Modos' }).click();
    await page.getByRole('button', { name: /^Duelo/ }).click();
    await expect(page.getByText('Quando ele jogar, você vê o resultado e o placar de vocês.')).toBeVisible();
    await expect(page.getByText('Placar dos duelos')).toHaveCount(0);
    await page.getByRole('button', { name: 'Começar Duelo' }).click();
    await waitForState(page, (x) => x.mode === 'duel' && x.status === 'playing', 'duelo aberto');

    await loadScenario(page, { board: CHECKER, tray: ['o20', 'o20', 'o20'] });
    await waitForState(page, (x) => x.status === 'lost' && x.showOutcome === true, 'fim do duelo');
    await page.getByRole('button', { name: 'Desafiar Amigo' }).click();
    await expect
      .poll(async () => (await state(page)).duelos.criados.length, { message: 'desafio no servidor' })
      .toBe(1);
    expect((await state(page)).duelos.criados[0].nome).toBe('Ana');

    // O Zeca joga o desafio enquanto a Ana ainda está na partida.
    expect(await page.evaluate(() => (window as any).__bb.amigoResponde('Zeca', 99999))).toBe(true);
    await page.getByRole('button', { name: 'Menu' }).click();

    await expect(page.getByText('Resultado do duelo')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText(/^Zeca passou você: 99\.999 × \d+\. Revanche\? Você 0 × 1 Zeca$/)).toBeVisible();
    await page.getByRole('button', { name: 'Legal!' }).click();
    await expect(page.getByText('Resultado do duelo')).toHaveCount(0);

    await page.getByRole('button', { name: 'Modos' }).click();
    await page.getByRole('button', { name: /^Duelo/ }).click();
    await expect(page.getByText('Placar dos duelos')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText('Você 0 × 1 Zeca', { exact: true })).toBeVisible({ timeout: 10_000 });
  });
});
