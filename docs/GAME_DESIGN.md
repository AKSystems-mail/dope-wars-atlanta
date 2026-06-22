# Dope Wars Atlanta — Game Design Document

> **Version:** 1.0.0  
> **Status:** In Development  
> **Genre:** Trading / Simulation / Strategy  
> **Art Style:** Retro pixel + neon (80s Miami / Atlanta hybrid)  
> **Target Audience:** Mature 17+ (drug themes, adult humor)

---

## 1. Game Overview

Dope Wars Atlanta is a turn-based trading simulation set in Atlanta, Georgia. Players travel between neighborhoods buying and selling automotive fluids (stand-in for illicit substances), managing debt, avoiding law enforcement, and building their empire within a limited time frame.

### 1.1 Core Loop

```
┌─────────────────────────────────────────────────┐
│                  MAIN MENU                        │
│        [New Game] [Load Game] [Settings]          │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│           DIFFICULTY SELECTION                    │
│  Mt Paran (Easy) │ E Atlanta (Normal) │ Hapeville│
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│             BOOT SCREEN (4s intro)                │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              GAME LOOP (main screen)              │
│                                                   │
│  ┌────────── HUD (cash, day, debt, bag) ───────┐ │
│  │                                               │ │
│  │  Current Location: Five Points                │ │
│  │                                               │ │
│  │  [Shop]  [Map]  [Bag]  [Bank]  [Menu]        │ │
│  │                                               │ │
│  │  ┌───────────────────────────────────────┐    │ │
│  │  │  Location Connections:                │    │ │
│  │  │  - West End (MARTA $5 / Ryde $25-60) │    │ │
│  │  │  - Midtown (Drive $20)               │    │ │
│  │  │  - Little Five (MARTA $5)            │    │ │
│  │  └───────────────────────────────────────┘    │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  Player selects: Travel to [Location] via [Mode]    │
│         │                                            │
│         ▼                                            │
│  Travel Animation (5s)                               │
│         │                                            │
│         ├── Encounter? ──► Choice ──► Consequence   │
│         │         │                                   │
│         │         └── Continue                        │
│         │                                             │
│         ▼                                             │
│  Arrived at [New Location]                            │
│         │                                             │
│         ▼                                             │
│  Ad Overlay (2s dismissable)                          │
│         │                                             │
│         ▼                                             │
│  ┌─── Shop? ──► Buy/Sell UI ──► Profit/Loss ──┐     │
│  │   Bank?   ──► Deposit/Withdraw              │     │
│  │   Bag?    ──► View inventory / equip weapon │     │
│  └──────────────────────────────────────────────┘     │
│                                                       │
│  Day advances with each travel action                 │
│  2% daily interest on debt (applied each tick)        │
│                                                       │
│  Game ends when:                                      │
│  - maxDays reached (win if net worth > 0)            │
│  - cash <= 0 AND debt > 0 (bankrupt = game over)     │
└───────────────────────────────────────────────────────┘
```

---

## 2. Difficulty Modes

### 2.1 Mt Paran (Easy Mode)

| Parameter | Value |
|---|---|
| Starting Cash | $15,000 |
| Starting Debt | $0 |
| Max Days | 30 |
| Encounter Rate | 50% of normal |
| Interest Rate | 1% daily |
| Starting Weapon | Bat |
| Description | "You're from the suburbs. Mom and Dad's basement is still an option." |

### 2.2 E Atlanta (Normal Mode)

| Parameter | Value |
|---|---|
| Starting Cash | $8,000 |
| Starting Debt | $2,000 |
| Max Days | 20 |
| Encounter Rate | 100% |
| Interest Rate | 2% daily |
| Starting Weapon | Fists |
| Description | "You know the streets. East Atlanta knows you." |

### 2.3 Hapeville (Hard Mode)

| Parameter | Value |
|---|---|
| Starting Cash | $5,000 |
| Starting Debt | $5,000 |
| Max Days | 14 |
| Encounter Rate | 150% |
| Interest Rate | 2% daily |
| Starting Weapon | Fists |
| Description | "Hapeville doesn't forgive. The clock is ticking." |

---

## 3. Location Design

### 3.1 The 11 Atlanta Locations

| ID | Name | Area | Bank | Weapons | Councilman | Bookbag |
|---|---|---|---|---|---|---|
| cobb | Cobb County | NW Perimeter | ✓ | | ✓ | |
| buckhead | Buckhead | North | ✓ | | | ✓ |
| midtown | Midtown | Central | ✓ | | | |
| five_points | Five Points | Downtown | | ✓ | | |
| west_end | West End | West | | ✓ | ✓ | |
| little_five | Little Five Points | East | | | ✓ | |
| decatur | Decatur | East | ✓ | | | |
| east_point | East Point | SW | | | | |
| hapeville | Hapeville | South | | ✓ | | |
| college_park | College Park | SW | | | | |
| airport | Airport | Far South | ✓ | ✓ | | |

### 3.2 Connection Graph

