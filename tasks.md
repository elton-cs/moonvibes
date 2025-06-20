# Moon Bag Game Backend - Implementation Tasks

## Overview
This document breaks down the implementation of Moon Bag, a push-your-luck bag-building game, into atomic and actionable tasks for junior developers. The backend will be implemented using Cairo smart contracts with the Dojo game engine framework on Starknet.

## Prerequisites
- Basic understanding of Cairo programming language
- Familiarity with Dojo framework concepts (Models, Systems, World)
- Knowledge of Entity Component System (ECS) architecture
- Understanding of smart contract development principles

## Technology Stack
- **Smart Contract Language**: Cairo v2.10.1
- **Game Framework**: Dojo v1.5.1
- **Build Tool**: Scarb
- **Local Blockchain**: Katana
- **Indexer**: Torii
- **Deployment Tool**: Sozo

---

## Phase 1: Project Setup and Configuration

### Task 1.1: Initialize Dojo Project Structure
**Priority**: High  
**Estimated Time**: 1-2 hours  
**Prerequisites**: Dojo installed locally

**Description**: Set up the basic Dojo project structure with proper configuration files.

**Acceptance Criteria**:
- [ ] Project directory structure created
- [ ] Scarb.toml configured with proper dependencies
- [ ] dojo_dev.toml and dojo_release.toml configuration files created
- [ ] katana.toml for local blockchain settings
- [ ] torii_dev.toml for indexer configuration
- [ ] Project builds successfully with `sozo build`

**Implementation Steps**:
1. Create new Dojo project: `sozo init moon_bag`
2. Update Scarb.toml with required dependencies:
   ```toml
   [dependencies]
   dojo = { git = "https://github.com/dojoengine/dojo", tag = "v1.5.1" }
   ```
3. Configure dojo_dev.toml with proper namespace and settings
4. Add Scarb scripts for common operations (build, migrate, start, pull)
5. Test project setup with `sozo build`

**Dojo-Specific Notes**:
- Use proper namespace configuration in dojo profile files
- Ensure all required traits are included in dependencies
- Follow Dojo naming conventions for models and systems

---

### Task 1.2: Create Project Library Structure
**Priority**: High  
**Estimated Time**: 30 minutes  
**Prerequisites**: Task 1.1 complete

**Description**: Organize the project's module structure for scalability and maintainability.

**Acceptance Criteria**:
- [ ] lib.cairo properly configured with all modules
- [ ] Separate modules for models, systems, and helpers
- [ ] Proper imports and exports defined
- [ ] Project compiles without errors

**Implementation Steps**:
1. Create lib.cairo with proper module declarations
2. Set up separate directories: models/, systems/, helpers/
3. Create index files for each module directory
4. Define proper visibility and imports
5. Test compilation with `sozo build`

**Module Structure**:
```
src/
├── lib.cairo (main library file)
├── models/
│   ├── game_state.cairo
│   ├── player_stats.cairo
│   ├── bag.cairo
│   ├── orb.cairo
│   └── mod.cairo
├── systems/
│   ├── game_management.cairo
│   ├── orb_drawing.cairo
│   ├── shop_system.cairo
│   └── mod.cairo
└── helpers/
    ├── orb_effects.cairo
    ├── level_calculation.cairo
    └── mod.cairo
```

---

## Phase 2: Core Data Models Implementation

### Task 2.1: Implement Orb Model and Enum
**Priority**: High  
**Estimated Time**: 2-3 hours  
**Prerequisites**: Task 1.2 complete

**Description**: Create the foundational Orb model with all 25 orb types (12 starting + 13 shop orbs).

**Acceptance Criteria**:
- [ ] OrbType enum with all 25 orb variants defined
- [ ] Orb model struct with proper fields
- [ ] All required traits implemented (Drop, Serde, Introspect)
- [ ] Proper enum-to-felt252 conversion implemented
- [ ] Model compiles and passes basic tests

**Implementation Steps**:
1. Define OrbType enum with all variants:
   ```cairo
   #[derive(Serde, Drop, Introspect, PartialEq, Debug)]
   enum OrbType {
       // Starting Orbs
       SingleBomb,
       DoubleBomb,
       TripleBomb,
       FivePoints,
       DoubleMultiplier,
       RemainingOrbs,
       BombCounter,
       Health,
       // Shop Orbs
       SevenPoints,
       EightPoints,
       NinePoints,
       CheddahBomb,
       MoonRock,
       BigMoonRock,
       HalfMultiplier,
       Multiplier1_5x,
       NextPoints2x,
       BigHealth,
       // ... etc
   }
   ```

2. Create Orb model:
   ```cairo
   #[derive(Drop, Serde)]
   #[dojo::model]
   struct Orb {
       #[key]
       orb_id: u32,
       orb_type: OrbType,
       value: i32,
       rarity: u8, // 0=common, 1=rare, 2=cosmic
   }
   ```

