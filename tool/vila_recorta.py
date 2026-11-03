"""Recorta o fundo liso de uma arte da vila gerada no Gemini.

Uso: python3 tool/vila_recorta.py art/vila/casinha.jpg /tmp/casinha.png
Depois reduza para no máximo 600 px e salve em assets/vila/<id>.webp
(WebP, qualidade ~88). O fundo é achado pelos cantos da imagem; sobras
soltas (como no canteiro de flores) precisam ser apagadas antes.
"""
import sys
from PIL import Image, ImageFilter
import numpy as np
from collections import deque
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGB')
a = np.asarray(im).astype(np.int32)
h, w, _ = a.shape
bg = np.median(np.concatenate([a[:20,:20].reshape(-1,3), a[-20:,-20:].reshape(-1,3), a[:20,-20:].reshape(-1,3), a[-20:,:20].reshape(-1,3)]), axis=0)
dist = np.sqrt(((a - bg) ** 2).sum(axis=2))
mask = np.zeros((h, w), bool)
tol = 22
q = deque()
for x in range(w):
    q.append((0, x)); q.append((h-1, x))
for y in range(h):
    q.append((y, 0)); q.append((y, w-1))
while q:
    y, x = q.popleft()
    if mask[y, x] or dist[y, x] > tol: continue
    mask[y, x] = True
    if y > 0: q.append((y-1, x))
    if y < h-1: q.append((y+1, x))
    if x > 0: q.append((y, x-1))
    if x < w-1: q.append((y, x+1))
alpha = Image.fromarray(((~mask) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))
rgba = im.convert('RGBA'); rgba.putalpha(alpha)
rgba = rgba.crop(rgba.getbbox())
rgba.save(out)
print(rgba.size)
