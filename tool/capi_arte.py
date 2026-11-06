"""Builds Capi's game art (assets/capi/) from the cut-out sources in art/capi/fontes/.

    python3 tool/capi_arte.py

Sources (painted with Gemini in the 3D vinyl style of the icon, background
removed with tool/recortar_fundo.py):
  art/capi/fontes/poses/<pose>.webp   Capi in each pose (caramel fur)
  art/capi/fontes/itens/<id>.webp     each wardrobe item alone, front view
  art/capi/fontes/filhote*.webp       the pup, standing and sleeping

Output:
  assets/capi/poses/<pose>_<coat>.webp  every pose in every fur colour: only
      the fur is recoloured (eyes, pink cheeks, mouth and teeth stay), with a
      gradient map on its brightness so the painted shading is kept
  assets/capi/itens/<id>.webp           items, shrunk for the game
  assets/capi/filhote*.webp             the pups

Where things sit on each pose (head centre, eye line, head width) is in
lib/ui/capi_arte.dart; POSES below must match it.
"""
import os

import numpy as np
from PIL import Image

FONTES = "art/capi/fontes"
SAIDA = "assets/capi"

# Height of the pose sprites in the game (Capi is drawn at most ~200 dp
# tall, 3x on dense phones).
ALTURA = 720
# Longest side of the item sprites.
ITEM = 512

# In source pixels: head centre x, eye line y, head width (cheek to cheek).
POSES = {
    "feliz": (699.5, 379.5, 1010),
    "comemora": (450, 172.5, 480),
    "preocupado": (547.5, 395.5, 1010),
    "triste": (279.5, 186, 499),
    "aponta": (335.5, 208.5, 506),
    "carrega": (780, 376, 1012),
}

# Things held that are not fur (source pixels: x0, y0, x1, y1).
PROTEGIDOS = {}

# Fur gradients (light, mid, dark), as in the old painted coats.
COATS = {
    "caramelo": None,
    "chocolate": ("#C9997A", "#8B5A3C", "#5A3520"),
    "neve": ("#FFFFFF", "#EEE6DC", "#C9BCAE"),
    "dourado": ("#FFF0B0", "#F2C14E", "#B8860B"),
    "galaxia": ("#9775FA", "#4C3FA6", "#1B1F4A"),
    "arco_iris": ("#FFE0F0", "#C9B8FF", "#7FB8F0"),
}

# Face landmarks, relative to the head (x from its centre, y from the eye
# line, both in head widths); measured on the "feliz" pose.
OLHOS = [(-0.301, 0.0), (0.301, 0.0)]
BOCHECHAS = [(-0.389, 0.15), (0.386, 0.155)]


def _hex(c):
    return np.array([int(c[i : i + 2], 16) for i in (1, 3, 5)], float)


def _ss(x, e0, e1):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def recolorir(im, coat, cx, ey, hw, protegidos=()):
    """Recolours the fur of [im] (RGBA) to [coat]'s gradient."""
    if coat is None:
        return im
    a = np.array(im).astype(float)
    rgb = a[..., :3] / 255
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx, mn = rgb.max(-1), rgb.min(-1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    hue = np.degrees(np.arctan2(np.sqrt(3) * (g - b), 2 * r - g - b)) % 360
    lum = 0.3 * r + 0.59 * g + 0.11 * b

    # Fur: warm orange-brown, saturated enough; pupils and dark lines stay.
    dh = np.abs(((hue - 30) + 180) % 360 - 180)
    w = _ss(sat, 0.12, 0.30) * (1 - _ss(dh, 27, 35)) * (a[..., 3] > 0)
    w *= _ss(lum, 0.10, 0.20)

    yy, xx = np.mgrid[0 : a.shape[0], 0 : a.shape[1]]
    for dx, dy in OLHOS:
        d = np.hypot(xx - (cx + dx * hw), yy - (ey + dy * hw))
        w *= _ss(d, 0.035 * hw, 0.05 * hw)
    # Only the pink of the cheeks is kept (the fur around them changes).
    dp = np.abs(((hue - 350) + 180) % 360 - 180)
    rosa = (1 - _ss(dp, 18, 30)) * _ss(sat, 0.10, 0.20)
    for dx, dy in BOCHECHAS:
        d = np.hypot((xx - (cx + dx * hw)) / 1.25, yy - (ey + dy * hw))
        w *= 1 - rosa * (1 - _ss(d, 0.09 * hw, 0.13 * hw))
    for x0, y0, x1, y1 in protegidos:
        dentro = (xx >= x0) & (xx <= x1) & (yy >= y0) & (yy <= y1)
        # the brick is redder than the fur (paws inside the box still change)
        db = np.abs(((hue - 12) + 180) % 360 - 180)
        w *= 1 - dentro * (1 - _ss(db, 10, 16))

    lo, hi = 0.12, 0.86
    t = np.clip((lum - lo) / (hi - lo), 0, 1)[..., None]
    light, mid, dark = (_hex(c) for c in coat)
    cor = np.where(t < 0.5, dark + (mid - dark) * (t / 0.5), mid + (light - mid) * ((t - 0.5) / 0.5))
    out = a.copy()
    out[..., :3] = a[..., :3] * (1 - w[..., None]) + cor * w[..., None]
    return Image.fromarray(out.astype(np.uint8))


def _encolher(im, altura=None, lado=None):
    if altura:
        k = altura / im.height
    else:
        k = min(1.0, lado / max(im.size))
    return im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)


def _salvar(im, caminho):
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    im.save(caminho, quality=82, method=4)


def main():
    for pose, (cx, ey, hw) in POSES.items():
        fonte = Image.open(f"{FONTES}/poses/{pose}.webp").convert("RGBA")
        for nome, coat in COATS.items():
            im = recolorir(fonte, coat, cx, ey, hw, PROTEGIDOS.get(pose, ()))
            _salvar(_encolher(im, altura=ALTURA), f"{SAIDA}/poses/{pose}_{nome}.webp")
        print("pose", pose)
    for f in sorted(os.listdir(f"{FONTES}/itens")):
        im = Image.open(f"{FONTES}/itens/{f}").convert("RGBA")
        _salvar(_encolher(im, lado=ITEM), f"{SAIDA}/itens/{f}")
    print("itens", len(os.listdir(f"{FONTES}/itens")))
    _salvar(_encolher(Image.open(f"{FONTES}/filhote.webp").convert("RGBA"), altura=360), f"{SAIDA}/filhote.webp")
    dorme = Image.open(f"{FONTES}/filhote_dormindo.webp").convert("RGBA")
    _salvar(_encolher(dorme, altura=300), f"{SAIDA}/filhote_dormindo.webp")
    print("filhotes")


if __name__ == "__main__":
    main()
