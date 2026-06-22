# Dope Wars Atlanta — Multiplayer Design (Future)

> **Status:** Planning / Pre-Implementation  
> **Engine:** Flutter + Flame + Nakama  
> **Timeline:** Phase 5 (Weeks 9-12)

---

## 1. Overview

Multiplayer brings real-time player interaction to Dope Wars Atlanta. Up to 4 players share a connected Atlanta economy where prices fluctuate based on all players' actions, encounters can involve multiple players, and leaderboards track who builds the biggest empire.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Nakama Server                         │
│                    (Docker Container)                    │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ Match    │  │ Economy  │  │ Leader   │  │ Chat    │ │
│  │ Making   │  │ Engine   │  │ Board    │  │ System  │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │           WebSocket (RT API)                     │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Player 1       │ │   Player 2       │ │   Player 3       │
│   (Flutter)      │ │   (Flutter)      │ │   (Flutter)      │
│                  │ │                  │ │                  │
│  Flame Game      │ │  Flame Game      │ │  Flame Game      │
│  + Nakama SDK    │ │  + Nakama SDK    │ │  + Nakama SDK    │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

### 2.1 Server Stack

| Component | Technology | Purpose |
|---|---|---|
| Game Server | Nakama (v3.x) | Matchmaking, state sync, RPCs |
| Database | CockroachDB (Nakama bundled) | Player data, matches |
| Cache | Redis (optional) | Real-time economy state |
| Hosting | Docker on VPS ($5-10/mo) | Self-hosted, full control |
| Client SDK | `nakama-flutter` | Flutter → Nakama socket |

### 2.2 Client Stack

```yaml
dependencies:
  flame: ^1.10.0
  nakama_flutter: ^1.8.0
  web_socket_channel: ^2.4.0
```

---

## 3. Game Modes

### 3.1 Free Market (2-4 players)

All players start in the same Atlanta with the same economy. Every buy/sell action affects global prices. First to reach net worth target wins.

**Settings:**
- Players: 2-4
- Target net worth: $50,000 / $100,000 / $200,000
- Day limit: None (or 30/60)
- Collision: Players cannot occupy same location simultaneously

### 3.2 Team Up (2v2)

Two teams of two share inventory and cash. Combined net worth wins.

**Settings:**
- Players: 4 (2v2)
- Shared bank account per team
- Separate inventories per player
- Combined net worth for win condition

### 3.3 Speed Run (Competitive)

Each player plays simultaneously on their own timeline. Fastest to reach net worth target wins. No player interaction — pure speed competition.

**Settings:**
- Players: 2-8
- Target: $50,000 net worth
- Real-time timer
- No collision (each player in their own instance)

---

## 4. Network Protocol

### 4.1 State Sync

```protobuf
// Player state sent to server every 200ms
message PlayerUpdate {
  string player_id;
  string location_id;
  int32 cash;
  int32 net_worth;
  float pos_x;
  float pos_y;
  bool is_traveling;
  string traveling_to;
  float travel_progress;
}

// Economy state broadcast to all players
message EconomyUpdate {
  map<string, float> prices;     // productId -> current price
  map<string, int32> event_ids;  // active events
  int32 game_day;
  int32 game_hour;
  string weather;
}

// Server authoritative state
message GameState {
  repeated PlayerState players;
  EconomyUpdate economy;
  int32 game_tick;
  int32 time_remaining_seconds;
}
```

### 4.2 OpCodes

| OpCode | Direction | Action |
|---|---|---|
| 1 | Client → Server | PlayerMove |
| 2 | Client → Server | BuyProduct |
| 3 | Client → Server | SellProduct |
| 4 | Client → Server | EncounterChoice |
| 5 | Server → Client | EconomyUpdate |
| 6 | Server → Client | PlayerJoined |
| 7 | Server → Client | PlayerLeft |
| 8 | Server → Client | ChatMessage |
| 9 | Server → Client | GameOver |
| 10 | Client → Server | Ping (heartbeat) |

### 4.3 Authoritative Server

The server is **authoritative** over:
- **Economy state**: All price calculations run server-side
- **Game clock**: Day/hour advancement broadcast from server
- **Win condition**: Server validates net worth targets
- **Encounters**: Random encounter rolls run server-side (prevent client cheating)

Clients are **authoritative** over:
- **UI state**: Rendering, animations, local input
- **Sound**: Local audio playback
- **Input prediction**: Client shows immediate travel start while server validates

---

## 5. Economy in Multiplayer

### 5.1 Shared Pricing Model

