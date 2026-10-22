const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const toolsDir = path.join(__dirname, '..', 'art', 'tools');
if (!fs.existsSync(toolsDir)) {
  fs.mkdirSync(toolsDir, { recursive: true });
}

// 1. Martelo (Hammer)
const marteloSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="headGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ffd95a"/>
      <stop offset="50%" stop-color="#f5b21e"/>
      <stop offset="100%" stop-color="#d48208"/>
    </linearGradient>
    <linearGradient id="faceGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#e0e8f0"/>
      <stop offset="50%" stop-color="#9eb2c0"/>
      <stop offset="100%" stop-color="#627888"/>
    </linearGradient>
    <linearGradient id="handleGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#e8b886"/>
      <stop offset="50%" stop-color="#c88e52"/>
      <stop offset="100%" stop-color="#9a622a"/>
    </linearGradient>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="12" stdDeviation="10" flood-color="#000000" flood-opacity="0.25"/>
    </filter>
  </defs>

  <g filter="url(#shadow)">
    <!-- Motion lines -->
    <path d="M 380 90 A 240 240 0 0 1 450 180" fill="none" stroke="#ffd95a" stroke-width="12" stroke-linecap="round" stroke-dasharray="16 12"/>
    <path d="M 405 70 A 260 260 0 0 1 480 160" fill="none" stroke="#ffffff" stroke-width="8" stroke-linecap="round" opacity="0.8"/>

    <!-- Sparkles on impact -->
    <path d="M 420 180 L 432 205 L 457 217 L 432 229 L 420 254 L 408 229 L 383 217 L 408 205 Z" fill="#ffd43b" stroke="#4a2a12" stroke-width="6"/>
    <path d="M 450 130 L 456 145 L 471 151 L 456 157 L 450 172 L 444 157 L 429 151 L 444 145 Z" fill="#ffffff" stroke="#4a2a12" stroke-width="5"/>
    <circle cx="360" cy="130" r="8" fill="#ffd95a"/>
    <circle cx="475" cy="245" r="7" fill="#ff922b"/>

    <!-- Hammer Handle -->
    <!-- Shadow beneath handle -->
    <line x1="230" y1="240" x2="90" y2="420" stroke="#000000" stroke-width="38" stroke-linecap="round" opacity="0.15"/>
    <!-- Main wooden handle -->
    <line x1="235" y1="235" x2="95" y2="415" stroke="#4a2a12" stroke-width="44" stroke-linecap="round"/>
    <line x1="235" y1="235" x2="95" y2="415" stroke="url(#handleGrad)" stroke-width="32" stroke-linecap="round"/>
    <!-- Grip wraps -->
    <line x1="165" y1="325" x2="145" y2="351" stroke="#4a2a12" stroke-width="8" stroke-linecap="round"/>
    <line x1="145" y1="351" x2="125" y2="377" stroke="#4a2a12" stroke-width="8" stroke-linecap="round"/>
    <line x1="125" y1="377" x2="105" y2="403" stroke="#4a2a12" stroke-width="8" stroke-linecap="round"/>
    <!-- Pommel cap -->
    <circle cx="95" cy="415" r="22" fill="#ffd95a" stroke="#4a2a12" stroke-width="8"/>
    <circle cx="95" cy="415" r="10" fill="#f5b21e"/>

    <!-- Hammer Head (angled group) -->
    <g transform="translate(260, 205) rotate(-38)">
      <!-- Back claw / peen -->
      <path d="M -90 -35 C -120 -20 -130 10 -115 35 L -80 25 Z" fill="url(#faceGrad)" stroke="#4a2a12" stroke-width="10" stroke-linejoin="round"/>
      <!-- Main golden block -->
      <rect x="-85" y="-45" width="170" height="90" rx="20" fill="url(#headGrad)" stroke="#4a2a12" stroke-width="10"/>
      <!-- Center safety band -->
      <rect x="-25" y="-45" width="50" height="90" fill="#f08c00" stroke="#4a2a12" stroke-width="10"/>
      <line x1="-15" y1="-45" x2="15" y2="45" stroke="#ffd95a" stroke-width="12" opacity="0.8"/>
      <!-- Metallic strike face -->
      <path d="M 85 -40 L 120 -35 C 130 -15 130 15 120 35 L 85 40 Z" fill="url(#faceGrad)" stroke="#4a2a12" stroke-width="10" stroke-linejoin="round"/>
      <!-- Shine highlight -->
      <rect x="-70" y="-35" width="140" height="14" rx="7" fill="#ffffff" opacity="0.6"/>
    </g>
  </g>
