const fs = require('fs');

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 500" width="1024" height="500">
  <defs>
    <!-- Background Gradient -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#141842" />
      <stop offset="50%" stop-color="#1F1654" />
      <stop offset="100%" stop-color="#31124D" />
    </linearGradient>

    <!-- Radial Glow behind Logo -->
    <radialGradient id="glowLogo" cx="35%" cy="50%" r="45%">
      <stop offset="0%" stop-color="#4F46E5" stop-opacity="0.35" />
      <stop offset="100%" stop-color="#141842" stop-opacity="0" />
    </radialGradient>

    <!-- Radial Glow behind Capi -->
    <radialGradient id="glowCapi" cx="72%" cy="50%" r="45%">
      <stop offset="0%" stop-color="#F59E0B" stop-opacity="0.30" />
      <stop offset="100%" stop-color="#31124D" stop-opacity="0" />
    </radialGradient>

    <!-- Gold Text Gradient -->
    <linearGradient id="goldText" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFFBEB" />
      <stop offset="35%" stop-color="#FDE047" />
      <stop offset="100%" stop-color="#D97706" />
    </linearGradient>

    <!-- Capivara fur gradient -->
    <linearGradient id="capiFur" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#B45309" />
      <stop offset="100%" stop-color="#78350F" />
    </linearGradient>

    <!-- Snout gradient -->
    <linearGradient id="capiSnout" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#78350F" />
      <stop offset="100%" stop-color="#451A03" />
    </linearGradient>

    <!-- Helmet gradient -->
    <linearGradient id="helmetGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FEF08A" />
      <stop offset="40%" stop-color="#FACC15" />
      <stop offset="100%" stop-color="#CA8A04" />
    </linearGradient>

    <!-- Isometric Grass Block Gradients -->
    <linearGradient id="grassTop" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#4ADE80" />
      <stop offset="100%" stop-color="#22C55E" />
    </linearGradient>
    <linearGradient id="dirtLeft" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#854D0E" />
      <stop offset="100%" stop-color="#543007" />
    </linearGradient>
    <linearGradient id="dirtRight" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#A16207" />
      <stop offset="100%" stop-color="#713F12" />
    </linearGradient>

    <!-- Drop Shadows -->
    <filter id="shadow3D" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="8" stdDeviation="6" flood-color="#090514" flood-opacity="0.65" />
    </filter>
    <filter id="glowStar" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="0" stdDeviation="4" flood-color="#FDE047" flood-opacity="0.9" />
    </filter>
  </defs>

  <!-- Background Base -->
  <rect width="1024" height="500" fill="url(#bgGrad)" />
  <rect width="1024" height="500" fill="url(#glowLogo)" />
  <rect width="1024" height="500" fill="url(#glowCapi)" />

  <!-- Background Floating Puzzle Blocks (Subtle & Thematic) -->
  <g opacity="0.25">
    <!-- Blue Block -->
    <polygon points="120,70 160,50 200,70 160,90" fill="#60A5FA" />
    <polygon points="120,70 160,90 160,130 120,110" fill="#2563EB" />
    <polygon points="160,90 200,70 200,110 160,130" fill="#1D4ED8" />

    <!-- Yellow Block -->
    <polygon points="860,80 900,60 940,80 900,100" fill="#FDE047" />
    <polygon points="860,80 900,100 900,140 860,120" fill="#EAB308" />
    <polygon points="900,100 940,80 940,120 900,140" fill="#CA8A04" />

    <!-- Purple Block -->
    <polygon points="90,380 130,360 170,380 130,400" fill="#C084FC" />
    <polygon points="90,380 130,400 130,440 90,420" fill="#9333EA" />
    <polygon points="130,400 170,380 170,420 130,440" fill="#7E22CE" />

    <!-- Red Block -->
    <polygon points="920,390 955,370 990,390 955,410" fill="#F87171" />
    <polygon points="920,390 955,410 955,445 920,425" fill="#DC2626" />
    <polygon points="955,410 990,390 990,425 955,445" fill="#B91C1C" />

    <!-- Cyan Block Top Center -->
    <polygon points="490,45 520,30 550,45 520,60" fill="#38BDF8" />
    <polygon points="490,45 520,60 520,90 490,75" fill="#0284C7" />
    <polygon points="520,60 550,45 550,75 520,90" fill="#0369A1" />
  </g>

  <!-- Stars & Sparkles -->
  <g fill="#FDE047" filter="url(#glowStar)">
    <polygon points="260,80 264,88 272,90 265,96 267,104 260,99 253,104 255,96 248,90 256,88" transform="scale(0.8) translate(70, 20)" />
    <polygon points="440,110 443,116 450,117 444,122 446,128 440,124 434,128 436,122 430,117 437,116" transform="scale(0.6) translate(290, 40)" />
    <polygon points="800,90 803,96 810,97 804,102 806,108 800,104 794,108 796,102 790,97 797,96" />
    <polygon points="630,70 633,76 640,77 634,82 636,88 630,84 624,88 626,82 620,77 627,76" transform="scale(0.7) translate(270, 20)" />
    <circle cx="210" cy="180" r="2.5" />
    <circle cx="480" cy="150" r="3" />
    <circle cx="750" cy="120" r="2.5" />
    <circle cx="910" cy="220" r="3" />
  </g>

  <!-- ================= RIGHT SIDE: CAPI & ISOMETRIC ISLAND ================= -->
  <g transform="translate(680, 200)" filter="url(#shadow3D)">
    <!-- Isometric Floating Island Base -->
    <g transform="translate(0, 110)">
      <!-- Top Grass Diamond -->
      <polygon points="0,-35 150,45 0,125 -150,45" fill="url(#grassTop)" stroke="#86EFAC" stroke-width="2" />
      <!-- Left Dirt Wall -->
      <polygon points="-150,45 0,125 0,200 -150,120" fill="url(#dirtLeft)" />
      <!-- Right Dirt Wall -->
      <polygon points="0,125 150,45 150,120 0,200" fill="url(#dirtRight)" />
      <!-- Stone layer accents in dirt -->
      <polygon points="-100,85 -60,105 -60,125 -100,105" fill="#4B5563" opacity="0.6" />
      <polygon points="60,105 100,85 100,105 60,125" fill="#374151" opacity="0.6" />
      
      <!-- Flower & Plant decorations on island -->
      <circle cx="-60" cy="40" r="6" fill="#F43F5E" />
      <circle cx="-60" cy="40" r="2.5" fill="#FEF08A" />
      <circle cx="70" cy="50" r="6" fill="#38BDF8" />
      <circle cx="70" cy="50" r="2.5" fill="#FEF08A" />
      <circle cx="-10" cy="20" r="7" fill="#FB923C" />
      <circle cx="-10" cy="20" r="3" fill="#FEF08A" />
    </g>

    <!-- Isometric Tower Stack on island (behind Capi) -->
    <g transform="translate(90, 30)">
      <!-- Block 1 (Cyan) -->
      <polygon points="0,-16 28,-1 0,14 -28,-1" fill="#38BDF8" />
      <polygon points="-28,-1 0,14 0,34 -28,19" fill="#0284C7" />
      <polygon points="0,14 28,-1 28,19 0,34" fill="#0369A1" />
      <!-- Block 2 (Purple) -->
      <g transform="translate(0, -22)">
        <polygon points="0,-14 24,-1 0,12 -24,-1" fill="#C084FC" />
        <polygon points="-24,-1 0,12 0,30 -24,17" fill="#9333EA" />
        <polygon points="0,12 24,-1 24,17 0,30" fill="#7E22CE" />
      </g>
      <!-- Block 3 (Yellow Top) -->
      <g transform="translate(0, -42)">
        <polygon points="0,-12 20,-1 0,10 -20,-1" fill="#FDE047" />
        <polygon points="-20,-1 0,10 0,26 -20,15" fill="#EAB308" />
        <polygon points="0,10 20,-1 20,15 0,26" fill="#CA8A04" />
      </g>
    </g>

    <!-- CAPI THE CAPYBARA (Hero Character) -->
    <g transform="translate(-25, -20)">
      <!-- Body -->
      <ellipse cx="0" cy="70" rx="65" ry="55" fill="url(#capiFur)" stroke="#451A03" stroke-width="4" />

      <!-- Little Front Paws resting -->
      <ellipse cx="-35" cy="115" rx="14" ry="9" fill="#78350F" stroke="#451A03" stroke-width="3" />
      <ellipse cx="35" cy="115" rx="14" ry="9" fill="#78350F" stroke="#451A03" stroke-width="3" />

      <!-- Head Base -->
      <path d="M -50,20 C -55,-25 55,-25 50,20 C 50,60 -50,60 -50,20 Z" fill="url(#capiFur)" stroke="#451A03" stroke-width="4" />

      <!-- Big Friendly Snout -->
      <rect x="-38" y="5" width="76" height="42" rx="16" fill="url(#capiSnout)" stroke="#270F04" stroke-width="3.5" />
      <!-- Nostrils -->
      <ellipse cx="-16" cy="22" rx="5" ry="3.5" fill="#1C0A02" />
      <ellipse cx="16" cy="22" rx="5" ry="3.5" fill="#1C0A02" />
      <!-- Big Cute Smile -->
      <path d="M -14,35 Q 0,44 14,35" fill="none" stroke="#270F04" stroke-width="3.5" stroke-linecap="round" />

      <!-- Rosy Cheeks -->
      <circle cx="-42" cy="28" r="9" fill="#F43F5E" opacity="0.45" />
      <circle cx="42" cy="28" r="9" fill="#F43F5E" opacity="0.45" />

      <!-- Happy Eyes (Arched Cheerful) -->
      <path d="M -30,-5 Q -22,-16 -14,-5" fill="none" stroke="#270F04" stroke-width="4.5" stroke-linecap="round" />
      <path d="M 14,-5 Q 22,-16 30,-5" fill="none" stroke="#270F04" stroke-width="4.5" stroke-linecap="round" />

      <!-- Ears -->
      <ellipse cx="-48" cy="-22" rx="9" ry="14" fill="#78350F" stroke="#451A03" stroke-width="3" transform="rotate(-15 -48 -22)" />
      <ellipse cx="48" cy="-22" rx="9" ry="14" fill="#78350F" stroke="#451A03" stroke-width="3" transform="rotate(15 48 -22)" />

      <!-- ICONIC YELLOW BUILDER HELMET -->
      <!-- Helmet Dome -->
      <path d="M -54,-15 C -56,-70 56,-70 54,-15 Z" fill="url(#helmetGrad)" stroke="#854D0E" stroke-width="4" />
      <!-- Helmet Ridge (Center line) -->
      <path d="M -8,-64 C -9,-67 9,-67 8,-64 L 11,-15 L -11,-15 Z" fill="#FEF08A" opacity="0.6" />
      <!-- Helmet Brim -->
      <ellipse cx="0" cy="-14" rx="60" ry="11" fill="url(#helmetGrad)" stroke="#854D0E" stroke-width="4" />
      <!-- Helmet Light Badge (Lamp/Reflective plate) -->
      <rect x="-14" y="-36" width="28" height="15" rx="5" fill="#FFFFFF" stroke="#CA8A04" stroke-width="2" />
      <polygon points="0,-33 5,-27 -5,-27" fill="#FBBF24" />
    </g>
  </g>

  <!-- ================= LEFT SIDE: LOGO & VALUE PROPOSITION ================= -->
  <g transform="translate(85, 120)" filter="url(#shadow3D)">
    <!-- Category Badge -->
    <g transform="translate(0, 0)">
      <rect width="260" height="34" rx="17" fill="rgba(255, 201, 77, 0.15)" stroke="#FBBF24" stroke-width="1.5" />
      <circle cx="20" cy="17" r="6" fill="#FBBF24" />
      <text x="35" y="22" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="13" font-weight="800" fill="#FDE047" letter-spacing="1.2">O JOGO DA CAPIVARA</text>
    </g>

    <!-- Main Title: CAPIBLOCKS -->
    <g transform="translate(0, 85)">
      <!-- 3D Shadow layer for text -->
      <text x="0" y="8" font-family="'Lilita One', 'Fredoka', 'Arial Black', Impact, sans-serif" font-size="82" font-weight="900" fill="#090514" letter-spacing="1">CapiBlocks</text>
      <!-- Gradient Golden Outline -->
      <text x="0" y="0" font-family="'Lilita One', 'Fredoka', 'Arial Black', Impact, sans-serif" font-size="82" font-weight="900" fill="none" stroke="#854D0E" stroke-width="14" stroke-linejoin="round" letter-spacing="1">CapiBlocks</text>
      <!-- Main Text Fill: CAPI (Gold) + BLOCKS (White) -->
      <text x="0" y="0" font-family="'Lilita One', 'Fredoka', 'Arial Black', Impact, sans-serif" font-size="82" font-weight="900" fill="url(#goldText)" letter-spacing="1">Capi<tspan fill="#FFFFFF">Blocks</tspan></text>
    </g>

    <!-- Catchphrase -->
    <g transform="translate(4, 135)">
      <text font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="21" font-weight="700" fill="#F4F1FF">
        Encaixe blocos, faça combos e construa a vila!
      </text>
    </g>

    <!-- Feature Pills (Pill Highlights) -->
    <g transform="translate(0, 175)">
      <!-- Pill 1: 100% Offline -->
      <g transform="translate(0, 0)">
        <rect width="130" height="38" rx="12" fill="rgba(255, 255, 255, 0.08)" stroke="rgba(255, 255, 255, 0.18)" stroke-width="1.5" />
        <text x="65" y="24" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" font-weight="700" fill="#38BDF8" text-anchor="middle">📴 100% Offline</text>
      </g>

      <!-- Pill 2: Sem Cadastro -->
      <g transform="translate(142, 0)">
        <rect width="140" height="38" rx="12" fill="rgba(255, 255, 255, 0.08)" stroke="rgba(255, 255, 255, 0.18)" stroke-width="1.5" />
        <text x="70" y="24" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" font-weight="700" fill="#34D399" text-anchor="middle">✨ Sem Cadastro</text>
      </g>

      <!-- Pill 3: Modo Obra & Torre -->
      <g transform="translate(294, 0)">
        <rect width="170" height="38" rx="12" fill="rgba(255, 255, 255, 0.08)" stroke="rgba(255, 255, 255, 0.18)" stroke-width="1.5" />
        <text x="85" y="24" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" font-weight="700" fill="#FBBF24" text-anchor="middle">🏝️ Ilha & Minijogos</text>
      </g>
    </g>
  </g>
</svg>`;

fs.writeFileSync('art/loja/banner-1024x500.svg', svg, 'utf8');
console.log('SAVED SVG');