3. Implement conversion traits and helper functions
4. Add comprehensive unit tests for all orb types
5. Document each orb's effect and usage

**Dojo-Specific Notes**:
- Use Introspect trait for enum, not IntrospectPacked
- Implement proper felt252 conversion for enum variants
- Ensure all fields have proper visibility modifiers
- Remember to derive all required traits

---

### Task 2.2: Implement GameState Model
**Priority**: High  
**Estimated Time**: 1-2 hours  
**Prerequisites**: Task 2.1 complete

**Description**: Create the core GameState model to track overall game status and progression.

**Acceptance Criteria**:
- [ ] GameState model with all required fields
- [ ] GameStatus enum for different game states
- [ ] Proper key structure for game identification
- [ ] All traits properly implemented
- [ ] Model validates with Dojo standards

**Implementation Steps**:
1. Define GameStatus enum:
   ```cairo
   #[derive(Serde, Drop, Introspect, PartialEq)]
   enum GameStatus {
       NotStarted,
       InProgress,
       LevelComplete,
       GameOver,
       Finished,
   }
   ```

2. Create GameState model:
   ```cairo
   #[derive(Drop, Serde)]
   #[dojo::model]
   struct GameState {
       #[key]
       player: ContractAddress,
       #[key]
       game_id: u64,
       status: GameStatus,
       current_level: u8,
       bombs_pulled_this_level: u8,
       orbs_pulled_this_level: u8,
       started_at: u64,
       last_updated: u64,
   }
   ```

3. Implement helper functions for game state management
4. Add validation functions for state transitions
5. Create unit tests for state changes

**Dojo-Specific Notes**:
- Use composite keys (player, game_id) for game identification
- Implement proper timestamp handling
- Ensure enum derives correct traits
- Add helper functions with #[generate_trait] attribute

---

### Task 2.3: Implement PlayerStats Model
**Priority**: High  
**Estimated Time**: 1-2 hours  
**Prerequisites**: Task 2.2 complete

**Description**: Create PlayerStats model to track all player currencies and statistics.

**Acceptance Criteria**:
- [ ] PlayerStats model with all required fields
- [ ] Proper key structure linking to GameState
- [ ] Helper functions for stat calculations
- [ ] Multiplier handling implementation
- [ ] Validation for stat bounds

**Implementation Steps**:
1. Create PlayerStats model:
   ```cairo
   #[derive(Drop, Serde)]
   #[dojo::model]
   struct PlayerStats {
       #[key]
       player: ContractAddress,
       #[key]
       game_id: u64,
       health: u8,
       points: u32,
       multiplier: u32, // stored as 100 = 1.0x, 150 = 1.5x, etc.
       cheddah: u32,
       moon_rocks: u32,
       badges: u32,
   }
   ```

2. Implement helper functions:
   ```cairo
   #[generate_trait]
   impl PlayerStatsImpl of PlayerStatsTrait {
       fn apply_multiplier(self: @PlayerStats, base_points: u32) -> u32 {
           // Implementation for multiplier calculation
       }
       
       fn is_alive(self: @PlayerStats) -> bool {
           *self.health > 0
       }
       
       fn can_afford_level(self: @PlayerStats, cost: u32) -> bool {
           *self.moon_rocks >= cost
       }
   }
   ```

3. Add validation functions for stat updates
4. Implement bounds checking for all stats
5. Create comprehensive unit tests

**Dojo-Specific Notes**:
- Store multiplier as integer (100 = 1.0x) to avoid floating point
- Use proper overflow protection for large numbers
- Implement helper traits for common operations
- Consider using u32 for points to handle large scores

---

### Task 2.4: Implement Bag Model
**Priority**: High  
**Estimated Time**: 2-3 hours  
**Prerequisites**: Task 2.3 complete

**Description**: Create the Bag model to represent the player's collection of orbs with dynamic array management.

**Acceptance Criteria**:
- [ ] Bag model with dynamic orb array
- [ ] Helper functions for bag manipulation
- [ ] Proper random orb selection implementation
- [ ] Bag validation and integrity checks
- [ ] Efficient orb removal mechanism

**Implementation Steps**:
1. Create Bag model:
   ```cairo
   #[derive(Drop, Serde)]
   #[dojo::model]
   struct Bag {
       #[key]
       player: ContractAddress,
       #[key]
       game_id: u64,
       orbs: Array<u32>, // Array of orb IDs
       total_orbs: u32,
   }
   ```

2. Implement bag management functions:
   ```cairo
   #[generate_trait]
   impl BagImpl of BagTrait {
       fn add_orb(ref self: Bag, orb_id: u32) {
           // Add orb to bag
       }
       
       fn remove_orb_at_index(ref self: Bag, index: u32) -> u32 {
           // Remove and return orb at specific index
       }
       
       fn get_random_orb_index(self: @Bag, seed: felt252) -> u32 {
           // Get random index for orb selection
       }
       
       fn is_empty(self: @Bag) -> bool {
           // Check if bag is empty
       }
   }
   ```

