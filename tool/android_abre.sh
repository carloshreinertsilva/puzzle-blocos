#!/usr/bin/env bash
# Instala a versão de lançamento num emulador Android e confere se o jogo
# passa da tela branca de abertura: o navegador não pega problemas que só
# existem no Android com o código otimizado (R8).
set -u
apk=build/app/outputs/flutter-apk/app-release.apk
saida=build/android_abre
mkdir -p "$saida"

adb install -r "$apk" || exit 1
adb logcat -c
adb shell am start -W -n com.capiblocks.app/.MainActivity
sleep 30
adb exec-out screencap -p > "$saida/tela.png"
adb logcat -d > "$saida/logcat.txt"

falhou=0
if grep -E 'Unhandled Exception|NoSuchMethodError|FATAL EXCEPTION' "$saida/logcat.txt"; then
  echo '::error::O jogo registrou um erro ao abrir no Android.'
  # O erro completo, para ler direto no log do CI.
  grep -E -A40 'FATAL EXCEPTION|Unhandled Exception' "$saida/logcat.txt" | head -120
  falhou=1
fi
if [ -z "$(adb shell pidof com.capiblocks.app | tr -d '[:space:]')" ]; then
  echo '::error::O jogo fechou sozinho ao abrir no Android.'
  falhou=1
fi
python3 - "$saida/tela.png" <<'PY' || falhou=1
import sys
from PIL import Image

imagem = Image.open(sys.argv[1]).convert('RGB')
pixels = list(imagem.getdata())
brancos = sum(1 for r, g, b in pixels if min(r, g, b) > 235) / len(pixels)
print(f'Tela branca: {brancos:.0%}')
if brancos > 0.6:
    print('::error::O jogo ficou parado na tela branca de abertura.')
    sys.exit(1)
PY
exit "$falhou"
