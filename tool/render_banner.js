const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function renderBanner() {
  const browser = await chromium.launch({
    args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader']
  });
  const page = await browser.newPage({
    viewport: { width: 1024, height: 500 },
    deviceScaleFactor: 1
  });

  const svgContent = fs.readFileSync('art/loja/banner-1024x500.svg', 'utf8');
  await page.setContent(`<!DOCTYPE html><html><body style="margin:0;padding:0;overflow:hidden;background:#141842;">${svgContent}</body></html>`);
  await page.waitForTimeout(200);

  const out1 = 'art/loja/banner-1024x500.png';
  const out2 = 'docs/loja/banner-1024x500.png';
  await page.screenshot({ path: out1 });
  fs.copyFileSync(out1, out2);
  await browser.close();
  console.log('BANNER RENDERED SUCCESSFULLY');
}

renderBanner().catch(err => {
  console.error(err);
  process.exit(1);
});