3. Implement random selection mechanism using block hash
4. Add validation for bag operations
5. Create unit tests for all bag operations

**Dojo-Specific Notes**:
- Arrays in Cairo are append-only, plan removal strategy carefully
- Use proper random number generation for orb selection
- Store array length separately for efficiency
- Remember that Array<T> cannot use Copy trait

---

### Task 2.5: Implement LevelProgress Model
**Priority**: Medium  
**Estimated Time**: 1-2 hours  
**Prerequisites**: Task 2.4 complete

**Description**: Create LevelProgress model to track level-specific progress and requirements.

**Acceptance Criteria**:
- [ ] LevelProgress model with level requirements
- [ ] Level configuration constants
- [ ] Progress tracking functions
- [ ] Level completion validation
- [ ] Reward calculation system

**Implementation Steps**:
1. Define level configuration constants:
   ```cairo
   mod LevelConfig {
       const LEVEL_1_POINTS: u32 = 12;
       const LEVEL_1_COST: u32 = 5;
       const LEVEL_1_REWARD: u32 = 8;
       // ... continue for all 7 levels
   }
   ```

2. Create LevelProgress model:
   ```cairo
   #[derive(Drop, Serde)]
   #[dojo::model]
   struct LevelProgress {
       #[key]
       player: ContractAddress,
       #[key]
       game_id: u64,
       current_level: u8,
       points_required: u32,
       points_earned: u32,
       level_cost: u32,
       cheddah_reward: u32,
   }
   ```

3. Implement level management functions
4. Add level completion checking
5. Create reward calculation system

**Dojo-Specific Notes**:
- Use constants for level configuration
- Implement proper level progression validation
- Consider using lookup tables for level data

---

### Task 2.6: Implement Shop Models
**Priority**: Medium  
**Estimated Time**: 2-3 hours  
**Prerequisites**: Task 2.5 complete

**Description**: Create Shop and PurchaseHistory models for the shop system.

**Acceptance Criteria**:
- [ ] Shop model with available orbs
- [ ] PurchaseHistory model for price scaling
- [ ] Shop generation logic
- [ ] Price calculation with 20% scaling
- [ ] Rarity-based orb selection

**Implementation Steps**:
1. Create Shop model:
   ```cairo
   #[derive(Drop, Serde)]
   #[dojo::model]
   struct Shop {
       #[key]
       player: ContractAddress,
       #[key]
       game_id: u64,
       #[key]
       level: u8,
       available_orbs: Array<u32>, // Array of orb IDs
       orb_prices: Array<u32>, // Corresponding prices
   }
   ```

2. Create PurchaseHistory model:
   ```cairo
   #[derive(Drop, Serde)]
   #[dojo::model]
   struct PurchaseHistory {
       #[key]
       player: ContractAddress,
       orb_type: OrbType,
       purchase_count: u32,
   }
   ```

3. Implement shop generation logic
4. Add price calculation with scaling
5. Create rarity-based selection system

**Dojo-Specific Notes**:
- Use separate arrays for orbs and prices
- Implement proper random selection for shop generation
- Consider using composite keys for purchase history

---

## Phase 3: Core Systems Implementation

### Task 3.1: Implement Game Management System
**Priority**: High  
**Estimated Time**: 3-4 hours  
**Prerequisites**: All models from Phase 2 complete

**Description**: Create the core game management system with start_game, quit_game, and reset_game functions.

**Acceptance Criteria**:
- [ ] start_game function implemented
- [ ] quit_game function implemented
- [ ] reset_game function implemented
- [ ] Proper permission checking
- [ ] Game state validation
- [ ] Event emission for game state changes

**Implementation Steps**:
1. Define the system interface:
   ```cairo
   #[starknet::interface]
   trait IGameManagement<T> {
       fn start_game(ref self: T) -> u64; // Returns game_id
       fn quit_game(ref self: T, game_id: u64);
       fn reset_game(ref self: T, game_id: u64);
   }
   ```

2. Implement the game management contract:
   ```cairo
   #[dojo::contract]
   mod game_management {
       use super::IGameManagement;
       use starknet::{get_caller_address, get_block_timestamp};
       use dojo::model::{ModelStorage};
       use dojo::world::{WorldStorage};
       
       #[abi(embed_v0)]
       impl GameManagementImpl of IGameManagement<ContractState> {
           fn start_game(ref self: ContractState) -> u64 {
               let mut world = self.world(@"moon_bag");
               let player = get_caller_address();
               // Implementation...
           }
       }
   }
   ```

3. Implement start_game function:
   - Generate unique game_id
   - Create initial GameState
   - Initialize PlayerStats with starting values
   - Create starting bag with 12 orbs
   - Emit GameStarted event

