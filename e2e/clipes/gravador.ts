import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import type { Locator, Page } from '@playwright/test';

/** Quadros por segundo dos vídeos (FPS=30 npm run clipes para 30). */
export const FPS = Number(process.env.FPS ?? 60);

/**
 * Grava a tela do jogo como vídeo vertical (1080x1920, MP4 H.264) para
 * Reels, TikTok e Shorts, a [FPS] quadros por segundo e sem engasgos.
 *
 * O navegador de testes desenha sem placa de vídeo e não dá conta de 60
 * quadros por segundo; por isso o relógio da página é controlado: o tempo
 * só anda 1/FPS de segundo por vez, e cada quadro é fotografado depois de
 * desenhado. A gravação demora mais que o clipe, mas o vídeo sai liso.
 *
 * Antes de abrir o jogo: `await Gravador.prepararRelogio(page)`.
 */
export class Gravador {
  private n = 0;
  private ultimo = '';
  private pasta: string;

  constructor(
    private page: Page,
    private nome: string,
    private saida = join(__dirname, 'saida'),
  ) {
    this.pasta = join(this.saida, `.quadros-${nome}`);
  }

  /** O relógio da página passa a poder ser controlado (o tempo ainda corre). */
  static async prepararRelogio(page: Page) {
    await page.clock.install();
  }

  /** Para o relógio: daqui em diante o tempo só anda quadro a quadro. */
  async comecar() {
    rmSync(this.pasta, { recursive: true, force: true });
    mkdirSync(this.pasta, { recursive: true });
    const agora = await this.page.evaluate(() => Date.now());
    await this.page.clock.pauseAt(agora + 20);
    await this.quadro();
  }

  /** Anda um quadro e o fotografa. */
  async quadro() {
    await this.page.clock.runFor(1000 / FPS);
    // O desenho termina em tarefas marcadas para logo depois do quadro.
    for (let i = 0; i < 3; i++) await this.page.clock.runFor(0);
    let foto = await this.foto();
    let hash = createHash('md5').update(foto).digest('hex');
    if (hash === this.ultimo) {
      // Talvez ainda não estivesse na tela: mais um instante e outra foto.
      await this.page.waitForTimeout(60);
      foto = await this.foto();
      hash = createHash('md5').update(foto).digest('hex');
    }
    this.ultimo = hash;
    writeFileSync(join(this.pasta, `${String(this.n++).padStart(5, '0')}.jpg`), foto);
  }

  private async foto() {
    await this.page.waitForTimeout(40);
    return this.page.screenshot({ type: 'jpeg', quality: 92 });
  }

  /** [ms] milissegundos de vídeo. */
  async esperar(ms: number) {
    const quadros = Math.max(1, Math.round((ms * FPS) / 1000));
    for (let i = 0; i < quadros; i++) await this.quadro();
  }

  /** Grava até [cond] valer (no máximo [maxMs] de vídeo). */
  async ate(cond: () => Promise<boolean>, maxMs = 8000) {
    const quadros = Math.round((maxMs * FPS) / 1000);
    for (let i = 0; i < quadros; i++) {
      if (await cond()) return;
      await this.quadro();
    }
    throw new Error(`${this.nome}: esperou ${maxMs} ms e nada.`);
  }

  /** Toca num botão e grava o que acontece logo depois. */
  async tocar(alvo: Locator, depoisMs = 400) {
    const box = await alvo.boundingBox();
    if (!box) throw new Error(`${this.nome}: botão fora da tela.`);
    const x = box.x + box.width / 2;
    const y = box.y + box.height / 2;
    await this.page.mouse.move(x, y);
    await this.page.mouse.down();
    await this.quadro();
    await this.page.mouse.up();
    await this.esperar(depoisMs);
  }

  /** Arrasta de [de] até [para] em [ms], como um dedo (anda junto com os quadros). */
  async arrastar(de: { x: number; y: number }, para: { x: number; y: number }, ms = 520) {
    const m = this.page.mouse;
    await m.move(de.x, de.y);
    await m.down();
    await this.esperar(100);
    const passos = Math.max(2, Math.round((ms * FPS) / 1000));
    for (let i = 1; i <= passos; i++) {
      // Sai devagar, acelera e chega devagar.
      const t = i / passos;
      const e = t < 0.5 ? 2 * t * t : 1 - (-2 * t + 2) ** 2 / 2;
      await m.move(de.x + (para.x - de.x) * e, de.y + (para.y - de.y) * e);
      await this.quadro();
    }
    await this.esperar(120);
    await m.up();
  }

  /** Monta o vídeo. Devolve o caminho do MP4. */
  async terminar(): Promise<string> {
    await this.esperar(1200);
    const mp4 = join(this.saida, `${this.nome}.mp4`);
    execFileSync('ffmpeg', [
      '-y', '-loglevel', 'error',
      '-framerate', String(FPS), '-i', join(this.pasta, '%05d.jpg'),
      '-vf', 'scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=0x1b2440,format=yuv420p',
      '-r', String(FPS),
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-movflags', '+faststart',
      mp4,
    ]);
    rmSync(this.pasta, { recursive: true, force: true });
    return mp4;
  }
}
