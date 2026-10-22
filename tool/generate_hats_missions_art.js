const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const artDir = path.join(__dirname, '..', 'art');
const missionsDir = path.join(artDir, 'missions');
const hatsDir = path.join(artDir, 'hats');

for (const d of [missionsDir, hatsDir]) {
  if (!fs.existsSync(d)) {
    fs.mkdirSync(d, { recursive: true });
  }
}

// 1. Ícone de Missões Diárias (Pergaminho / Prancheta com Checkmarks e Estrelas)
const missionsSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bgGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#4f46e5"/>
      <stop offset="100%" stop-color="#7c3aed"/>
    </linearGradient>
    <linearGradient id="boardGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#d97706"/>
      <stop offset="100%" stop-color="#92400e"/>
    </linearGradient>
    <linearGradient id="paperGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="100%" stop-color="#f1f5f9"/>
    </linearGradient>
    <linearGradient id="checkGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#34d399"/>
      <stop offset="100%" stop-color="#059669"/>
    </linearGradient>
    <linearGradient id="starGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#fde047"/>
      <stop offset="100%" stop-color="#eab308"/>
    </linearGradient>
  </defs>

  <!-- Background Circle -->
  <circle cx="256" cy="256" r="236" fill="url(#bgGrad)" stroke="#1e1b4b" stroke-width="12"/>
  <circle cx="256" cy="256" r="218" fill="none" stroke="#a5b4fc" stroke-width="4" opacity="0.4"/>

  <!-- Clipboard Backing -->
  <g transform="translate(256, 266)">
    <!-- Shadow -->
    <rect x="-142" y="-172" width="284" height="344" rx="28" fill="#0f172a" opacity="0.4" transform="translate(0, 16)"/>
    <!-- Board -->
    <rect x="-140" y="-170" width="280" height="340" rx="28" fill="url(#boardGrad)" stroke="#1e1b4b" stroke-width="10"/>
    
    <!-- Paper Sheet -->
    <rect x="-116" y="-130" width="232" height="280" rx="18" fill="url(#paperGrad)" stroke="#1e1b4b" stroke-width="7"/>

    <!-- Clip at top -->
    <rect x="-60" y="-188" width="120" height="42" rx="12" fill="#e2e8f0" stroke="#1e1b4b" stroke-width="8"/>
    <circle cx="0" cy="-167" r="10" fill="#94a3b8" stroke="#1e1b4b" stroke-width="4"/>

    <!-- 3 Daily Mission Checklist Items -->
    <!-- Item 1 -->
    <g transform="translate(-86, -80)">
      <circle cx="0" cy="0" r="18" fill="url(#checkGrad)" stroke="#1e1b4b" stroke-width="5"/>
      <path d="M -8 -1 L -2 6 L 9 -6" fill="none" stroke="#ffffff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
      <rect x="28" y="-7" width="110" height="14" rx="7" fill="#64748b"/>
    </g>

    <!-- Item 2 -->
    <g transform="translate(-86, -10)">
      <circle cx="0" cy="0" r="18" fill="url(#checkGrad)" stroke="#1e1b4b" stroke-width="5"/>
      <path d="M -8 -1 L -2 6 L 9 -6" fill="none" stroke="#ffffff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
      <rect x="28" y="-7" width="90" height="14" rx="7" fill="#64748b"/>
    </g>

    <!-- Item 3 -->
    <g transform="translate(-86, 60)">
      <circle cx="0" cy="0" r="18" fill="url(#checkGrad)" stroke="#1e1b4b" stroke-width="5"/>
      <path d="M -8 -1 L -2 6 L 9 -6" fill="none" stroke="#ffffff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
      <rect x="28" y="-7" width="120" height="14" rx="7" fill="#64748b"/>
    </g>
  </g>

  <!-- Big Glowing Star at Bottom Right -->
  <g transform="translate(360, 360)">
    <path d="M 0 -54 L 16 -18 L 54 -14 L 26 14 L 33 52 L 0 32 L -33 52 L -26 14 L -54 -14 L -16 -18 Z" 
          fill="url(#starGrad)" stroke="#1e1b4b" stroke-width="8"/>
    <!-- Star shine highlight -->
    <path d="M 0 -42 L 10 -14 L 40 -11 L 18 10 L 23 40 L 0 24 L -23 40 L -18 10 L -40 -11 L -10 -14 Z" 
          fill="#fef08a" opacity="0.6"/>
  </g>

  <!-- Sparkles -->
  <polygon points="120,100 125,114 139,120 125,126 120,140 115,126 101,120 115,114" fill="#ffffff" stroke="#1e1b4b" stroke-width="3"/>
  <polygon points="380,120 384,130 395,135 384,140 380,150 376,140 365,135 376,130" fill="#ffffff" stroke="#1e1b4b" stroke-width="3"/>