</svg>`;

// 2. Girar Peça (Rotate)
const girarSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="arrowGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#4facfe"/>
      <stop offset="100%" stop-color="#00f2fe"/>
    </linearGradient>
    <linearGradient id="arrowGrad2" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ffd95a"/>
      <stop offset="100%" stop-color="#f5b21e"/>
    </linearGradient>
    <linearGradient id="blockGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ff9a44"/>
      <stop offset="100%" stop-color="#e8590c"/>
    </linearGradient>
    <filter id="glow" x="-15%" y="-15%" width="130%" height="130%">
      <feDropShadow dx="0" dy="10" stdDeviation="12" flood-color="#000000" flood-opacity="0.25"/>
    </filter>
  </defs>

  <g filter="url(#glow)">
    <!-- Outer rotation track -->
    <circle cx="256" cy="256" r="195" fill="none" stroke="#22b8cf" stroke-width="14" stroke-dasharray="24 16" opacity="0.4"/>

    <!-- Arrow 1 (top-right arc, clockwise) -->
    <path d="M 120 180 A 185 185 0 0 1 390 150" fill="none" stroke="url(#arrowGrad)" stroke-width="36" stroke-linecap="round"/>
    <path d="M 120 180 A 185 185 0 0 1 390 150" fill="none" stroke="#4a2a12" stroke-width="48" stroke-linecap="round" style="mix-blend-mode: destination-over;"/>
    <!-- Arrowhead 1 -->
    <path d="M 370 110 L 440 160 L 370 210 Z" fill="url(#arrowGrad)" stroke="#4a2a12" stroke-width="10" stroke-linejoin="round"/>

    <!-- Arrow 2 (bottom-left arc, clockwise) -->
    <path d="M 392 332 A 185 185 0 0 1 122 362" fill="none" stroke="url(#arrowGrad2)" stroke-width="36" stroke-linecap="round"/>
    <path d="M 392 332 A 185 185 0 0 1 122 362" fill="none" stroke="#4a2a12" stroke-width="48" stroke-linecap="round" style="mix-blend-mode: destination-over;"/>
    <!-- Arrowhead 2 -->
    <path d="M 142 402 L 72 352 L 142 302 Z" fill="url(#arrowGrad2)" stroke="#4a2a12" stroke-width="10" stroke-linejoin="round"/>

    <!-- Center Rotating Puzzle Piece (T-piece or L-piece angled) -->
    <g transform="translate(256, 256) rotate(25)">
      <!-- Drop shadow -->
      <rect x="-70" y="-70" width="140" height="140" rx="24" fill="#000000" opacity="0.18" transform="translate(0, 14)"/>
      <!-- Main block 1 -->
      <rect x="-65" y="-65" width="65" height="65" rx="14" fill="url(#blockGrad)" stroke="#4a2a12" stroke-width="8"/>
      <rect x="-58" y="-58" width="51" height="14" rx="7" fill="#ffffff" opacity="0.6"/>
      <!-- Main block 2 -->
      <rect x="0" y="-65" width="65" height="65" rx="14" fill="url(#blockGrad)" stroke="#4a2a12" stroke-width="8"/>
      <rect x="7" y="-58" width="51" height="14" rx="7" fill="#ffffff" opacity="0.6"/>
      <!-- Main block 3 -->
      <rect x="0" y="0" width="65" height="65" rx="14" fill="url(#blockGrad)" stroke="#4a2a12" stroke-width="8"/>
      <rect x="7" y="7" width="51" height="14" rx="7" fill="#ffffff" opacity="0.6"/>
      <!-- Main block 4 -->
      <rect x="-65" y="0" width="65" height="65" rx="14" fill="url(#blockGrad)" stroke="#4a2a12" stroke-width="8"/>
      <rect x="-58" y="7" width="51" height="14" rx="7" fill="#ffffff" opacity="0.6"/>

      <!-- Center pivot screw / button -->
      <circle cx="0" cy="0" r="22" fill="#ffd95a" stroke="#4a2a12" stroke-width="7"/>
      <circle cx="0" cy="0" r="10" fill="#f5b21e"/>
    </g>

    <!-- Sparkles -->
    <path d="M 440 290 L 448 305 L 463 313 L 448 321 L 440 336 L 432 321 L 417 313 L 432 305 Z" fill="#ffd43b" stroke="#4a2a12" stroke-width="5"/>
    <circle cx="80" cy="210" r="8" fill="#ffd95a"/>
  </g>
</svg>`;

