# Dope Wars Atlanta — Development Roadmap

> **Version:** 1.0.0  
> **Last Updated:** 2026-06-22  
> **Timeline:** 6 months (aggressive solo dev)  
> **Target Platforms:** Linux Desktop → Android → Web (future)

---

## Phase 0: Project Foundation ✅ COMPLETE

| Task | Status | Notes |
|---|---|---|
| Git repo init | ✅ Done | `~/DopeWars-Atlanta/`, branch: `main` |
| Flutter project scaffold | ✅ Done | `dope_wars_atl/` with pubspec |
| Core models | ✅ Done | GameState, Location, Product, Weapon |
| Core services | ✅ Done | GameService, SaveService, SoundService, AdService |
| Theme system | ✅ Done | AppTheme with retro pixel aesthetic |
| Map overlay painter | ✅ Done | PixelMapOverlayPainter with 11 locations |
| Boot screen | ✅ Done | 4s animation intro |
| Documentation suite | ✅ Done | ARCHITECTURE, GAME_DESIGN, DEV_ROADMAP, API_REFERENCE, MAP_SYSTEM, MULTIPLAYER_DESIGN |

---

## Phase 1: Core Gameplay Loop 🎯 CURRENT

**Goal**: Buildable, runnable game with complete buy/sell/travel/encounter loop.

### 1.1 Full Integration & Polish

| Task | Est. Effort | Priority | Dependencies |
|---|---|---|---|
| Verify `flutter pub get` + build | 1hr | 🔴 Critical | None |
| Fix any import/API errors | 2hr | 🔴 Critical | Build verification |
| Add Flame base package | 1hr | 🟡 Medium | None |
| Create `flame_game/` overlay directory structure | 30min | 🟢 Low | Flame package |
| Wire complete screen navigation (boot → game → map → travel) | 3hr | 🔴 Critical | Build verification |
| Fix MapScreen to properly use PixelMapOverlayPainter | 2hr | 🟡 Medium | MapScreen |

### 1.2 Core Systems QA

| Task | Est. Effort | Priority | Dependencies |
|---|---|---|---|
| Test all 3 travel modes (MARTA, Ryde, Drive) | 2hr | 🔴 Critical | Navigation wired |
| Test all 4 encounter types | 2hr | 🔴 Critical | Travel working |
| Verify pricing engine (buy/sell with multipliers) | 2hr | 🔴 Critical | Economy model |
| Test save/load cycle | 1hr | 🔴 Critical | SaveService |
| Test all 3 difficulty modes | 1hr | 🟡 Medium | New game flow |

### 1.3 Asset Pipeline

| Task | Est. Effort | Priority | Dependencies |
|---|---|---|---|
| Create placeholder map background image | 1hr | 🟡 Medium | Pixel painte |
| Generate 5 ad PNG images | 2hr | 🟡 Medium | AdService |
| Create 5 WAV sound effects | 2hr | 🟡 Medium | SoundService |
| Edit pubspec.yaml assets section | 15min | 🟡 Medium | Assets exist |

**Deliverable**: Working game at `dope_wars_atl/` that can be run with `flutter run -d linux`

---

## Phase 2: Map & Navigation Overhaul 🗺️ (Weeks 3-4)

**Goal**: Interactive map screen with smooth pan, zoom, and location selection.

### 2.1 Map Improvements

| Task | Est. Effort | Priority |
|---|---|---|
| Redesign map layout for 1000x1000 coord grid | 3hr | 🟡 Medium |
| Add pinch-to-zoom gesture (InteractiveViewer) | 4hr | 🟢 Low |
| Improve travel path animation (smooth curved paths) | 3hr | 🟢 Low |
| Add distance-based travel times | 2hr | 🟢 Low |
| Visual indicators for undiscovered vs visited locations | 2hr | 🟢 Low |

### 2.2 Screen Architecture

| Task | Est. Effort | Priority |
|---|---|---|
| Convert GameScreen to use screen-state enum | 2hr | 🟡 Medium |
| Add animated screen transitions (slide left/right) | 3hr | 🟢 Low |
| Persistent bottom nav bar across all screens | 2hr | 🟡 Medium |
| Back gesture support | 1hr | 🟢 Low |

---

## Phase 3: Bank, Weapons & Upgrades 💰 (Weeks 5-6)

