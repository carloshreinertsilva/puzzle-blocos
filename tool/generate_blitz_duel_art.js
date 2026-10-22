const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const artDir = path.join(__dirname, '..', 'art');
const blitzDir = path.join(artDir, 'blitz');
const dueloDir = path.join(artDir, 'duelo');

for (const d of [blitzDir, dueloDir]) {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
}

// 1. Ícone do Modo Blitz (Cronômetro + Raio veloz + Capi com óculos de velocidade)
const blitzSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="clockGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#2a3356"/>
      <stop offset="100%" stop-color="#141938"/>
    </linearGradient>
    <linearGradient id="ringGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ff922b"/>
      <stop offset="50%" stop-color="#ffd43b"/>
      <stop offset="100%" stop-color="#ff6b6b"/>
    </linearGradient>
    <linearGradient id="boltGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#fff3bf"/>
      <stop offset="30%" stop-color="#ffd43b"/>
      <stop offset="100%" stop-color="#f59f00"/>
    </linearGradient>
    <linearGradient id="fireGrad" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0%" stop-color="#ff6b6b"/>
      <stop offset="60%" stop-color="#ffa94d"/>
      <stop offset="100%" stop-color="#ffd43b"/>
    </linearGradient>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="14" stdDeviation="10" flood-color="#000000" flood-opacity="0.3"/>
    </filter>
  </defs>

  <g filter="url(#shadow)">
    <!-- Motion trails / Speed lines -->
    <path d="M 90 200 C 60 210 50 250 80 270" fill="none" stroke="#ffd43b" stroke-width="10" stroke-linecap="round" opacity="0.6"/>
    <path d="M 70 290 C 45 310 40 340 75 360" fill="none" stroke="#ffa94d" stroke-width="12" stroke-linecap="round" opacity="0.7"/>
    <path d="M 110 390 C 80 410 75 440 115 450" fill="none" stroke="#ff6b6b" stroke-width="10" stroke-linecap="round" opacity="0.5"/>

    <!-- Outer Speed Flames Behind Clock -->
    <path d="M 230 70 C 210 20 270 10 280 50 C 310 10 360 40 340 85 Z" fill="url(#fireGrad)" stroke="#4a2a12" stroke-width="8"/>

    <!-- Clock Top Button / Crown -->
    <rect x="232" y="44" width="48" height="32" rx="10" fill="#ffd43b" stroke="#4a2a12" stroke-width="10"/>
    <rect x="242" y="24" width="28" height="24" rx="8" fill="#ff922b" stroke="#4a2a12" stroke-width="8"/>

    <!-- Main Stopwatch Body -->
    <circle cx="256" cy="270" r="180" fill="url(#ringGrad)" stroke="#4a2a12" stroke-width="16"/>
    <circle cx="256" cy="270" r="150" fill="url(#clockGrad)" stroke="#4a2a12" stroke-width="10"/>

    <!-- Inner Radial Dial Ticks -->
    <circle cx="256" cy="270" r="136" fill="none" stroke="#ffffff" stroke-width="4" stroke-dasharray="6 22" opacity="0.4"/>
    <circle cx="256" cy="144" r="6" fill="#ffd43b"/>
    <circle cx="382" cy="270" r="6" fill="#ffd43b"/>
    <circle cx="256" cy="396" r="6" fill="#ffd43b"/>
    <circle cx="130" cy="270" r="6" fill="#ffd43b"/>

    <!-- Big Digital "60s" or Energy Lightning Bolt Across Center -->
    <!-- Stylized Mighty Lightning Bolt -->
    <path d="M 285 130 L 195 270 L 255 270 L 210 405 L 340 245 L 275 245 Z" 
          fill="url(#boltGrad)" stroke="#4a2a12" stroke-width="12" stroke-linejoin="round"/>
    <!-- Bolt Inner Highlight -->
    <path d="M 275 150 L 215 255 L 265 255 L 235 365 L 315 255 L 265 255 Z" 
          fill="#ffffff" opacity="0.6"/>

    <!-- Speed Sparkles -->
    <path d="M 390 140 L 400 160 L 420 170 L 400 180 L 390 200 L 380 180 L 360 170 L 380 160 Z" fill="#ffffff" stroke="#4a2a12" stroke-width="5"/>
    <path d="M 120 150 L 128 165 L 145 172 L 128 180 L 120 195 L 112 180 L 95 172 L 112 165 Z" fill="#ffd43b" stroke="#4a2a12" stroke-width="5"/>
    <circle cx="410" cy="350" r="10" fill="#ffd43b" stroke="#4a2a12" stroke-width="4"/>

    <!-- Badge Text "60s" Ribbon at Bottom -->
    <g transform="translate(256, 435)">
      <rect x="-80" y="-24" width="160" height="48" rx="20" fill="#ff6b6b" stroke="#4a2a12" stroke-width="8"/>
      <text x="0" y="10" font-family="Arial, sans-serif" font-weight="900" font-size="28" fill="#ffffff" text-anchor="middle" stroke="#4a2a12" stroke-width="2">60s BLITZ</text>
    </g>
  </g>
