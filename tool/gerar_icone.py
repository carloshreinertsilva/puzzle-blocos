"""Gera todos os ícones do app a partir da arte do ícone (art/icone-fonte.jpg).

A arte ocupa o quadrado inteiro: a Apple e o Google arredondam os cantos
sozinhos. Gera:
- art/icone-{1024,512,48}.png e docs/loja/icone-512.png (lojas);
- ios/Runner/Assets.xcassets/AppIcon.appiconset (sem transparência);
- android mipmap-*/ic_launcher.png (Androids antigos) e
  ic_launcher_frente.png (ícone adaptativo: a arte cabe na área que todo
  formato de recorte mostra, sobre o fundo azul do ícone);
- web/favicon.png e web/icons/ (o "maskable" com margem para o círculo).

Uso: python3 tool/gerar_icone.py
"""

import json
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
FONTE = RAIZ / 'art' / 'icone-fonte.jpg'
# A cor do céu nas bordas da arte (o mesmo do fundo do ícone adaptativo).
FUNDO = (28, 26, 85)

arte = Image.open(FONTE).convert('RGB')


def lado(n):
    return arte.resize((n, n), Image.LANCZOS)


def com_margem(n, fracao, fundo=FUNDO, transparente=False):
    """A arte em [fracao] do quadrado de lado n, centrada."""
    modo = 'RGBA' if transparente else 'RGB'
    cor = (0, 0, 0, 0) if transparente else fundo
    tela = Image.new(modo, (n, n), cor)
    m = round(n * fracao)
    p = (n - m) // 2
    tela.paste(lado(m).convert(modo), (p, p))
    return tela


def salvar(img, caminho):
    caminho = RAIZ / caminho
    caminho.parent.mkdir(parents=True, exist_ok=True)
    img.save(caminho, optimize=True)
    print('  ', caminho.relative_to(RAIZ), img.size[0])


# Lojas.
for n in (1024, 512, 48):
    salvar(lado(n), f'art/icone-{n}.png')
salvar(lado(512), 'docs/loja/icone-512.png')

# iPhone: cada tamanho pedido no Contents.json.
pasta = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for img in json.load(open(RAIZ / pasta / 'Contents.json'))['images']:
    pts = float(img['size'].split('x')[0])
    escala = int(img['scale'][0])
    salvar(lado(round(pts * escala)), f"{pasta}/{img['filename']}")

# Android. O ícone adaptativo tem 108 dp e o celular mostra até os 72 dp do
# meio (círculo, gota, quadrado arredondado): a arte ocupa 76 dp, então todo
# formato mostra quase ela inteira, sem cortar o capacete.
for nome, d in (('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)):
    salvar(lado(round(48 * d)), f'android/app/src/main/res/mipmap-{nome}/ic_launcher.png')
    salvar(
        com_margem(round(108 * d), 76 / 108, transparente=True),
        f'android/app/src/main/res/mipmap-{nome}/ic_launcher_frente.png',
    )

# Web.
salvar(lado(32), 'web/favicon.png')
for n in (192, 512):
    salvar(lado(n), f'web/icons/Icon-{n}.png')
    # "maskable": o navegador pode recortar num círculo de 80% do lado.
    salvar(com_margem(n, 0.86), f'web/icons/Icon-maskable-{n}.png')
