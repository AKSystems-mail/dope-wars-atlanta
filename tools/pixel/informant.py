#!/usr/bin/env python3
"""Procedural neon-noir pixel art for DopeWars encounter art.

Free and reproducible: every pixel is placed on a strict integer grid against a
fixed palette, so the style properties that matter (no anti-aliasing, no
off-palette blend colours, dithered gradients, 1px rain) are guaranteed rather
than hoped for. Compare to a diffusion model, which tends to soften edges and
invent stray hues in smoke and reflections.

Render at native size, upscale nearest-neighbour for display:
    python3 informant.py informant 128 224
"""

import sys
from PIL import Image

# ── Palette ────────────────────────────────────────────────────────────────
# ~30 colours, teal/cyan dominant, magenta neon as the only hot accent.
# A dict of names keeps the drawing code readable.
P = {
    # deep shadow teal (walls, cores, outlines)
    "void":    (0x08, 0x1F, 0x26),
    "shadow":  (0x0B, 0x2B, 0x33),
    "deep":    (0x0E, 0x35, 0x40),
    # mid teal wall
    "mid":     (0x17, 0x50, 0x5C),
    "mid2":    (0x1E, 0x64, 0x70),
    # lit teal
    "lit":     (0x3E, 0x9A, 0xA6),
    "lit2":    (0x5F, 0xBD, 0xC4),
    # bright cyan highlights
    "cyan":    (0x8F, 0xE6, 0xE4),
    "cyanw":   (0xB7, 0xF4, 0xF0),
    "white":   (0xDF, 0xFB, 0xF8),
    # neon magenta
    "mag_deep":(0x4A, 0x0C, 0x34),
    "mag_dk":  (0x6E, 0x10, 0x49),
    "mag":     (0xC0, 0x10, 0x70),
    "neon":    (0xFF, 0x2F, 0xA0),
    "neon2":   (0xFF, 0x6F, 0xBE),
    "neon3":   (0xFF, 0xA3, 0xD4),
    # warm skin (kept desaturated so it doesn't fight the neon)
    "skin_d":  (0x6B, 0x3B, 0x2C),
    "skin":    (0x8C, 0x53, 0x40),
    "skin_l":  (0xC9, 0x8A, 0x67),
    "skin_h":  (0xEF, 0xB8, 0x92),
}


