// Define the interface
#[starknet::interface]
pub trait IGameManagement<T> {
    fn start_game(ref self: T) -> u64; // Returns game_id
    fn quit_game(ref self: T, game_id: u64);
    fn reset_game(ref self: T, game_id: u64);
}

// Dojo contract implementation
#[dojo::contract]
pub mod game_management {
    use super::IGameManagement;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    use dojo::world::{WorldStorage};
    
    // Import models from our project
    use crate::models::game_state::{GameState, GameStatus};
    use crate::models::player_stats::PlayerStats;
    use crate::models::bag::{Bag, create_starting_bag};
    use crate::models::level_progress::{LevelProgress, get_level_config};
    use crate::models::shop::Shop;

    // Events for game management
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameStarted {
        #[key]
        pub player: ContractAddress,
        #[key] 
        pub game_id: u64,
        pub started_at: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameQuit {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub final_score: u32,
        pub moon_rocks_earned: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameReset {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub reset_at: u64,
    }

    #[abi(embed_v0)]
    impl GameManagementImpl of IGameManagement<ContractState> {
        fn start_game(ref self: ContractState) -> u64 {
            let mut world = self.world_default();
            let player = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Generate unique game ID using timestamp and player address
            let player_felt: felt252 = player.into();
            let game_id: u64 = (current_time + player_felt.try_into().unwrap_or(0)).try_into().unwrap();
            
            // Initialize GameState
            let game_state = GameState {
                player,
                game_id,
                status: GameStatus::InProgress,
                current_level: 1,
                bombs_pulled_this_level: 0,
                orbs_pulled_this_level: 0,
                started_at: current_time,
                last_updated: current_time,
            };
            
            // Initialize PlayerStats with starting values from PRD
            let player_stats = PlayerStats {
                player,
                game_id,
                health: 5,
                points: 0,
                multiplier: 100, // 1.0x stored as 100
                cheddah: 0,
                moon_rocks: 304, // Starting amount
                badges: 0,
            };
            
            // Initialize starting bag with 12 orbs
            let starting_orbs = create_starting_bag();
            let bag = Bag {
                player,
                game_id,
                orbs: starting_orbs,
                total_orbs: 12, // STARTING_BAG_SIZE constant value
            };
            
            // Initialize level progress for level 1
            let (points_required, level_cost, cheddah_reward) = get_level_config(1);
            let level_progress = LevelProgress {
                player,
                game_id,
                current_level: 1,
                points_required,
                points_earned: 0,
                level_cost,
                cheddah_reward,
                orbs_pulled_this_level: array![],
            };
            
            // Initialize empty shop for level 1
            let shop = Shop {
                player,
                game_id,
                level: 1,
                available_orbs: array![],
                orb_prices: array![],
                shop_generated: false,
            };
            
            // Write all models to world
            world.write_model(@game_state);
            world.write_model(@player_stats);
            world.write_model(@bag);
            world.write_model(@level_progress);
            world.write_model(@shop);
            
            // Emit game started event
            world.emit_event(@GameStarted { 
                player, 
                game_id, 
                started_at: current_time 
            });
            
            game_id
        }

        fn quit_game(ref self: ContractState, game_id: u64) {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Validate game exists and player owns it
            let mut game_state: GameState = world.read_model((player, game_id));
            assert(game_state.status == GameStatus::InProgress, 'Game not in progress');
            
            // Get player stats for final calculations
            let player_stats: PlayerStats = world.read_model((player, game_id));
            
            // Calculate final rewards - convert points to moon rocks 1:1
            let moon_rocks_earned = player_stats.points;
            let final_score = player_stats.points;
            
            // Update game status to finished
            game_state.status = GameStatus::Finished;
            game_state.last_updated = get_block_timestamp();
            world.write_model(@game_state);
            
            // Emit game quit event
            world.emit_event(@GameQuit { 
                player, 
                game_id, 
                final_score,
                moon_rocks_earned 
            });
        }

        fn reset_game(ref self: ContractState, game_id: u64) {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Validate game exists and player owns it
            let game_state: GameState = world.read_model((player, game_id));
            assert(game_state.player == player, 'Not your game');
            
            // Reset all game models by erasing them (sets to default values)
            world.erase_model(@game_state);
            
            let player_stats: PlayerStats = world.read_model((player, game_id));
            world.erase_model(@player_stats);
            
            let bag: Bag = world.read_model((player, game_id));
            world.erase_model(@bag);
            
            let level_progress: LevelProgress = world.read_model((player, game_id));
            world.erase_model(@level_progress);
            
            let shop: Shop = world.read_model((player, game_id, 1));
            world.erase_model(@shop);
            
            // Emit game reset event
            world.emit_event(@GameReset { player, game_id, reset_at: get_block_timestamp() });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}