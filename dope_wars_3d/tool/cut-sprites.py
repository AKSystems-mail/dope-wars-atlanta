#!/usr/bin/env python3
"""Cut the baked checkerboard out of the hood sprites.

The Flutter assets ship as RGB PNGs with the transparency preview painted in
(two greys). Nothing in the Flutter app ever drew them, so nobody noticed. For
the 3D build they need real alpha, so this floods the background in from the
edges and writes RGBA copies into public/assets/sprites/.

Run from dope_wars_3d/: python3 tool/cut-sprites.py
"""
from collections import deque
from pathlib import Path
from PIL import Image

SRC = Path("../dope_wars_atl/assets/sprites")
DST = Path("public/assets/sprites")
HOODS = ["buckhead", "midtown", "little_five", "decatur", "west_end", "cobb"]


def is_background(px):
    r, g, b = px[:3]
    return abs(r - g) < 10 and abs(g - b) < 10 and 100 <= r <= 165


def cut(im):
    im = im.convert("RGB")
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    q = deque()

    for x in range(w):
        for y in (0, h - 1):
            q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            q.append((x, y))

    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i] or not is_background(px[x, y]):
            continue
        seen[i] = 1
        if x > 0:
            q.append((x - 1, y))
        if x + 1 < w:
            q.append((x + 1, y))
        if y > 0:
            q.append((x, y - 1))
        if y + 1 < h:
            q.append((x, y + 1))

    out = im.convert("RGBA")
    op = out.load()
    cleared = 0
    for y in range(h):
        for x in range(w):
            if seen[y * w + x]:
                op[x, y] = (0, 0, 0, 0)
                cleared += 1
    return out, cleared


if __name__ == "__main__":
    DST.mkdir(parents=True, exist_ok=True)
    for name in HOODS:
        src = SRC / f"{name}.png"
        if not src.exists():
            print(f"skip {name}: no source")
            continue
        im, cleared = cut(Image.open(src))
        dst = DST / f"{name}.png"
        im.save(dst)
        pct = 100 * cleared / (im.size[0] * im.size[1])
        print(f"{name}: {im.size[0]}x{im.size[1]} cleared {pct:.0f}% -> {dst}")
