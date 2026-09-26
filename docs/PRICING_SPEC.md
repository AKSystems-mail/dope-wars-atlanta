# Pricing & The Ring — Implementation Spec

> **Status: DRAFT for review.** Rationale: `DESIGN_DECISIONS.md` D1, D2, D8, D10, D11, D14.
> Ships **before** Progressive mode, because it changes Classic too.

---

## 1. Order of work — do not reorder

1. **Materialize the market on arrival.** Prices and shelf resolved once per arrival and
   held. This is first because everything else is built on a price that currently does not
   hold still (traps 1 and 8).
2. **Per-hood multipliers and the ring.**
3. **Reputation on the location card** (D11, D14).

---

## 2. The price model

Today `GameState.getPrice()` takes a base price and rolls noise, and every hood references
the same `Product.defaults` instances — so location has no economic effect at all.

**The model is one local *level* per (hood, product), with buy and sell both derived from
it.** That makes the same-hood margin structural rather than a rule someone has to remember.

```
level(p, hood) = base(p) × valueMult(hood, p) × eventMult(hood, p) × jitter

buy(p, hood)  = round(level × 1.0625)
sell(p, hood) = min(round(level × 0.9375), buy - 1)

jitter     = uniform(0.85, 1.15), rolled ONCE per arrival and held
valueMult  = 0.70 at the product's cheap source · 1.50 at its premium market · 1.00 otherwise
eventMult  = 1.50 on a demand spike · 0.30 on a market flood · 1.00 otherwise
```

`sell / buy = 0.882` always — the "slightly negative" margin from D1. A round trip in one
hood cannot profit, whatever the multipliers or events do.

**Why not `sell = buy × 0.875 × premiumMult` (the first draft in this file):** it allowed a
buy-back loop. Any sell-side multiplier above `1 / 0.875 = 1.143` makes local selling
profitable, and the premium multiplier is 1.50 — so buying a premium hood's own product and
selling it straight back would have printed money, repeatably, in one visit. Driving both
sides off one level is immune to that, and it means the `same_hood_loses` check is a
regression guard rather than the only thing standing between the game and an exploit.

Worked example, shrooms (base 150): buy at its cheap source `150 × 0.70 × 1.0625 = 111.6`;
sell at its premium market `150 × 1.50 × 0.9375 = 210.9`. Spread ≈ 1.89x, profit ≈ 0.66 ×
base per unit.

**Events move the level, not one side.** A spike lifts the level, so both prices rise in
step: it is a *destination* premium (bring goods to the hood that wants them), never a local
buy-back loop. This also means events and hood multipliers compose as one formula rather
than two systems fighting (trap 2).

**Retires `baseSellPrice` and `highPrice`** — both become derivable. Demand Spike and Market
Flood stop being absolute-value pushes and become `eventMult`. The product table in
`SPEC.md` §3 loses its Min/Max columns.

---

## 3. The ring

Each product has exactly one cheap source and one premium market:

| Product | Cheap source (buyMult 0.70) | Premium market (sellMult 1.50) |
|---|---|---|
| Blunts | Buckhead | Decatur |
| Acid | Decatur | Little Five |
| Shrooms | Little Five | Midtown |
| Oxy | Midtown | West End |
| Powda | West End | Buckhead |

**Cobb County** is off-ring by design: premium on **oxy and shrooms**, no cheap source. A
cash-out detour, road-only, most expensive to reach.

Magnitudes vary ±10–15% per run via `jitter`. Hood personalities never rotate.

---

## 4. Shelf rules

- **Guaranteed:** each hood always stocks its cheap-source product, so a lap can always be
  started. Buckhead additionally always stocks its premium (powda) — home should always be
  a place you can cash out.
- **Proposed fill-in — Cobb has no cheap source,** so its guarantee has to be defined. Fix:
  **Cobb always stocks oxy** (one of its two premiums), so a Cobb trip is never wasted.
- **Randomized per visit, not per game:** the remaining 2–3 slots. Count floor 3–5 products
  per hood so no shop reads as broken.
- **You can only buy and sell what a hood stocks this visit.** Arriving with product a hood
  doesn't want is intended risk (D8).

---

## 5. The market object

On arrival, resolve and **persist into the save**:

```json
"market": {
  "hoodId": "decatur",
  "visitIndex": 7,
  "shelf": ["acid", "blunts", "shrooms"],
  "prices": { "acid": {"buy": 38, "sell": 33}, "blunts": {"buy": 60, "sell": 79} }
}
```

Held until the next arrival. **Persisted rather than derived** — it is the simplest thing
that kills both the reroll exploit and the flickering price, and it is debuggable. (A
deterministic `hash(seed, hood, visitIndex)` would also work and saves a few bytes; not
worth the indirection.)

`visitIndex` increments per arrival so the roll can never be replayed.

---

## 6. Reputation on the location card

For hoods in `knownHoods` only, show two lines on the existing `location_card.dart`:

```
Decatur — college town
Known for: cheap Acid · Pays for: Blunts
```

Classic fills `knownHoods` on first visit; Progressive via the informant (D14). The shelf
stays hidden either way.

---

## 7. Checks — one per non-trivial rule

- `same_hood_loses`: for every hood, selling any product it stocks in the same hood is a
  loss. Guards the money-printing exploit.
- `ring_profits`: buy each hood's cheap source, sell that product in its premium market —
  positive for all five. Guards the ring table.
- `market_is_stable`: resolving the same arrival twice yields identical prices. Guards the
  reroll/flicker bug.
- `shelf_guarantee`: the guaranteed product is present across N rolls; count stays 3–5.