**Goal**: Complete shop system with banks, weapon purchases, and inventory upgrades.

### 3.1 Banking System

| Task | Est. Effort | Priority |
|---|---|---|
| Bank screen UI (deposit/withdraw/balance) | 3hr | 🟡 Medium |
| Interest accrual on savings (0.5% daily) | 1hr | 🟢 Low |
| ATM fee system (withdraw fee at non-home banks) | 1hr | 🟢 Low |

### 3.2 Weapon Shop

| Task | Est. Effort | Priority |
|---|---|---|
| Weapon shop UI (buy/equip/sell) | 3hr | 🟡 Medium |
| Weapon comparison tooltip (stats vs current) | 2hr | 🟢 Low |
| Weapon break animation | 1hr | 🟢 Low |

### 3.3 Bookbag Upgrades

| Task | Est. Effort | Priority |
|---|---|---|
| Upgrade tiers UI (10/25/50/100 capacity) | 2hr | 🟢 Low |
| Upgrade cost scaling | 1hr | 🟢 Low |

---

## Phase 4: Visual Polish & Feedback ✨ (Weeks 7-8)

**Goal**: Production-quality visual presentation with smooth animations.

### 4.1 Animation Pass

| Task | Est. Effort | Priority |
|---|---|---|
| Boot screen ASCII animation (typewriter effect) | 2hr | 🟡 Medium |
| Travel screen particle effects (road lines, neon streaks) | 4hr | 🟢 Low |
| Buy/sell count-up animation (cash counter) | 2hr | 🟢 Low |
| Encounter text typewriter effect | 1hr | 🟢 Low |
| Screen transition animations | 3hr | 🟢 Low |

### 4.2 Audio Pass

| Task | Est. Effort | Priority |
|---|---|---|
| Replace placeholder sounds with high-quality WAVs | 3hr | 🟢 Low |
| Add ambient city soundscape (low loop) | 2hr | 🟢 Low |
| Volume mixer per sound category | 2hr | 🟢 Low |

### 4.3 Error States & Edge Cases

| Task | Est. Effort | Priority |
|---|---|---|
| "Not enough cash" toast messages | 1hr | 🟡 Medium |
| "No connection" disabled travel buttons with tooltip | 1hr | 🟡 Medium |
| Empty inventory state | 30min | 🟢 Low |
| Day 0 edge case | 30min | 🟢 Low |
| Negative cash guard | 30min | 🟡 Medium |

---

## Phase 5: Multiplayer Foundation 🔌 (Weeks 9-12)

**Goal**: Nakama server setup + real-time multiplayer for 2-4 players.

