import { defineConfig } from '@playwright/test';

const PORT = 8790;

/**
 * Capturas de tela das lojas (não roda no CI):
 *   npm run build && npm run loja
 * Telas cruas (1080x1920) em e2e/loja/saida/<idioma>/; depois
 * `node ../tool/loja_montar.js` monta as capturas com a faixa de texto.
 */
export default defineConfig({
  testDir: './loja',
  timeout: 180_000,
  workers: 1,
  retries: 0,
  reporter: [['list']],
  use: {
    baseURL: `http://localhost:${PORT}`,
    channel: 'chromium',
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
