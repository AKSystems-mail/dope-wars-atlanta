# Dope Wars — Atlanta

> A modernized Drug Wars tribute set in Atlanta, GA.
> Flutter (Android) + Firebase backend.

---

## 1. Core Gameplay Loop

1. Player arrives at a location (starts in **Buckhead**)
2. Check product prices (3–5 products available per location, randomized at game start)
3. **Buy** low → **Travel** (costs 1 day) → **Sell** high
4. Survive random encounters, police, and rival gangs
5. Repeat until Day 30 / 60 / 90
6. **Highest net worth wins** (cash + bank + inventory value − debt)

---

## 2. Locations (6)

| Location | Special Feature |
|---|---|
| **Midtown** | 🏦 Bank (deposit/withdraw, earns interest) |
| **Buckhead** | 👔 Councilman (starting location, pay debt, borrow more, bailout) |
| **Cobb County** | 🚫 Travel restricted — Ryde or Drive only. Most expensive routes |
| **Little Five Points** | 🎒 Bookbag upgrades |
| **Decatur** | — |
| **West End** | 🔫 Weapon shop |

Each location has 3–5 products available, randomized at game start (not all products at all locations).

Product availability is **hidden** until the player arrives at that location.

---

## 3. Products (5)

| Product | Base | Min | Max |
|---|---|---|---|
| **Blunts / Pre Rolls** 🚬 | $60 | $40 | $120 |
| **Oxy** 💊 | $20 | $5 | $80 |
| **Shrooms** 🍄 | $150 | $70 | $350 |
| **Powda** ❄️ | $120 | $60 | $325 |
| **Acid** 🎨 | $55 | $10 | $130 |

### Pricing Algorithm

- **Normal day**: price = base × random(0.7 to 1.3) at each location
- **Demand spike** (~15% chance on arrival): one product pushed toward **max** — popup: *"Demand is through the roof! Prices are sky high!"*
- **Market flood** (~10% chance on arrival): one product pushed toward **min** — popup: *"The market is flooded! Everything is cheap!"*

---

## 4. Starting State & Difficulty

| Difficulty | Starting Cash | Starting Debt | Name |
|---|---|---|---|
| 🟢 Easy | $6,000 | $5,000 | **Mount Paran** |
| 🟡 Normal | $4,000 | $10,000 | **East Atlanta** |
| 🔴 Hard | $2,000 | $15,000 | **Hapeville** |

- **Starting location**: Buckhead (same as Councilman)
- **Inventory**: Bookbag (capacity 100), empty
- **Starting weapon**: Fists

### Game Duration
30 / 60 / 90 days. Selected in Settings at game start.

---

## 5. Inventory & Bookbag

**Bookbag capacity** starts at **100**. Upgrades only available in **Little Five Points**:

| Capacity | Cost |
|---|---|
| 100 | Starter |
| 250 | $400 |
| 600 | $1,000 |
| 1,000 | $3,000 |

- Bookbag capacity and current count displayed next to Debt in the stats bar
- Cannot buy product when inventory is full
- **Sell All** button available next to Sell (sells all of one selected product type)

---

## 6. Weapons

Weapons only available in **West End**:

| Weapon | Cost | Win % | Uses Before Break | Notes |
|---|---|---|---|---|
| 👊 **Fists** | Free | 45% | ∞ | 2-minute cooldown after use |
| 🔫 **Blicky** | $300 | 52% | 5 | Breaks after 5 fights, removed from inventory |
| 🔫 **Strap** | $550 | 63% | 5 | Same |
| 🔫 **Draco** | $3,000 | 77% | 5 | Same |

---

## 7. Travel System

**Every travel = 1 day** advances. 5-second animation overlay matching transport type.

### Transport Options

| Method | Cost | Cobb County? | Cooldown |
|---|---|---|---|
| 🚇 **MARTA** | $5 | ❌ No | — |
| 🚗 **Ryde** | $25–$60 (surge pricing) | ✅ Yes | 1 min |
| 🚙 **Drive** | $20 | ✅ Yes | — |

### Surge Pricing (Ryde)
Price fluctuates based on **real-time Atlanta time**:
- **2 PM – 6 PM** (Atlanta time): highest rates ($50–$60)
- **Late night (1 AM – 5 AM)**: cheapest ($25–$35)
- Otherwise: standard $35–$45
- This applies regardless of the player's actual time zone

### Map
- Travel button opens an Atlanta highway map
- Player taps a location to travel there
- **Cancel button** on the travel widget

---

## 8. Random Encounters

### 🚇 MARTA (3% trigger)

| Action | % | Result |
|---|---|---|
| **Run 🏃** | 97% escape | 💨 Clear |
| Run — caught | 3% | Lose 4% inventory + 2% cash |
| **Fight 👊** | 25% subdue | ✅ Move on |
| Fight — lose | 75% | Lose 11% inventory + 15% cash |
| **Arrest** | — | Councilman bailout ($200–$600 added to debt) |

Run/Fight situations only happen **once per travel turn**.

### 🚗 Ryde (3% trigger — undercover cop)

| Outcome | % | Result |
|---|---|---|
| **Bribe** | 40% | Success — continue to destination |
| **Arrest** | 8% | Lose all inventory + half cash. Continue playing |
| **Nothing** | 52% | Proceed normally |

### 🚙 Drive (6% trigger — GSP chase, 75% caught)

- **Arrest** → Councilman bailout ($500–$1,000 added to debt)
- GSP is intentionally aggressive. Drive is high-risk, high-speed.