4. Implement quit_game function:
   - Validate game exists and player owns it
   - Update game status to Finished
   - Calculate final rewards
   - Emit GameQuit event

5. Implement reset_game function:
   - Validate permissions
   - Reset all game models to initial state
   - Emit GameReset event

**Dojo-Specific Notes**:
- Use world.uuid() for unique game ID generation
- Implement proper error handling with asserts
- Make world reference mutable for writes
- Emit events for all state changes

---

### Task 3.2: Implement Orb Drawing System
**Priority**: High  
**Estimated Time**: 4-5 hours  
**Prerequisites**: Task 3.1 complete

**Description**: Create the core orb drawing system with pull_orb function and orb effect processing.

**Acceptance Criteria**:
- [ ] pull_orb function implemented
- [ ] Random orb selection from bag
- [ ] All 25 orb effects implemented
- [ ] Proper stat updates
- [ ] Special orb mechanics (RemainingOrbs, BombCounter)
- [ ] Game state validation after each pull

**Implementation Steps**:
1. Define the orb drawing interface:
   ```cairo
   #[starknet::interface]
   trait IOrbDrawing<T> {
       fn pull_orb(ref self: T, game_id: u64) -> u32; // Returns pulled orb_id
       fn get_bag_contents(self: @T, player: ContractAddress, game_id: u64) -> Array<u32>;
   }
   ```

2. Implement pull_orb function:
   ```cairo
   fn pull_orb(ref self: ContractState, game_id: u64) -> u32 {
       let mut world = self.world(@"moon_bag");
       let player = get_caller_address();
       
       // Validate game state
       let game_state: GameState = world.read_model((player, game_id));
       assert(game_state.status == GameStatus::InProgress, 'Game not in progress');
       
       // Get bag and select random orb
       let mut bag: Bag = world.read_model((player, game_id));
       assert(!bag.is_empty(), 'Bag is empty');
       
       let orb_index = bag.get_random_orb_index(get_block_timestamp().into());
       let orb_id = bag.remove_orb_at_index(orb_index);
       
       // Process orb effects
       self.process_orb_effects(orb_id, player, game_id);
       
       // Update bag
       world.write_model(@bag);
       
       orb_id
   }
   ```

3. Implement process_orb_effects function:
   ```cairo
   #[generate_trait]
   impl InternalImpl of InternalTrait {
       fn process_orb_effects(
           self: @ContractState, 
           orb_id: u32, 
           player: ContractAddress, 
           game_id: u64
       ) {
           let mut world = self.world(@"moon_bag");
           let orb: Orb = world.read_model(orb_id);
           let mut stats: PlayerStats = world.read_model((player, game_id));
           
           match orb.orb_type {
               OrbType::FivePoints => {
                   let points = apply_multiplier(5, stats.multiplier);
                   stats.points += points;
               },
               OrbType::SingleBomb => {
                   stats.health = stats.health.saturating_sub(1);
               },
               OrbType::RemainingOrbs => {
                   let bag: Bag = world.read_model((player, game_id));
                   let points = apply_multiplier(bag.total_orbs, stats.multiplier);
                   stats.points += points;
               },
               // ... implement all other orb types
           }
           
           world.write_model(@stats);
       }
   }
   ```

4. Implement all 25 orb effects
5. Add special mechanics for dynamic orbs
6. Create comprehensive unit tests

**Dojo-Specific Notes**:
- Use block timestamp for randomness
- Implement proper error handling for edge cases
- Use saturating_sub to prevent underflow
- Emit events for each orb pull

---

### Task 3.3: Implement Level Progression System
**Priority**: High  
**Estimated Time**: 2-3 hours  
**Prerequisites**: Task 3.2 complete

**Description**: Create the level progression system with milestone checking and level advancement.

**Acceptance Criteria**:
- [ ] check_level_complete function implemented
- [ ] advance_level function implemented
- [ ] Milestone validation
- [ ] Cheddah reward distribution
- [ ] Level cost deduction
- [ ] Multiplier reset between levels

**Implementation Steps**:
1. Define level progression interface:
   ```cairo
   #[starknet::interface]
   trait ILevelProgression<T> {
       fn check_level_complete(self: @T, player: ContractAddress, game_id: u64) -> bool;
       fn advance_level(ref self: T, game_id: u64);
       fn get_level_requirements(self: @T, level: u8) -> (u32, u32, u32); // points, cost, reward
   }
   ```

2. Implement milestone checking:
   ```cairo
   fn check_level_complete(self: @T, player: ContractAddress, game_id: u64) -> bool {
       let world = self.world(@"moon_bag");
       let stats: PlayerStats = world.read_model((player, game_id));
       let progress: LevelProgress = world.read_model((player, game_id));
       
       stats.points >= progress.points_required
   }
   ```

