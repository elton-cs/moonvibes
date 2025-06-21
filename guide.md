# Moon Bag Game - Frontend Integration Guide

This guide provides complete documentation for integrating with the Moon Bag smart contracts on Starknet using the Dojo framework.

## 📋 Quick Reference

**World Address**: `0x07cb912d0029e3799c4b8f2253b21481b2ec814c5daf72de75164ca82e7c42a5`  
**Namespace**: `dojo_starter`  
**Framework**: Dojo v1.5.1 on Starknet

---

## 🎮 Complete External Function Reference

### 1. Game Management System (`dojo_starter-game_management`)

#### `start_game() → u64`
- **Purpose**: Initialize a new game session
- **Parameters**: None
- **Returns**: Unique game_id for this session
- **Sozo**: `sozo execute dojo_starter-game_management start_game --wait`
- **Frontend**: Essential first call to begin any game

#### `quit_game(game_id: u64)`
- **Purpose**: Voluntarily end game, converting points to moon rocks 1:1
- **Parameters**: `game_id: u64`
- **Sozo**: `sozo execute dojo_starter-game_management quit_game --calldata <game_id> --wait`
- **Frontend**: Player-initiated game termination

#### `reset_game(game_id: u64)`
- **Purpose**: Reset game to initial state (erases all progress)
- **Parameters**: `game_id: u64`
- **Sozo**: `sozo execute dojo_starter-game_management reset_game --calldata <game_id> --wait`
- **Frontend**: Complete game reset functionality

### 2. Orb Drawing System (`dojo_starter-orb_drawing`)

#### `pull_orb(game_id: u64) → OrbType`
- **Purpose**: Core game loop - draw random orb and apply effects
- **Parameters**: `game_id: u64`
- **Returns**: `OrbType` (felt252 value 1-18)
- **Sozo**: `sozo execute dojo_starter-orb_drawing pull_orb --calldata <game_id> --wait`
- **Frontend**: Primary gameplay action, called repeatedly

#### `get_bag_contents(player: ContractAddress, game_id: u64) → Array<OrbType>`
- **Purpose**: Read-only function to view current bag contents
- **Parameters**: `player: ContractAddress`, `game_id: u64`
- **Returns**: `Array<OrbType>`
- **Sozo**: `sozo execute dojo_starter-orb_drawing get_bag_contents --calldata <player> <game_id> --wait`
- **Frontend**: Display current bag state to player

### 3. Level Progression System (`dojo_starter-level_progression`)

#### `check_level_complete(player: ContractAddress, game_id: u64) → bool`
- **Purpose**: Check if current level requirements are met
- **Parameters**: `player: ContractAddress`, `game_id: u64`
- **Returns**: `bool`
- **Sozo**: `sozo execute dojo_starter-level_progression check_level_complete --calldata <player> <game_id> --wait`
- **Frontend**: Validation before attempting level advancement

#### `advance_level(game_id: u64)`
- **Purpose**: Progress to next level after completing current level
- **Parameters**: `game_id: u64`
- **Effects**: Awards cheddah, resets multiplier, advances level
- **Sozo**: `sozo execute dojo_starter-level_progression advance_level --calldata <game_id> --wait`
- **Frontend**: Level progression after meeting requirements

#### `get_level_requirements(level: u8) → (u32, u32, u32)`
- **Purpose**: Get configuration for any level
- **Parameters**: `level: u8` (1-7)
- **Returns**: `(milestone_points, moon_rock_cost, cheddah_reward)`
- **Sozo**: `sozo execute dojo_starter-level_progression get_level_requirements --calldata <level> --wait`
- **Frontend**: Display level information to player

#### `pay_level_cost(game_id: u64, level: u8)`
- **Purpose**: Pay moon rocks to unlock a level
- **Parameters**: `game_id: u64`, `level: u8`
- **Sozo**: `sozo execute dojo_starter-level_progression pay_level_cost --calldata <game_id> <level> --wait`
- **Frontend**: Level unlock mechanic

### 4. Shop System (`dojo_starter-shop_system`)

#### `generate_shop(game_id: u64)`
- **Purpose**: Generate shop inventory for current level
- **Parameters**: `game_id: u64`
- **Effects**: Creates randomized shop with 6 orbs (2 common, 2 rare, 2 cosmic)
- **Sozo**: `sozo execute dojo_starter-shop_system generate_shop --calldata <game_id> --wait`
- **Frontend**: Initialize shop for current level

#### `purchase_orb(game_id: u64, orb_type: OrbType)`
- **Purpose**: Buy an orb from shop using cheddah
- **Parameters**: `game_id: u64`, `orb_type: OrbType` (felt252: 1-18)
- **Sozo**: `sozo execute dojo_starter-shop_system purchase_orb --calldata <game_id> <orb_type_felt> --wait`
- **Frontend**: Shop purchase functionality