// 3. Trocar Peças (Reroll / Swap Tray)
const trocarSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="blockA" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ff6b6b"/>
      <stop offset="100%" stop-color="#c92a2a"/>
    </linearGradient>
    <linearGradient id="blockB" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#38d9a9"/>
      <stop offset="100%" stop-color="#099268"/>
    </linearGradient>
    <linearGradient id="blockC" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#da77f2"/>
      <stop offset="100%" stop-color="#862e9c"/>
    </linearGradient>
    <linearGradient id="swapArrow" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ffd95a"/>
      <stop offset="100%" stop-color="#f59f00"/>
    </linearGradient>
    <filter id="trocarShadow" x="-15%" y="-15%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="12" flood-color="#000000" flood-opacity="0.25"/>
    </filter>
  </defs>

  <g filter="url(#trocarShadow)">
    <!-- Swirling cyclical arrows -->
    <!-- Path from Top to Right -->
    <path d="M 285 110 C 375 125 410 200 405 270" fill="none" stroke="url(#swapArrow)" stroke-width="26" stroke-linecap="round"/>
    <path d="M 405 270 L 425 240 M 405 270 L 375 255" stroke="url(#swapArrow)" stroke-width="24" stroke-linecap="round"/>
    <!-- Path from Right to Bottom-Left -->
    <path d="M 360 360 C 290 430 190 420 135 365" fill="none" stroke="url(#swapArrow)" stroke-width="26" stroke-linecap="round"/>
    <!-- Path from Bottom-Left to Top -->
    <path d="M 115 315 C 90 220 145 130 220 100" fill="none" stroke="url(#swapArrow)" stroke-width="26" stroke-linecap="round"/>

    <!-- Three blocks in triangle orbit -->
    <!-- Block 1: Top (Red/Orange) -->
    <g transform="translate(256, 115)">
      <rect x="-42" y="-42" width="84" height="84" rx="18" fill="url(#blockA)" stroke="#4a2a12" stroke-width="9"/>
      <rect x="-32" y="-32" width="64" height="18" rx="9" fill="#ffffff" opacity="0.6"/>
      <circle cx="0" cy="0" r="14" fill="#ffffff" opacity="0.8"/>
    </g>

    <!-- Block 2: Bottom-Right (Cyan/Green) -->
    <g transform="translate(365, 335)">
      <rect x="-42" y="-42" width="84" height="84" rx="18" fill="url(#blockB)" stroke="#4a2a12" stroke-width="9"/>
      <rect x="-32" y="-32" width="64" height="18" rx="9" fill="#ffffff" opacity="0.6"/>
      <circle cx="0" cy="0" r="14" fill="#ffffff" opacity="0.8"/>
    </g>

    <!-- Block 3: Bottom-Left (Purple) -->
    <g transform="translate(147, 335)">
      <rect x="-42" y="-42" width="84" height="84" rx="18" fill="url(#blockC)" stroke="#4a2a12" stroke-width="9"/>
      <rect x="-32" y="-32" width="64" height="18" rx="9" fill="#ffffff" opacity="0.6"/>
      <circle cx="0" cy="0" r="14" fill="#ffffff" opacity="0.8"/>
    </g>

    <!-- Center Shuffle Icon -->
    <circle cx="256" cy="275" r="42" fill="#ffffff" stroke="#4a2a12" stroke-width="9"/>
    <!-- Cute swap icon inside center -->
    <path d="M 235 260 L 275 260 M 265 250 L 275 260 L 265 270" fill="none" stroke="#f59f00" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M 275 290 L 235 290 M 245 280 L 235 290 L 245 300" fill="none" stroke="#22b8cf" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>

    <!-- Stars -->
    <path d="M 256 25 L 264 45 L 285 53 L 264 61 L 256 81 L 248 61 L 227 53 L 248 45 Z" fill="#ffd43b" stroke="#4a2a12" stroke-width="6"/>
  </g>
