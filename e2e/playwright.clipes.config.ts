import { defineConfig } from '@playwright/test';

const PORT = 8790;

/**
 * Clipes do jogo para as redes sociais (não roda no CI):
 *   npm run build && npm run clipes
 * Os vídeos (1080x1920, MP4) ficam em e2e/clipes/saida/. Precisa do ffmpeg.
 */
export default defineConfig({
  testDir: './clipes',
  timeout: 300_000,
  workers: 1,
  retries: 0,
  reporter: [['list']],
  use: {
    baseURL: `http://localhost:${PORT}`,
    locale: 'pt-BR',
    channel: 'chromium',
    // 360x640 a 3x = 1080x1920, o tamanho dos vídeos verticais.
    viewport: { width: 360, height: 640 },
    deviceScaleFactor: 3,
    launchOptions: { args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader'] },
  },
  webServer: {
    command: `${process.platform === 'win32' ? 'python' : 'python3'} serve.py ${PORT} ../build/web_test`,
    port: PORT,
    reuseExistingServer: true,
  },
});