#### `get_shop_contents(player: ContractAddress, game_id: u64, level: u8) → (Array<OrbType>, Array<u32>)`
- **Purpose**: View current shop inventory and prices
- **Parameters**: `player: ContractAddress`, `game_id: u64`, `level: u8`
- **Returns**: `(available_orbs, prices)`
- **Sozo**: `sozo execute dojo_starter-shop_system get_shop_contents --calldata <player> <game_id> <level> --wait`
- **Frontend**: Display shop contents to player

#### `get_orb_price(player: ContractAddress, orb_type: OrbType) → u32`
- **Purpose**: Get current price for an orb (includes 20% scaling per purchase)
- **Parameters**: `player: ContractAddress`, `orb_type: OrbType`
- **Returns**: `u32` (price in cheddah)
- **Sozo**: `sozo execute dojo_starter-shop_system get_orb_price --calldata <player> <orb_type_felt> --wait`
- **Frontend**: Dynamic pricing display

#### `refresh_shop(game_id: u64)`
- **Purpose**: Clear and regenerate shop inventory
- **Parameters**: `game_id: u64`
- **Sozo**: `sozo execute dojo_starter-shop_system refresh_shop --calldata <game_id> --wait`
- **Frontend**: Shop refresh functionality

---

## 🎯 Complete Game Playthrough Scenario

### Scenario: Player starts game, progresses through levels, shops, and eventually loses

Let's follow Alice (address: `0x123...abc`) through a complete game session:

#### Phase 1: Game Initialization

```bash
# 1. Start new game
sozo execute dojo_starter-game_management start_game --wait
# Returns: [1703458234] (this becomes our game_id)

# 2. Check starting bag contents (optional)
sozo execute dojo_starter-orb_drawing get_bag_contents --calldata 0x123abc 1703458234 --wait
# Returns: Array with 12 starting orbs (6 FivePoints, 2 SingleBomb, 2 Health, 2 DoubleMultiplier)
```

**Frontend State After Phase 1:**
- game_id: 1703458234
- Player Stats: 5 health, 0 points, 304 moon rocks, 0 cheddah, 1.0x multiplier
- Level: 1 (need 12 points to complete)
- Bag: 12 orbs total

#### Phase 2: Level 1 Gameplay Loop

```bash
# 3. Pull first orb
sozo execute dojo_starter-orb_drawing pull_orb --calldata 1703458234 --wait
# Returns: [4] (FivePoints orb)
# Effect: +5 points (with 1.0x multiplier = 5 points)
# Player Stats: 5 health, 5 points, 304 moon rocks, 0 cheddah, 1.0x multiplier

# 4. Pull second orb  
sozo execute dojo_starter-orb_drawing pull_orb --calldata 1703458234 --wait
# Returns: [5] (DoubleMultiplier orb)
# Effect: Multiplier becomes 2.0x
# Player Stats: 5 health, 5 points, 304 moon rocks, 0 cheddah, 2.0x multiplier

# 5. Pull third orb
sozo execute dojo_starter-orb_drawing pull_orb --calldata 1703458234 --wait  
# Returns: [4] (FivePoints orb)
# Effect: +5 points with 2.0x multiplier = +10 points (rounds up)
# Player Stats: 5 health, 15 points, 304 moon rocks, 0 cheddah, 2.0x multiplier

# Level 1 Complete! (15 points >= 12 required)
# Event: LevelComplete emitted automatically
```

**Frontend State After Level 1:**
- Player Stats: 5 health, 15 points, 304 moon rocks, 10 cheddah (earned from level), 1.0x multiplier (reset)
- Level: 1 → advancing to 2
- Bag: 9 orbs remaining

#### Phase 3: Level Progression & Shop

```bash
# 6. Advance to Level 2
sozo execute dojo_starter-level_progression advance_level --calldata 1703458234 --wait
# Effect: Awards 10 cheddah, resets multiplier, advances to level 2
# Player Stats: 5 health, 15 points, 304 moon rocks, 10 cheddah, 1.0x multiplier

# 7. Generate shop for Level 2
sozo execute dojo_starter-shop_system generate_shop --calldata 1703458234 --wait
# Effect: Creates random shop inventory with 6 orbs

# 8. Check shop contents
sozo execute dojo_starter-shop_system get_shop_contents --calldata 0x123abc 1703458234 2 --wait
# Returns: ([SevenPoints, MoonRock, EightPoints, NextPoints2x, BigHealth, BigMoonRock], [5, 8, 11, 14, 21, 23])

# 9. Check price for specific orb (EightPoints)
sozo execute dojo_starter-shop_system get_orb_price --calldata 0x123abc 13 --wait
# Returns: [11] (11 cheddah - base price, first purchase)

# 10. Purchase EightPoints orb
sozo execute dojo_starter-shop_system purchase_orb --calldata 1703458234 13 --wait
# Effect: -11 cheddah, +1 EightPoints orb to bag
# Player Stats: 5 health, 15 points, 304 moon rocks, -1 cheddah (insufficient!)
# This would fail - player needs more cheddah
```

Let's continue the scenario where Alice doesn't shop and continues with Level 2:

