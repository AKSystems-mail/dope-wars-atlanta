# Progressive Mode — Implementation Spec

> **Status: DRAFT for review.** Rationale: `DESIGN_DECISIONS.md` D3, D4, D12–D17.
> Depends on `PRICING_SPEC.md` (the ring must exist for any of this to mean anything).

---

## 1. Mode config

| | Classic | Progressive |
|---|---|---|
| Hoods at start | all six | **Buckhead + Decatur** |
| Unlocks | n/a | **4** (informant), to reach six |
| Day cap | 30 / 60 / 90 | **same** |
| Difficulty | cash + debt + duration | **same table** |
| Heat | on, invisible | on, **bare state word** |
| Reputation | on first visit | **when the informant tells you** |
| Win | highest net worth at the cap | **own the city**: six hoods + debt cleared |
| After the win | end screen | **play on**; heat climbs, no decay, no bailout |

Progressive is a configuration of the same engine. Classic is unaffected by every row
except the heat row, which both modes share.

---

## 2. Starting state

Buckhead and Decatur unlocked — **and they are deliberately the first ring leg.** Buckhead
is the cheap blunts source and Decatur pays premium for blunts, so the opening trip teaches
the whole mechanic in one hop. That is not luck; do not reorder the ring table without
redoing this.

**The opening is road-only.** MARTA requires the MARTA card, found after the first sale
(§6), so early travel is Drive ($20) or Ryde ($25–60).

**Difficulty is unchanged** — starting cash, debt, and duration from the existing tiers.

---

## 3. Unlock sequence

**Proposed order, walking the ring:** Little Five → Midtown → West End → Cobb.

Deriving the order from the ring means every unlock extends an arc the player can already
run, and each new hood is immediately a buyer or a source for what they already carry.

*Consequence worth accepting deliberately:* a fixed order means every Progressive run is
the same route. That is good for learnability — the map is an atlas you can memorise — and
variance still comes from the shelf, the informant's timing, and heat. If replay variety
matters later, rotate the order from a small fixed set; it is a data change.

**Budget check (from `DESIGN_DECISIONS.md`):** four unlocks at p = 0.40 costs ~10 arrivals,
which fits a 30-day run alongside 3–5 trading legs. Money is not the constraint; the hunt is.

---

## 4. The informant

The mode's gate, guide, and only story delivery. Uses the existing choice-dialogue system
(`_setEncounterWithChoices` / `EncounterChoice` / `encounter_overlay.dart`) — this is
content, not new engineering.

- **Armed by a cash threshold.** Threshold values are tuning, set at build.
- **Appears on a roll** once armed: any unlocked hood **except Cobb**, p ≈ 0.4–0.5.
- **Tail is bounded — this rule matters more than p:** armed means he appears **within 3
  arrivals**. Pure randomness has a run-ruining tail; at p = 0.25 about one run in eighteen
  sees nothing across ten arrivals, and that player loses without being able to tell why.
- **Never in Cobb County.** Cobb is road-only and the most expensive hood to reach; progress
  behind it would be a soft-lock risk.
- **Fee: 1–5 units of any product except the hood's own cheap source.** A category rule,
  not a named item (D17) — so it is always payable from the bag, and the cost stays in goods
  rather than in days. The tension is the point: goods handed over are goods not sold.
- **Refusing delays, it never loses.** He reappears.
- **Reward:** unlocks the next hood in the sequence *and* adds that hood to `knownHoods`,
  so its reputation appears on the location card. The teaching is the tip's reward.

---

## 5. Heat

Lives in **both** modes. Generalises the existing rule in `SPEC.md` §10, where clearing the
debt drops the GSP chase to 2% and the undercover cop to 1% — police pressure already
modulated by player state.

- Internal integer, 0–100. **Never displayed as a number** (D9).
- **Classic: invisible.** The player should suspect, not audit.
- **Progressive: a bare state word** — Cool / Warm / Hot — plus diegetic signals (more
  cops, the world reacting).
- **Rises** from carrying volume, selling, growing territory (Progressive), and random
  events. Slight and gradual.
- **Falls only by laying low in one place** — an explicit action that costs a day. This is
  what gives the mechanic bite in a capped run: patience is not free.
- **Modulates the §8 encounter rates** (MARTA 3%, Ryde 3%, Drive 6%, Water Boys 8%,
  YNs 10%). One formula: heat scales the rate, and the debt-cleared bonus is the floor.
- **Post-win (Progressive): decay is disabled and heat only climbs.**

---

## 6. Dropped items

The MARTA card is the **first instance of a general mechanism, not a special case**: an item
found rather than bought. Found after the first sale, and later after fights.

- Store as `items: { "marta_card": true }` so future drops need no schema change.
- **Bearing on travel:** MARTA is unavailable in Progressive until the card is found. Classic
  is unchanged — it keeps MARTA from the start.
- *Scope note:* the broader drop table (which items, which fight outcomes) is **not specified
  here.** This spec only claims the card and the storage shape.

---

## 7. Save schema

Every field defaults so existing saves load as Classic / all hoods / heat 0.

| Field | Values | Notes |
|---|---|---|
| `mode` | `classic` \| `progressive` | default `classic` |
| `unlockedHoods` | string[] | Progressive only; Classic = all six |
| `knownHoods` | string[] | Classic: by visit · Progressive: via informant |
| `heat` | int 0–100 | default 0 |
| `items` | map<string,bool> | dropped items; MARTA card is the first |
| `market` | object | current visit's shelf + prices (`PRICING_SPEC.md` §5) |
| `informant` | `{armed, sightings, pendingHood}` | Progressive only |

Additive only. Classic's existing save must load byte-for-byte unchanged in behaviour.

---

## 8. Post-win behaviour

No bailout. The councilman declines, in dialogue:

> *"I think you can take care of yourself these days."*

Thematically that is the payoff: the man who staked you at the start is the one who tells
you you're done needing him. Heat climbs with decay disabled; the run ends when you are out
of product or out of money.

---

## 9. Where each trap is answered

Trap numbers refer to `DESIGN_DECISIONS.md` → Loose ends → Implementation traps.

| Trap | Answered in |
|---|---|
| 1 shelf reroll · 8 price flicker | `PRICING_SPEC.md` §1, §5 |
| 2 events vs multipliers | `PRICING_SPEC.md` §2 |
| 3 heat vs debt bonus | §5 of this file |
| 4 never reuse `isTravelable` | §7 (`unlockedHoods` is save state) |
| 5 save schema + Classic compat | §7 |
| 6 locked hoods, no soft-locks | §3, §4 (Cobb never gates) |
| 7 lay low needs an affordance | §5 |
| 9 what the multiplier multiplies | `PRICING_SPEC.md` §2 |
