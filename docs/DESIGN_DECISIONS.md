# Dope Wars Atlanta — Design Decisions Log

> Running record of decisions made in design conversation.
> **Why** lives here. **What ships** lives in `SPEC.md`.
> Items marked **PROPOSED** are awaiting approval and are not spec yet.
> `docs/GAME_DESIGN.md` is stale and superseded — see D0.

---

## D0 — Which doc is the truth (settled)

`SPEC.md` (repo root) is the live spec: 6 locations, 5 products. `docs/GAME_DESIGN.md`
describes an abandoned vision — 11 locations (Five Points, East Point, Hapeville,
College Park, Airport) and car-fluid products (motor oil, coolant, transmission
fluid). Its §4.2 "Location Price Multipliers" table is the source of the
"I thought we already wrote this" confusion. It is not usable; the products don't
exist in the game.

**Rule going forward:** `SPEC.md` for what ships, this file for why, and
`DEV_ROADMAP.md` for order.

---

## D1 — Pricing: profit requires travel (settled)

The shipped economy has no location term. `GameState.getPrice()` takes a base
price and rolls ±30% noise, and every location references the same
`Product.defaults` instances, so a product costs the same everywhere. Worse, base
sell sits below base buy for all five products (blunts 60/40, oxy 20/5, shrooms
150/70, powda 120/60, acid 55/10), so a round trip in one place is a guaranteed
loss and the only profit path was a random Market Flood or Demand Spike.

That is why the game read as "only money and time" — there was no geography to
exploit. The original's core mechanic was missing.

**Decision:**

- Same-location margin stays **slightly negative** — sell ≈ 85–90% of buy. A round
  trip in one hood always loses a little.
- **Location multipliers do the work.** Buying in a glutted hood and selling in a
  hood that wants it is the only real profit.
- Therefore **profit requires travel**, and travel already costs cash, a day, and
  carries encounter risk. The loop closes.

**Rejected:** reversing base buy/sell globally. If sell exceeds buy at the same
location, the player buys and sells in one spot forever — bag capacity slows it,
it does not stop it. Unbounded money in Buckhead.

---

## D2 — Product preference table (PROPOSED — not spec yet)

Each of the 5 products has exactly **one cheap source** and **one premium market**,
forming a ring through all six hoods:

**Ring: Buckhead → Decatur → Little Five → Midtown → West End → Buckhead**

| Product | Cheap source (−30% buy) | Premium market (+50% sell) |
|---|---|---|
| Blunts | Buckhead | Decatur |
| Acid | Decatur | Little Five |
| Shrooms | Little Five | Midtown |
| Oxy | Midtown | West End |
| Powda | West End | Buckhead |

Buckhead both opens the game and closes the loop: you arrive holding powda and
leave holding cheap blunts. Every hood is a buy *and* a sell, so every unlock
extends a route the player can already run.

**Cobb County is the outlier by design:** premium on **oxy and shrooms**, **no
cheap supply**. It's a cash-out detour, not a ring stop — road-only, most
expensive to reach, fewest products. That gives it a role instead of being a
sixth generic market.

**Supporting rules (PROPOSED):**

1. **Sell anything anywhere.** The shop shows what the hood stocks for buying, plus
   your bag as sellable. Without this, a premium in a hood that doesn't stock the
   product is meaningless. This is also the original's rule.
2. **Each hood always stocks its cheap-source product**, so the ring is always
   runnable. Other slots stay randomized as they are today (`SPEC.md` §2).
3. **Hood personalities are stable; magnitudes vary ±10–15% per run.** Learn the
   city once, relearn the margins each run. Full per-run randomization of *which*
   hood wants *what* would destroy the mental-atlas feel that makes Progressive
   work.

---

## D3 — Two single-player modes, one engine (settled)

**Classic** and **Progressive** are single-player. Multiplayer is a separate axis,
not a third peer. Naming per the house rule: clear, not clever.

