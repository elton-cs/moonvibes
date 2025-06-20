# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dojo game starter project called "moonvibes" (internally "dojo_starter") - a blockchain-based game built on Starknet using the Dojo game engine framework. The project implements a simple movement system demonstrating Dojo's Entity Component System (ECS) architecture.

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

# Build contracts
sozo build

# Deploy to local node
sozo migrate

# Start game state indexer (replace <WORLD_ADDRESS> with output from migrate)
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

### Using Scarb Scripts
```bash
# Build and migrate in one command
scarb run migrate

# Spawn a player
scarb run spawn

# Move the player (direction: 1=Left, 2=Right, 3=Up, 4=Down)
scarb run move
```

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
    - `models.cairo` - Data models (Position, Moves, Direction, Vec2)
    - `systems/actions.cairo` - Game logic (spawn, move)
    - `lib.cairo` - Library entry point
  - `tests/` - Test files

### Game Components
- **Models**: Define game state structure
  - `Position`: Player coordinates using Vec2
  - `Moves`: Tracks remaining moves and capabilities
  - `Direction`: Movement directions enum

- **Systems**: Define game logic
  - `spawn()`: Initialize player at (10, 10) with 100 moves
  - `move(direction)`: Move player in cardinal directions

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