</svg>`;

// 4. Pá 3x3 (Shovel 3x3)
const paSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bladeGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ffd95a"/>
      <stop offset="60%" stop-color="#f5b21e"/>
      <stop offset="100%" stop-color="#d48208"/>
    </linearGradient>
    <linearGradient id="steelGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#f1f3f5"/>
      <stop offset="50%" stop-color="#ced4da"/>
      <stop offset="100%" stop-color="#868e96"/>
    </linearGradient>
    <linearGradient id="handleShovel" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#e8b886"/>
      <stop offset="100%" stop-color="#a87446"/>
    </linearGradient>
    <filter id="shovelGlow" x="-15%" y="-15%" width="130%" height="130%">
      <feDropShadow dx="0" dy="12" stdDeviation="12" flood-color="#000000" flood-opacity="0.25"/>
    </filter>
  </defs>

  <g filter="url(#shovelGlow)">
    <!-- 3x3 Blueprint Target Grid behind shovel tip -->
    <g transform="translate(80, 240) scale(0.72)">
      <!-- Background glow -->
      <rect x="0" y="0" width="300" height="300" rx="28" fill="#1864ab" fill-opacity="0.35" stroke="#339af0" stroke-width="8" stroke-dasharray="16 10"/>
      <!-- Grid 3x3 cells -->
      <rect x="15" y="15" width="80" height="80" rx="14" fill="#4dabf7" fill-opacity="0.4" stroke="#ffffff" stroke-width="5"/>
      <rect x="110" y="15" width="80" height="80" rx="14" fill="#4dabf7" fill-opacity="0.4" stroke="#ffffff" stroke-width="5"/>
      <rect x="205" y="15" width="80" height="80" rx="14" fill="#4dabf7" fill-opacity="0.4" stroke="#ffffff" stroke-width="5"/>

      <rect x="15" y="110" width="80" height="80" rx="14" fill="#4dabf7" fill-opacity="0.4" stroke="#ffffff" stroke-width="5"/>
      <!-- Center target cell -->
      <rect x="110" y="110" width="80" height="80" rx="14" fill="#ffd43b" fill-opacity="0.75" stroke="#ffffff" stroke-width="6"/>
      <circle cx="150" cy="150" r="14" fill="#f59f00"/>
      <rect x="205" y="110" width="80" height="80" rx="14" fill="#4dabf7" fill-opacity="0.4" stroke="#ffffff" stroke-width="5"/>

      <rect x="15" y="205" width="80" height="80" rx="14" fill="#4dabf7" fill-opacity="0.4" stroke="#ffffff" stroke-width="5"/>
      <rect x="110" y="205" width="80" height="80" rx="14" fill="#4dabf7" fill-opacity="0.4" stroke="#ffffff" stroke-width="5"/>
      <rect x="205" y="205" width="80" height="80" rx="14" fill="#4dabf7" fill-opacity="0.4" stroke="#ffffff" stroke-width="5"/>

      <!-- "3x3" Badge on corner -->
      <g transform="translate(230, 230)">
        <circle cx="28" cy="28" r="32" fill="#ffd43b" stroke="#4a2a12" stroke-width="7"/>
        <text x="28" y="37" font-family="Lilita, sans-serif" font-size="24" font-weight="bold" fill="#4a2a12" text-anchor="middle">3x3</text>
      </g>
    </g>

    <!-- Shovel angled across (from top-right down to center-left) -->
    <!-- D-Grip at Top Right -->
    <g transform="translate(390, 80) rotate(-35)">
      <path d="M -30 -30 C -30 -60 30 -60 30 -30 L 30 10 L -30 10 Z" fill="url(#bladeGrad)" stroke="#4a2a12" stroke-width="10"/>
      <ellipse cx="0" cy="-32" rx="16" ry="12" fill="#ffffff" opacity="0.7"/>
      <rect x="-16" y="8" width="32" height="30" rx="6" fill="#868e96" stroke="#4a2a12" stroke-width="8"/>
    </g>

    <!-- Handle Shaft -->
    <line x1="370" y1="105" x2="225" y2="295" stroke="#4a2a12" stroke-width="36" stroke-linecap="round"/>
    <line x1="370" y1="105" x2="225" y2="295" stroke="url(#handleShovel)" stroke-width="24" stroke-linecap="round"/>
    <line x1="365" y1="105" x2="230" y2="285" stroke="#ffffff" stroke-width="6" stroke-linecap="round" opacity="0.6"/>

    <!-- Shovel Collar / Socket -->
    <polygon points="210,270 245,295 220,325 185,300" fill="url(#steelGrad)" stroke="#4a2a12" stroke-width="10"/>

    <!-- Heavy-Duty Blade Spade Head -->
    <g transform="translate(190, 340) rotate(-35)">
      <!-- Blade scoop -->
      <path d="M -60 -40 C -70 20 -40 70 0 95 C 40 70 70 20 60 -40 Z" fill="url(#bladeGrad)" stroke="#4a2a12" stroke-width="10" stroke-linejoin="round"/>
      <!-- Steel wear edge -->
      <path d="M -45 50 C -25 75 0 90 0 90 C 0 90 25 75 45 50 L 50 65 C 25 90 0 102 0 102 C 0 102 -25 90 -50 65 Z" fill="url(#steelGrad)" stroke="#4a2a12" stroke-width="8"/>
      <!-- Center spine ridge -->
      <line x1="0" y1="-30" x2="0" y2="70" stroke="#4a2a12" stroke-width="8" stroke-linecap="round"/>
      <!-- Highlight -->
      <path d="M -42 -25 C -45 10 -25 45 -5 60" fill="none" stroke="#ffffff" stroke-width="8" stroke-linecap="round" opacity="0.6"/>
    </g>

    <!-- Dirt / Rocks debris particles -->
    <circle cx="100" cy="380" r="10" fill="#a87446" stroke="#4a2a12" stroke-width="5"/>
    <circle cx="135" cy="450" r="14" fill="#7a4c26" stroke="#4a2a12" stroke-width="6"/>
    <circle cx="220" cy="450" r="9" fill="#c88e52" stroke="#4a2a12" stroke-width="5"/>
    <path d="M 70 410 L 80 425 L 95 430 L 80 435 L 70 450 L 60 435 L 45 430 L 60 425 Z" fill="#ffd43b" stroke="#4a2a12" stroke-width="5"/>
  </g>
</svg>`;