**Progressive is a configuration toggle, not a second engine.** The same screens,
the same save format with more fields set. What it flips:

- start location and which hoods are unlocked
- day cap **off** — time still costs, it stops being a deadline
- heat on
- win condition: net worth at end of days → **own the city**
- informant gating on

Classic is untouched by all of it.

---

## D4 — Progressive: what it is (settled)

- **Starts in Buckhead.** Already the case in `SPEC.md` §4 — no change needed.
- **The lender is available from turn one.** Borrowing is an opt-in strategy, not
  something you earn. Taking his money in the first minute is a legitimate opening
  move with a real cost later.
- **Unlock cadence: cash threshold + story beat.** Hitting a money mark brings the
  informant back with the next name *and* the next piece of story. Progression is
  bought with success, and framed by narrative.
- **The map is the progress bar — the mode's signature element.** One node lit at
  the start, six at the end. Protect this above other polish. In Classic the map is
  wallpaper; in Progressive the map is the thing you're playing for.
- **The informant is both the gate and the guide.** The choice-dialogue encounter
  system already exists (`_setEncounterWithChoices` / `EncounterChoice` /
  `encounter_overlay.dart`), so this is **content, not engineering** — pay him,
  trade with him, lean on him, or talk your way in, with different costs.
- **Some unlocks are capabilities, not just markets:** bank (Midtown), weapons
  (West End), bookbag (Little Five).
- **Endgame: turn his leverage against you.** The final unlock is gated behind
  clearing Councilman debt to zero. Classic's debt is a perpetual 2% treadmill;
  Progressive's is finite and killable, and killing it is how you take the city.
  This gives an endless trading sim a last act.

---

## D5 — Heat (settled)

**Heat lives in both modes**, randomized like the original's police encounters — it
must not be Progressive-only, or Classic quietly loses a system it already has.

It generalises something already in `SPEC.md` §10: paying off debt currently drops
the GSP chase to 2% and the undercover cop to 1%. That is police pressure modulated
by player state. Heat makes that a real meter instead of a single bonus.

- **Rises** from carrying volume, selling hard, and (in Progressive) growing
  territory — a slight escalation, not a spike.
- **Modulates existing encounter rates** (`SPEC.md` §8): MARTA 3%, Ryde 3%,
  Drive 6%, Water Boys 8%, YNs 10%.
- **Falls by laying low in one place** — a new verb for the game.
- Makes luck legible: the player can influence the odds instead of only suffering
  them.

---

## D6 — Failure model in Progressive (settled)

With no day cap there's no "you ran out of time." Failing is a **setback, not an
ending**: a raid takes product, a jail hit costs cash and days. Momentum-based and
forgiving.

**The one exception:** defaulting on the Councilman ends you. That's what keeps the
lender a real decision instead of free money, and it's the only debt in the game
that terminates a run.

---

## D7 — Multiplayer (settled: parked)

Multiplayer was motivated by wanting more depth. Depth is cheaper to get from
Progressive plus the economy fix, so multiplayer comes off the near roadmap.

`SPEC.md` §15 ("Deal or Fight", leaderboard, anonymous auth) and
`docs/MULTIPLAYER_DESIGN.md` (Nakama server, Free Market / Team Up / Speed Run)
stay on disk as reference. **No work is scheduled.** Nothing in `lib/` implements
any of it today.

---

## Open — needs a decision before spec

1. **Sell-anywhere vs. align stock lists** (D2 rule 1). Sell-anywhere is recommended;
   it's the original's rule and it decouples the table from randomized availability.
2. **Heat's decay shape** — automatic per day, or only when you lay low in one place?
   Decides whether heat is a meter to manage or a slope to ride.
3. **Threshold values** for the informant's cash marks, per difficulty.
4. **Does the day counter stay visible in Progressive?** Recommendation: yes, keep
   "Day N" for flavour, drop only the deadline.