```
                  Cobb County
                      │
                  Buckhead
                      │
                   Midtown
                  ╱      ╲
            Five Points   Little Five
             ╱    ╲            │
        West End   East Point  Decatur
                      │
                College Park
                      │
                  Hapeville
                      │
                   Airport
```

**MARTA Lines (Blue/Red):**
- Cobb ↔ Buckhead ↔ Midtown ↔ Five Points ↔ East Point ↔ College Park ↔ Airport
- Five Points ↔ West End
- Five Points ↔ Little Five ↔ Decatur

**Highway Connections (I-20/I-75/I-85/GA-400):**
- Buckhead ↔ Midtown ↔ Five Points
- West End ↔ Five Points ↔ Little Five
- I-285 belt connects: Cobb ↔ Buckhead ↔ Decatur ↔ East Point ↔ College Park

---

## 4. Economy & Pricing

### 4.1 Product Catalog

| Product ID | Name | Base Price | Category | Emoji |
|---|---|---|---|---|
| motor_oil | Motor Oil | $80 | Standard | 🛢️ |
| antifreeze | Antifreeze | $120 | Standard | 🧊 |
| brake_fluid | Brake Fluid | $100 | Standard | 💧 |
| transmission | Transmission Fluid | $200 | Premium | ⚙️ |
| gasoline | Gasoline | $150 | Standard | ⛽ |
| diesel | Diesel | $175 | Premium | 🛢️ |
| coolant | Coolant | $650 | Luxury | 💎 |

### 4.2 Location Price Multipliers

Each location has "preferred" products that sell for more and "unwanted" products that sell for less:

| Location | High Price (+50%) | Low Price (-30%) |
|---|---|---|
| Cobb County | antifreeze | motor_oil |
| Buckhead | coolant, transmission | brake_fluid |
| Midtown | coolant | motor_oil |
| Five Points | gasoline | coolant |
| West End | brake_fluid | gasoline |
| Little Five | motor_oil | transmission |
| Decatur | transmission | brake_fluid |
| East Point | diesel | antifreeze |
| Hapeville | motor_oil | coolant |
| College Park | gasoline | diesel |
| Airport | diesel, gasoline | coolant |

### 4.3 Pricing Formula

```
basePrice = product.basePrice
locationMultiplier = location.priceMultipliers[productId] ?? 1.0
eventMultiplier = hasDemandSpike ? 2.0 : hasMarketFlood ? 0.5 : 1.0
randomWalk = basePrice * RandomNormal(0, volatility)  // ±10-20%
dailyDecay = 0.98  // prices drift toward mean

finalPrice = max(10, (basePrice * locationMultiplier * eventMultiplier + randomWalk) * dailyDecay)
```

### 4.4 Dynamic Events

Events are triggered on each arrival at a new location:

| Event | Probability | Effect | Duration |
|---|---|---|---|
| Demand Spike | 8% | 2x price for one product | 1 visit |
| Market Flood | 5% | 0.5x price for one product | 1 visit |
| Police Crackdown | 3% | +20% encounter rate | 2 days |
| Holiday | 2% | All prices +15% | 3 days |

---

## 5. Inventory & Equipment

### 5.1 Backpack System

- **Base capacity**: 10 units (no upgrades purchased)
- **Upgrade levels**:
  - Level 1: 10 units (free)
  - Level 2: 25 units ($500 at Buckhead)
  - Level 3: 50 units ($1,500 at Buckhead)
  - Level 4: 100 units ($5,000 at Buckhead)
- Products stack per slot (99 max per product type)

### 5.2 Weapon System

| Weapon | Kill Chance | Durability | Cost | Location |
|---|---|---|---|---|
| Fists | 0.20 | ∞ (unbreakable) | Free (default) | Everywhere |
| Bat | 0.35 | 10 | $80 | Five Points, Hapeville |
| Glock | 0.55 | 15 | $350 | West End, Airport |
| Tec-9 | 0.65 | 10 | $600 | West End, Five Points |
| AK-47 | 0.80 | 25 | $1,200 | Airport, West End |

- **Durability**: Each use (fight or intimidate) reduces durability by 1
- **Breakage**: When durability = 0, weapon is lost
- **Kill Chance**: Probability of winning a fight (checked on each combat encounter)

---

## 6. Encounter System

### 6.1 Encounter Flow

```
Travel initiated
    │
    ▼
Random roll: encounterChance%
    │
    ├── Miss ──► Continue to destination
    │
    ▼ Hit
    │
    ├── Transport-specific encounter
    │   ├── MARTA: Police
    │   ├── Ryde: Cop
    │   └── Drive: GSP Chase
    │
    ├── Location-specific encounter
    │   ├── Midtown → Water Boys
    │   └── West End → YNs
    │
    ▼
EncounterOverlay displayed:
    Text description of situation
    Choice buttons (2-3 options)
    │
    ▼
Player choice → Consequence → notifyListeners()
    │
    └── Continue to destination + show ad
```

### 6.2 Encounter Dialogue Examples

**MARTA Police:**
```
👮 MARTA POLICE
"Hold it right there!"
What do you do?

[RUN]     [FIGHT]
```

