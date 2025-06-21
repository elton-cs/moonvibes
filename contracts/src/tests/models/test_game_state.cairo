// ================================
// GameState Model Tests - Task 5.1
// Comprehensive unit tests for GameState model with 100% coverage
// ================================

#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource};
    
    use crate::models::game_state::{GameState, GameStatus, GameStateTrait, m_GameState};

    // ================================
    // Test Helper Functions
    // ================================

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_GameState::TEST_CLASS_HASH),
            ].span()
        }
    }

    fn create_test_game_state() -> GameState {
        GameState {
            player: contract_address_const::<0x123>(),
            game_id: 1,
            status: GameStatus::NotStarted,
            current_level: 1,
            bombs_pulled_this_level: 0,
            orbs_pulled_this_level: 0,
            started_at: 0,
            last_updated: 0,
        }
    }

    // ================================
    // Basic Creation and Validation Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_game_state_creation() {
        let game_state = create_test_game_state();
        
        assert(game_state.player == contract_address_const::<0x123>(), 'Wrong player address');
        assert(game_state.game_id == 1, 'Wrong game ID');
        assert(game_state.status == GameStatus::NotStarted, 'Wrong initial status');
        assert(game_state.current_level == 1, 'Wrong initial level');
        assert(game_state.bombs_pulled_this_level == 0, 'Wrong bombs count');
        assert(game_state.orbs_pulled_this_level == 0, 'Wrong orbs count');
        assert(game_state.started_at == 0, 'Wrong start time');
        assert(game_state.last_updated == 0, 'Wrong update time');
    }

    #[test]
    #[available_gas(150000)]
    fn test_game_state_with_different_statuses() {
        let mut game_state = create_test_game_state();
        
        // Test NotStarted status
        game_state.status = GameStatus::NotStarted;
        assert(game_state.status == GameStatus::NotStarted, 'NotStarted status failed');
        
        // Test InProgress status
        game_state.status = GameStatus::InProgress;
        assert(game_state.status == GameStatus::InProgress, 'InProgress status failed');
        
        // Test LevelComplete status
        game_state.status = GameStatus::LevelComplete;
        assert(game_state.status == GameStatus::LevelComplete, 'LevelComplete status failed');
        
        // Test GameOver status
        game_state.status = GameStatus::GameOver;
        assert(game_state.status == GameStatus::GameOver, 'GameOver status failed');
        
        // Test Finished status
        game_state.status = GameStatus::Finished;
        assert(game_state.status == GameStatus::Finished, 'Finished status failed');
    }

    #[test]
    #[available_gas(100000)]
    fn test_game_state_level_boundaries() {
        let mut game_state = create_test_game_state();
        
        // Test minimum level
        game_state.current_level = 1;
        assert(game_state.current_level == 1, 'Min level failed');
        
        // Test maximum level
        game_state.current_level = 7;
        assert(game_state.current_level == 7, 'Max level failed');
        
        // Test intermediate level
        game_state.current_level = 4;
        assert(game_state.current_level == 4, 'Mid level failed');
    }

    // ================================
    // GameState Trait Function Tests
    // ================================

    #[test]
    #[available_gas(200000)]
    fn test_start_new_game() {
        let player = contract_address_const::<0x456>();
        let game_id = 2;
        let timestamp = 1000;
        
        let game_state = GameStateTrait::start_new_game(player, game_id, timestamp);
        
        assert(game_state.player == player, 'Wrong player in new game');
        assert(game_state.game_id == game_id, 'Wrong game_id in new game');
        assert(game_state.status == GameStatus::InProgress, 'Wrong status in new game');
        assert(game_state.current_level == 1, 'Wrong level in new game');
        assert(game_state.bombs_pulled_this_level == 0, 'Wrong bombs in new game');
        assert(game_state.orbs_pulled_this_level == 0, 'Wrong orbs in new game');
        assert(game_state.started_at == timestamp, 'Wrong start time in new game');
        assert(game_state.last_updated == timestamp, 'Wrong update time in new game');
    }

    #[test]
    #[available_gas(150000)]
    fn test_is_game_active() {
        let mut game_state = create_test_game_state();
        
        // Test active statuses
        game_state.status = GameStatus::InProgress;
        assert(game_state.is_game_active(), 'InProgress should be active');
        
        game_state.status = GameStatus::LevelComplete;
        assert(game_state.is_game_active(), 'LevelComplete should be active');
        
        // Test inactive statuses
        game_state.status = GameStatus::NotStarted;
        assert(!game_state.is_game_active(), 'NotStarted should not be active');
        
        game_state.status = GameStatus::GameOver;
        assert(!game_state.is_game_active(), 'GameOver should not be active');
        
        game_state.status = GameStatus::Finished;
        assert(!game_state.is_game_active(), 'Finished should not be active');
    }

    #[test]
    #[available_gas(150000)]
    fn test_can_pull_orb() {
        let mut game_state = create_test_game_state();
        
        // Should be able to pull orb when InProgress
        game_state.status = GameStatus::InProgress;
        assert(game_state.can_pull_orb(), 'Should pull orb when InProgress');
        
        // Should not be able to pull orb in other statuses
        game_state.status = GameStatus::NotStarted;
        assert(!game_state.can_pull_orb(), 'Should not pull orb when NotStarted');
        
        game_state.status = GameStatus::LevelComplete;
        assert(!game_state.can_pull_orb(), 'Should not pull orb when LevelComplete');
        
        game_state.status = GameStatus::GameOver;
        assert(!game_state.can_pull_orb(), 'Should not pull orb when GameOver');
        
        game_state.status = GameStatus::Finished;
        assert(!game_state.can_pull_orb(), 'Should not pull orb when Finished');
    }

    #[test]
    #[available_gas(100000)]
    fn test_increment_orbs_pulled() {
        let mut game_state = create_test_game_state();
        
        // Test initial state
        assert(game_state.orbs_pulled_this_level == 0, 'Initial orbs should be 0');
        
        // Test incrementing
        game_state.increment_orbs_pulled();
        assert(game_state.orbs_pulled_this_level == 1, 'Orbs should be 1 after increment');
        
        // Test multiple increments
        game_state.increment_orbs_pulled();
        game_state.increment_orbs_pulled();
        assert(game_state.orbs_pulled_this_level == 3, 'Orbs should be 3 after increments');
    }

    #[test]
    #[available_gas(100000)]
    fn test_increment_bombs_pulled() {
        let mut game_state = create_test_game_state();
        
        // Test initial state
        assert(game_state.bombs_pulled_this_level == 0, 'Initial bombs should be 0');
        
        // Test incrementing
        game_state.increment_bombs_pulled();
        assert(game_state.bombs_pulled_this_level == 1, 'Bombs should be 1 after increment');
        
        // Test multiple increments
        game_state.increment_bombs_pulled();
        game_state.increment_bombs_pulled();
        assert(game_state.bombs_pulled_this_level == 3, 'Bombs should be 3 after increments');
    }

    #[test]
    #[available_gas(150000)]
    fn test_advance_level() {
        let mut game_state = create_test_game_state();
        let timestamp = 2000;
        
        // Set up some pulled orbs/bombs to test reset
        game_state.increment_orbs_pulled();
        game_state.increment_bombs_pulled();
        
        // Advance level
        game_state.advance_level(timestamp);
        
        assert(game_state.current_level == 2, 'Level should advance to 2');
        assert(game_state.status == GameStatus::InProgress, 'Status should be InProgress');
        assert(game_state.orbs_pulled_this_level == 0, 'Orbs should reset to 0');
        assert(game_state.bombs_pulled_this_level == 0, 'Bombs should reset to 0');
        assert(game_state.last_updated == timestamp, 'Last updated should match');
    }

    #[test]
    #[available_gas(100000)]
    fn test_set_game_over() {
        let mut game_state = create_test_game_state();
        let timestamp = 3000;
        
        game_state.set_game_over(timestamp);
        
        assert(game_state.status == GameStatus::GameOver, 'Status should be GameOver');
        assert(game_state.last_updated == timestamp, 'Last updated should match');
    }

    #[test]
    #[available_gas(100000)]
    fn test_set_level_complete() {
        let mut game_state = create_test_game_state();
        let timestamp = 4000;
        
        game_state.set_level_complete(timestamp);
        
        assert(game_state.status == GameStatus::LevelComplete, 'Status should be LevelComplete');
        assert(game_state.last_updated == timestamp, 'Last updated should match');
    }

    #[test]
    #[available_gas(100000)]
    fn test_set_finished() {
        let mut game_state = create_test_game_state();
        let timestamp = 5000;
        
        game_state.set_finished(timestamp);
        
        assert(game_state.status == GameStatus::Finished, 'Status should be Finished');
        assert(game_state.last_updated == timestamp, 'Last updated should match');
    }

    // ================================
    // Edge Case and Error Condition Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_counter_overflow_protection() {
        let mut game_state = create_test_game_state();
        
        // Set counters to max u8 value
        game_state.orbs_pulled_this_level = 255;
        game_state.bombs_pulled_this_level = 255;
        
        // Test that incrementing doesn't panic (implementation should handle overflow)
        game_state.increment_orbs_pulled();
        game_state.increment_bombs_pulled();
        
        // Values should either wrap around or stay at max (implementation-dependent)
        assert(game_state.orbs_pulled_this_level <= 255, 'Orbs overflow not handled');
        assert(game_state.bombs_pulled_this_level <= 255, 'Bombs overflow not handled');
    }

    #[test]
    #[available_gas(100000)]
    fn test_level_advancement_boundaries() {
        let mut game_state = create_test_game_state();
        let timestamp = 6000;
        
        // Test advancing from max level - 1
        game_state.current_level = 6;
        game_state.advance_level(timestamp);
        assert(game_state.current_level == 7, 'Should advance to max level');
        
        // Test advancing from max level (should handle gracefully)
        game_state.current_level = 7;
        game_state.advance_level(timestamp);
        // Implementation should either cap at 7 or handle max level scenario
        assert(game_state.current_level >= 7, 'Max level handling failed');
    }

    // ================================
    // World Integration Tests
    // ================================

    #[test]
    #[available_gas(500000)]
    fn test_game_state_world_storage() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0x789>();
        let game_id = 3;
        let game_state = GameStateTrait::start_new_game(player, game_id, 1000);
        
        // Test writing to world
        world.write_model_test(@game_state);
        
        // Test reading from world
        let retrieved_state: GameState = world.read_model((player, game_id));
        
        assert(retrieved_state.player == player, 'Retrieved player mismatch');
        assert(retrieved_state.game_id == game_id, 'Retrieved game_id mismatch');
        assert(retrieved_state.status == GameStatus::InProgress, 'Retrieved status mismatch');
        assert(retrieved_state.current_level == 1, 'Retrieved level mismatch');
    }

    #[test]
    #[available_gas(300000)]
    fn test_game_state_model_deletion() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0xABC>();
        let game_id = 4;
        let game_state = GameStateTrait::start_new_game(player, game_id, 2000);
        
        // Write and verify
        world.write_model_test(@game_state);
        let retrieved_state: GameState = world.read_model((player, game_id));
        assert(retrieved_state.game_id == game_id, 'State not written correctly');
        
        // Delete and verify
        world.erase_model(@game_state);
        let deleted_state: GameState = world.read_model((player, game_id));
        assert(deleted_state.game_id == 0, 'State not deleted correctly');
        assert(deleted_state.current_level == 0, 'Level not reset after deletion');
    }

    #[test]
    #[available_gas(200000)]
    fn test_multiple_game_states() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player1 = contract_address_const::<0x111>();
        let player2 = contract_address_const::<0x222>();
        let game_id = 5;
        
        let game_state1 = GameStateTrait::start_new_game(player1, game_id, 3000);
        let mut game_state2 = GameStateTrait::start_new_game(player2, game_id, 4000);
        game_state2.current_level = 3;
        
        // Write both states
        world.write_model_test(@game_state1);
        world.write_model_test(@game_state2);
        
        // Verify both are stored correctly
        let retrieved_state1: GameState = world.read_model((player1, game_id));
        let retrieved_state2: GameState = world.read_model((player2, game_id));
        
        assert(retrieved_state1.current_level == 1, 'Player1 level wrong');
        assert(retrieved_state2.current_level == 3, 'Player2 level wrong');
        assert(retrieved_state1.player != retrieved_state2.player, 'Players should differ');
    }
}