#### Phase 4: Level 2 Gameplay

```bash
# 11. Continue pulling orbs for Level 2 (need 18 points total)
sozo execute dojo_starter-orb_drawing pull_orb --calldata 1703458234 --wait
# Returns: [1] (SingleBomb)
# Effect: -1 health
# Player Stats: 4 health, 15 points, 304 moon rocks, 10 cheddah, 1.0x multiplier

# 12. Pull another orb
sozo execute dojo_starter-orb_drawing pull_orb --calldata 1703458234 --wait
# Returns: [4] (FivePoints)
# Effect: +5 points
# Player Stats: 4 health, 20 points, 304 moon rocks, 10 cheddah, 1.0x multiplier

# Level 2 Complete! (20 points >= 18 required)
```

#### Phase 5: Continue Through Levels Until Loss

```bash
# 13. Advance to Level 3
sozo execute dojo_starter-level_progression advance_level --calldata 1703458234 --wait
# Player Stats: 4 health, 20 points, 304 moon rocks, 22 cheddah, 1.0x multiplier

# 14-20. Continue pulling orbs...
# Let's say Alice gets unlucky and pulls several bombs:

sozo execute dojo_starter-orb_drawing pull_orb --calldata 1703458234 --wait
# Returns: [1] (SingleBomb) - health: 4→3

sozo execute dojo_starter-orb_drawing pull_orb --calldata 1703458234 --wait  
# Returns: [2] (DoubleBomb) - health: 3→1

sozo execute dojo_starter-orb_drawing pull_orb --calldata 1703458234 --wait
# Returns: [1] (SingleBomb) - health: 1→0

# GAME OVER! Health reached 0
# Event: GameOver emitted with reason 'health_zero'
# Final Stats: 0 health, ~25 points, 329 moon rocks (points converted), 22 cheddah
```

#### Phase 6: Optional Game End Actions

```bash
# 21. Player could quit game manually (if not already game over)
sozo execute dojo_starter-game_management quit_game --calldata 1703458234 --wait
# Effect: Converts remaining points to moon rocks 1:1

# 22. Or reset for a new attempt
sozo execute dojo_starter-game_management reset_game --calldata 1703458234 --wait
# Effect: Erases all progress, returns to default state
```

---

## 🔄 Frontend Integration Flow

### 1. Game Initialization Flow
```
start_game() → store game_id → get_bag_contents() (optional)
```

### 2. Core Gameplay Loop
```
pull_orb() → check game state → 
  if level_complete: advance_level() → generate_shop() (optional)
  if game_over: handle end state
  else: continue loop
```

### 3. Shop Interaction Flow
```
generate_shop() → get_shop_contents() → display to user →
  get_orb_price() → purchase_orb() (if player chooses) →
  refresh_shop() (if player wants new inventory)
```

### 4. Level Progression Flow
```
check_level_complete() → advance_level() → 
  pay_level_cost() (if required) → continue gameplay
```

---

## 📊 Key Parameters & Data Types

### Orb Type Mappings (felt252 values)
```
SingleBomb: 1      SevenPoints: 9       EightPoints: 13      BigHealth: 17
DoubleBomb: 2      CheddahBomb: 10      NinePoints: 14       BigMoonRock: 18
TripleBomb: 3      MoonRock: 11         NextPoints2x: 15
FivePoints: 4      HalfMultiplier: 12   Multiplier1_5x: 16
DoubleMultiplier: 5  Health: 8          RemainingOrbs: 6
BombCounter: 7
```

### Level Configuration
```javascript
const LEVEL_CONFIG = {
  1: { points: 12, cost: 5, reward: 10 },
  2: { points: 18, cost: 6, reward: 12 },
  3: { points: 28, cost: 8, reward: 15 },
  4: { points: 44, cost: 10, reward: 18 },
  5: { points: 66, cost: 12, reward: 22 },
  6: { points: 94, cost: 16, reward: 26 },
  7: { points: 130, cost: 20, reward: 30 }
};
```

### Game State Values
```
GameStatus: InProgress(0), LevelComplete(1), GameOver(2), Finished(3)
Starting Values: 5 health, 304 moon rocks, 12-orb bag, 1.0x multiplier
```

---

## 🎯 Frontend Best Practices

### 1. State Management
- Store `game_id` in component state after `start_game()`
- Listen for events to update UI in real-time
- Cache shop contents to avoid repeated calls

### 2. Error Handling
- Validate parameters before function calls
- Handle insufficient resources (cheddah, moon rocks, health)
- Implement retry logic for failed transactions

### 3. User Experience
- Show loading states during transactions
- Display clear error messages
- Update UI immediately after successful transactions
- Implement optimistic updates where appropriate

### 4. Performance
- Batch read operations when possible
- Use events for real-time updates instead of polling
- Cache static data (level requirements, orb prices)

This guide provides everything needed to integrate a frontend with the Moon Bag smart contracts. Each function call in the example scenario demonstrates the complete game flow from initialization to completion.