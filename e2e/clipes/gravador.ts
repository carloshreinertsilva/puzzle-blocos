import { execFileSync } from 'node:child_process';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import type { Page } from '@playwright/test';

/**
 * Grava a tela do jogo como vídeo vertical (1080x1920, MP4 H.264), pronto
 * para Reels, TikTok e Shorts. Usa o screencast do Chromium (quadros JPEG
 * com o horário de cada um) e o ffmpeg para montar o vídeo a 30 qps.
 */
export class Gravador {
  private quadros: { arquivo: string; t: number }[] = [];
  private pasta: string;
  private cdp?: Awaited<ReturnType<ReturnType<Page['context']>['newCDPSession']>>;

  constructor(
    private page: Page,
    private nome: string,
    private saida = join(__dirname, 'saida'),
  ) {
    this.pasta = join(this.saida, `.quadros-${nome}`);
  }

  async comecar() {
    rmSync(this.pasta, { recursive: true, force: true });
    mkdirSync(this.pasta, { recursive: true });
    const cdp = await this.page.context().newCDPSession(this.page);
    this.cdp = cdp;
    cdp.on('Page.screencastFrame', async (f) => {
      const arquivo = join(this.pasta, `${String(this.quadros.length).padStart(5, '0')}.jpg`);
      writeFileSync(arquivo, Buffer.from(f.data, 'base64'));
      this.quadros.push({ arquivo, t: f.metadata.timestamp ?? Date.now() / 1000 });
      await cdp.send('Page.screencastFrameAck', { sessionId: f.sessionId }).catch(() => {});
    });
    await cdp.send('Page.startScreencast', {
      format: 'jpeg',
      quality: 92,
      maxWidth: 1080,
      maxHeight: 1920,
      everyNthFrame: 1,
    });
  }

  /** Para e monta o vídeo. Devolve o caminho do MP4. */
  async terminar(): Promise<string> {
    await this.cdp?.send('Page.stopScreencast');
    await this.page.waitForTimeout(300);
    if (this.quadros.length < 2) throw new Error(`Nenhum quadro gravado em ${this.nome}.`);
    // Cada quadro fica na tela até o próximo (o screencast só manda quadros
    // quando algo muda), e o último fica 1,5 s.
    const linhas: string[] = [];
    this.quadros.forEach((q, i) => {
      const prox = this.quadros[i + 1];
      const dur = prox ? Math.max(prox.t - q.t, 0.001) : 1.5;
      linhas.push(`file '${q.arquivo}'`, `duration ${dur.toFixed(4)}`);
    });
    linhas.push(`file '${this.quadros[this.quadros.length - 1].arquivo}'`);
    const lista = join(this.pasta, 'lista.txt');
    writeFileSync(lista, linhas.join('\n'));
    const mp4 = join(this.saida, `${this.nome}.mp4`);
    execFileSync('ffmpeg', [
      '-y', '-loglevel', 'error',
      '-f', 'concat', '-safe', '0', '-i', lista,
      '-vf', 'fps=30,scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=0x1b2440,format=yuv420p',
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-movflags', '+faststart',
      mp4,
    ]);
    rmSync(this.pasta, { recursive: true, force: true });
    return mp4;
  }
}
