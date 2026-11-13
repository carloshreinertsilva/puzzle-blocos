import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import type { Locator, Page } from '@playwright/test';

/** Quadros por segundo dos vídeos (FPS=30 npm run clipes para 30). */
export const FPS = Number(process.env.FPS ?? 60);

/**
 * Lojas que aparecem no cartão final. O selo da App Store só pode ser
 * usado com o app já na loja (regra da Apple): ligue `appStore` quando a
 * revisão for aprovada (ou rode com APP_STORE=1).
 */
export const LOJAS = {
  googlePlay: true,
  appStore: process.env.APP_STORE === '1',
};

/** Convite padrão do cartão final (cada clipe pode passar o seu). */
export const CONVITE_PADRAO = 'Vem jogar com o <b>Capi</b>!';

/**
 * Arquivos da marca, em e2e/clipes/marca/: o ícone do jogo e, se
 * existirem, os selos oficiais das lojas (google-play.png, app-store.svg,
 * baixados das páginas de marca do Google e da Apple). Sem o selo, o cartão
 * escreve o nome da loja.
 */
function marca(appStore = LOJAS.appStore) {
  const pasta = join(__dirname, 'marca');
  // Um nome sem extensão: vale o .png ou o .svg que existir.
  const dado = (nome: string) => {
    for (const [ext, tipo] of [['png', 'image/png'], ['svg', 'image/svg+xml']]) {
      const f = join(pasta, `${nome}.${ext}`);
      if (existsSync(f)) return `data:${tipo};base64,${readFileSync(f).toString('base64')}`;
    }
    return '';
  };
  return {
    icone: dado('icone'),
    googlePlay: LOJAS.googlePlay ? dado('google-play') || 'texto' : '',
    appStore: appStore ? dado('app-store') || 'texto' : '',
  };
}

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
  // Quadro em que o vídeo começa (a logo entra aí) e em que o cartão final
  // de convite aparece (-1: ainda não).
  private inicio = 0;
  private fim = { de: -1, convite: CONVITE_PADRAO };

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
    await this.page.evaluate((m) => (window as any).__clipe.marca(m), marca());
    // A fonte do jogo, para a legenda (carrega em tempo real).
    await this.page.evaluate(() => (window as any).__clipe.fonte);
    this.inicio = this.n;
    await this.quadro();
  }

  /**
   * Avança [ms] do jogo sem gravar nada (um corte no vídeo), ou até [cond]
   * valer: esperas longas (a lâmpada da dica) e telas que não devem
   * aparecer (o anúncio de teste do vídeo de +10 segundos).
   */
  async pular(ms: number, cond?: () => Promise<boolean>) {
    for (let t = 0; t < ms; t += 100) {
      if (cond && (await cond())) return;
      await this.page.clock.runFor(100);
    }
    if (cond && !(await cond())) throw new Error(`${this.nome}: pulou ${ms} ms e nada.`);
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
    const intro = seg(this.n - this.inicio);
    const fim = this.fim.de >= 0 ? seg(this.n - this.fim.de) : -1;
    await this.page.evaluate((c) => (window as any).__clipe.desenhar(c), {
      x, y, dedo, escala, html, legenda: fim >= 0 ? 0 : legenda,
      intro, fim, convite: this.fim.convite,
    });
  }

  /**
   * Fecha o vídeo com o cartão de convite (logo, o Capi, [convite] e as
   * lojas) por [ms] e monta o MP4. Devolve o caminho do MP4.
   */
  async terminar(convite = CONVITE_PADRAO, ms = 3200): Promise<string> {
    await this.esperar(500);
    this.fim = { de: this.n, convite };
    await this.esperar(ms);
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
    .clipe-titulo { font: 44px/1 'Lilita One', sans-serif; color: #fff4cc;
      -webkit-text-stroke: 9px #2a1458; paint-order: stroke fill;
      letter-spacing: .5px; }
    #clipe-marca, #clipe-fim { position: fixed; inset: 0; display: flex;
      flex-direction: column; align-items: center; justify-content: center;
      pointer-events: none; opacity: 0; }
    #clipe-marca { z-index: 2147483645;
      background: radial-gradient(circle at 50% 46%, rgba(20,22,58,.62) 0,
        rgba(20,22,58,.25) 45%, rgba(20,22,58,0) 75%); }
    #clipe-marca .caixa, #clipe-fim .caixa { display: flex;
      flex-direction: column; align-items: center; gap: 10px; }
    #clipe-marca img { width: 132px; height: 132px; border-radius: 32px; }
    #clipe-fim { z-index: 2147483644; background: rgba(14,16,46,.86);
      backdrop-filter: blur(8px); text-align: center; }
    #clipe-fim .icone { width: 92px; height: 92px; border-radius: 24px; }
    #clipe-fim .titulo { font-size: 38px; }
    #clipe-fim .capi { width: 150px; height: 150px; object-fit: contain;
      margin: 2px 0 -6px; }
    #clipe-fim .convite { font: 30px/1.1 'Lilita One', sans-serif;
      color: #fff; -webkit-text-stroke: 6px #14163a; paint-order: stroke fill;
      padding: 0 22px; }
    #clipe-fim .convite b { color: #ffc94d; font-weight: normal; }
    #clipe-fim .gratis { font: 20px 'Lilita One', sans-serif; color: #8ce99a; }
    #clipe-fim .selos { display: flex; gap: 10px; margin-top: 4px; }
    #clipe-fim .selos { align-items: center; }
    #clipe-fim .selos img { height: 44px; }
    #clipe-fim .selo-texto { font: 17px/1.1 'Lilita One', sans-serif;
      color: #fff; background: #000; border: 2px solid #9aa0a6;
      border-radius: 10px; padding: 8px 12px; }
    #clipe-fim .bio { font: 17px 'Lilita One', sans-serif;
      color: rgba(255,255,255,.75); margin-top: 6px; }
  \`;
  document.head.appendChild(css);
  const dedo = document.createElement('div');
  dedo.id = 'clipe-dedo';
  const legenda = document.createElement('div');
  legenda.id = 'clipe-legenda';
  const marcaEl = document.createElement('div');
  marcaEl.id = 'clipe-marca';
  const fim = document.createElement('div');
  fim.id = 'clipe-fim';
  document.body.append(fim, marcaEl, legenda, dedo);
  const titulo = '<div class="clipe-titulo titulo">CapiBlocks</div>';
  const loja = (img, nome) => img === 'texto'
    ? '<span class="selo-texto">' + nome + '</span>'
    : '<img src="' + img + '" alt="' + nome + '">';
  const onda = (t, f) => Math.sin(t * f * Math.PI * 2);
  const entre = (v) => Math.max(0, Math.min(1, v));
  const fonte = new FontFace('Lilita One', 'url(assets/assets/fonts/LilitaOne-Regular.ttf)');
  window.__clipe = {
    fonte: fonte.load().then((f) => document.fonts.add(f)).catch(() => {}),
    marca(m) {
      const icone = m.icone ? '<img src="' + m.icone + '" alt="">' : '';
      marcaEl.innerHTML = '<div class="caixa">' + icone + titulo + '</div>';
      const selos = [m.googlePlay && loja(m.googlePlay, 'Google Play'),
        m.appStore && loja(m.appStore, 'App Store')].filter(Boolean).join('');
      fim.dataset.gratis = m.appStore ? 'Grátis no Android e no iPhone' : 'Grátis no Android';
      fim.innerHTML = '<div class="caixa">'
        + (m.icone ? '<img class="icone" src="' + m.icone + '" alt="">' : '')
        + titulo
        + '<img class="capi" src="assets/assets/capi/poses/comemora_caramelo.webp" alt="">'
        + '<div class="convite"></div>'
        + '<div class="gratis">' + fim.dataset.gratis + '</div>'
        + '<div class="selos">' + selos + '</div>'
        + '<div class="bio">link na bio</div></div>';
    },
    desenhar(c) {
      // A logo na abertura: entra com um pulo, brilha e sobe sumindo; o
      // jogo já aparece por trás, então o gancho não espera a marca.
      const a = c.intro;
      let op = 0, esc = 1, sobe = 0;
      if (a >= 0 && a < 1.6) {
        const sai = entre((a - 1.15) / 0.45);
        op = entre(a / 0.12) * (1 - sai);
        esc = a < 0.28 ? 0.55 + 0.53 * Math.sin((a / 0.28) * Math.PI / 2)
          : a < 0.45 ? 1.08 - 0.08 * ((a - 0.28) / 0.17)
          : 1 + 0.035 * onda(a - 0.45, 1.6);
        esc *= 1 - 0.35 * sai;
        sobe = -170 * sai * sai;
      }
      marcaEl.style.opacity = op;
      const brilho = 0.45 + 0.35 * (0.5 + 0.5 * onda(a, 1.8));
      const caixa = marcaEl.firstChild;
      if (caixa) {
        caixa.style.transform = 'translateY(' + sobe + 'px) scale(' + esc + ')';
        caixa.style.filter = 'drop-shadow(0 0 ' + (10 + 14 * brilho) + 'px rgba(255,201,77,' + brilho + '))';
      }
      // O cartão de convite no fim.
      const b = c.fim;
      fim.style.opacity = b < 0 ? 0 : entre(b / 0.3);
      if (b >= 0 && fim.firstChild) {
        const convite = fim.querySelector('.convite');
        if (convite.innerHTML !== c.convite) convite.innerHTML = c.convite;
        const pop = b < 0.35 ? 0.5 + 0.6 * Math.sin((b / 0.35) * Math.PI / 2)
          : b < 0.5 ? 1.1 - 0.1 * ((b - 0.35) / 0.15) : 1 + 0.03 * onda(b, 1.4);
        const icone = fim.querySelector('.icone');
        if (icone) icone.style.transform = 'scale(' + pop + ')';
        fim.querySelector('.titulo').style.transform = 'scale(' + pop + ')';
        fim.querySelector('.capi').style.transform =
          'translateY(' + (-14 * Math.abs(onda(b, 1.2))) + 'px)';
        const entra = entre((b - 0.45) / 0.3);
        convite.style.opacity = entra;
        convite.style.transform = 'translateY(' + (24 * (1 - entra)) + 'px)';
        const lojas = entre((b - 0.75) / 0.3);
        const selos = fim.querySelector('.selos');
        selos.style.opacity = lojas;
        selos.style.transform = 'translateY(' + (30 * (1 - lojas)) + 'px) scale('
          + (1 + 0.04 * onda(b, 1.4) * lojas) + ')';
        fim.querySelector('.gratis').style.opacity = lojas;
        fim.querySelector('.bio').style.opacity = lojas;
      }
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

/** Para a prévia do cartão sem o jogo (clipes/previa.ts). */
export const marcaParaPrevia = (appStore: boolean) => marca(appStore);
export const CAMADA_PARA_PREVIA = CAMADA;
