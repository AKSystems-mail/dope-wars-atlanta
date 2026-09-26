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

## D2 — Product preference table (SETTLED — ring approved)

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

**Magnitudes vary ±10–15% per run; hood personalities do not.** Learn the city once,
relearn the margins each run. Fully randomizing *which* hood wants *what* would
destroy the mental-atlas feel that makes Progressive work.

**Shop and availability rules: see D8.**

---

## D3 — Two single-player modes, one engine (settled)

**Classic** and **Progressive** are single-player. Multiplayer is a separate axis,
not a third peer. Naming per the house rule: clear, not clever.

**Progressive is a configuration toggle, not a second engine.** The same screens,
the same save format with more fields set. What it flips:

- start location and which hoods are unlocked
- day cap **same as Classic** — 30/60/90 still apply (revised from "cap off"; see D12)
- heat on
- win condition: **own the city within the cap** — all six hoods unlocked and the
  councilman cleared before the days run out
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

## D8 — Availability, shelves, and the sell rule (settled)

**Stable ring, volatile shelves.**

- **Every hood always stocks ONE of its two ring products** — either its cheap source
  or its premium market. Which one is a per-hood design choice, so sourcing and
  cashing out are not equally reliable.
- **Every other product is randomized per VISIT, not per game.** Arrive in Buckhead
  and it might also have Oxy and Shrooms; come back later and it might have only
  Acid. `SPEC.md` §2 said "randomized at game start" — that becomes per-visit.
- **This makes "availability is hidden until you arrive" meaningful every time**,
  not once at game start. Arrival stays an event.
- What the player memorises is **who pays for what and who is cheap** — the ring.
  What stays uncertain is **what's on the shelf right now**.

**The sell rule (settled): you can only buy and sell what a hood stocks this visit.**
Sell-anywhere is **rejected**. Arriving with product a hood doesn't want is
**intended risk, not a defect** — hauling goods to a market that doesn't want them is
the original's sting, and it stays. What the guarantee buys is a reliable spine: some
legs always work, the rest are a gamble.

**Proposed assignment of the guaranteed slot:** every hood guarantees its **cheap
source**, so a lap can always be *started* — and **Buckhead additionally guarantees
its premium**, because it's home and closes the loop, making it the one place you can
always cash out. The other premiums stay a hunt.

**Count floor:** the guaranteed slot plus 2–3 random others, keeping 3–5 products per
hood as `SPEC.md` §2 requires. A hood offering a single product reads as broken.

**Implementation note:** availability must be computed **per arrival** rather than
read from the `Location.products` const, and must **not** be persisted in the save —
it isn't state the player owns. That also keeps it out of Classic's save format.

---

## D9 — Heat surfacing: state, not a number (settled)

Heat is **mechanically** a number; the player never sees the number.

**Settled: no meter, no number — show a state.**

- A 0-100 bar invites min-maxing the police instead of playing the street, and it
  adds a HUD element competing with the legibility pass that just made everything
  bigger.
- **Classic keeps heat invisible**, preserving the original's "random cops" feel.
  The player should suspect, not audit.
- **Progressive shows a bare state word** — Cool / Warm / Hot — and nothing more. The
  signal also arrives diegetically: cops get more frequent and the world reacts.
- Cost is identical either way: the number exists internally, the UI simply doesn't
  print it.

---

## D10 — When a hood's premium actually fires (PROPOSED)

"When does West End's oxy premium show up?" is really two questions, because two
different things are called "the premium":

- **The preference is permanent.** West End pays +50% for oxy on **every** visit. It's
  the hood's identity and it never moves or rotates.
- **The stock is per visit.** With only the cheap source guaranteed, oxy appears at
  West End solely on visits whose random roll includes it — roughly **half to
  three-quarters** of visits under a "guaranteed + 2–3 random" draw.

So the premium is live every single time; there's just nothing to sell into unless the
shelf has it. A trip that finds no oxy costs fare, a day, and leaves you carrying.

**Settled: fully random. No weighting.** The premium's appearance is whatever the
per-visit roll gives — expect it on roughly half to three-quarters of visits. A trip
that finds nothing is accepted as the original's risk, consistent with the sell rule
in D8.

Consequence worth naming: the player **cannot distinguish "they don't buy this" from
"they don't have it today"** — both look identical at the shop. That is exactly why
the surfacing question below matters. Randomness is only legible against a known
baseline.

**It also has to be learnable.** An invisible ring makes the design read as noise
rather than depth, so surface the stable facts and hide only the volatile one:

- **Public:** what a hood is known for (its cheap source) and what it pays for (its
  premium) — shown on the location card the game already has (`location_card.dart`).
- **Hidden:** what's on the shelf this visit — `SPEC.md` §2, unchanged.

Hood reputation is knowledge; today's shelf is a roll. That split is exactly what makes
the map an atlas instead of a slot machine.

**Stacking:** a hood premium (+50%) and a Demand Spike (8% on arrival, one product
pushed toward max) can land on the same product. **Let them stack** — a rare jackpot,
and it costs nothing because both systems already exist.

---

## D11 — How the ring reaches the player (settled for Progressive)

**The location card, introduced by the informant.** A hood's **reputation** — what it's
known for (cheap source) and what it pays for (premium) — appears on the existing
`location_card.dart`. The **shelf** stays hidden per `SPEC.md` §2.

