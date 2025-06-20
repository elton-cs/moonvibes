use starknet::ContractAddress;

// Define the interface
#[starknet::interface]
pub trait ILevelProgression<T> {
    fn check_level_complete(self: @T, player: ContractAddress, game_id: u64) -> bool;
    fn advance_level(ref self: T, game_id: u64);
    fn get_level_requirements(self: @T, level: u8) -> (u32, u32, u32); // points, cost, reward
    fn pay_level_cost(ref self: T, game_id: u64, level: u8);
}

// Dojo contract implementation
#[dojo::contract]
pub mod level_progression {
    use super::ILevelProgression;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    use dojo::world::{WorldStorage};
    
    // Import models and types
    use crate::models::game_state::{GameState, GameStatus};
    use crate::models::player_stats::{PlayerStats, PlayerStatsTrait};
    use crate::models::level_progress::{LevelProgress, LevelProgressTrait, get_level_config, is_valid_level, get_next_level, LevelConfig};
    use crate::models::shop::{Shop, ShopTrait};

    // Events for level progression
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct LevelAdvanced {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub from_level: u8,
        pub to_level: u8,
        pub cheddah_earned: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct LevelCostPaid {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub level: u8,
        pub moon_rocks_spent: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameCompleted {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub final_level: u8,
        pub final_score: u32,
    }

    #[abi(embed_v0)]
    impl LevelProgressionImpl of ILevelProgression<ContractState> {
        fn check_level_complete(self: @ContractState, player: ContractAddress, game_id: u64) -> bool {
            let world = self.world_default();
            let player_stats: PlayerStats = world.read_model((player, game_id));
            let level_progress: LevelProgress = world.read_model((player, game_id));
            
            // Check if current points meet the level requirement
            player_stats.points >= level_progress.points_required
        }

        fn advance_level(ref self: ContractState, game_id: u64) {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Validate level completion
            assert(self.check_level_complete(player, game_id), 'Level not complete');
            
            // Get current state
            let mut game_state: GameState = world.read_model((player, game_id));
            let mut player_stats: PlayerStats = world.read_model((player, game_id));
            let level_progress: LevelProgress = world.read_model((player, game_id));
            
            assert(game_state.status == GameStatus::LevelComplete, 'Game not in level complete');
            
            let from_level = game_state.current_level;
            
            // Award cheddah for completing the level
            let cheddah_earned = level_progress.cheddah_reward;
            player_stats.cheddah += cheddah_earned;
            
            // Reset multiplier to 1.0x between levels
            player_stats.multiplier = 100;
            
            // Check if this is the final level
            if game_state.current_level >= LevelConfig::MAX_LEVEL {
                // Game completed!
                game_state.status = GameStatus::Finished;
                
                // Convert remaining points to moon rocks (1:1 ratio)
                let moon_rocks_earned = player_stats.convert_points_to_moon_rocks();
                
                world.emit_event(@GameCompleted { 
                    player, 
                    game_id, 
                    final_level: game_state.current_level,
                    final_score: player_stats.points + moon_rocks_earned
                });
            } else {
                // Advance to next level
                let next_level = get_next_level(game_state.current_level);
                if let Option::Some(new_level) = next_level {
                    game_state.current_level = new_level;
                    game_state.status = GameStatus::InProgress;
                    
                    // Reset level counters
                    game_state.bombs_pulled_this_level = 0;
                    game_state.orbs_pulled_this_level = 0;
                    
                    // Create new level progress
                    let mut new_level_progress = level_progress;
                    new_level_progress.initialize_for_level(new_level);
                    world.write_model(@new_level_progress);
                    
                    // Clear shop for new level
                    let mut shop: Shop = world.read_model((player, game_id, new_level));
                    shop.clear_shop();
                    world.write_model(@shop);
                }
            }
            
            // Update last modified timestamp
            game_state.last_updated = get_block_timestamp();
            
            // Write updated models
            world.write_model(@game_state);
            world.write_model(@player_stats);
            
            // Emit level advancement event
            world.emit_event(@LevelAdvanced { 
                player, 
                game_id, 
                from_level,
                to_level: game_state.current_level,
                cheddah_earned
            });
        }

        fn get_level_requirements(self: @ContractState, level: u8) -> (u32, u32, u32) {
            // Validate level
            assert(is_valid_level(level), 'Invalid level');
            
            // Return (milestone_points, moon_rock_cost, cheddah_reward)
            get_level_config(level)
        }

        fn pay_level_cost(ref self: ContractState, game_id: u64, level: u8) {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Validate inputs
            assert(is_valid_level(level), 'Invalid level');
            
            // Get level cost
            let (_, level_cost, _) = get_level_config(level);
            
            // Get player stats and validate they can afford it
            let mut player_stats: PlayerStats = world.read_model((player, game_id));
            assert(player_stats.can_afford_moon_rocks(level_cost), 'Insufficient moon rocks');
            
            // Deduct the cost
            player_stats.spend_moon_rocks(level_cost);
            
            // Write updated stats
            world.write_model(@player_stats);
            
            // Emit payment event
            world.emit_event(@LevelCostPaid { 
                player, 
                game_id, 
                level,
                moon_rocks_spent: level_cost
            });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter"
        fn world_default(self: @ContractState) -> WorldStorage {
            self.world(@"dojo_starter")
        }
        
        /// Check if player can advance to the next level
        fn can_advance_to_level(
            self: @ContractState, 
            player: ContractAddress, 
            game_id: u64, 
            target_level: u8
        ) -> bool {
            let world = self.world_default();
            let game_state: GameState = world.read_model((player, game_id));
            let player_stats: PlayerStats = world.read_model((player, game_id));
            
            // Check if game is in correct state
            if game_state.status != GameStatus::LevelComplete {
                return false;
            }
            
            // Check if target level is the next level
            if target_level != game_state.current_level + 1 {
                return false;
            }
            
            // Check if target level is valid
            if !is_valid_level(target_level) {
                return false;
            }
            
            // Check if player can afford the level cost
            let (_, level_cost, _) = get_level_config(target_level);
            if !player_stats.can_afford_moon_rocks(level_cost) {
                return false;
            }
            
            true
        }
        
        /// Get current level status
        fn get_level_status(
            self: @ContractState, 
            player: ContractAddress, 
            game_id: u64
        ) -> (u8, u32, u32, u32, bool) {
            let world = self.world_default();
            let game_state: GameState = world.read_model((player, game_id));
            let player_stats: PlayerStats = world.read_model((player, game_id));
            let level_progress: LevelProgress = world.read_model((player, game_id));
            
            let current_level = game_state.current_level;
            let current_points = player_stats.points;
            let points_required = level_progress.points_required;
            let remaining_points = level_progress.get_remaining_points();
            let is_complete = level_progress.is_level_complete();
            
            (current_level, current_points, points_required, remaining_points, is_complete)
        }
    }
}