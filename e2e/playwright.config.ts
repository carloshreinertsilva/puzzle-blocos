import { defineConfig } from '@playwright/test';

const PORT = 8790;

/**
 * Testes de ponta a ponta do jogo no navegador.
 * Antes de rodar: `npm run build` (gera ../build/web_test com a ponte de
 * testes ligada). Cada teste roda nos 4 tamanhos de tela abaixo.
 */
export default defineConfig({
  testDir: './tests',
  timeout: 120_000,
  expect: { timeout: 15_000 },
  fullyParallel: true,
  workers: process.env.CI ? 2 : 4,
  retries: process.env.CI ? 1 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: `http://localhost:${PORT}`,
    locale: 'pt-BR',
    deviceScaleFactor: 2,
    // The full Chromium, not the lighter headless shell: with the
    // WebAssembly renderer the shell crashed or froze about once every
    // 100 tests; the full browser ran 156 in a row without a problem.
    channel: 'chromium',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    launchOptions: {
      // Renderização por software: funciona em máquinas sem GPU (CI).
      args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader'],
    },
  },
  webServer: {
    command: `${process.platform === 'win32' ? 'python' : 'python3'} serve.py ${PORT} ../build/web_test`,
    port: PORT,
    reuseExistingServer: true,
  },
  projects: [
    { name: 'iphone-se', use: { viewport: { width: 375, height: 667 } } },
    { name: 'iphone-pro-max', use: { viewport: { width: 430, height: 932 } } },
    { name: 'android-pequeno', use: { viewport: { width: 360, height: 640 } } },
    // Tablet at 1x pixel density: at 2x it is the heaviest screen (1640x2360)
    // and, rendered without a GPU on CI's 2 cores, drags could time out.
    // Layout checks use CSS pixels, so they are unaffected.
    {
      name: 'tablet',
      use: { viewport: { width: 820, height: 1180 }, deviceScaleFactor: 1 },
    },
  ],
});
