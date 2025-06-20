use starknet::ContractAddress;
use crate::models::orb::OrbType;

// Define the interface
#[starknet::interface]
pub trait IOrbDrawing<T> {
    fn pull_orb(ref self: T, game_id: u64) -> OrbType;
    fn get_bag_contents(self: @T, player: ContractAddress, game_id: u64) -> Array<OrbType>;
}

// Dojo contract implementation
#[dojo::contract]
pub mod orb_drawing {
    use super::IOrbDrawing;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    use dojo::world::{WorldStorage};
    
    // Import models and types
    use crate::models::orb::OrbType;
    use crate::models::game_state::{GameState, GameStatus};
    use crate::models::player_stats::{PlayerStats, PlayerStatsTrait};
    use crate::models::bag::{Bag, BagTrait};
    use crate::models::level_progress::{LevelProgress, LevelProgressTrait};

    // Events for orb drawing
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct OrbPulled {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub orb_type: OrbType,
        pub orb_number: u32,
        pub points_gained: u32,
        pub health_change: i8,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct LevelComplete {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub level: u8,
        pub cheddah_earned: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameOver {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub final_score: u32,
        pub reason: felt252, // 'health_zero' or 'bag_empty'
    }

    #[abi(embed_v0)]
    impl OrbDrawingImpl of IOrbDrawing<ContractState> {
        fn pull_orb(ref self: ContractState, game_id: u64) -> OrbType {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Validate game state
            let mut game_state: GameState = world.read_model((player, game_id));
            assert(game_state.status == GameStatus::InProgress, 'Game not in progress');
            
            // Get bag and validate it's not empty
            let mut bag: Bag = world.read_model((player, game_id));
            assert(!bag.is_empty(), 'Bag is empty');
            
            // Draw random orb using block timestamp as seed
            let seed = get_block_timestamp().into();
            let drawn_orb = bag.draw_random_orb(seed);
            
            // Get current player stats and level progress
            let mut player_stats: PlayerStats = world.read_model((player, game_id));
            let mut level_progress: LevelProgress = world.read_model((player, game_id));
            
            // Apply orb effects
            let (points_gained, health_change) = self.apply_orb_effects(
                ref player_stats, 
                @game_state, 
                @bag, 
                drawn_orb
            );
            
            // Update counters
            game_state.orbs_pulled_this_level += 1;
            if self.is_bomb_orb(drawn_orb) {
                game_state.bombs_pulled_this_level += 1;
            }
            game_state.last_updated = get_block_timestamp();
            
            // Record orb in level progress
            level_progress.record_orb_pull(drawn_orb);
            level_progress.add_points(points_gained);
            
            // Check for level completion
            if level_progress.is_level_complete() {
                self.handle_level_complete(ref game_state, ref player_stats, @level_progress);
                world.emit_event(@LevelComplete { 
                    player, 
                    game_id, 
                    level: game_state.current_level,
                    cheddah_earned: level_progress.cheddah_reward 
                });
            }
            
            // Check for game over conditions
            if player_stats.health == 0 {
                game_state.status = GameStatus::GameOver;
                world.emit_event(@GameOver { 
                    player, 
                    game_id, 
                    final_score: player_stats.points,
                    reason: 'health_zero'
                });
            } else if bag.is_empty() {
                game_state.status = GameStatus::GameOver;
                world.emit_event(@GameOver { 
                    player, 
                    game_id, 
                    final_score: player_stats.points,
                    reason: 'bag_empty'
                });
            }
            
            // Write updated models to world
            world.write_model(@bag);
            world.write_model(@player_stats);
            world.write_model(@game_state);
            world.write_model(@level_progress);
            
            // Emit orb pulled event
            world.emit_event(@OrbPulled { 
                player, 
                game_id, 
                orb_type: drawn_orb,
                orb_number: game_state.orbs_pulled_this_level.into(),
                points_gained,
                health_change
            });
            
            drawn_orb
        }

        fn get_bag_contents(self: @ContractState, player: ContractAddress, game_id: u64) -> Array<OrbType> {
            let world = self.world_default();
            let bag: Bag = world.read_model((player, game_id));
            bag.get_all_orb_types()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter"
        fn world_default(self: @ContractState) -> WorldStorage {
            self.world(@"dojo_starter")
        }
        
        /// Apply effects for all 25 orb types
        fn apply_orb_effects(
            self: @ContractState,
            ref player_stats: PlayerStats,
            game_state: @GameState,
            bag: @Bag,
            orb_type: OrbType
        ) -> (u32, i8) {
            let mut points_gained: u32 = 0;
            let mut health_change: i8 = 0;
            
            match orb_type {
                // Starting Orbs - Points
                OrbType::FivePoints => {
                    points_gained = self.apply_multiplier(5, player_stats.multiplier);
                    player_stats.points += points_gained;
                },
                
                // Starting Orbs - Bombs
                OrbType::SingleBomb => {
                    health_change = -1;
                    player_stats.apply_health_change(-1);
                },
                OrbType::DoubleBomb => {
                    health_change = -2;
                    player_stats.apply_health_change(-2);
                },
                OrbType::TripleBomb => {
                    health_change = -3;
                    player_stats.apply_health_change(-3);
                },
                
                // Starting Orbs - Multipliers
                OrbType::DoubleMultiplier => {
                    player_stats.multiplier = (player_stats.multiplier * 200) / 100; // 2.0x
                },
                
                // Starting Orbs - Special
                OrbType::RemainingOrbs => {
                    let remaining_count = *bag.total_orbs;
                    points_gained = self.apply_multiplier(remaining_count, player_stats.multiplier);
                    player_stats.points += points_gained;
                },
                OrbType::BombCounter => {
                    let bomb_count: u32 = (*game_state.bombs_pulled_this_level).into();
                    points_gained = self.apply_multiplier(bomb_count, player_stats.multiplier);
                    player_stats.points += points_gained;
                },
                OrbType::Health => {
                    health_change = 1;
                    player_stats.apply_health_change(1);
                },
                
                // Shop Orbs - Common Points
                OrbType::SevenPoints => {
                    points_gained = self.apply_multiplier(7, player_stats.multiplier);
                    player_stats.points += points_gained;
                },
                
                // Shop Orbs - Common Special
                OrbType::CheddahBomb => {
                    health_change = -1;
                    player_stats.apply_health_change(-1);
                    player_stats.cheddah += 10; // Gives cheddah despite being a bomb
                },
                OrbType::MoonRock => {
                    player_stats.moon_rocks += 2;
                },
                OrbType::HalfMultiplier => {
                    player_stats.multiplier = (player_stats.multiplier * 50) / 100; // 0.5x
                },
                
                // Shop Orbs - Rare Points
                OrbType::EightPoints => {
                    points_gained = self.apply_multiplier(8, player_stats.multiplier);
                    player_stats.points += points_gained;
                },
                OrbType::NinePoints => {
                    points_gained = self.apply_multiplier(9, player_stats.multiplier);
                    player_stats.points += points_gained;
                },
                
                // Shop Orbs - Rare Special
                OrbType::NextPoints2x => {
                    // This would require special state tracking for next orb only
                    // For now, apply immediate 2x multiplier effect
                    player_stats.multiplier = (player_stats.multiplier * 200) / 100; // 2.0x
                },
                OrbType::Multiplier1_5x => {
                    player_stats.multiplier = (player_stats.multiplier * 150) / 100; // 1.5x
                },
                
                // Shop Orbs - Cosmic
                OrbType::BigHealth => {
                    health_change = 3;
                    player_stats.apply_health_change(3);
                },
                OrbType::BigMoonRock => {
                    player_stats.moon_rocks += 10;
                },
            }
            
            (points_gained, health_change)
        }
        
        /// Apply multiplier calculation with rounding up
        fn apply_multiplier(self: @ContractState, base_points: u32, multiplier: u32) -> u32 {
            // Always round up: (base_points * multiplier + 99) / 100
            (base_points * multiplier + 99) / 100
        }
        
        /// Check if orb is a bomb type
        fn is_bomb_orb(self: @ContractState, orb_type: OrbType) -> bool {
            match orb_type {
                OrbType::SingleBomb | OrbType::DoubleBomb | OrbType::TripleBomb | OrbType::CheddahBomb => true,
                _ => false,
            }
        }
        
        /// Handle level completion logic
        fn handle_level_complete(
            self: @ContractState,
            ref game_state: GameState,
            ref player_stats: PlayerStats,
            level_progress: @LevelProgress
        ) {
            // Award cheddah
            player_stats.cheddah += *level_progress.cheddah_reward;
            
            // Reset multiplier to 1.0x between levels
            player_stats.multiplier = 100;
            
            // Advance level
            game_state.current_level += 1;
            game_state.status = GameStatus::LevelComplete;
        }
    }
}