"""Cuts the flat chroma background out of the Gemini paintings of Capi.

    python3 tool/recortar_fundo.py <entrada> <saida.webp> [<entrada> <saida.webp> ...]

The paintings are asked for on a flat #00FF00 background (#FF00FF for things
that are green themselves, like the backpack); the colour is read from the
border of each image. Alpha comes from how much the key colour dominates
each pixel, with a soft ramp so the edges stay smooth; the key colour that
bleeds into the edges is taken out (no green halo). Only the main figure is
kept (the Gemini sparkle in a corner and stray specks go), and the image is
cropped to it with a small margin.
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

MARGEM = 8


def _chave(rgb):
    """How much the key colour dominates each pixel, and which key it is."""
    borda = np.concatenate([rgb[:8].reshape(-1, 3), rgb[-8:].reshape(-1, 3), rgb[:, :8].reshape(-1, 3), rgb[:, -8:].reshape(-1, 3)])
    r, g, b = np.median(borda, axis=0)
    r_, g_, b_ = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    if g > r and g > b:
        return g_ - np.maximum(r_, b_), "verde"
    return np.minimum(r_, b_) - g_, "magenta"


def recortar(caminho):
    rgb = np.asarray(Image.open(caminho).convert("RGB")).astype(float)
    d, tipo = _chave(rgb)
    fundo = np.median(np.concatenate([d[:8].ravel(), d[-8:].ravel(), d[:, :8].ravel(), d[:, -8:].ravel()]))

    # d <= baixo: figure; d >= alto: background; in between: soft edge.
    baixo, alto = 18.0, max(60.0, 0.55 * fundo)
    alfa = np.clip((alto - d) / (alto - baixo), 0, 1)

    # Main figure only: the biggest blob, plus pieces at least 3% its size.
    solido = alfa > 0.5
    rotulos, n = ndimage.label(solido)
    if n > 1:
        tamanhos = ndimage.sum(solido, rotulos, range(1, n + 1))
        manter = [i + 1 for i, t in enumerate(tamanhos) if t >= 0.03 * tamanhos.max()]
        perto = ndimage.binary_dilation(np.isin(rotulos, manter), iterations=4)
        alfa *= perto
    # Pinholes inside the figure (highlights that came out near the key).
    cheio = ndimage.binary_fill_holes(alfa > 0.5)
    buracos = cheio & (alfa <= 0.5) & (d < 0.35 * fundo)
    alfa[buracos] = 1

    # Edges: a soft edge pixel is figure and background mixed by alpha, so
    # the background's share is taken out (unmixing), and the edge is pulled
    # in a little.
    cor_fundo = np.median(np.concatenate([rgb[:8].reshape(-1, 3), rgb[-8:].reshape(-1, 3)]), axis=0)
    out = rgb.copy()
    borda = (alfa > 0.02) & (alfa < 1)
    a = np.maximum(alfa[borda], 0.15)[:, None]
    out[borda] = (rgb[borda] - (1 - a) * cor_fundo) / a
    alfa = np.clip((alfa - 0.08) / 0.92, 0, 1)

    # No key colour left: the dominant channel goes down to the others (only
    # where the key dominates, so the figure's own colours stay).
    if tipo == "verde":
        teto = np.maximum(out[..., 0], out[..., 2])
        out[..., 1] = np.where(out[..., 1] > teto, teto, out[..., 1])
    else:
        teto = out[..., 1] + 0.5 * np.abs(out[..., 0] - out[..., 2])
        for c in (0, 2):
            out[..., c] = np.where((d > 0), np.minimum(out[..., c], teto), out[..., c])

    a8 = (alfa * 255).round().astype(np.uint8)
    im = Image.fromarray(np.dstack([out.clip(0, 255).astype(np.uint8), a8]))
    ys, xs = np.nonzero(a8 > 8)
    caixa = (
        max(0, xs.min() - MARGEM),
        max(0, ys.min() - MARGEM),
        min(im.width, xs.max() + 1 + MARGEM),
        min(im.height, ys.max() + 1 + MARGEM),
    )
    return im.crop(caixa)


def main(args):
    if not args or len(args) % 2:
        sys.exit(__doc__)
    for entrada, saida in zip(args[::2], args[1::2]):
        im = recortar(entrada)
        im.save(saida, lossless=False, quality=92, alpha_quality=100, method=6)
        print(saida, im.size)


if __name__ == "__main__":
    main(sys.argv[1:])
