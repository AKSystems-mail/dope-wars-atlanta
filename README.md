# Dope Wars Atlanta 🏙️💰

> A drug-trade empire simulation game set in Atlanta, Georgia.
> Built with **Flutter** + **Flame** (optional hybrid layer).
> Target: Linux Desktop → Android → Web

---

## Quick Start

```bash
# Prerequisites
# - Flutter 3.29.2+ (see https://docs.flutter.dev/get-started/install/linux)
# - Dart SDK ^3.7.2

# Get the code
git clone https://github.com/AKSystems-mail/dw-atl.git
cd dw-atl/dope_wars_atl

# Get dependencies
flutter pub get

# Run on desktop
flutter run -d linux

# Build for release
flutter build linux --release
flutter build apk --release
```

---

## Game Overview

Travel between 11 Atlanta neighborhoods buying and selling automotive fluids (stand-in for illicit substances). Manage cash, debt, and inventory while avoiding police encounters. Build your empire within a limited number of in-game days.

### Core Loop

```
Travel to Location → Buy Low → Travel to New Location → Sell High → Avoid Cops → Repeat
```

### Key Features

- **11 Atlanta locations** with MARTA and highway connection networks
- **7 products** with supply/demand economy engine
- **3 transport modes**: MARTA ($5), Ryde ($25-60), Drive ($20)
- **5 weapons** with kill chance and durability mechanics
- **4 encounter types** (police, GSP, YNs, Water Boys)
- **3 difficulty modes**: Mt Paran (easy), E Atlanta (normal), Hapeville (hard)
- **Banking system** with deposits and withdrawals
- **Backpack upgrades** (10 → 25 → 50 → 100 slots)
- **Parody ad system** with 5 Atlanta-themed interstitial ads

---

## Documentation

| Document | Description |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Full system architecture, data flow, state management |
| [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) | Game design document, mechanics, locations, encounters |
| [docs/DEV_ROADMAP.md](docs/DEV_ROADMAP.md) | Development roadmap with phases and milestones |
| [docs/API_REFERENCE.md](docs/API_REFERENCE.md) | Internal API reference for all services and models |
| [docs/MAP_SYSTEM.md](docs/MAP_SYSTEM.md) | Map coordinate system and overlay painter design |
| [docs/MULTIPLAYER_DESIGN.md](docs/MULTIPLAYER_DESIGN.md) | Future multiplayer architecture with Nakama |

---

## Development

### Model Strategy

| AI Model | Purpose |
|---|---|
| DeepSeek V4 Flash | Architecture, edge cases, debugging, economy balancing |
| Gemma 4 12b | UI components, boilerplate, documentation |

### Git Workflow

```bash
git checkout -b feature/<name>
# ... work ...
git add -A && git commit -m "feat: description"
git checkout main
git merge feature/<name>
git push origin main
```

### Useful Commands

```bash
# Run tests
flutter test

# Check dependencies
flutter pub deps

# Update packages
flutter pub upgrade

# Analyze code
flutter analyze
```

---

## Project Structure

```
dope_wars_atl/
├── lib/
│   ├── main.dart                 # App entry, Provider setup
│   ├── models/                   # GameState, Location, Product, Weapon
│   ├── services/                 # GameService, SaveService, SoundService
│   ├── screens/                  # BootScreen, GameScreen, MapScreen
│   ├── widgets/                  # HUD, map overlays, encounters, ads
│   ├── utils/                    # Emoji maps, sprite definitions
│   └── theme/                    # AppTheme (retro pixel aesthetic)
├── assets/
│   ├── ads/                      # PNG ad images
│   ├── sounds/                   # WAV sound effects
│   └── images/                   # Map background, sprites
├── flame_game/                   # Future Flame overlay
├── docs/                         # Documentation suite
└── pubspec.yaml
```

---

## License

© 2026 Kennedy AI. All rights reserved.