| Task | Est. Effort | Priority |
|---|---|---|
| Nakama server deployment (Docker) | 4hr | 🟡 Medium |
| Flame network sync layer (WebSocket) | 8hr | 🟡 Medium |
| Player matchmaking (quick join / private lobby) | 6hr | 🟡 Medium |
| Shared economy (prices fluctuate based on all player actions) | 8hr | 🟡 Medium |
| Player collision on map (can't occupy same location) | 4hr | 🟢 Low |
| Chat system (in-game text chat) | 3hr | 🟢 Low |

See [MULTIPLAYER_DESIGN.md](./MULTIPLAYER_DESIGN.md) for full architecture.

---

## Phase 6: Content Expansion 📦 (Weeks 13-16)

**Goal**: Rich game world with missions, events, and achievements.

### 6.1 Missions System

| Task | Est. Effort | Priority |
|---|---|---|
| Councilman's Special missions (3-5 story missions) | 8hr | 🟡 Medium |
| Random side jobs (deliver package, collect debt) | 4hr | 🟢 Low |
| Mission completion rewards | 2hr | 🟢 Low |

### 6.2 Random Events

| Task | Est. Effort | Priority |
|---|---|---|
| Police crackdown (doubled encounter rate, 2 days) | 2hr | 🟢 Low |
| Market crash (all prices -30%, 3 days) | 2hr | 🟢 Low |
| Atlanta United win (prices +15%, 1 day party) | 1hr | 🟢 Low |
| Heat wave (coolant demand spikes) | 1hr | 🟢 Low |

### 6.3 Achievements (20+)

| Achievement | Condition |
|---|---|
| **First Sale** | Sell your first product |
| **Big Spender** | Spend $10,000 total |
| **Debt Free** | Pay off all debt |
| **Hundred Grand** | Reach $100,000 net worth |
| **Survivor** | Survive 50 days |
| **Globe Trotter** | Visit all 11 locations |
| **Stockpile** | Fill backpack to capacity |
| **Guns Blazing** | Win 10 fights |
| **Smooth Talker** | Successfully bribe 5 cops |
| **Escaped** | Outrun GSP 3 times |
| **Waterproof** | Survive Water Boys encounter |
| **YN Whisperer** | Pass YNs check with weapon |
| **Bailout King** | Use bankruptcy bailout |
| **Marta Regular** | Take MARTA 20 times |
| **Ryder** | Take Ryde 30 times |
| **Road Warrior** | Drive 50 times |
| **Weapon Collector** | Own all 5 weapons |
| **Luxury Dealer** | Sell 100 units of coolant |
| **No Interest** | Pay $10,000 in interest |
| **Impossible** | Win on Hapeville difficulty |

---

## Phase 7: Mobile Port 📱 (Weeks 17-20)

**Goal**: Android and iOS builds with touch-optimized UI.

### 7.1 Android

| Task | Est. Effort | Priority |
|---|---|---|
| Android build pipeline (SDKMAN, Java 21) | 2hr | 🟡 Medium |
| Touch input optimization (tap targets > 48dp) | 4hr | 🟡 Medium |
| Android back button handling | 1hr | 🟡 Medium |
| Notch/notch display cutout handling | 2hr | 🟢 Low |
| Google Play Store listing assets | 4hr | 🟢 Low |

### 7.2 iOS

| Task | Est. Effort | Priority |
|---|---|---|
| iOS build (Xcode/macOS required) | — | 🟠 Blocked |
| Haptic feedback on encounters | 2hr | 🟢 Low |

---

## Phase 8: CI/CD & Release 🚀 (Weeks 21-24)

**Goal**: Automated build pipeline, distribution, and launch.

| Task | Est. Effort | Priority |
|---|---|---|
| GitHub Actions: flutter test on PR | 2hr | 🟡 Medium |
| GitHub Actions: flutter build linux --release | 2hr | 🟡 Medium |
| GitHub Actions: flutter build apk --release | 2hr | 🟡 Medium |
| Firebase App Distribution for Android beta | 1hr | 🟢 Low |
| Linux AppImage packaging | 3hr | 🟢 Low |
| itch.io release page | 2hr | 🟢 Low |
| Release v1.0.0 | — | 🎯 Goal |

---

## Development Principles

### Documentation-First

Before writing any code for a new system:

```
┌──────────────────────┐
│ 1. Write markdown     │
│    spec in docs/      │
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ 2. Review with user   │
│    (clarify gaps)     │
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ 3. Implement          │
│    (code + tests)     │
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ 4. Verify & commit    │
│    (build + push)     │
└──────────────────────┘
```

### Model Strategy

- **DeepSeek V4 Flash**: Architecture, edge cases, debugging, multiplayer design, economy balancing
- **Gemma 4 12b**: UI components, boilerplate, asset generation, documentation, routine updates

### Git Workflow

```bash
# Feature branch
git checkout -b feature/<name>
# ... work ...
git add -A && git commit -m "feat: description"
git checkout main
git merge feature/<name>
git push origin main
```

### Convention

```
feat:     New feature
fix:      Bug fix
docs:     Documentation
refactor: Code change (no functional change)
perf:     Performance improvement
test:     Test addition/modification
chore:    Build/config/maintenance
```

---

## Quick Reference

```bash
# Run the game
cd ~/DopeWars-Atlanta/dope_wars_atl
flutter run -d linux

# Build for release
flutter build linux --release
flutter build apk --release

# Run tests
flutter test

# Check dependencies
flutter pub deps

# Update packages
flutter pub upgrade
```

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Flutter Flame compatibility issues | Medium | Medium | Pin versions, test early |
| Nakama server cost for multiplayer | Low | High | Self-hosted Docker, free tier |
| Desktop vs mobile layout differences | Medium | Medium | Responsive layout from start |
| Sound asset licensing | Low | Low | Create original WAVs |
| Build time increases with scope | High | Low | CI/CD, incremental builds |
| Godot-to-Flutter port complexity | Low | High | Already using Flutter-native map |