</svg>`;

// 2. Ícone do Modo Duelo (Bandeiras / Ferramentas Cruzadas com Escudo e "VS")
const dueloSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="shieldGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#339af0"/>
      <stop offset="50%" stop-color="#1c7ed6"/>
      <stop offset="100%" stop-color="#1864ab"/>
    </linearGradient>
    <linearGradient id="goldBorder" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ffe066"/>
      <stop offset="50%" stop-color="#fcc419"/>
      <stop offset="100%" stop-color="#d9480f"/>
    </linearGradient>
    <linearGradient id="swordBlade1" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="50%" stop-color="#dee2e6"/>
      <stop offset="100%" stop-color="#adb5bd"/>
    </linearGradient>
    <linearGradient id="vsGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ff8787"/>
      <stop offset="50%" stop-color="#fa5252"/>
      <stop offset="100%" stop-color="#c92a2a"/>
    </linearGradient>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="14" stdDeviation="10" flood-color="#000000" flood-opacity="0.3"/>
    </filter>
  </defs>

  <g filter="url(#shadow)">
    <!-- Crossed Swords / Builder Rulers in Background -->
    <!-- Sword Left to Right -->
    <g transform="rotate(45 256 256)">
      <rect x="242" y="50" width="28" height="340" rx="6" fill="url(#swordBlade1)" stroke="#4a2a12" stroke-width="8"/>
      <path d="M 242 50 L 256 25 L 270 50 Z" fill="#ffffff" stroke="#4a2a12" stroke-width="8"/>
      <rect x="220" y="380" width="72" height="18" rx="6" fill="#ffd43b" stroke="#4a2a12" stroke-width="8"/>
      <rect x="246" y="398" width="20" height="55" rx="5" fill="#845ef7" stroke="#4a2a12" stroke-width="7"/>
      <circle cx="256" cy="460" r="14" fill="#ffd43b" stroke="#4a2a12" stroke-width="7"/>
    </g>

    <!-- Sword Right to Left -->
    <g transform="rotate(-45 256 256)">
      <rect x="242" y="50" width="28" height="340" rx="6" fill="url(#swordBlade1)" stroke="#4a2a12" stroke-width="8"/>
      <path d="M 242 50 L 256 25 L 270 50 Z" fill="#ffffff" stroke="#4a2a12" stroke-width="8"/>
      <rect x="220" y="380" width="72" height="18" rx="6" fill="#ffd43b" stroke="#4a2a12" stroke-width="8"/>
      <rect x="246" y="398" width="20" height="55" rx="5" fill="#ff6b6b" stroke="#4a2a12" stroke-width="7"/>
      <circle cx="256" cy="460" r="14" fill="#ffd43b" stroke="#4a2a12" stroke-width="7"/>
    </g>

    <!-- Central Crest Shield -->
    <path d="M 256 90 
             C 360 90 380 130 380 230 
             C 380 340 290 410 256 430 
             C 222 410 132 340 132 230 
             C 132 130 152 90 256 90 Z" 
          fill="url(#goldBorder)" stroke="#4a2a12" stroke-width="16"/>

    <path d="M 256 112 
             C 345 112 360 145 360 230 
             C 360 325 285 388 256 405 
             C 227 388 152 325 152 230 
             C 152 145 167 112 256 112 Z" 
          fill="url(#shieldGrad)" stroke="#4a2a12" stroke-width="10"/>

    <!-- Capi Builder Head Silhouette inside shield -->
    <g transform="translate(256, 215)">
      <!-- Yellow Hardhat -->
      <path d="M -50 0 C -50 -45 50 -45 50 0 Z" fill="#ffd43b" stroke="#4a2a12" stroke-width="8"/>
      <line x1="-60" y1="0" x2="60" y2="0" stroke="#4a2a12" stroke-width="9" stroke-linecap="round"/>
      <path d="M -10 -40 C -10 -48 10 -48 10 -40" fill="none" stroke="#4a2a12" stroke-width="7" stroke-linecap="round"/>
      
      <!-- Capi snout and ears -->
      <circle cx="-42" cy="5" r="12" fill="#c08457" stroke="#4a2a12" stroke-width="6"/>
      <circle cx="42" cy="5" r="12" fill="#c08457" stroke="#4a2a12" stroke-width="6"/>
      <rect x="-42" y="0" width="84" height="60" rx="24" fill="#d99b6d" stroke="#4a2a12" stroke-width="8"/>
      <!-- Eyes confident -->
      <ellipse cx="-18" cy="22" rx="5" ry="7" fill="#4a2a12"/>
      <ellipse cx="18" cy="22" rx="5" ry="7" fill="#4a2a12"/>
      <circle cx="-16" cy="19" r="2" fill="#ffffff"/>
      <circle cx="20" cy="19" r="2" fill="#ffffff"/>
      <!-- Snout -->
      <ellipse cx="0" cy="42" rx="16" ry="10" fill="#a0633b"/>
      <ellipse cx="0" cy="38" rx="8" ry="5" fill="#4a2a12"/>
    </g>

    <!-- Bold "VS" Emblem over bottom of shield -->
    <g transform="translate(256, 330)">
      <circle cx="0" cy="0" r="48" fill="url(#vsGrad)" stroke="#ffd43b" stroke-width="8"/>
      <circle cx="0" cy="0" r="48" fill="none" stroke="#4a2a12" stroke-width="12"/>
      <text x="0" y="14" font-family="Arial, sans-serif" font-weight="900" font-size="38" fill="#ffffff" text-anchor="middle" stroke="#4a2a12" stroke-width="3">VS</text>
    </g>

    <!-- Sparkles -->
    <path d="M 100 120 L 108 135 L 125 142 L 108 150 L 100 165 L 92 150 L 75 142 L 92 135 Z" fill="#ffd43b" stroke="#4a2a12" stroke-width="4"/>
    <path d="M 400 100 L 407 115 L 422 122 L 407 130 L 400 145 L 393 130 L 378 122 L 393 115 Z" fill="#ffd43b" stroke="#4a2a12" stroke-width="4"/>
  </g>
</svg>`;

