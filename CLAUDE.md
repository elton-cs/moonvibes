# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is Moon Bag - a push-your-luck bag-building game built on Starknet using the Dojo game engine framework. The project implements a cosmic-themed orb drawing mechanic where players draw orbs from their bag to score points while avoiding bombs. The MVP focuses on consumable orbs only (points, health, multipliers) without complex interaction mechanics.

## Technology Stack

- **Smart Contract Language**: Cairo v2.10.1
- **Game Framework**: Dojo v1.5.1
- **Build Tool**: Scarb (Cairo's package manager)
- **Local Blockchain**: Katana
- **Indexer**: Torii
- **Deployment Tool**: Sozo

## Essential Commands

### Development Setup
```bash
# Start local Starknet node (keep this running in a terminal)
katana --dev --dev.no-fee

# Build contracts (use frequently during development to check for errors)
sozo build

# Deploy to local node (ONLY run after all contracts are correctly implemented)
sozo migrate

# Start game state indexer (replace <WORLD_ADDRESS> with output from migrate)
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

### Using Scarb Scripts
```bash
# Build and migrate in one command
scarb run migrate

# Start a new game
scarb run start

# Pull an orb from the bag
scarb run pull
```

### Important Development Notes
- **ALWAYS** use `sozo build` frequently during development to check for compiler errors
- **ONLY** run `sozo migrate` at the very end once all contracts are correctly implemented
- The user will handle Katana and Torii instances

### Docker Alternative
```bash
# Start entire stack with Docker
docker compose up
```

### Testing
```bash
# Run tests
scarb test
```

## Core Architecture

### Dojo ECS Structure
The project follows Dojo's Entity Component System (ECS) pattern:
- **Models** (components): Define data structures stored on-chain
- **Systems** (logic): Define functions that manipulate model data
- **World**: Central registry that manages all models and systems

### Key Models
- **GameState**: Tracks active status, current level, bombs pulled counter
- **PlayerStats**: Health, points, multiplier (fixed-point), currencies (moon_rocks, cheddah)
- **Bag**: Dynamic array of orb types for bag-building mechanics  
- **LevelProgress**: Tracks orbs pulled during current level

### Core Systems
- **start_game()**: Initializes new game with starting resources and 12-orb starting bag
- **pull_orb()**: Core game loop - draws random orb, applies effects, checks win/loss conditions

### Game Flow Architecture
1. Player pays moon rocks to start level (costs defined in `get_level_config()`)
2. Player draws orbs using `pull_orb()` - each orb applies immediate effects
3. Level completes when milestone points reached (triggers cheddah reward)
4. Game ends when health reaches 0 or bag is empty (converts points to moon rocks 1:1)

### Orb Effect System
All 17 orb types are processed through `apply_orb_effect()` helper function:
- **Points**: Applied with current multiplier (always rounds up)
- **Bombs**: Reduce health, tracked in `bombs_pulled` counter
- **Multipliers**: Modify future point calculations (stored as 100 = 1.0x)
- **Special**: RemainingOrbs uses current bag size, BombCounter uses bombs_pulled
- **Health/Currency**: Direct stat modifications

### Level Configuration
Hardcoded in `get_level_config()` returning (milestone_points, moon_rock_cost):
- Level 1: 12 points, 5 moon rocks
- Level 2: 18 points, 6 moon rocks  
- Level 3: 28 points, 8 moon rocks
- Level 4: 44 points, 10 moon rocks
- Level 5: 66 points, 12 moon rocks
- Level 6: 94 points, 16 moon rocks
- Level 7: 130 points, 20 moon rocks

## Implementation Status

### Completed Features ✅
- **Core Models**: GameState, PlayerStats, Bag, LevelProgress with proper Dojo traits
- **Orb System**: Complete OrbType enum with 17 orb variants and felt252 conversion
- **Game Systems**: Functional start_game() and pull_orb() with full game logic
- **Helper Architecture**: Modular helper functions for orb effects, bag management, progression
- **Event System**: Comprehensive events for GameStarted, OrbPulled, LevelComplete, GameOver
- **Level Configuration**: 7-level progression with milestone requirements
- **Starting Values**: Proper game initialization (5 health, 304 moon rocks, 12-orb starting bag)

### Missing Features ⚠️
- **Helper Function Implementations**: The helper modules are imported but not yet implemented:
  - `orb_effects.cairo` - Orb effect processing logic
  - `bag_management.cairo` - Bag initialization and random orb drawing
  - `game_progression.cairo` - Level completion and game over checking
- **Test Suite**: Current tests are outdated and need updating for actual game models
- **Shop System**: Not implemented (future feature for purchasing new orbs)

### Critical Dependencies
The game systems rely on these helper functions that need implementation:
- `apply_orb_effect()` - Processes all orb effects with multiplier calculations
- `initialize_starting_bag()` - Creates the initial 12-orb bag composition
- `draw_random_orb()` - Removes random orb from bag using block timestamp
- `check_level_complete()` - Validates if milestone points reached
- `check_game_over()` - Checks health/empty bag conditions
- `calculate_cheddah_reward()` - Determines cheddah earned per level

## Project Structure

```
contracts/
├── Scarb.toml                   # Build config with dojo v1.5.1 dependency
├── dojo_dev.toml               # World config with "dojo_starter" namespace  
├── src/
│   ├── lib.cairo               # Main library entry point
│   ├── models.cairo            # Complete data models (4 models + enum)
│   ├── systems/actions.cairo   # Main game systems (2 functions)
│   └── helpers/               # Missing implementations
│       ├── orb_effects.cairo
│       ├── bag_management.cairo
│       └── game_progression.cairo
└── tests/
    └── test_world.cairo        # Outdated tests needing updates
```

## Development Workflow

1. Always ensure Katana is running before deploying
2. After making contract changes, rebuild with `sozo build`
3. Deploy changes with `sozo migrate` or `scarb run migrate`
4. The world address changes with each deployment - update Torii accordingly
5. Use Sozo execute commands or Scarb scripts to interact with the game

## Key Implementation Notes

### Dojo Patterns Used
- **ECS Architecture**: Clear separation between data models and system logic
- **Namespace**: Uses "dojo_starter" namespace throughout
- **Event-Driven**: Emits events for all major game state changes
- **Model Keys**: Uses ContractAddress as primary key for player-specific data
- **World Access**: Systems use `world_default()` helper for consistent world access

### Cairo Patterns
- **Fixed-Point Arithmetic**: Multiplier stored as u32 (100 = 1.0x) to avoid floating point
- **Safe Operations**: Uses saturating arithmetic and proper error handling
- **Array Handling**: Bag uses Array<OrbType> with proper append-only operations
- **Random Generation**: Uses block timestamp for pseudorandom orb selection

### Game Balance
- **Starting Resources**: 5 health, 304 moon rocks, 0 cheddah, 1.0x multiplier
- **Point Calculation**: Always rounds up when applying multipliers
- **Level Scaling**: Exponential point requirements (12→18→28→44→66→94→130)
- **Economy**: Points convert to moon rocks 1:1 at game end