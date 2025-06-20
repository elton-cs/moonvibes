// Define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn start_game(ref self: T);
    fn pull_orb(ref self: T);
}

// Dojo contract
#[dojo::contract]
pub mod actions {
    use super::{IActions};
    use starknet::{ContractAddress, get_caller_address, get_block_info};
    use dojo_starter::models::{
        GameState, PlayerStats, Bag, LevelProgress,
        get_level_config, STARTING_HEALTH, STARTING_MOON_ROCKS, 
        STARTING_CHEDDAH, STARTING_POINTS, BASE_MULTIPLIER
    };
    use dojo_starter::helpers::orb_effects::{apply_orb_effect};
    use dojo_starter::helpers::bag_management::{initialize_starting_bag, draw_random_orb};
    use dojo_starter::helpers::game_progression::{
        check_level_complete, check_game_over, calculate_cheddah_reward
    };

    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameStarted {
        #[key]
        pub player: ContractAddress,
        pub level: u8,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct OrbPulled {
        #[key]
        pub player: ContractAddress,
        pub orb_type: felt252, // Store as felt252 for event
        pub remaining_orbs: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct LevelComplete {
        #[key]
        pub player: ContractAddress,
        pub level: u8,
        pub points: u32,
        pub cheddah_earned: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameOver {
        #[key]
        pub player: ContractAddress,
        pub final_level: u8,
        pub final_points: u32,
        pub moon_rocks_earned: u32,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn start_game(ref self: ContractState) {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Read current player stats
            let mut stats: PlayerStats = world.read_model(player);
            
            // Get level 1 config
            let (_, moon_rock_cost) = get_level_config(1);
            
            // Check if player has enough moon rocks
            if stats.moon_rocks == 0 {
                // First time player, give starting resources
                stats.moon_rocks = STARTING_MOON_ROCKS;
            }
            
            assert(stats.moon_rocks >= moon_rock_cost, 'Not enough moon rocks');
            
            // Initialize game state
            let game_state = GameState {
                player,
                is_active: true,
                current_level: 1,
                bombs_pulled: 0,
            };
            
            // Initialize player stats for new game
            stats.moon_rocks -= moon_rock_cost;
            stats.health = STARTING_HEALTH;
            stats.points = STARTING_POINTS;
            stats.multiplier = BASE_MULTIPLIER;
            stats.cheddah = STARTING_CHEDDAH;
            
            // Initialize bag with starting orbs
            let bag = Bag {
                player,
                orb_ids: initialize_starting_bag(),
            };
            
            // Clear level progress
            let level_progress = LevelProgress {
                player,
                orbs_pulled: array![],
            };
            
            // Write all models
            world.write_model(@game_state);
            world.write_model(@stats);
            world.write_model(@bag);
            world.write_model(@level_progress);
            
            // Emit event
            world.emit_event(@GameStarted { player, level: 1 });
        }
        
        fn pull_orb(ref self: ContractState) {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Read current state
            let mut game_state: GameState = world.read_model(player);
            let mut stats: PlayerStats = world.read_model(player);
            let mut bag: Bag = world.read_model(player);
            let mut level_progress: LevelProgress = world.read_model(player);
            
            // Verify game is active
            assert(game_state.is_active, 'Game not active');
            assert(bag.orb_ids.len() > 0, 'Bag is empty');
            
            // Get random seed from block info
            let block_info = get_block_info().unbox();
            let random_seed = block_info.block_timestamp.into();
            
            // Draw random orb
            let (orb_type, updated_bag) = draw_random_orb(bag, random_seed);
            bag = updated_bag;
            
            // Apply orb effects
            let (updated_stats, updated_game_state) = apply_orb_effect(
                orb_type, stats, game_state, @bag
            );
            stats = updated_stats;
            game_state = updated_game_state;
            
            // Add to pulled orbs history
            level_progress.orbs_pulled.append(orb_type);
            
            // Write updated models
            world.write_model(@stats);
            world.write_model(@game_state);
            world.write_model(@bag);
            world.write_model(@level_progress);
            
            // Emit orb pulled event
            world.emit_event(@OrbPulled { 
                player, 
                orb_type: orb_type.into(),
                remaining_orbs: bag.orb_ids.len(),
            });
            
            // Check game end conditions
            if check_game_over(stats.health, bag.orb_ids.len()) {
                // Game over
                game_state.is_active = false;
                
                // Convert points to moon rocks (1:1)
                stats.moon_rocks += stats.points;
                
                world.write_model(@game_state);
                world.write_model(@stats);
                
                world.emit_event(@GameOver {
                    player,
                    final_level: game_state.current_level,
                    final_points: stats.points,
                    moon_rocks_earned: stats.points,
                });
            } else if check_level_complete(stats.points, game_state.current_level) {
                // Level complete
                let cheddah_reward = calculate_cheddah_reward(game_state.current_level);
                stats.cheddah += cheddah_reward;
                
                world.emit_event(@LevelComplete {
                    player,
                    level: game_state.current_level,
                    points: stats.points,
                    cheddah_earned: cheddah_reward,
                });
                
                // Advance to next level
                game_state.current_level += 1;
                
                // Reset multiplier for new level
                stats.multiplier = BASE_MULTIPLIER;
                
                // Clear pulled orbs for new level
                level_progress.orbs_pulled = array![];
                
                // Check if there's a next level
                let (next_milestone, _) = get_level_config(game_state.current_level);
                if next_milestone == 999999 {
                    // No more levels, end game
                    game_state.is_active = false;
                    stats.moon_rocks += stats.points;
                    
                    world.emit_event(@GameOver {
                        player,
                        final_level: game_state.current_level - 1,
                        final_points: stats.points,
                        moon_rocks_earned: stats.points,
                    });
                }
                
                world.write_model(@game_state);
                world.write_model(@stats);
                world.write_model(@level_progress);
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}