**Ryde Cop:**
```
👮‍♂️ RYDE COP
"License and registration."
He smells something...

[BRIBE $200]   [RUN]
```

**GSP Chase:**
```
🚔 GSP CHASE
Blue lights flash. You pull over.
You're arrested for trafficking.

[PAY FINE]   [CALL COUNCILMAN]
```

**Water Boys (Midtown):**
```
💧 WATER BOYS
"Say, you got any water?"
They swarm your ride and jack X units!

[DISMISS] (forced consequence)
```

**YNs (West End — armed):**
```
🫡 YNs
"Yo, what hood you claim?"
They eye your AK-47 and nod.
"Cool, cool. Stay safe out here."
They let you pass.

[DISMISS]
```

**YNs (West End — unarmed):**
```
🫡 YNs
"Yo, what hood you claim?"
You ain't strapped. They take $X.
"Next time come correct."

[DISMISS]
```

---

## 7. Game Over Conditions

### 7.1 Win Condition

Reach `maxDays` (30/20/14 depending on difficulty) with:
- Net worth (cash + bankBalance - debt) > $0
- OR complete the "Councilman's Special" mission (future)

**Win Screen shows:**
- "🏆 YOU WIN!"
- Final cash
- Net worth
- Total earned
- Days survived
- "NEW GAME" button

### 7.2 Lose Condition

Cash reaches $0 AND debt > $0 (can't pay interest):

**Lose Screen shows:**
- "💀 GAME OVER"
- Final stats
- "NEW GAME" button
- "BAILOUT (to $500)" button (one-time emergency)

**Bailout**: Drops cash to $500, debt remains. Available once per game.

---

## 8. Ad System (Thematic)

Parody ads shown as full-screen overlays after each travel arrival:

| Ad | Slogan | Asset |
|---|---|---|
| Ryde | "Ryde or Die — Every Ride's a Gamble" | assets/ads/ryde.png |
| Re-Elect Councilman | "He Gets Things Done" | assets/ads/councilman.png |
| Get Higher | "Your Neighborhood Smoke Spot" | assets/ads/get_higher.png |
| Certified Pre-Owned Whips | "0% APR or Your Firstborn" | assets/ads/certified_whips.png |
| The Varsity | "Eat Here or Die Trying" | assets/ads/the_varsity.png |

Ads are thematic atmosphere-builders, not monetization. They reinforce the Atlanta setting and dark humor tone.

---

## 9. UI/UX Design

### 9.1 Visual Style

- **Color palette**: Dark backgrounds (#0a0a0a), neon accents (green #00ff9d, pink #ff4081, gold #ffd740, blue #42a5f5)
- **Typography**: Jersey M54 font (retro sports-style) for all game text
- **Borders**: 1px solid-color borders (pixel-perfect aesthetic)
- **Backgrounds**: Semi-transparent card overlays, 95% opacity
- **Animations**: Smooth transitions, pulsing glows, dashed travel lines

### 9.2 HUD Layout

```
┌──────────────────────────────────────────────────────┐
│ $15,000  B$5,000  D$2,000  D5/20  ☀️Afternoon  📦12  │
└──────────────────────────────────────────────────────┘
```

- Left: Cash (green)
- Left: Bank balance (teal, shown only if > 0)
- Left: Debt (pink, shown only if > 0)
- Center: Day counter (gray)
- Center-right: Time of day + weather icon
- Right: Inventory count (gold)

### 9.3 Action Buttons

Bottom navigation bar with 5 actions:
```
[🛒 SHOP]  [🗺️ MAP]  [🎒 BAG]  [🏦 BANK]  [⚙️ MENU]
```

---

## 10. Audio Design

### 10.1 Sound Effects

| Action | Sound | File |
|---|---|---|
| MARTA travel | Two-tone chime | marta_chime.wav |
| Ryde/Drive travel | Car horn | car_horn.wav |
| Buy/Sell | Cash register ka-ching | cash_register.wav |
| Encounter trigger | Percussive alert | encounter.wav |
| Weapon fire | Gunshot crack | weapon_fire.wav |

### 10.2 Audio Philosophy

- All sounds are offline WAV files (no streaming)
- Volume control in settings (0.0-1.0)
- Sound on/off toggle in menu
- No background music in current scope (planned for v2)

---

## 11. Future Content

### 11.1 Planned Features (v2)

- **Multiplayer**: Real-time trading between players, leaderboards
- **Weather system**: Rain reduces police encounter rate, fog increases it
- **Missions**: Councilman gives special tasks for bonus cash
- **Random events**: Police crackdowns, market crashes, Atlanta United wins
- **Achievements**: 20+ achievements (100k net worth, survive 50 days, etc.)
- **Statistics screen**: Deep analytics of player performance

### 11.2 Stretch Goals

- Pixel art character creator
- Day/night cycle with visual changes
- Weapon upgrade system (silencers, extended mags)
- "Factions" system (ally with neighborhoods)
- Real-time multiplayer via Nakama
- Web export (Flutter Web)