3. Implement level advancement:
   ```cairo
   fn advance_level(ref self: T, game_id: u64) {
       let mut world = self.world(@"moon_bag");
       let player = get_caller_address();
       
       // Validate level completion
       assert(self.check_level_complete(player, game_id), 'Level not complete');
       
       // Award cheddah
       let mut stats: PlayerStats = world.read_model((player, game_id));
       let progress: LevelProgress = world.read_model((player, game_id));
       stats.cheddah += progress.cheddah_reward;
       
       // Reset multiplier
       stats.multiplier = 100; // 1.0x
       
       // Advance to next level
       let mut game_state: GameState = world.read_model((player, game_id));
       game_state.current_level += 1;
       
       // Update models
       world.write_model(@stats);
       world.write_model(@game_state);
       
       // Generate new level progress
       let new_progress = self.create_level_progress(player, game_id, game_state.current_level);
       world.write_model(@new_progress);
   }
   ```

4. Implement level configuration system
5. Add level completion validation
6. Create unit tests for level progression

**Dojo-Specific Notes**:
- Use lookup tables for level configurations
- Implement proper validation for level advancement
- Reset appropriate stats between levels
- Emit events for level progression

---

### Task 3.4: Implement Shop System
**Priority**: Medium  
**Estimated Time**: 3-4 hours  
**Prerequisites**: Task 3.3 complete

**Description**: Create the shop system with shop generation, orb purchasing, and price scaling.

**Acceptance Criteria**:
- [ ] generate_shop function implemented
- [ ] purchase_orb function implemented
- [ ] Price scaling with 20% increase per purchase
- [ ] Rarity-based orb selection (3 common, 2 rare, 1 cosmic)
- [ ] Purchase validation and error handling
- [ ] Orb addition to player's bag

**Implementation Steps**:
1. Define shop system interface:
   ```cairo
   #[starknet::interface]
   trait IShopSystem<T> {
       fn generate_shop(ref self: T, game_id: u64);
       fn purchase_orb(ref self: T, game_id: u64, orb_id: u32);
       fn get_shop_contents(self: @T, player: ContractAddress, game_id: u64, level: u8) -> (Array<u32>, Array<u32>);
       fn get_orb_price(self: @T, player: ContractAddress, orb_type: OrbType) -> u32;
   }
   ```

2. Implement shop generation:
   ```cairo
   fn generate_shop(ref self: T, game_id: u64) {
       let mut world = self.world(@"moon_bag");
       let player = get_caller_address();
       let game_state: GameState = world.read_model((player, game_id));
       
       let mut shop_orbs = ArrayTrait::new();
       let mut shop_prices = ArrayTrait::new();
       
       // Generate 3 common orbs
       let common_orbs = self.select_random_orbs_by_rarity(0, 3);
       // Generate 2 rare orbs
       let rare_orbs = self.select_random_orbs_by_rarity(1, 2);
       // Generate 1 cosmic orb
       let cosmic_orbs = self.select_random_orbs_by_rarity(2, 1);
       
       // Add all orbs to shop with calculated prices
       // Implementation...
   }
   ```

3. Implement purchase system:
   ```cairo
   fn purchase_orb(ref self: T, game_id: u64, orb_id: u32) {
       let mut world = self.world(@"moon_bag");
       let player = get_caller_address();
       
       // Get orb details
       let orb: Orb = world.read_model(orb_id);
       let price = self.get_orb_price(player, orb.orb_type);
       
       // Validate purchase
       let mut stats: PlayerStats = world.read_model((player, game_id));
       assert(stats.cheddah >= price, 'Insufficient cheddah');
       
       // Deduct payment
       stats.cheddah -= price;
       
       // Add orb to bag
       let mut bag: Bag = world.read_model((player, game_id));
       bag.add_orb(orb_id);
       
       // Update purchase history
       let mut history: PurchaseHistory = world.read_model((player, orb.orb_type));
       history.purchase_count += 1;
       
       // Write updates
       world.write_model(@stats);
       world.write_model(@bag);
       world.write_model(@history);
   }
   ```

4. Implement price scaling calculation:
   ```cairo
   fn get_orb_price(self: @T, player: ContractAddress, orb_type: OrbType) -> u32 {
       let world = self.world(@"moon_bag");
       let history: PurchaseHistory = world.read_model((player, orb_type));
       let base_price = self.get_base_price(orb_type);
       
       // Calculate 20% increase per purchase: base_price * 1.2^purchase_count
       let multiplier = pow(120, history.purchase_count) / pow(100, history.purchase_count);
       (base_price * multiplier).into()
   }
   ```

5. Implement rarity-based selection
6. Add purchase validation and error handling
7. Create comprehensive unit tests

**Dojo-Specific Notes**:
- Use proper random number generation for shop selection
- Implement efficient price calculation
- Handle purchase history across multiple games
- Validate all purchases before processing

---

## Phase 4: Helper Functions and Utilities