</svg>`;

// 2. Ícone do Baú Diário de Tesouros
const chestSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bgChestGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#1e3a8a"/>
      <stop offset="100%" stop-color="#0f172a"/>
    </linearGradient>
    <linearGradient id="woodGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#b45309"/>
      <stop offset="100%" stop-color="#78350f"/>
    </linearGradient>
    <linearGradient id="goldGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#fde047"/>
      <stop offset="100%" stop-color="#ca8a04"/>
    </linearGradient>
    <linearGradient id="glowGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#fef08a"/>
      <stop offset="100%" stop-color="#38bdf8"/>
    </linearGradient>
  </defs>

  <!-- Background Circle -->
  <circle cx="256" cy="256" r="236" fill="url(#bgChestGrad)" stroke="#090d16" stroke-width="12"/>
  <circle cx="256" cy="256" r="218" fill="none" stroke="#60a5fa" stroke-width="4" opacity="0.3"/>

  <!-- Golden Ray Burst / Glow behind Chest -->
  <g opacity="0.6">
    <polygon points="256,230 190,70 230,60" fill="#fde047" opacity="0.4"/>
    <polygon points="256,230 260,50 300,60" fill="#fde047" opacity="0.4"/>
    <polygon points="256,230 360,90 390,120" fill="#fde047" opacity="0.4"/>
    <polygon points="256,230 120,110 150,85" fill="#fde047" opacity="0.4"/>
  </g>

  <!-- Chest Body (Bottom base) -->
  <g transform="translate(256, 320)">
    <!-- Shadow -->
    <ellipse cx="0" cy="100" rx="180" ry="32" fill="#000000" opacity="0.5"/>
    
    <!-- Chest Base Container -->
    <path d="M -150 0 L 150 0 L 130 90 C 130 100 -130 100 -130 90 Z" fill="url(#woodGrad)" stroke="#090d16" stroke-width="10"/>

    <!-- Gold Straps Base -->
    <path d="M -115 0 L -100 88" stroke="url(#goldGrad)" stroke-width="20" stroke-linecap="round"/>
    <path d="M 115 0 L 100 88" stroke="url(#goldGrad)" stroke-width="20" stroke-linecap="round"/>
    <path d="M -115 0 L -100 88" stroke="#090d16" stroke-width="20" stroke-linecap="round" fill="none" opacity="0.2"/>

    <!-- Golden Lock Plate -->
    <rect x="-24" y="-12" width="48" height="42" rx="10" fill="url(#goldGrad)" stroke="#090d16" stroke-width="6"/>
    <circle cx="0" cy="4" r="5" fill="#090d16"/>
    <polygon points="-3,4 3,4 2,16 -2,16" fill="#090d16"/>
  </g>

  <!-- Chest Open Lid (Tilted back) -->
  <g transform="translate(256, 215)">
    <!-- Inner Chest Glow -->
    <ellipse cx="0" cy="4" rx="130" ry="24" fill="url(#glowGrad)" opacity="0.9"/>

    <!-- Open Top Lid -->
    <path d="M -150 -10 C -150 -70 150 -70 150 -10 L 140 10 C 140 -40 -140 -40 -140 10 Z" fill="url(#woodGrad)" stroke="#090d16" stroke-width="10"/>
    
    <!-- Gold Lid Straps -->
    <path d="M -110 5 C -110 -50 -110 -50 -105 -55" stroke="url(#goldGrad)" stroke-width="16" fill="none"/>
    <path d="M 110 5 C 110 -50 110 -50 105 -55" stroke="url(#goldGrad)" stroke-width="16" fill="none"/>
  </g>

  <!-- Gems & Stars bursting from chest -->
  <!-- Center Star -->
  <g transform="translate(256, 170)">
    <path d="M 0 -36 L 11 -12 L 36 -9 L 18 9 L 22 34 L 0 21 L -22 34 L -18 9 L -36 -9 L -11 -12 Z" 
          fill="url(#goldGrad)" stroke="#090d16" stroke-width="6"/>
  </g>
  <!-- Ruby Diamond Left -->
  <polygon points="180,180 195,160 210,180 195,200" fill="#ef4444" stroke="#090d16" stroke-width="5"/>
  <!-- Sapphire Diamond Right -->
  <polygon points="310,165 328,145 346,165 328,185" fill="#38bdf8" stroke="#090d16" stroke-width="5"/>
  <!-- Emerald Block -->
  <rect x="235" y="110" width="26" height="26" rx="6" fill="#10b981" stroke="#090d16" stroke-width="5" transform="rotate(25 248 123)"/>
</svg>`;