```dart
// Server-side pricing with global state
class MultiplayerEconomy {
  Map<String, Map<String, int>> locationPrices; // locationId -> productId -> price
  
  void onPlayerBuy(String playerId, String locationId, String productId, int quantity) {
    // Increase price by 2% per unit bought (supply/demand)
    locationPrices[locationId][productId] = 
        (locationPrices[locationId][productId] * (1 + 0.02 * quantity)).round();
    
    // Notify all players in the match
    broadcastEconomyUpdate();
  }
  
  void onPlayerSell(String playerId, String locationId, String productId, int quantity) {
    // Decrease price by 1.5% per unit sold
    locationPrices[locationId][productId] = 
        (locationPrices[locationId][productId] * (1 - 0.015 * quantity)).round();
    
    broadcastEconomyUpdate();
  }
}
```

### 5.2 Player Collision

Two players cannot occupy the same location simultaneously:

```dart
class LocationOccupancy {
  Map<String, String> locationPlayer; // locationId -> playerId
  
  bool tryOccupy(String locationId, String playerId) {
    if (locationPlayer.containsKey(locationId) && locationPlayer[locationId] != playerId) {
      return false; // Already occupied
    }
    locationPlayer[locationId] = playerId;
    return true;
  }
  
  void leaveLocation(String locationId) {
    locationPlayer.remove(locationId);
  }
}
```

If the destination is occupied, the player sees:
```
"📍 [Player Name] is at [Location]"
"Wait for them to leave, or pick another destination"
```

---

## 6. Match Flow

### 6.1 Lobby → Game → Results

```
┌─────────────────┐
│   LOBBY SCREEN   │
│                   │
│  Matchmaking...   │
│  or Invite Link   │
│                   │
│  Players: 2/4     │
│  ┌───────────┐   │
│  │ Player 1  │   │
│  │ Player 2  │   │
│  │ Waiting.. │   │
│  └───────────┘   │
│                   │
│  [START] [LEAVE]  │
└─────────┬─────────┘
          │ All ready
          ▼
┌─────────────────┐
│  COUNTDOWN (3s)  │
│                   │
│     3... 2... 1..│
└─────────┬─────────┘
          │
          ▼
┌─────────────────────────────────────────┐
│            GAME SCREEN                   │
│                                          │
│  ┌─ HUD ────────────────────────────┐   │
│  │ $15K  D5/20  ☀️  📦12  👤P2 $8K │   │
│  └──────────────────────────────────┘   │
│                                          │
│  Player markers visible on map           │
│  Prices update in real-time             │
│  Chat panel (slide-up)                   │
│                                          │
│  Win condition progress bar             │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────┐
│   RESULTS SCREEN │
│                   │
│  🏆 WINNER        │
│  Player 1         │
│  Net Worth: $52K  │
│                   │
│  ┌ Leaderboard ─┐│
│  │ 1. P1  $52K  ││
│  │ 2. P2  $31K  ││
│  └──────────────┘│
│                   │
│  [PLAY AGAIN]     │
│  [LEAVE]          │
└─────────────────┘
```

### 6.2 Matchmaking

```dart
class Matchmaker {
  // Quick play — join any open match
  Future<Match> quickPlay(Player player);
  
  // Create private lobby (shareable invite code)
  Future<Match> createPrivateLobby(Player host, {int maxPlayers = 4});
  
  // Join private lobby by code
  Future<Match> joinByCode(String inviteCode, Player joiner);
  
  // Match criteria
  static const minPlayers = 2;
  static const maxPlayers = 4;
  static const readyTimeout = 120; // seconds to wait for ready
}
```

---

## 7. Chat System

### 7.1 In-Game Chat

- **Sliding panel** from bottom (triggered by chat icon)
- **Message types**: All, Team (2v2 mode only), System
- **Emoji reactions** on messages (tap to react)
- **Presets** for quick messages:
  - "Nice deal!" 🤝
  - "Watch out — cops!" 🚔
  - "Anyone at Airport?" ✈️
  - "gg" 🎮

### 7.2 Chat Protocol

```dart
class ChatMessage {
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final ChatChannel channel; // .all, .team, .system
  final List<String> reactions; // emoji reactions
}

// Nakama channel-based chat
var channel = await socket.joinChat(target: matchId, type: ChannelType.Room);
await socket.writeChatMessage(channel, "Anyone at Airport?");
socket.onChannelMessage = (message) {
  // Display in chat panel
};
```

---

## 8. Nakama Server Setup

### 8.1 Docker Deployment

```yaml
# docker-compose.yml
version: '3'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: nakama
      POSTGRES_USER: nakama
      POSTGRES_PASSWORD: changeme
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  nakama:
    image: registry.heroiclabs.com/heroiclabs/nakama:3.20.0
    ports:
      - "7350:7350"  # HTTP API
      - "7351:7351"  # gRPC API
    environment:
      - DB_NAME=nakama
      - DB_USER=nakama
      - DB_PASS=changeme
      - DB_ADDRESS=postgres:5432
    depends_on:
      - postgres
    volumes:
      - ./nakama-config:/nakama/data

volumes:
  postgres_data:
```

### 8.2 Server-Side Lua Module