### Task 4.1: Implement Orb Effects Helper
**Priority**: Medium  
**Estimated Time**: 2-3 hours  
**Prerequisites**: Task 3.2 complete

**Description**: Create comprehensive orb effect processing utilities with proper multiplier handling.

**Acceptance Criteria**:
- [ ] Multiplier calculation functions
- [ ] Point application with rounding
- [ ] Health modification functions
- [ ] Currency effect processing
- [ ] Special orb mechanics
- [ ] Effect validation and bounds checking

**Implementation Steps**:
1. Create orb effects helper module:
   ```cairo
   mod orb_effects {
       use super::{PlayerStats, Bag, GameState};
       
       fn apply_points_with_multiplier(base_points: u32, multiplier: u32) -> u32 {
           // Multiply by multiplier (stored as 100 = 1.0x)
           // Always round up: (base_points * multiplier + 99) / 100
           (base_points * multiplier + 99) / 100
       }
       
       fn apply_health_change(mut stats: PlayerStats, change: i8) -> PlayerStats {
           if change > 0 {
               stats.health += change.abs();
           } else {
               stats.health = stats.health.saturating_sub(change.abs());
           }
           stats
       }
       
       fn apply_multiplier_change(mut stats: PlayerStats, multiplier_change: u32) -> PlayerStats {
           stats.multiplier = (stats.multiplier * multiplier_change) / 100;
           stats
       }
   }
   ```

2. Implement special orb mechanics:
   ```cairo
   fn process_remaining_orbs_effect(
       bag: @Bag, 
       stats: PlayerStats
   ) -> u32 {
       let remaining_count = bag.total_orbs;
       apply_points_with_multiplier(remaining_count, stats.multiplier)
   }
   
   fn process_bomb_counter_effect(
       game_state: @GameState, 
       stats: PlayerStats
   ) -> u32 {
       let bomb_count = game_state.bombs_pulled_this_level;
       apply_points_with_multiplier(bomb_count, stats.multiplier)
   }
   ```

3. Implement currency effects
4. Add effect validation functions
5. Create unit tests for all effects

**Dojo-Specific Notes**:
- Use integer arithmetic to avoid floating point issues
- Implement proper overflow protection
- Use saturating arithmetic for health changes
- Add bounds checking for all effects

---

### Task 4.2: Implement Game Progression Helper
**Priority**: Medium  
**Estimated Time**: 1-2 hours  
**Prerequisites**: Task 4.1 complete

**Description**: Create helper functions for game progression, win/loss conditions, and reward calculations.

**Acceptance Criteria**:
- [ ] Win/loss condition checking
- [ ] Game over detection
- [ ] Final score calculation
- [ ] Reward conversion (points to moon rocks)
- [ ] Game completion validation

**Implementation Steps**:
1. Create game progression utilities:
   ```cairo
   mod game_progression {
       use super::{GameState, PlayerStats, GameStatus};
       
       fn check_game_over(stats: @PlayerStats, bag: @Bag) -> bool {
           *stats.health == 0 || bag.is_empty()
       }
       
       fn check_level_requirements_met(stats: @PlayerStats, required_points: u32) -> bool {
           *stats.points >= required_points
       }
       
       fn calculate_final_rewards(stats: @PlayerStats) -> u32 {
           // Convert points to moon rocks at 1:1 ratio
           *stats.points
       }
       
       fn determine_game_outcome(
           game_state: @GameState,
           stats: @PlayerStats,
           bag: @Bag
       ) -> GameStatus {
           if check_game_over(stats, bag) {
               GameStatus::GameOver
           } else if check_level_requirements_met(stats, 130) { // Max level points
               GameStatus::Finished
           } else {
               GameStatus::InProgress
           }
       }
   }
   ```

2. Implement scoring system
3. Add reward calculation functions
4. Create game completion utilities
5. Add comprehensive unit tests

**Dojo-Specific Notes**:
- Use proper validation for all calculations
- Implement consistent scoring across all systems
- Handle edge cases properly
- Provide clear feedback for game outcomes

---

### Task 4.3: Implement Bag Management Helper
**Priority**: Medium  
**Estimated Time**: 1-2 hours  
**Prerequisites**: Task 4.2 complete

**Description**: Create advanced bag management utilities for efficient orb manipulation.

**Acceptance Criteria**:
- [ ] Efficient orb search functions
- [ ] Bag validation utilities
- [ ] Orb counting by type
- [ ] Bag state analysis
- [ ] Performance optimized operations

**Implementation Steps**:
1. Create bag management utilities:
   ```cairo
   mod bag_management {
       use super::{Bag, Orb, OrbType};
       
       fn count_orbs_by_type(bag: @Bag, orb_type: OrbType) -> u32 {
           let mut count = 0;
           let mut i = 0;
           while i < bag.orbs.len() {
               let orb_id = *bag.orbs.at(i);
               // Get orb and check type
               // Implementation...
               i += 1;
           }
           count
       }
       
       fn get_orb_type_distribution(bag: @Bag) -> Array<(OrbType, u32)> {
           // Return array of (orb_type, count) tuples
           // Implementation...
       }
       
       fn validate_bag_integrity(bag: @Bag) -> bool {
           // Validate bag state consistency
           bag.orbs.len() == bag.total_orbs
       }
   }
   ```

