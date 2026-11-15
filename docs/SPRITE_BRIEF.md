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

## 2. What actually exists (audited, not assumed)

| Asset | Size | Wired? | Style |
|---|---|---|---|
| Hood buildings ×16 (`assets/sprites/`) | 224×208 | **no** | isometric daylight pixel diorama, full colour, **hood name burned into the art** |
| Small hoods ×4 (`*_sm.png`) | 56×52 | no | same art, pre-shrunk |
| Map pin icons ×16 (`loc_*.png`) | 48×48 | no | illegible at native size |
| `map_background_v3.jpg` | 606×1280 | **yes** (Flame + three.js) | pixel highway plate |
| `travel/frames/drive_0..7.png` | 64×64 ×8 | **yes** (`travel_animation.dart`) | purple car, green headlights, neon-leaning |
| `informant_encounter.png` | 128×164 | **yes** | neon-noir pixel illustration |
| Ad art ×5 (`assets/ads/`) | 1024×576 | **yes** | neon poster: type, glitch, scanlines |
| Contact sheets (`building_sprites`, `clean_buildings`, `player_sprite`, `ui_icons`) | 1024² / 1024×576 | no | sheets, not sprites |

Three things this audit changes:

- **The car is done.** `drive_sheet.png` (8 × 64px) already animates on travel. P0 below is
  no longer "draw a car", it is "decide whether the car belongs to the neon or the pixel
  family".
- **`assets/sprites/` is not in `pubspec.yaml`**, so the 16 buildings, the `_sm`s and the
  `loc_*.png`s are not even inside the app. They are repo art, unused by both builds.
- **Every building has a hood name burned into its bottom 34px, and the names are wrong.**
  `buckhead.png` says LITTLE FIVE POINTS, `cobb.png` says BUCKHEAD, `little_five.png` says
  UNIVERSITY HOUSE, `airport.png` says COLLEGE PARK, and the rest say CARROLL COUNTY, NORTH
  HILL, STAR COUNTY, Habersham, SuburbanBank — not Atlanta hoods. Crop the bottom 34px and
  they become usable anonymous buildings; keep it and the map lies.

Two art directions are in the repo and they do not meet in the middle:

- **isometric daylight pixel diorama** — the buildings, the map plate
- **neon noir** — the ads, the informant portrait, the car

Pick one before new art is drawn; the ads are the loudest thing on screen and the furthest
from the map.

Palette (`lib/theme/app_theme.dart` — the only source of truth):

```
#1a1625  background     #00ff9d  accent green    #ffd700  gold
#2a2438  card           #ff00f7  accent pink     #ff3355  danger
#221e30  surface        #e8e4f0  text            #9e94ad  dim
```

Hoods: `#fdd835` Buckhead · `#1e88e5` Midtown · `#ab47bc` Little Five · `#e53935` West End ·
`#fb8c00` Decatur · `#78909c` Cobb.

---

## 3. What is genuinely missing (ranked by how unfinished it looks)

Everything the player taps that has no art is an emoji today — `lib/utils/sprites.dart` is
emoji-only, and 3 of the 4 weapons share 🔫.

### P0 — product icons, 5 × 32×32
`prod_blunts`, `prod_powda`, `prod_acid`, `prod_shrooms`, `prod_oxy`. These are on the shop
row, the bag and every price line. 4–6 shapes, 2px black outline, legible at 32px on a 390pt
screen.

### P1 — weapons, 4 × 24×24, each visually distinct
`wpn_fists`, `wpn_blicky`, `wpn_strap`, `wpn_draco`. Fists / pistol / SMG / rifle — the
silhouettes must differ at 24px or the weapon shop is four identical guns.

### P2 — the six encounter types, 512² waist-up
`enc_cop`, `enc_thief`, `enc_dealer`, `enc_hobo`, `enc_femme`, `enc_mission`. Only the
informant has art. One pose each, hard shadow, no background.

### P3 — transport icons, 3 × 32×32
MARTA / Ryde / Drive, plus the drive cycle if the car is redrawn to match.

### P4 — hood variants, 2 per hood, 224×208, labels cropped
Rich and rough state per hood, so day 20 looks different from day 1.

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