// 5. Mochila / Caixa de Ferramentas (Toolbox)
const mochilaSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="boxGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ffd95a"/>
      <stop offset="60%" stop-color="#f5b21e"/>
      <stop offset="100%" stop-color="#e09a12"/>
    </linearGradient>
    <linearGradient id="lidGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ff922b"/>
      <stop offset="100%" stop-color="#d9480f"/>
    </linearGradient>
    <linearGradient id="leatherGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#8e5a30"/>
      <stop offset="100%" stop-color="#4a2a12"/>
    </linearGradient>
    <filter id="boxShadow" x="-15%" y="-15%" width="130%" height="130%">
      <feDropShadow dx="0" dy="14" stdDeviation="14" flood-color="#000000" flood-opacity="0.25"/>
    </filter>
  </defs>

  <g filter="url(#boxShadow)">
    <!-- Tools sticking out behind box -->
    <!-- Hammer sticking out top-left -->
    <g transform="translate(170, 150) rotate(-28)">
      <rect x="-12" y="-120" width="24" height="120" rx="8" fill="#c88e52" stroke="#4a2a12" stroke-width="8"/>
      <rect x="-35" y="-155" width="70" height="38" rx="10" fill="#ffd95a" stroke="#4a2a12" stroke-width="8"/>
    </g>
    <!-- Ruler sticking out top-right -->
    <g transform="translate(340, 150) rotate(22)">
      <rect x="-14" y="-130" width="28" height="130" rx="6" fill="#ffd43b" stroke="#4a2a12" stroke-width="8"/>
      <line x1="-14" y1="-110" x2="-2" y2="-110" stroke="#4a2a12" stroke-width="4"/>
      <line x1="-14" y1="-90" x2="4" y2="-90" stroke="#4a2a12" stroke-width="4"/>
      <line x1="-14" y1="-70" x2="-2" y2="-70" stroke="#4a2a12" stroke-width="4"/>
      <line x1="-14" y1="-50" x2="4" y2="-50" stroke="#4a2a12" stroke-width="4"/>
    </g>

    <!-- Handle on Top -->
    <path d="M 200 170 C 200 115 312 115 312 170" fill="none" stroke="#4a2a12" stroke-width="32" stroke-linecap="round"/>
    <path d="M 200 170 C 200 115 312 115 312 170" fill="none" stroke="url(#leatherGrad)" stroke-width="20" stroke-linecap="round"/>

    <!-- Main Toolbox Body -->
    <rect x="90" y="210" width="332" height="210" rx="36" fill="url(#boxGrad)" stroke="#4a2a12" stroke-width="12"/>
    <!-- Lid / Rim -->
    <rect x="76" y="180" width="360" height="60" rx="20" fill="url(#lidGrad)" stroke="#4a2a12" stroke-width="12"/>
    <rect x="95" y="190" width="322" height="14" rx="7" fill="#ffffff" opacity="0.6"/>

    <!-- Metal Reinforced Corner Brackets -->
    <path d="M 90 270 L 130 270 L 130 310" fill="none" stroke="#4a2a12" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M 422 270 L 382 270 L 382 310" fill="none" stroke="#4a2a12" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="115" cy="290" r="6" fill="#e0e8f0"/>
    <circle cx="397" cy="290" r="6" fill="#e0e8f0"/>

    <!-- Center Leather Strap & Buckle -->
    <rect x="226" y="176" width="60" height="248" rx="14" fill="url(#leatherGrad)" stroke="#4a2a12" stroke-width="10"/>
    <!-- Metal Buckle / Clasp -->
    <rect x="216" y="240" width="80" height="56" rx="12" fill="#ffd95a" stroke="#4a2a12" stroke-width="10"/>
    <rect x="234" y="254" width="44" height="28" rx="6" fill="#4a2a12"/>
    <circle cx="256" cy="268" r="6" fill="#ffd95a"/>

    <!-- Capi Builder Paw / Cap Badge on Box -->
    <g transform="translate(160, 335)">
      <!-- Builder Cap icon -->
      <path d="M -25 10 C -25 -20 25 -20 25 10 Z" fill="#ffd95a" stroke="#4a2a12" stroke-width="6"/>
      <line x1="-32" y1="10" x2="32" y2="10" stroke="#4a2a12" stroke-width="7" stroke-linecap="round"/>
    </g>

    <!-- Stars & sparkles -->
    <path d="M 435 155 L 443 170 L 458 178 L 443 186 L 435 201 L 427 186 L 412 178 L 427 170 Z" fill="#ffd43b" stroke="#4a2a12" stroke-width="5"/>
    <circle cx="85" cy="150" r="8" fill="#ffd95a"/>
  </g>