---

## 9. Special Location Events

### Water Boys — Driving to Midtown (8% chance)
- Lose **30% of inventory** automatically

### YNs — Traveling to West End (10% chance)

| Condition | Options |
|---|---|
| **No weapons (Fists only)** | Automatic — lose **80% inventory** |
| **Has weapons** | **Run** (78% escape, drop 20% inv) or **Fight** (50% win / 50% lose = **game over**) |

---

## 10. Councilman & Debt

- **Starting debt**: $10,000 (for Normal), $5,000 (Easy), $15,000 (Hard)
- **Interest**: 2% per day
- **Located in**: Buckhead (also the starting location)
- **Functions**:
  - Pay off debt (reduces interest drain)
  - **Borrow more** (take additional loans)
  - **Bailout** from MARTA/GSP arrest → added to debt
  - **Bankruptcy bailout** (when cash or inventory hits 0) → heavy debt added, continue playing
- **Bonus**: If debt is fully paid off:
  - GSP chase chance drops to **2%**
  - Undercover cop chance drops to **1%**

---

## 11. Bank

- **Located in**: Midtown
- Deposits earn **interest**
- Protects cash from being lost in some encounters
- Contributes to final net worth score

---

## 12. Game Over & Win

### Game Over Triggers
- **Cash = $0** (can accept Councilman bailout → severe debt)
- **Inventory = 0** (same bailout option)
- **Lose West End YN fight** — death, no bailout

### Win Condition
- Survive all days (30/60/90)
- **Final Score** = Cash + Bank Balance + (Inventory × estimated value) − Total Debt
- Highest net worth wins

---

## 13. Settings

| Option | Values |
|---|---|
| **Sound** | On / Off |
| **Game Duration** | 30 days / 60 days / 90 days |
| **Difficulty** | Mount Paran / East Atlanta / Hapeville |

- **Gear icon** (⚙️) to the right of the Day counter opens Settings popup
- Changing Duration or Difficulty triggers a **warning** and starts a new game
- Changing Duration is **not** reflected retroactively in the Day counter

---

## 14. UI & Visual Design

### Color Palette

| Token | Color | Usage |
|---|---|---|
| `bg-game-background` | `#1a1625` | Main background |
| `bg-game-card` | `#2a2438` | Cards, stats bar |
| `text-game-accent` | `#00ff9d` | Bright green — primary accent |
| `text-game-accent2` | `#ff00f7` | Bright pink — secondary accent |
| `text-white` | `#ffffff` | Default text |
| `text-gray-400` | `#9ca3af` | Secondary text |

### Layout
- **Stats bar** (Cash, Debt, Day, Bookbag capacity/count) anchored to top at all times
- **Market items**: white text, accent-colored prices
- **Location cards**: glow effect with `border-game-accent`
- **Travel overlays**: `bg-black/80` with green transport icons
- **Dialogs**: game card background color
- White bars removed from location screens

### Fonts
- Permanent Marker
- Lacquer
- Splash
- Press Start 2P
- Protest Revolution

### Animations
- 5-second transport animation overlay on travel:
  - 🚇 MARTA — Train icon
  - 🚗 Ryde — Local Taxi icon
  - 🚙 Drive — Drive ETA icon
- Travel widgets: fade in / slide in animations
- **MARTA chime**: subway door closing sound (`marta-chime.mp3` in assets)

---

## 15. Backend (Firebase)

### Multiplayer: Deal or Fight (Turn-Based)

When two players are in the **same location**, both are notified.

**Initiator chooses:**
1. **Deal** 🤝 — Propose a trade: "X units of Product A for Y units of Product B (or $Z)"
   - Recipient can **Accept**, **Counter-offer**, or **Decline**
   - If accepted, trade executes immediately
2. **Fight** ⚔️ — Turn-based combat

**Fight Rules:**
- **Best of 3 rounds** — each round both players roll their weapon's win%. Higher roll wins the round. First to 2 wins the fight.
- Before the fight, choose which weapon to use from equipped inventory
- **Flee** option: forfeit the fight, drop 15% inventory + 10% cash. Winner collects the spoils. Loser continues playing.
- Winner takes a portion of the loser's remaining inventory + cash
- Loser continues playing (not game over)

### Weapons Inventory

- **Separate from the bookbag** — weapons don't compete with drug inventory space
- **Max 3 weapon slots** (always have Fists as default backup)
- **Auto-switch on break** — when a weapon hits 0/5 uses, the next equipped weapon auto-takes its place in subsequent fights
- Choose which weapon to equip before each multiplayer fight
- Weapons available for purchase in **West End** only

### Leaderboard
- Based on inventory value + available cash
- Displayed at end of game

### Authentication
- Unique player names
- Anonymous Firebase auth

### Save State
- Auto-save game state
- Resume interrupted games

---

## 16. Events Summary

| Event | Trigger | Probability | Effect |
|---|---|---|---|
| Demand spike | Arrival at location | ~15% | One product → max price |
| Market flood | Arrival at location | ~10% | One product → min price |
| MARTA police | MARTA travel | 3% | Run/Fight/Arrest |
| Undercover cop | Ryde travel | 3% | Bribe/Arrest/Nothing |
| GSP chase | Drive travel | 6% (75% caught) | Arrest → bailout |
| Water Boys | Drive to Midtown | 8% | Lose 30% inventory |
| YNs | Travel to West End | 10% | Lose 80% or Run/Fight |
