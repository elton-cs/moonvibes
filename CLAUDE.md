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

## Project Architecture

### Core Structure
- `/contracts/` - Main project directory
  - `src/` - Game contract source code
    - `models.cairo` - Data models (GameState, PlayerStats, Bag, Orbs)
    - `systems/actions.cairo` - Game logic (start_game, pull_orb)
    - `helpers/` - Modular helper functions
      - `orb_effects.cairo` - Orb effect processing
      - `bag_management.cairo` - Bag manipulation
      - `game_progression.cairo` - Level and milestone logic
    - `lib.cairo` - Library entry point
  - `tests/` - Test files

### Game Components
- **Models**: Define game state structure
  - `GameState`: Active status, current level, bombs pulled counter
  - `PlayerStats`: Health, points, multiplier, currencies
  - `Bag`: Dynamic array of orb IDs
  - `LevelProgress`: Tracks pulled orbs for current level

- **Systems**: Define game logic
  - `start_game()`: Initialize new game with starting bag and stats
  - `pull_orb()`: Draw orb from bag and process all game mechanics

### Orb Types (MVP - Consumables Only)
- **Points**: FivePoints, SevenPoints, EightPoints, NinePoints
- **Bombs**: SingleBomb (-1), DoubleBomb (-2), TripleBomb (-3)
- **Health**: Health (+1), BigHealth (+3)
- **Multipliers**: DoubleMultiplier (2x), Multiplier1_5x (1.5x), HalfMultiplier (0.5x)
- **Special**: RemainingOrbs, BombCounter
- **Currency**: MoonRock (+2), BigMoonRock (+10), CheddahBomb (-1 health, +10 cheddah)

### Configuration Files
- `Scarb.toml` - Build configuration and script shortcuts
- `dojo_dev.toml` - Development world configuration
- `dojo_release.toml` - Production world configuration
- `katana.toml` - Local blockchain settings
- `torii_dev.toml` - Indexer configuration
- `compose.yaml` - Docker orchestration

## Development Workflow

1. Always ensure Katana is running before deploying
2. After making contract changes, rebuild with `sozo build`
3. Deploy changes with `sozo migrate` or `scarb run migrate`
4. The world address changes with each deployment - update Torii accordingly
5. Use Sozo execute commands or Scarb scripts to interact with the game

## Key Patterns

- Follow Dojo's ECS architecture when adding new features
- Models define data structure, Systems define behavior
- Use the existing Direction enum pattern for constrained choices
- Maintain the coordinate system established by Vec2