</svg>`;

const files = [
  { name: 'ferramenta-martelo', svg: marteloSvg },
  { name: 'ferramenta-girar', svg: girarSvg },
  { name: 'ferramenta-trocar', svg: trocarSvg },
  { name: 'ferramenta-pa', svg: paSvg },
  { name: 'mochila-ferramentas', svg: mochilaSvg }
];

for (const f of files) {
  const svgPath = path.join(toolsDir, `${f.name}.svg`);
  const vcPath = path.join(toolsDir, `${f.name}.vectorcraft`);
  const pngPath = path.join(toolsDir, `${f.name}.png`);
  fs.writeFileSync(svgPath, f.svg, 'utf8');
  console.log(`Wrote ${svgPath}`);

  // Convert to .vectorcraft
  try {
    execSync(`vectorcraft-cli convert "${svgPath}" "${vcPath}"`, { stdio: 'inherit' });
    execSync(`vectorcraft-cli convert "${svgPath}" "${pngPath}" --scale 1`, { stdio: 'inherit' });
    const png128Path = path.join(toolsDir, `${f.name}-128.png`);
    execSync(`vectorcraft-cli convert "${svgPath}" "${png128Path}" --scale 0.25`, { stdio: 'inherit' });
    console.log(`Generated ${vcPath}, ${pngPath} and ${png128Path}`);
  } catch (err) {
    console.error(`Error processing ${f.name}:`, err.message);
  }
}
