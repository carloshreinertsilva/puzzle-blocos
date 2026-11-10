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
  // O dedo na tela: onde está, desde que quadro está apertado / foi solto.
  private dedo = { x: 0, y: 0, apertouEm: -1, soltouEm: -1 };
  // Legenda de abertura: texto e os quadros em que aparece e some.
  private texto = { html: '', de: 0, ate: -1 };

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
    // O relógio ainda corre enquanto isto roda: se o ponto de pausa já
    // passou, tenta de novo um pouco mais à frente.
    for (let folga = 50; ; folga *= 4) {
      const agora = await this.page.evaluate(() => Date.now());
      try {
        await this.page.clock.pauseAt(agora + folga);
        break;
      } catch (e) {
        if (folga > 5000) throw e;
      }
    }
    await this.page.evaluate(CAMADA);
    // A fonte do jogo, para a legenda (carrega em tempo real).
    await this.page.evaluate(() => (window as any).__clipe.fonte);
    await this.quadro();
  }

  /** Anda um quadro e o fotografa. */
  async quadro() {
    await this.page.clock.runFor(1000 / FPS);
    // O desenho termina em tarefas marcadas para logo depois do quadro.
    for (let i = 0; i < 3; i++) await this.page.clock.runFor(0);
    await this.desenharCamada();
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
    await this.apertar(x, y, async () => {
      await this.page.mouse.move(x, y);
      await this.page.mouse.down();
      await this.esperar(100);
      await this.page.mouse.up();
    });
    await this.esperar(depoisMs);
  }

  /** Arrasta de [de] até [para] em [ms], como um dedo (anda junto com os quadros). */
  async arrastar(de: { x: number; y: number }, para: { x: number; y: number }, ms = 520) {
    const m = this.page.mouse;
    await this.apertar(de.x, de.y, async () => {
      await m.move(de.x, de.y);
      await m.down();
      await this.esperar(100);
      const passos = Math.max(2, Math.round((ms * FPS) / 1000));
      for (let i = 1; i <= passos; i++) {
        // Sai devagar, acelera e chega devagar.
        const t = i / passos;
        const e = t < 0.5 ? 2 * t * t : 1 - (-2 * t + 2) ** 2 / 2;
        const x = de.x + (para.x - de.x) * e;
        const y = de.y + (para.y - de.y) * e;
        await m.move(x, y);
        this.dedo.x = x;
        this.dedo.y = y;
        await this.quadro();
      }
      await this.esperar(120);
      await m.up();
    });
  }

  /**
   * Mostra o dedo apertando em (x, y) enquanto [acao] roda. Para toques que
   * o jogo recebe por outro caminho (a ponte de testes), use com uma ação
   * que só grava quadros.
   */
  async apertar(x: number, y: number, acao: () => Promise<void>) {
    this.dedo = { x, y, apertouEm: this.n, soltouEm: -1 };
    await acao();
    this.dedo.soltouEm = this.n;
  }

  /** Uma legenda grande no alto do vídeo por [ms] (aceita <b>destaque</b>; sem emoji, a fonte do jogo não tem). */
  legenda(html: string, ms = 2600) {
    this.texto = { html, de: this.n, ate: this.n + Math.round((ms * FPS) / 1000) };
  }

  /** Põe o dedo e a legenda no quadro atual (animados pelo número do quadro). */
  private async desenharCamada() {
    const seg = (quadros: number) => quadros / FPS;
    const { x, y, apertouEm, soltouEm } = this.dedo;
    let dedo = 0;
    let escala = 1;
    if (apertouEm >= 0) {
      const desde = seg(this.n - apertouEm);
      if (soltouEm < 0) {
        dedo = Math.min(1, desde / 0.08);
        escala = 1 - 0.18 * Math.min(1, desde / 0.1);
      } else {
        const depois = seg(this.n - soltouEm);
        dedo = Math.max(0, 1 - depois / 0.18);
        escala = 0.82 + 0.3 * Math.min(1, depois / 0.18);
      }
    }
    const { html, de, ate } = this.texto;
    let legenda = 0;
    if (html && this.n >= de) {
      const entrada = Math.min(1, seg(this.n - de) / 0.25);
      const saida = Math.max(0, Math.min(1, seg(ate - this.n) / 0.3));
      legenda = Math.min(entrada, saida);
    }
    await this.page.evaluate((c) => (window as any).__clipe.desenhar(c), {
      x, y, dedo, escala, html, legenda,
    });
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

/**
 * Camada por cima do jogo com o dedo (para quem assiste ver de onde a peça
 * sai) e a legenda de abertura. É desenhada quadro a quadro pelo Gravador;
 * nada aqui tem animação própria, que andaria fora do relógio do vídeo.
 */
const CAMADA = `(() => {
  if (window.__clipe) return;
  const css = document.createElement('style');
  css.textContent = \`
    #clipe-dedo { position: fixed; left: 0; top: 0; width: 44px; height: 44px;
      margin: -22px 0 0 -22px; border-radius: 50%; pointer-events: none;
      z-index: 2147483647; background: rgba(255,255,255,.38);
      border: 3px solid rgba(255,255,255,.95);
      box-shadow: 0 2px 10px rgba(0,0,0,.4); opacity: 0; }
    #clipe-legenda { position: fixed; left: 20px; right: 20px; top: 21%;
      text-align: center; pointer-events: none; z-index: 2147483646;
      font: 30px/1.12 'Lilita One', sans-serif; color: #fff;
      -webkit-text-stroke: 6px #14163a; paint-order: stroke fill;
      opacity: 0; }
    #clipe-legenda span { display: inline-block; padding: 10px 16px 12px;
      border-radius: 18px; background: rgba(14, 16, 46, .78);
      box-shadow: 0 6px 18px rgba(0,0,0,.45); }
    #clipe-legenda b { color: #ffc94d; font-weight: normal; }
  \`;
  document.head.appendChild(css);
  const dedo = document.createElement('div');
  dedo.id = 'clipe-dedo';
  const legenda = document.createElement('div');
  legenda.id = 'clipe-legenda';
  document.body.append(dedo, legenda);
  const fonte = new FontFace('Lilita One', 'url(assets/assets/fonts/LilitaOne-Regular.ttf)');
  window.__clipe = {
    fonte: fonte.load().then((f) => document.fonts.add(f)).catch(() => {}),
    desenhar(c) {
      dedo.style.left = c.x + 'px';
      dedo.style.top = c.y + 'px';
      dedo.style.opacity = c.dedo;
      dedo.style.transform = 'scale(' + c.escala + ')';
      const html = '<span>' + c.html + '</span>';
      if (legenda.innerHTML !== html) legenda.innerHTML = html;
      legenda.style.opacity = c.legenda;
      legenda.style.transform = 'scale(' + (0.88 + 0.12 * c.legenda) + ')';
    },
  };
})()`;