class Canvas:
    """A tiny indexed pixel canvas. put() clips; nothing blends, ever."""

    def __init__(self, w, h, fill="void"):
        self.w, self.h = w, h
        self.px = [[P[fill]] * w for _ in range(h)]

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = P[c] if isinstance(c, str) else c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return P["void"]

    def rect(self, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.put(xx, yy, c)

    def frame(self, x, y, w, h, c):
        for xx in range(x, x + w):
            self.put(xx, y, c)
            self.put(xx, y + h - 1, c)
        for yy in range(y, y + h):
            self.put(x, yy, c)
            self.put(x + w - 1, yy, c)

    def vline(self, x, y0, y1, c):
        for y in range(y0, y1):
            self.put(x, y, c)

    def hline(self, y, x0, x1, c):
        for x in range(x0, x1):
            self.put(x, y, c)

    def dither_rect(self, x, y, w, h, a, b, parity=0, period=2):
        """Checkerboard fill between two palette colours. This is how every
        gradient in the piece is built — no smooth ramps anywhere."""
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if ((xx // period) + (yy // period)) % 2 == parity:
                    self.put(xx, yy, a)
                else:
                    self.put(xx, yy, b)

    def to_image(self, scale=1):
        img = Image.new("RGB", (self.w, self.h))
        img.putdata([c for row in self.px for c in row])
        if scale > 1:
            img = img.resize((self.w * scale, self.h * scale), Image.NEAREST)
        return img


def draw_informant(w=128, h=224, seed=7):
    """A lone figure in the rain, alley, dual rim light. Informant encounter."""
    c = Canvas(w, h, "void")

    # deterministic LCG so the rain is reproducible run to run
    s = seed
    def rnd(n):
        nonlocal s
        s = (s * 1103515245 + 12345) & 0x7FFFFFFF
        return s % n

    horizon = int(h * 0.78)  # ground line

    # ── back wall ─────────────────────────────────────────────────────────
    c.rect(0, 0, w, horizon, "deep")
    # lit wash from the cyan source (upper right) — dithered, not a ramp
    c.dither_rect(w // 2, 0, w - w // 2, horizon, "mid", "deep", 0)
    c.dither_rect(int(w * 0.62), 0, int(w * 0.38), horizon, "mid2", "mid", 0)
    c.rect(w - 2, 0, 2, horizon, "lit")  # bright edge nearest the light
    # Brighten the wall band directly behind the figure's lower body. The
    # figure stands left-of-centre, so without this the near-black legs sit
    # against near-black wall and the silhouette can't be read at all. This is
    # the window light falling across the wall at figure height.
    c.dither_rect(int(w * 0.22), int(h * 0.55), int(w * 0.26), horizon - int(h * 0.55),
                  "mid2", "mid", 0)

    # brick texture: only bricks facing the light get the highlight
    for by in range(0, horizon, 6):
        for bx in range(0, w, 10):
            if rnd(3) == 0 and bx > w // 2:
                c.rect(bx, by, 2, 1, "mid2")
            elif rnd(4) == 0:
                c.rect(bx, by, 3, 1, "shadow")

    # ── window: thick magenta frame, blown-out pale interior ─────────────
    wx, wy, ww, wh = int(w * 0.58), int(h * 0.18), int(w * 0.30), int(h * 0.30)
    c.rect(wx, wy, ww, wh, "white")        # interior glow
    c.frame(wx, wy, ww, wh, "neon")        # hot frame
    c.frame(wx - 1, wy - 1, ww + 2, wh + 2, "mag_dk")
    # blinds / interior forms as pale blocks
    for i in range(0, wh - 2, 4):
        c.rect(wx + 2, wy + 2 + i, ww - 4, 2, "cyanw")
    c.vline(wx + ww // 2, wy + 2, wy + wh - 2, "cyan")

    # ── payphone on the left wall ────────────────────────────────────────
    px_, py_ = int(w * 0.10), int(h * 0.40)
    c.rect(px_, py_, 8, 12, "mid2")
    c.frame(px_, py_, 8, 12, "mid")
    c.rect(px_ + 1, py_ + 1, 6, 3, "lit2")   # screen
    for by_ in range(py_ + 5, py_ + 10, 2):  # keypad suggestion
        c.rect(px_ + 2, by_, 4, 1, "mid")
    c.rect(px_ + 2, py_ - 2, 4, 2, "lit")    # signage on top
    c.vline(px_ + 7, py_ + 12, py_ + 16, "mid")  # cord stub

    # neon sign, cropped top-left, magenta spill. The spill is a soft falloff
    # of nested rects, not a checkerboard — a dither here reads as a glitch.
    sw, sh = int(w * 0.16), int(h * 0.10)
    c.rect(0, 0, sw, sh, "mag")
    c.frame(0, 0, sw, sh, "neon2")
    c.rect(2, 2, sw - 4, sh - 4, "mag_dk")  # sign face
    for i, (ox, oy, ow, oh) in enumerate([  # nested spill, darker outward
        (sw, 0, 3, sh + 6), (sw + 3, 0, 3, sh + 10), (sw + 6, 0, 4, sh + 14),
    ]):
        c.rect(ox, oy, ow, oh, "mag_dk" if i else "mag")
    c.rect(sw + 9, 0, 3, sh + 18, "shadow")
    c.dither_rect(sw, sh, 8, 6, "mag_dk", "shadow", 0)

    # ── rain: 1px vertical dashes in 3 brightness tiers ──────────────────
    # Split into a sparse BACK layer (drawn before the figure) and a thin,
    # brighter FRONT layer (after it). A single uniform pass over everything
    # reads as noise and flattens the silhouette; two layers give depth.
    def rain(count, tiers, ymax):
        for _ in range(count):
            rx, ry = rnd(w), rnd(ymax)
            ln = 2 + rnd(7)
            tier = tiers[rnd(len(tiers))]
            for k in range(ln):
                c.put(rx, ry + k, tier)

    rain(int(w * h * 0.012), ("mid", "mid2"), horizon)  # behind the figure

    # ── figure ──────────────────────────────────────────────────────────
    # (drawn between the two rain layers)
    # Proportioned as a real standing figure (~1:7 head-to-height) so it reads
    # as a person rather than a blob. cx is the body centreline.
    cx = int(w * 0.36)
    head_top = int(h * 0.30)
    head_h, head_w = 8, 7
    shoulder_y = head_top + head_h + 1
    hip_y = int(h * 0.60)
    foot_y = horizon - 1
    torso_w = 11
    left = cx - torso_w // 2

    # head
    c.rect(cx - head_w // 2, head_top, head_w, head_h, "shadow")
    c.rect(cx - head_w // 2 + 1, head_top + 2, head_w - 2, 3, "skin_d")  # face, shadowed
    c.put(cx, head_top + 3, "skin_l")                                     # one lit cheek
    # hair / cap
    c.rect(cx - head_w // 2, head_top, head_w, 2, "void")
    # neck
    c.rect(cx - 1, shoulder_y - 1, 2, 2, "skin_d")

    # shoulders + coat torso. Narrow and stopping well above the feet: a wide
    # coat running to the ankles is what makes the lower half read as a single
    # pillar instead of two legs.
    coat_bot = hip_y - 10
    c.rect(left, shoulder_y, torso_w, coat_bot - shoulder_y, "shadow")
    c.rect(left, shoulder_y, torso_w, 2, "mid")   # shoulders catch light
    c.rect(cx - 1, shoulder_y + 2, 2, coat_bot - shoulder_y - 2, "void")  # coat opening

    # arms: one down, one bent up to the mouth (the phone/cigarette gesture)
    c.rect(left - 2, shoulder_y + 1, 2, 18, "void")            # left arm, hanging
    c.rect(left + torso_w, shoulder_y + 1, 2, 14, "void")      # right arm, lower
    # bent forearm rising to the face
    c.rect(left + torso_w, shoulder_y - 3, 2, 5, "void")
    c.rect(left + torso_w - 2, shoulder_y - 6, 4, 4, "void")

    # legs — two clearly separated columns, starting right under the coat hem
    # and running to the shoes. The gap is the wall showing through, so the
    # silhouette separates naturally without any cheat lighting.
    leg_w = 3
    leg_top = coat_bot  # meet the coat hem, no floating gap
    c.rect(left, leg_top, leg_w, foot_y - leg_top, "void")
    c.rect(left + torso_w - leg_w, leg_top, leg_w, foot_y - leg_top, "void")
    # shoes
    c.rect(left - 1, foot_y - 1, leg_w + 2, 2, "mid")
    c.rect(left + torso_w - leg_w - 1, foot_y - 1, leg_w + 2, 2, "mid")

    # ── dual rim light: magenta from the neon (left), cyan from the window
    # (right). This is the whole point of the piece, so it goes on every
    # silhouette edge that faces a light source.
    c.vline(left, shoulder_y, hip_y, "neon")                     # coat left
    c.vline(left + 1, shoulder_y + 2, hip_y - 2, "mag")
    c.vline(left - 2, shoulder_y + 1, shoulder_y + 16, "neon")    # hanging arm
    c.vline(left + torso_w, shoulder_y, shoulder_y + 14, "cyan") # coat right
    c.vline(left + torso_w + 1, shoulder_y, shoulder_y + 12, "lit")
    # head rims
    for dy in range(head_h):
        if dy < 2:
            c.put(cx - head_w // 2, head_top + dy, "neon")
            c.put(cx + head_w // 2 - 1, head_top + dy, "cyan")
    c.put(cx - head_w // 2, head_top + 2, "neon2")
    c.put(cx + head_w // 2 - 1, head_top + 2, "lit2")
    # leg rims — each leg gets BOTH edges lit, not just the outer ones. With
    # only outer rims the two legs read as one mass because the leg value and
    # the wall behind are so close; outlining the inner edges separates them.
    c.vline(left, leg_top + 2, foot_y - 2, "mag")                       # outer L
    c.vline(left + torso_w - leg_w, leg_top + 2, foot_y - 2, "lit")    # outer R
    c.vline(left + leg_w - 1, leg_top + 3, foot_y - 2, "mag_dk")        # inner L
    c.vline(left + torso_w - leg_w, leg_top + 3, foot_y - 2, "deep")    # inner R

    # cigarette ember at the mouth, hand raised
    c.put(cx + 2, head_top + 3, "neon3")
    c.put(cx + 3, head_top + 3, "white")

    # ── ground: wet, reflective, dithered ───────────────────────────────
    c.rect(0, horizon, w, h - horizon, "shadow")
    c.dither_rect(0, horizon, w, h - horizon, "deep", "void", 0)
    # wet ground: neon reflection sits DIRECTLY below the sign, not in the
    # corner. A wide checkerboard out at the edge reads as a compression
    # artifact; a narrow smear under the light source reads as a reflection.
    c.dither_rect(0, horizon, sw + 4, (h - horizon) // 2, "mag_dk", "deep", 0)
    c.dither_rect(1, horizon + 2, sw, (h - horizon) // 3, "mag", "mag_dk", 0)
    c.dither_rect(int(w * 0.55), horizon, int(w * 0.30), (h - horizon) // 2, "mid", "deep", 0)
    c.hline(horizon, 0, w, "mid2")  # the bright wet edge
    # pale pool under the figure (bounce light)
    c.dither_rect(left - 4, horizon + 1, torso_w + 8, 5, "mid2", "deep", 0)

    # ── FRONT rain: sparse and bright, over the figure, to build depth ───
    rain(int(w * h * 0.004), ("cyan", "cyanw", "lit2"), h)

    return c


if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else "informant"
    w = int(sys.argv[2]) if len(sys.argv) > 2 else 128
    h = int(sys.argv[3]) if len(sys.argv) > 3 else 224
    out = sys.argv[4] if len(sys.argv) > 4 else f"{name}.png"
    canvas = draw_informant(w, h)
    img = canvas.to_image(scale=1)
    img.save(out)
    # a nearest-neighbour preview at 4x so the pixels are actually visible
    img.resize((w * 4, h * 4), Image.NEAREST).save(out.replace(".png", "_4x.png"))
    print(f"wrote {out} ({w}x{h}) and {out.replace('.png','_4x.png')} (4x preview)")
