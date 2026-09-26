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
the same `Product.defaults` instances — so location has no economic effect at all. The
model below replaces it. **Sell is always derived from the local buy price**, so there is
one source of truth and no separate sell base that can drift.

```
buy(p, hood)  = round(base(p) × buyMult(hood, p) × jitter)
sell(p, hood) = round(buy(p, hood) × SAME_HOOD_MARGIN × sellMult(hood, p))

jitter          = uniform(0.85, 1.15)      # rolled once per arrival, then held
SAME_HOOD_MARGIN = 0.875                   # D1: a round trip in one hood always loses
buyMult(hood, p)  = 0.70 if p is hood's cheap source, else 1.00
sellMult(hood, p) = 1.50 if p is hood's premium market, else 1.00
```

Worked example, shrooms (base 150): buy in its cheap hood at `150 × 0.70 = 105`; sell in
its premium hood at `105 / 0.70 × 0.875 × 1.50 = 196.9`. Spread 1.875x base, profit
≈ 0.61 × base per unit.

**Retires `baseSellPrice` and `highPrice`.** Demand Spike and Market Flood become
multipliers on this same pipeline (spike ×1.50 on sell, flood ×0.30 on buy) instead of
absolute values, so there is one formula rather than two systems fighting (trap 2). This
changes the product table in `SPEC.md` §3 and needs a matching doc edit.

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