2. Implement orb search functions
3. Add bag analysis utilities
4. Create performance optimized operations
5. Add comprehensive unit tests

**Dojo-Specific Notes**:
- Use efficient iteration patterns
- Implement proper array bounds checking
- Consider gas optimization for large bags
- Use proper error handling

---

## Phase 5: Testing and Validation

### Task 5.1: Implement Unit Tests for Models
**Priority**: High  
**Estimated Time**: 4-5 hours  
**Prerequisites**: All models implemented

**Description**: Create comprehensive unit tests for all data models.

**Acceptance Criteria**:
- [ ] Tests for all model CRUD operations
- [ ] Tests for model validation
- [ ] Tests for model relationships
- [ ] Tests for edge cases
- [ ] Tests for error conditions
- [ ] 100% code coverage for models

**Implementation Steps**:
1. Create test module structure:
   ```
   tests/
   ├── models/
   │   ├── test_game_state.cairo
   │   ├── test_player_stats.cairo
   │   ├── test_bag.cairo
   │   ├── test_orb.cairo
   │   └── mod.cairo
   └── mod.cairo
   ```

2. Implement GameState tests:
   ```cairo
   #[cfg(test)]
   mod test_game_state {
       use super::GameState;
       use starknet::ContractAddress;
       
       #[test]
       fn test_game_state_creation() {
           let game_state = GameState {
               player: 0x123.try_into().unwrap(),
               game_id: 1,
               status: GameStatus::NotStarted,
               current_level: 1,
               bombs_pulled_this_level: 0,
               orbs_pulled_this_level: 0,
               started_at: 0,
               last_updated: 0,
           };
           
           assert(game_state.current_level == 1, 'Level should be 1');
           assert(game_state.status == GameStatus::NotStarted, 'Status should be NotStarted');
       }
   }
   ```

3. Implement comprehensive tests for each model
4. Add edge case testing
5. Include error condition testing
6. Measure and achieve high code coverage

**Dojo-Specific Notes**:
- Use Dojo's testing framework
- Test model serialization/deserialization
- Validate all trait implementations
- Include integration tests with World

---

### Task 5.2: Implement Unit Tests for Systems
**Priority**: High  
**Estimated Time**: 5-6 hours  
**Prerequisites**: All systems implemented

**Description**: Create comprehensive unit tests for all system functions.

**Acceptance Criteria**:
- [ ] Tests for all system functions
- [ ] Tests for system interactions
- [ ] Tests for permission validation
- [ ] Tests for game flow scenarios
- [ ] Tests for error handling
- [ ] Integration tests with models

**Implementation Steps**:
1. Create system test structure:
   ```
   tests/
   ├── systems/
   │   ├── test_game_management.cairo
   │   ├── test_orb_drawing.cairo
   │   ├── test_level_progression.cairo
   │   ├── test_shop_system.cairo
   │   └── mod.cairo
   ```

2. Implement game management tests:
   ```cairo
   #[cfg(test)]
   mod test_game_management {
       use super::*;
       use dojo::world::{WorldStorage, WorldStorageTrait};
       use dojo::model::{ModelStorage};
       
       #[test]
       fn test_start_game() {
           let mut world = WorldStorageTrait::new();
           let player = 0x123.try_into().unwrap();
           
           // Test game initialization
           let game_id = start_game(&mut world, player);
           
           // Verify game state
           let game_state: GameState = world.read_model((player, game_id));
           assert(game_state.status == GameStatus::InProgress, 'Game should be in progress');
           
           // Verify player stats
           let stats: PlayerStats = world.read_model((player, game_id));
           assert(stats.health == 5, 'Health should be 5');
           assert(stats.moon_rocks == 304, 'Moon rocks should be 304');
       }
   }
   ```

3. Test all system functions
4. Add integration tests
5. Test error conditions
6. Validate system interactions

**Dojo-Specific Notes**:
- Use proper Dojo testing patterns
- Mock world state for testing
- Test with multiple game scenarios
- Validate event emissions

---

### Task 5.3: Implement Integration Tests
**Priority**: Medium  
**Estimated Time**: 3-4 hours  
**Prerequisites**: All unit tests complete

**Description**: Create end-to-end integration tests for complete game scenarios.

**Acceptance Criteria**:
- [ ] Complete game playthrough tests
- [ ] Multi-level progression tests
- [ ] Shop interaction tests
- [ ] Error recovery tests
- [ ] Performance tests
- [ ] Stress tests