// 3. Troféu Duelo
const trofeuSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="goldCup" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#fff3bf"/>
      <stop offset="30%" stop-color="#ffd43b"/>
      <stop offset="70%" stop-color="#f59f00"/>
      <stop offset="100%" stop-color="#d9480f"/>
    </linearGradient>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="14" stdDeviation="10" flood-color="#000000" flood-opacity="0.3"/>
    </filter>
  </defs>

  <g filter="url(#shadow)">
    <!-- Confetti in air -->
    <rect x="90" y="90" width="16" height="16" rx="4" fill="#ff6b6b" transform="rotate(25 90 90)"/>
    <rect x="400" y="80" width="14" height="14" rx="3" fill="#339af0" transform="rotate(-35 400 80)"/>
    <circle cx="140" cy="60" r="8" fill="#ffd43b"/>
    <circle cx="370" cy="50" r="7" fill="#51cf66"/>
    <rect x="80" y="240" width="12" height="18" rx="3" fill="#cc5de8" transform="rotate(45 80 240)"/>
    <rect x="420" y="230" width="14" height="14" rx="3" fill="#ffd43b" transform="rotate(15 420 230)"/>

    <!-- Handles -->
    <path d="M 160 160 C 80 160 80 280 160 280" fill="none" stroke="url(#goldCup)" stroke-width="26" stroke-linecap="round"/>
    <path d="M 160 160 C 80 160 80 280 160 280" fill="none" stroke="#4a2a12" stroke-width="12" stroke-linecap="round"/>

    <path d="M 352 160 C 432 160 432 280 352 280" fill="none" stroke="url(#goldCup)" stroke-width="26" stroke-linecap="round"/>
    <path d="M 352 160 C 432 160 432 280 352 280" fill="none" stroke="#4a2a12" stroke-width="12" stroke-linecap="round"/>

    <!-- Cup Body -->
    <path d="M 150 110 L 362 110 C 362 250 310 310 256 320 C 202 310 150 250 150 110 Z" 
          fill="url(#goldCup)" stroke="#4a2a12" stroke-width="14"/>
    <ellipse cx="256" cy="110" rx="106" ry="24" fill="#ffe066" stroke="#4a2a12" stroke-width="12"/>

    <!-- Star Emblem on Cup -->
    <path d="M 256 160 L 267 190 L 298 193 L 274 213 L 281 243 L 256 227 L 231 243 L 238 213 L 214 193 L 245 190 Z" 
          fill="#ffffff" stroke="#4a2a12" stroke-width="6"/>

    <!-- Stem & Base -->
    <rect x="236" y="320" width="40" height="55" rx="6" fill="url(#goldCup)" stroke="#4a2a12" stroke-width="12"/>
    <!-- Pedestal Base -->
    <path d="M 180 430 L 200 375 L 312 375 L 332 430 Z" fill="#2b334a" stroke="#4a2a12" stroke-width="14"/>
    <rect x="160" y="424" width="192" height="40" rx="12" fill="#1b2133" stroke="#4a2a12" stroke-width="14"/>
    <!-- Gold Nameplate on Pedestal -->
    <rect x="190" y="434" width="132" height="20" rx="6" fill="#ffd43b" stroke="#4a2a12" stroke-width="5"/>
    <text x="256" y="449" font-family="Arial, sans-serif" font-weight="900" font-size="12" fill="#4a2a12" text-anchor="middle">VENCEDOR</text>
  </g>
</svg>`;

const jobs = [
  { dir: blitzDir, name: 'icone-blitz', svg: blitzSvg },
  { dir: dueloDir, name: 'icone-duelo', svg: dueloSvg },
  { dir: dueloDir, name: 'trofeu-duelo', svg: trofeuSvg },
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
