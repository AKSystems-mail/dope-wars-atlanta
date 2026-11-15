# Sprite brief — what to draw, and what the engine can actually do with it

For Akil. Everything here is what the **Flutter/Flame** build can consume, since that is
the shipping app; the three.js build is the reference and the sprite factory.

---

## 1. The one hard rule

Flame has no 3D. It draws PNGs on a canvas. So every sprite must be **flat art with the
perspective baked in** — same trick as the map today: one fixed camera, drawn once by hand
or baked once by us, never re-projected at runtime. Picked direction: **fake perspective**.

The baked camera, used by everything from now on:

- **3/4 view from above**, tilt ≈ 30° down from horizontal
- **rotated 20–30° to the right** of straight-on, so one side face is visible
- **light from the upper left**, one shadow direction, shadow painted into the sprite
- horizon never visible; the sprite is the object, not a scene

If a sprite is drawn straight-on it will not sit next to the existing hood buildings
without looking pasted on.

---

## 2. Established style, from the art already in the repo

| Sprite | Size | Notes |
|---|---|---|
| Hood buildings (`buckhead.png`, `midtown.png`, …) | 224×208 | RGB, black background, **desaturated grey** (143,143,142 / 117,117,116). The colour comes from the map node ring, never from the building. |
| Small hood (`*_sm.png`) | 56×52 | same art, pre-shrunk — do not resize at runtime |
| Small icons (`loc_*.png`) | 48×48 | |
| Hanafuda-style portraits / encounter | 1024×1024-ish, downscaled to phone | `informant_encounter.png` |

Two habits worth keeping:

- **Buildings are grey and colourless.** Neon is UI's job (rings, borders, text). A neon
  building fights the ring around it.
- **`*_sm.png` are hand-shrunk, not scaled.** `FilterQuality.none` on a 224px sprite at 56px
  reads as mud; the shipped small files are redrawn/quantised.

Palette (`lib/theme/app_theme.dart` — the only source of truth):

```
#1a1625  background     #00ff9d  accent green    #ffd700  gold
#2a2438  card           #ff00f7  accent pink     #ff3355  danger
#221e30  surface        #e8e4f0  text            #9e94ad  dim
```

Hoods: `#fdd835` Buckhead · `#1e88e5` Midtown · `#ab47bc` Little Five · `#e53935` West End ·
`#fb8c00` Decatur · `#78909c` Cobb.

---

## 3. What needs drawing (ranked, in the order it unblocks work)

### P0 — the car, because travel is the game
Currently the three.js build animates `drive_0..7` frames; nothing in the Flutter build
moves.

- **`car_rear.png`** — 8 frames, 64×64 each, one PNG per frame: `car_rear_0.png … _7.png`.
  Rear-3/4 view, wheels rotating, 2-frame suspension bob (frames 2 and 6 sit 1px lower).
- **`car_side.png`** — 8 frames, 64×64. Side view (fake-perspective is fine sideways), for
  the travel sheet's horizontal run.
- **`car.png`** — 32×32 static, top-down-ish for the map dot while parked.

Restriction: **transparent background, object fills 85% of the canvas, all frames identical
in silhouette position** — the car must not drift between frames or it will jitter.

### P1 — icons that are currently emoji
The emoji in `sprites.dart` is the most prototype-looking thing in the shipping app.

- **Products**, 32×32, one each: `prod_blunts`, `prod_powda`, `prod_acid`, `prod_shrooms`,
  `prod_oxy`. Object on transparent, 2px black outline, readable at 32px on a 390pt screen —
  that means 4–6 shapes maximum, no fine detail.
- **Weapons**, 24×24: `wpn_fists`, `wpn_knife`, `wpn_pistol`, `wpn_uzi`, `wpn_shotgun`.
- **UI affordances**, 24×24: `ui_cash`, `ui_bag`, `ui_heat`, `ui_bank`. Optional — the HUD
  reads fine as text; only draw these if you want the HUD to get denser.

### P2 — sets that make the world feel alive
- **Hood building variants**, 224×208, grey like the existing six: 2 per hood (a "rich" and
  a "rough" state). This lets the same hood look different by day 20 without new code.
- **Encounter portraits**, 512×512: cop, rival dealer, stick-up kid, street preacher. One
  pose each, waist-up, hard shadow, no background.
- **Ad art**, 320×180: the four fake brands are the funniest thing in the game and they are
  currently stretched PNGs.

---

## 4. Technical spec — hand this part to anyone drawing

- **Format** PNG-32 (RGBA), straight alpha, **no premultiplied alpha**, no interlacing.
- **Palette** ≤ 32 colours per sprite, no gradients, no anti-aliased edges (Flame does not
  need AA; the nearest-neighbour upscale will blur it anyway).
- **Outline** 2px, colour `#12101e`, around the silhouette. Interior lines 1px.
- **Sizes** multiples of 8, and each sprite is delivered at its **final display size × 1**
  (no 2×/4× source — Flame will upscale by integer factors set in code).
- **Anchor** canvas centre unless stated; the map expects centre-anchored sprites.
- **No drop shadows on transparent PNG** at export — shadow is painted as pixels, not alpha,
  so it never goes grey-fringed on the dark background.
- **Naming** `snake_case`, group prefix (`car_`, `prod_`, `wpn_`, `ui_`), animation index last
  (`_0.._7`).
- **Where it goes** `dope_wars_atl/assets/sprites/`, then I add the entry to `pubspec.yaml`
  and load it through `utils/sprites.dart`. One folder, no subfolders.

---

## 5. The line I cannot cross

I can quantise, outline, recolour, bake angles from the three.js build, and composite a
sheet. I **cannot** draw a character, a vehicle rear, or a hand-lettered logo — those are
your hands or an artist's. What I *can* do in the meantime:

- render the three.js car at 8 rotation angles into a sheet (`tool/bake-sprites.mjs`)
- quantise any PNG to the palette above and clamp it to 32 colours
- extend an existing grey building into a "night" variant by palette swap

---

## 6. Order of operations

1. `car_rear` 8 frames — unblocks travel animation, the single biggest "this looks unfinished"
   item.
2. Product icons 5× 32px — kills the emoji.
3. Weapon icons — cheap, same session as products.
4. Hood night variants — makes day 20 feel like a different city.
5. Encounters + ads — last, because they cost the most and block nothing.