**Implementation Steps**:
1. Create integration test scenarios:
   ```cairo
   #[cfg(test)]
   mod integration_tests {
       #[test]
       fn test_complete_game_playthrough() {
           // Start game
           // Pull orbs until level complete
           // Advance through all levels
           // Use shop system
           // Complete or fail game
           // Verify final state
       }
       
       #[test]
       fn test_shop_price_scaling() {
           // Start game
           // Complete level to earn cheddah
           // Purchase same orb multiple times
           // Verify price scaling
       }
       
       #[test]
       fn test_all_orb_effects() {
           // Test each orb type's effect
           // Verify stat changes
           // Test special orb mechanics
       }
   }
   ```

2. Implement complete game scenarios
3. Test error conditions and recovery
4. Add performance testing
5. Create stress tests for edge cases

**Dojo-Specific Notes**:
- Test with realistic game scenarios
- Validate world state consistency
- Test with multiple concurrent games
- Measure gas usage and optimization

---

## Phase 6: Deployment and Configuration

### Task 6.1: Configure Deployment Scripts
**Priority**: Medium  
**Estimated Time**: 1-2 hours  
**Prerequisites**: All testing complete

**Description**: Set up proper deployment scripts and configuration for different environments.

**Acceptance Criteria**:
- [ ] Scarb scripts for deployment
- [ ] Environment-specific configurations
- [ ] Permission setup scripts
- [ ] Migration scripts
- [ ] Deployment validation

**Implementation Steps**:
1. Update Scarb.toml with deployment scripts:
   ```toml
   [scripts]
   migrate = "sozo migrate"
   start = "sozo execute game_management start_game"
   pull = "sozo execute orb_drawing pull_orb --calldata $GAME_ID"
   ```

2. Configure dojo profile files:
   ```toml
   [world]
   name = "moon_bag"
   seed = "moon_bag"
   
   [namespace]
   default = "moon_bag"
   mapping = { "moon_bag" = "moon_bag" }
   ```

3. Set up permission configuration
4. Create deployment validation scripts
5. Document deployment process

**Dojo-Specific Notes**:
- Configure proper namespaces
- Set up correct permissions for systems
- Use environment-specific configurations
- Validate deployment with tests

---

### Task 6.2: Create Documentation
**Priority**: Low  
**Estimated Time**: 2-3 hours  
**Prerequisites**: Implementation complete

**Description**: Create comprehensive documentation for the smart contract backend.

**Acceptance Criteria**:
- [ ] API documentation for all systems
- [ ] Model schema documentation
- [ ] Deployment guide
- [ ] Game mechanics documentation
- [ ] Developer setup guide
- [ ] Troubleshooting guide

**Implementation Steps**:
1. Document all system functions
2. Create model schema documentation
3. Write deployment and setup guides
4. Document game mechanics and rules
5. Create troubleshooting guide
6. Add code examples and usage patterns

**Dojo-Specific Notes**:
- Include Dojo-specific patterns
- Document namespace and permission requirements
- Provide Cairo-specific examples
- Include gas optimization notes

---

## Development Guidelines

### Code Quality Standards
- Follow Cairo naming conventions
- Use proper error handling with descriptive messages
- Implement comprehensive unit tests
- Add inline documentation for complex functions
- Use proper trait derivations for all models
- Implement gas-optimized solutions

### Dojo Best Practices
- Keep models small and focused
- Use proper key structures for efficient queries
- Implement helper functions with `#[generate_trait]`
- Use appropriate visibility modifiers
- Follow ECS architecture principles
- Implement proper event emission

### Security Considerations
- Validate all user inputs
- Implement proper permission checks
- Use safe arithmetic operations
- Validate game state transitions
- Implement proper randomness
- Protect against reentrancy

### Testing Strategy
- Aim for 100% code coverage
- Test all edge cases and error conditions
- Include integration tests for complete scenarios
- Use property-based testing where applicable
- Test with realistic game data
- Validate gas usage and optimization

---

## Estimated Timeline

- **Phase 1**: 2-3 hours
- **Phase 2**: 12-15 hours  
- **Phase 3**: 15-18 hours
- **Phase 4**: 6-8 hours
- **Phase 5**: 12-15 hours
- **Phase 6**: 3-5 hours

**Total Estimated Time**: 50-64 hours

This timeline assumes a junior developer working part-time (4-6 hours per day), resulting in approximately 2-3 weeks of development time.

---

## Conclusion

This task breakdown provides a comprehensive roadmap for implementing the Moon Bag game backend using Cairo smart contracts with the Dojo framework. Each task is designed to be atomic and actionable, with clear acceptance criteria and implementation guidance.

The modular approach ensures that the system is maintainable, testable, and follows Dojo best practices. The extensive testing phase ensures reliability and correctness of the implementation.

For questions or clarifications on any task, refer to the Dojo documentation or seek guidance from experienced Dojo developers.