```lua
-- modules/economy.lua
local economy = {}

function economy.buy_product(context, payload)
  local data = nk.json_decode(payload)
  local product_id = data.product_id
  local quantity = data.quantity
  local location_id = data.location_id
  local player_id = context.user_id
  
  -- Check collision
  local occupied = nk.storage_read({user_id = player_id, key = "current_location"})
  local occupant = nk.storage_read({key = "location_occupant_" .. location_id})
  if occupant and occupant.value ~= player_id then
    return nk.json_encode({success = false, error = "location_occupied"})
  end
  
  -- Calculate price
  local price = nk.storage_read({key = "price_" .. location_id .. "_" .. product_id})
  local total_cost = price.value * quantity
  
  -- Check funds
  local player_cash = nk.storage_read({user_id = player_id, key = "cash"})
  if player_cash.value < total_cost then
    return nk.json_encode({success = false, error = "insufficient_funds"})
  end
  
  -- Execute transaction
  nk.storage_write({
    user_id = player_id, key = "cash", value = player_cash.value - total_cost
  })
  price.value = math.floor(price.value * (1 + 0.02 * quantity))
  nk.storage_write({key = "price_" .. location_id .. "_" .. product_id, value = price.value})
  
  return nk.json_encode({success = true, new_price = price.value})
end

nk.register_rpc(economy.buy_product, "economy/buy_product")
```

---

## 9. Flame Integration

### 9.1 Game Loop with Network Sync

```dart
class MultiplayerGame extends FlameGame {
  late final NakamaSocket socket;
  late final CameraComponent camera;
  final List<PlayerSprite> otherPlayers = [];
  
  @override
  Future<void> onLoad() async {
    // Initialize Nakama socket
    socket = await NakamaSocket.connect(host: 'your-server:7350');
    
    // Join match
    var match = await socket.joinMatch(matchId: matchId);
    
    // Listen for state updates
    socket.onMatchData = (data) {
      if (data.opCode == 5) { // EconomyUpdate
        updatePrices(data.data);
      } else if (data.opCode == 1) { // PlayerMove
        updatePlayerPosition(data.senderId, data.data);
      }
    };
    
    // Create player sprites
    camera = CameraComponent.withFixedResolution(1000, 1000);
    add(camera);
  }
  
  @override
  void update(double dt) {
    // Send position update every 200ms
    _positionTimer += dt;
    if (_positionTimer >= 0.2) {
      socket.sendMatchData(matchId, 1, currentPositionBytes);
      _positionTimer = 0;
    }
    super.update(dt);
  }
}
```

### 9.2 Player Indicators on Map

Each remote player appears as a colored dot on the map:

```dart
class PlayerIndicator extends Component {
  String playerId;
  String name;
  Color color;          // Assigned at match start
  Vector2 position;     // Current position
  String locationId;    // Current location (or null if traveling)
  
  @override
  void render(Canvas canvas) {
    // Draw colored circle
    canvas.drawCircle(position.toOffset(), 10, Paint()..color = color);
    
    // Draw player name above
    // (faded when same location as local player)
  }
}
```

---

## 10. Anti-Cheat

| Measure | Implementation |
|---|---|
| **Authoritative economy** | All prices calculated server-side |
| **Encounter RNG** | Random rolls on server, not client |
| **Rate limiting** | Max 10 actions per second per player |
| **Integrity checks** | Cash/inventory validated on every transaction |
| **Travel validation** | Server checks connection graph before allowing move |
| **Speed hack prevention** | Server-side travel timer (can't arrive early) |

---

## 11. Deployment & Scaling

### 11.1 VPS Requirements ($5-10/month)

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 1 vCPU | 2 vCPU |
| RAM | 1 GB | 2 GB |
| Storage | 10 GB | 20 GB |
| Bandwidth | 1 TB | 2 TB |
| Players supported | ~100 concurrent | ~500 concurrent |

### 11.2 Scaling Strategy

1. **Single VPS**: Up to 100 concurrent players
2. **Docker Swarm**: Partition matches across nodes
3. **Nakama Multi-Node**: Active/active cluster with shared Postgres

---

## 12. Development Checklist

- [ ] Nakama server Docker setup
- [ ] `nakama_flutter` SDK integration
- [ ] Matchmaking (quick play + invite codes)
- [ ] Player state sync (position, cash, location)
- [ ] Server-authoritative economy engine
- [ ] Location collision logic
- [ ] Player indicators on Flame map
- [ ] In-game chat (all + team channels)
- [ ] Leaderboard (match-end + global)
- [ ] Anti-cheat validation layer
- [ ] Disconnect/reconnect handling
- [ ] Deployment + monitoring

---

## 13. References

- [Nakama Documentation](https://heroiclabs.com/docs/nakama/)
- [nakama-flutter SDK](https://pub.dev/packages/nakama_flutter)
- [Flame Network Sync](https://docs.flame-engine.org/main/networking.html)
- [Docker Compose for Nakama](https://heroiclabs.com/docs/nakama/getting-started/docker/#docker-compose)
