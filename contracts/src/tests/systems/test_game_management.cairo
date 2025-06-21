// ================================
// Game Management System Tests - Task 5.2
// Comprehensive unit tests for game management system with integration testing
// ================================

#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, contract_address_const};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef};
    
    use crate::models::game_state::{GameState, GameStatus, m_GameState};
    use crate::models::player_stats::{PlayerStats, m_PlayerStats};
    use crate::models::bag::{Bag, m_Bag};
    use crate::models::level_progress::{LevelProgress, m_LevelProgress};
    use crate::models::orb::OrbType;
    use crate::systems::game_management::{game_management, IGameManagementDispatcher, IGameManagementDispatcherTrait};

    // ================================
    // Test Setup Functions
    // ================================

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_GameState::TEST_CLASS_HASH),
                TestResource::Model(m_PlayerStats::TEST_CLASS_HASH),
                TestResource::Model(m_Bag::TEST_CLASS_HASH),
                TestResource::Model(m_LevelProgress::TEST_CLASS_HASH),
                TestResource::Contract(game_management::TEST_CLASS_HASH),
            ].span()
        }
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"dojo_starter", @"game_management")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span())
        ].span()
    }

    // ================================
    // Basic System Function Tests
    // ================================

    #[test]
    #[available_gas(5000000)]
    fn test_start_game_basic() {
        let player = contract_address_const::<0x123>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start a new game
        let game_id = game_system.start_game();

        // Verify game state was created correctly
        let game_state: GameState = world.read_model((player, game_id));
        assert(game_state.status == GameStatus::InProgress, 'Game not in progress');
        assert(game_state.current_level == 1, 'Wrong starting level');
        assert(game_state.bombs_pulled_this_level == 0, 'Wrong bomb count');
        assert(game_state.orbs_pulled_this_level == 0, 'Wrong orb count');

        // Verify player stats were initialized
        let player_stats: PlayerStats = world.read_model((player, game_id));
        assert(player_stats.health == 5, 'Wrong starting health');
        assert(player_stats.moon_rocks == 304, 'Wrong starting moon rocks');
        assert(player_stats.cheddah == 0, 'Wrong starting cheddah');
        assert(player_stats.points == 0, 'Wrong starting points');
        assert(player_stats.multiplier == 100, 'Wrong starting multiplier');

        // Verify bag was created with starting orbs
        let bag: Bag = world.read_model((player, game_id));
        assert(bag.total_orbs == 12, 'Wrong starting orb count');
        assert(bag.orbs.len() == 12, 'Wrong bag size');

        // Verify level progress was initialized
        let level_progress: LevelProgress = world.read_model((player, game_id));
        assert(level_progress.level == 1, 'Wrong progress level');
        assert(level_progress.points_required == 12, 'Wrong points required');
        assert(level_progress.cheddah_reward == 15, 'Wrong cheddah reward');
    }

    #[test]
    #[available_gas(3000000)]
    fn test_start_multiple_games() {
        let player = contract_address_const::<0x456>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start first game
        let game_id1 = game_system.start_game();
        
        // Start second game
        let game_id2 = game_system.start_game();

        // Verify games have different IDs
        assert(game_id1 != game_id2, 'Game IDs should differ');

        // Verify both games exist independently
        let game_state1: GameState = world.read_model((player, game_id1));
        let game_state2: GameState = world.read_model((player, game_id2));
        
        assert(game_state1.status == GameStatus::InProgress, 'Game1 not in progress');
        assert(game_state2.status == GameStatus::InProgress, 'Game2 not in progress');
        assert(game_state1.game_id == game_id1, 'Game1 ID mismatch');
        assert(game_state2.game_id == game_id2, 'Game2 ID mismatch');
    }

    #[test]
    #[available_gas(3000000)]
    fn test_quit_game() {
        let player = contract_address_const::<0x789>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start and then quit a game
        let game_id = game_system.start_game();
        game_system.quit_game(game_id);

        // Verify game state changed to GameOver
        let game_state: GameState = world.read_model((player, game_id));
        assert(game_state.status == GameStatus::GameOver, 'Game should be over');
        
        // Verify player gets points converted to moon rocks
        let player_stats: PlayerStats = world.read_model((player, game_id));
        // Since points start at 0, moon rocks should still be 304
        assert(player_stats.moon_rocks == 304, 'Moon rocks conversion failed');
        assert(player_stats.points == 0, 'Points should be reset');
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('Game not found',))]
    fn test_quit_nonexistent_game() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Try to quit a game that doesn't exist
        game_system.quit_game(999);
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('Game already finished',))]
    fn test_quit_already_finished_game() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start and quit a game
        let game_id = game_system.start_game();
        game_system.quit_game(game_id);
        
        // Try to quit again (should fail)
        game_system.quit_game(game_id);
    }

    #[test]
    #[available_gas(3000000)]
    fn test_reset_game() {
        let player = contract_address_const::<0xABC>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start a game and modify some state
        let game_id = game_system.start_game();
        
        // Manually modify game state to simulate progress
        let mut game_state: GameState = world.read_model((player, game_id));
        game_state.orbs_pulled_this_level = 5;
        game_state.bombs_pulled_this_level = 2;
        world.write_model_test(@game_state);

        let mut player_stats: PlayerStats = world.read_model((player, game_id));
        player_stats.points = 50;
        player_stats.health = 3;
        world.write_model_test(@player_stats);

        // Reset the game
        game_system.reset_game(game_id);

        // Verify game was reset to initial state
        let reset_game_state: GameState = world.read_model((player, game_id));
        assert(reset_game_state.status == GameStatus::InProgress, 'Game should be in progress');
        assert(reset_game_state.current_level == 1, 'Level should reset to 1');
        assert(reset_game_state.orbs_pulled_this_level == 0, 'Orbs pulled should reset');
        assert(reset_game_state.bombs_pulled_this_level == 0, 'Bombs pulled should reset');

        let reset_player_stats: PlayerStats = world.read_model((player, game_id));
        assert(reset_player_stats.health == 5, 'Health should reset');
        assert(reset_player_stats.points == 0, 'Points should reset');
        assert(reset_player_stats.moon_rocks == 304, 'Moon rocks should reset');
        assert(reset_player_stats.multiplier == 100, 'Multiplier should reset');

        let reset_bag: Bag = world.read_model((player, game_id));
        assert(reset_bag.total_orbs == 12, 'Bag should reset to 12 orbs');
    }

    // ================================
    // Game State Validation Tests
    // ================================

    #[test]
    #[available_gas(2000000)]
    fn test_get_game_info() {
        let player = contract_address_const::<0xDEF>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start a game
        let game_id = game_system.start_game();

        // Get game info
        let (status, level, health, points, moon_rocks, orbs_remaining) = game_system.get_game_info(game_id);

        assert(status == GameStatus::InProgress, 'Wrong status returned');
        assert(level == 1, 'Wrong level returned');
        assert(health == 5, 'Wrong health returned');
        assert(points == 0, 'Wrong points returned');
        assert(moon_rocks == 304, 'Wrong moon rocks returned');
        assert(orbs_remaining == 12, 'Wrong orbs remaining returned');
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('Game not found',))]
    fn test_get_info_nonexistent_game() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Try to get info for non-existent game
        let _info = game_system.get_game_info(999);
    }

    #[test]
    #[available_gas(3000000)]
    fn test_can_start_level() {
        let player = contract_address_const::<0x111>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start a game
        let game_id = game_system.start_game();

        // Should be able to start level 1 (already started)
        assert(game_system.can_start_level(game_id, 1), 'Should start level 1');

        // Should not be able to start level 2 without completing level 1
        assert(!game_system.can_start_level(game_id, 2), 'Should not start level 2');

        // Should not be able to start invalid levels
        assert(!game_system.can_start_level(game_id, 0), 'Should not start level 0');
        assert(!game_system.can_start_level(game_id, 8), 'Should not start level 8');
    }

    // ================================
    // Integration Tests with Other Systems
    // ================================

    #[test]
    #[available_gas(4000000)]
    fn test_game_state_consistency() {
        let player = contract_address_const::<0x222>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start multiple games and verify they don't interfere
        let game_id1 = game_system.start_game();
        let game_id2 = game_system.start_game();

        // Modify first game
        let mut game_state1: GameState = world.read_model((player, game_id1));
        game_state1.orbs_pulled_this_level = 3;
        world.write_model_test(@game_state1);

        // Verify second game is unaffected
        let game_state2: GameState = world.read_model((player, game_id2));
        assert(game_state2.orbs_pulled_this_level == 0, 'Game2 should be unaffected');

        // Verify first game maintains its state
        let updated_game_state1: GameState = world.read_model((player, game_id1));
        assert(updated_game_state1.orbs_pulled_this_level == 3, 'Game1 state should persist');
    }

    #[test]
    #[available_gas(4000000)]
    fn test_starting_bag_composition() {
        let player = contract_address_const::<0x333>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start a game
        let game_id = game_system.start_game();

        // Verify starting bag has correct composition
        let bag: Bag = world.read_model((player, game_id));
        assert(bag.total_orbs == 12, 'Should have 12 starting orbs');

        // Count specific orb types
        let orb_span = bag.orbs.span();
        let mut five_points_count = 0;
        let mut single_bomb_count = 0;
        let mut i = 0;
        
        while i < bag.orbs.len() {
            let orb = *orb_span.at(i);
            if orb == OrbType::FivePoints {
                five_points_count += 1;
            } else if orb == OrbType::SingleBomb {
                single_bomb_count += 1;
            }
            i += 1;
        };

        assert(five_points_count == 6, 'Should have 6 FivePoints orbs');
        assert(single_bomb_count == 2, 'Should have 2 SingleBomb orbs');
    }

    // ================================
    // Error Handling and Edge Cases
    // ================================

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('Game not found',))]
    fn test_reset_nonexistent_game() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Try to reset a game that doesn't exist
        game_system.reset_game(999);
    }

    #[test]
    #[available_gas(3000000)]
    fn test_game_id_generation() {
        let player = contract_address_const::<0x444>();
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Start multiple games and ensure unique IDs
        let mut game_ids = array![];
        let mut i = 0;
        
        while i < 5 {
            let game_id = game_system.start_game();
            game_ids.append(game_id);
            i += 1;
        };

        // Verify all IDs are unique
        let game_span = game_ids.span();
        let mut j = 0;
        
        while j < game_ids.len() {
            let mut k = j + 1;
            while k < game_ids.len() {
                assert(*game_span.at(j) != *game_span.at(k), 'Game IDs should be unique');
                k += 1;
            };
            j += 1;
        };
    }

    // ================================
    // Performance and Gas Tests
    // ================================

    #[test]
    #[available_gas(2000000)]
    fn test_start_game_gas_efficiency() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"game_management").unwrap();
        let game_system = IGameManagementDispatcher { contract_address };

        // Starting a game should complete within reasonable gas limits
        let _game_id = game_system.start_game();
        // If we reach this point, the gas limit was sufficient
        assert(true, 'Game started within gas limit');
    }
}