// 3. Ícone do Guarda-Roupa / Coleção de Chapéus do Capi
const hatsSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bgHatGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#f59e0b"/>
      <stop offset="100%" stop-color="#ea580c"/>
    </linearGradient>
    <linearGradient id="crownGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#fde047"/>
      <stop offset="100%" stop-color="#eab308"/>
    </linearGradient>
    <linearGradient id="partyGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#38bdf8"/>
      <stop offset="100%" stop-color="#ec4899"/>
    </linearGradient>
    <linearGradient id="helmetGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#ffd43b"/>
      <stop offset="100%" stop-color="#f59f00"/>
    </linearGradient>
  </defs>

  <!-- Background Circle -->
  <circle cx="256" cy="256" r="236" fill="url(#bgHatGrad)" stroke="#451a03" stroke-width="12"/>
  <circle cx="256" cy="256" r="218" fill="none" stroke="#fef08a" stroke-width="4" opacity="0.4"/>

  <!-- Pedestal / Hat Stand -->
  <g transform="translate(256, 370)">
    <ellipse cx="0" cy="20" rx="120" ry="24" fill="#000000" opacity="0.3"/>
    <path d="M -80 15 L 80 15 L 60 -10 L -60 -10 Z" fill="#78350f" stroke="#451a03" stroke-width="8"/>
    <rect x="-14" y="-80" width="28" height="75" rx="6" fill="#92400e" stroke="#451a03" stroke-width="7"/>
  </g>

  <!-- Royal Crown (Center Top) -->
  <g transform="translate(256, 230)">
    <!-- Crown Body -->
    <path d="M -110 30 L -120 -40 L -60 0 L 0 -60 L 60 0 L 120 -40 L 110 30 Z" 
          fill="url(#crownGrad)" stroke="#451a03" stroke-width="10" stroke-linejoin="round"/>
    
    <!-- Crown Base Band -->
    <rect x="-115" y="24" width="230" height="34" rx="10" fill="#ca8a04" stroke="#451a03" stroke-width="8"/>

    <!-- Jewels on Crown Points -->
    <circle cx="-120" cy="-44" r="12" fill="#ef4444" stroke="#451a03" stroke-width="5"/>
    <circle cx="0" cy="-64" r="15" fill="#38bdf8" stroke="#451a03" stroke-width="6"/>
    <circle cx="120" cy="-44" r="12" fill="#ef4444" stroke="#451a03" stroke-width="5"/>

    <!-- Jewels in Band -->
    <circle cx="-70" cy="41" r="9" fill="#10b981" stroke="#451a03" stroke-width="4"/>
    <circle cx="0" cy="41" r="11" fill="#ef4444" stroke="#451a03" stroke-width="4"/>
    <circle cx="70" cy="41" r="9" fill="#10b981" stroke="#451a03" stroke-width="4"/>
  </g>

  <!-- Mini Hard Hat (Left) -->
  <g transform="translate(130, 310) rotate(-15)">
    <path d="M -45 5 C -45 -25 45 -25 45 5 Z" fill="url(#helmetGrad)" stroke="#451a03" stroke-width="7"/>
    <rect x="-52" y="3" width="104" height="12" rx="6" fill="#f59f00" stroke="#451a03" stroke-width="5"/>
  </g>

  <!-- Mini Party Hat (Right) -->
  <g transform="translate(380, 310) rotate(15)">
    <polygon points="-35,15 35,15 0,-55" fill="url(#partyGrad)" stroke="#451a03" stroke-width="7"/>
    <circle cx="0" cy="-60" r="10" fill="#fde047" stroke="#451a03" stroke-width="4"/>
    <path d="M -22 0 L 22 0" stroke="#ffffff" stroke-width="5" stroke-linecap="round"/>
    <path d="M -12 -25 L 12 -25" stroke="#fde047" stroke-width="4" stroke-linecap="round"/>
  </g>

  <!-- Sparkles -->
  <polygon points="120,130 126,144 140,150 126,156 120,170 114,156 100,150 114,144" fill="#ffffff" stroke="#451a03" stroke-width="3"/>
  <polygon points="380,120 385,132 397,137 385,142 380,154 375,142 363,137 375,132" fill="#ffffff" stroke="#451a03" stroke-width="3"/>
</svg>`;

const jobs = [
  { dir: missionsDir, name: 'icone-missoes', svg: missionsSvg },
  { dir: missionsDir, name: 'icone-bau', svg: chestSvg },
  { dir: hatsDir, name: 'icone-chapeus', svg: hatsSvg },
];

for (const job of jobs) {
  const svgPath = path.join(job.dir, `${job.name}.svg`);
  const vcPath = path.join(job.dir, `${job.name}.vectorcraft`);
  const pngPath = path.join(job.dir, `${job.name}.png`);
  const png128Path = path.join(job.dir, `${job.name}-128.png`);

  fs.writeFileSync(svgPath, job.svg, 'utf8');
  console.log(`Saved ${svgPath}`);

  try {
    execSync(`vectorcraft-cli convert "${svgPath}" "${vcPath}"`, { stdio: 'inherit' });
    execSync(`vectorcraft-cli convert "${svgPath}" "${pngPath}" --scale 1`, { stdio: 'inherit' });
    execSync(`vectorcraft-cli convert "${svgPath}" "${png128Path}" --scale 0.25`, { stdio: 'inherit' });
    console.log(`Converted ${job.name} -> vectorcraft and pngs`);
  } catch (e) {
    console.error(`Error converting ${job.name}:`, e.message);
  }
}
