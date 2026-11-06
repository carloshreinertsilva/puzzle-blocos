"""Gera as imagens da abertura do Android.

Uso (na raiz do projeto): python3 tool/gerar_abertura_android.py

Lê art/capi.png e assets/fonts/LilitaOne-Regular.ttf e escreve em
android/app/src/main/res/:
- drawable-*/splash_capi.png: o Capi da tela de abertura (Android 12+ usa
  um quadro de 288 dp, com o desenho dentro do círculo central de 192 dp);
- drawable-*/splash_marca.png: o nome CapiBlocks embaixo (200 x 80 dp).

O ícone do app (inclusive o adaptativo) vem de tool/gerar_icone.py.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

RAIZ = Path(__file__).resolve().parent.parent
RES = RAIZ / 'android/app/src/main/res'
DENSIDADES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
CAPI = Image.open(RAIZ / 'art/capi.png').convert('RGBA')
CAPI = CAPI.crop(CAPI.getbbox())
FONTE = RAIZ / 'assets/fonts/LilitaOne-Regular.ttf'


def capi_em(lado, altura):
    """O Capi com a altura pedida, centralizado num quadro transparente."""
    escala = altura / CAPI.height
    capi = CAPI.resize(
        (round(CAPI.width * escala), round(CAPI.height * escala)),
        Image.LANCZOS,
    )
    quadro = Image.new('RGBA', (lado, lado), (0, 0, 0, 0))
    quadro.alpha_composite(
        capi, ((lado - capi.width) // 2, (lado - capi.height) // 2)
    )
    return quadro


def marca(largura, altura):
    """CapiBlocks em Lilita One, branco com sombra roxa."""
    img = Image.new('RGBA', (largura, altura), (0, 0, 0, 0))
    tamanho = round(altura * 0.55)
    fonte = ImageFont.truetype(str(FONTE), tamanho)
    desenho = ImageDraw.Draw(img)
    caixa = desenho.textbbox((0, 0), 'CapiBlocks', font=fonte)
    x = (largura - (caixa[2] - caixa[0])) / 2 - caixa[0]
    y = (altura - (caixa[3] - caixa[1])) / 2 - caixa[1]
    sombra = round(tamanho * 0.08)
    desenho.text((x, y + sombra), 'CapiBlocks', font=fonte, fill='#2A1458')
    desenho.text((x, y), 'CapiBlocks', font=fonte, fill='#FFFFFF')
    return img


def salvar(img, pasta, nome):
    destino = RES / pasta / nome
    destino.parent.mkdir(parents=True, exist_ok=True)
    img.save(destino, optimize=True)


for nome, d in DENSIDADES.items():
    salvar(capi_em(round(288 * d), round(150 * d)), f'drawable-{nome}', 'splash_capi.png')
    salvar(marca(round(200 * d), round(80 * d)), f'drawable-{nome}', 'splash_marca.png')
print('Imagens geradas em', RES)