- **Progressive:** the informant introduces a hood's reputation as part of the tip, so
  the player knows before they travel. That teaching *is* the tip's reward.
- **Classic: still open.** Reputation cannot be Progressive-only — the economy fix
  ships in Classic *first*, so Classic would get more complex while staying opaque.
  Options: (a) all six visible from the start — zero new state, and Classic's identity
  is optimization, not discovery; or (b) revealed on first visit — one new save field,
  and closest to the original, where a single visit taught you everything.

---

## Loose ends

### Settled this round

**D12 — Progressive runs on the same clock as Classic.** Progressive keeps the
30 / 60 / 90 duration options. This supersedes the earlier "day cap off" line in D3.
The two modes now differ by **world and goal**, not by time model:

- **Classic** — every hood open from turn one; maximise net worth before the days run
  out. A score attack.
- **Progressive** — the city opens as you earn it; **own the city within the cap** —
  all six hoods unlocked and the councilman cleared before the days run out.

Consequences worth stating: `maxDays` stays meaningful in Progressive, so time remains
a real cost and **laying low costs days** — which is what gives heat its bite. Reaching
the cap with the city unfinished ends the run with a score rather than a win, and that
is the mode's honest failure state.

**D13 — The informant.** Settled rules:

- **Threshold-armed, randomly appearing.** Hitting a cash mark arms the next encounter;
  he then turns up at random on arrival, in any hood. You cannot summon him and you
  cannot rush him — the milestone gates *whether*, the roll gates *when*.
- **Never in Cobb County.** Cobb is road-only and the most expensive hood to reach;
  putting progress behind it would be a soft-lock risk (see trap 6).
- **Paid in product, not cash.** A tip costs a named product and quantity. This is the
  mode's central tension in one rule: **progression competes with commerce** — the
  goods you hand him are goods you didn't sell.
- **Refusing delays, it does not lose.** He reappears. No hard-lock, no punishment for
  not carrying the goods yet.

**D14 — Reveal rules.** One field, `knownHoods`, with two population rules:

- **Classic:** a hood's reputation appears on its location card **on first visit** —
  closest to the original, where one visit taught you everything.
- **Progressive:** it appears when the informant tells you, so you know before you
  travel. That teaching is the tip's reward.

**D15 — Difficulty is unchanged in both modes.** Starting cash, starting debt, and
duration. The existing three-tier table applies to Progressive as-is, because D12 gives
Progressive the same clock.

### Still open

1. **Progressive's ending presentation** — end screen, or keep playing past the win?
   The mechanics are settled (the cap ends the run); this is only what the player sees.
2. **What the informant asks for** — which product and quantity, per tier. Content and
   tuning, not structure.

### Implementation traps — no decision needed, but they must be in the spec

1. **Save-scumming the shelves.** Availability is per-arrival and deliberately *not*
   persisted, so closing and reopening the app at the same hood would reroll a fresh
   shelf for free, forever. Derive the roll from a saved seed + hood + visit counter so
   it stays stable until the player actually arrives again.
2. **Events vs multipliers.** Demand Spike and Market Flood currently use absolute
   `highPrice` / `baseBuyPrice`. With hood multipliers they must compose —
   `base × hood × event` — or the two systems fight. This is a money path.
3. **Heat vs the debt bonus.** Heat scales the same §8 encounter rates that the
   debt-cleared bonus already lowers to 2% / 1%. Needs one stated formula: heat scales
   the rate, and the debt bonus is the floor (or the cap).
4. **Do not reuse `isTravelable` for gating.** It's a per-location constant marked
   "reserved for future multiplayer"; Progressive gating is per-save state. Sharing them
   means mutating a constant at runtime and leaking unlocks between saves.
5. **Save schema and Classic compatibility.** New fields: mode, unlocked set, intel set,
   heat. Existing saves must load unchanged — Classic, all hoods, heat 0.
6. **Locked hoods on the map.** They need a visual state, and no unlock order may leave
   a hood reachable only through another locked one. No soft-locks.
7. **Lay low needs an affordance.** If heat only drops through an explicit action, the
   UI needs a verb for it or the mechanic is invisible.
8. **Prices reroll on every rebuild — the displayed price is not the charged price.**
   `_ProductRow.build()` calls `getBuyPrice` / `getSellPrice`, and `GameState.getPrice`
   constructs `Random()` fresh on every call. So every rebuild of a product row rolls a
   new number, and `buyProduct` rolls *again* at the moment of purchase. The shop
   currently shows a random draw and charges a different one.

   **This shares its fix with trap 1: materialize the market on arrival.** Shelf *and*
   prices resolved once, seeded from save state, held until the player next arrives.
   That single mechanism kills the reroll exploit and the flickering price together —
   and it's the only way "Decatur pays 1.4x for shrooms" becomes a fact a player can
   learn, rather than a distribution re-rolled per frame. It should therefore land
   **first** in the pricing phase, before multipliers, because everything else is built
   on a price that currently doesn't hold still.

### Tuning, not design — defer to build

Heat gain and decay rates, the Cool / Warm / Hot bands, and the informant's cash
thresholds. Numbers that need playtesting, not a design ruling.
