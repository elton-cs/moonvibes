// ================================
// LevelProgress Model Tests - Task 5.1
// Comprehensive unit tests for LevelProgress model with level configuration
// ================================

#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, contract_address_const};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource};
    
    use crate::models::level_progress::{
        LevelProgress, LevelProgressTrait, LevelConfig, 
        get_level_config, is_valid_level, get_next_level,
        m_LevelProgress
    };
    use crate::models::orb::OrbType;

    // ================================
    // Test Helper Functions
    // ================================

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_LevelProgress::TEST_CLASS_HASH),
            ].span()
        }
    }

    fn create_test_level_progress() -> LevelProgress {
        LevelProgress {
            player: contract_address_const::<0x123>(),
            game_id: 1,
            level: 1,
            points_required: 12,
            cheddah_reward: 15,
            orbs_pulled: array![],
        }
    }

    // ================================
    // Level Configuration Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_level_config_all_levels() {
        // Test all 7 levels have correct configuration
        let (points1, cost1, reward1) = get_level_config(1);
        assert(points1 == 12, 'Level 1 points wrong');
        assert(cost1 == 5, 'Level 1 cost wrong');
        assert(reward1 == 15, 'Level 1 reward wrong');
        
        let (points2, cost2, reward2) = get_level_config(2);
        assert(points2 == 18, 'Level 2 points wrong');
        assert(cost2 == 6, 'Level 2 cost wrong');
        assert(reward2 == 20, 'Level 2 reward wrong');
        
        let (points3, cost3, reward3) = get_level_config(3);
        assert(points3 == 28, 'Level 3 points wrong');
        assert(cost3 == 8, 'Level 3 cost wrong');
        assert(reward3 == 30, 'Level 3 reward wrong');
        
        let (points4, cost4, reward4) = get_level_config(4);
        assert(points4 == 44, 'Level 4 points wrong');
        assert(cost4 == 10, 'Level 4 cost wrong');
        assert(reward4 == 40, 'Level 4 reward wrong');
        
        let (points5, cost5, reward5) = get_level_config(5);
        assert(points5 == 66, 'Level 5 points wrong');
        assert(cost5 == 12, 'Level 5 cost wrong');
        assert(reward5 == 55, 'Level 5 reward wrong');
        
        let (points6, cost6, reward6) = get_level_config(6);
        assert(points6 == 94, 'Level 6 points wrong');
        assert(cost6 == 16, 'Level 6 cost wrong');
        assert(reward6 == 75, 'Level 6 reward wrong');
        
        let (points7, cost7, reward7) = get_level_config(7);
        assert(points7 == 130, 'Level 7 points wrong');
        assert(cost7 == 20, 'Level 7 cost wrong');
        assert(reward7 == 100, 'Level 7 reward wrong');
    }

    #[test]
    #[available_gas(100000)]
    fn test_is_valid_level() {
        // Test valid levels
        assert(is_valid_level(1), 'Level 1 should be valid');
        assert(is_valid_level(2), 'Level 2 should be valid');
        assert(is_valid_level(3), 'Level 3 should be valid');
        assert(is_valid_level(4), 'Level 4 should be valid');
        assert(is_valid_level(5), 'Level 5 should be valid');
        assert(is_valid_level(6), 'Level 6 should be valid');
        assert(is_valid_level(7), 'Level 7 should be valid');
        
        // Test invalid levels
        assert(!is_valid_level(0), 'Level 0 should be invalid');
        assert(!is_valid_level(8), 'Level 8 should be invalid');
        assert(!is_valid_level(255), 'Level 255 should be invalid');
    }

    #[test]
    #[available_gas(100000)]
    fn test_get_next_level() {
        // Test valid level progressions
        assert(get_next_level(1) == Option::Some(2), 'Next level from 1 should be 2');
        assert(get_next_level(2) == Option::Some(3), 'Next level from 2 should be 3');
        assert(get_next_level(3) == Option::Some(4), 'Next level from 3 should be 4');
        assert(get_next_level(4) == Option::Some(5), 'Next level from 4 should be 5');
        assert(get_next_level(5) == Option::Some(6), 'Next level from 5 should be 6');
        assert(get_next_level(6) == Option::Some(7), 'Next level from 6 should be 7');
        
        // Test max level
        assert(get_next_level(7) == Option::None, 'Next level from 7 should be None');
        
        // Test invalid levels
        assert(get_next_level(0) == Option::None, 'Next level from 0 should be None');
        assert(get_next_level(8) == Option::None, 'Next level from 8 should be None');
    }

    #[test]
    #[available_gas(50000)]
    fn test_level_config_constants() {
        assert(LevelConfig::MIN_LEVEL == 1, 'MIN_LEVEL should be 1');
        assert(LevelConfig::MAX_LEVEL == 7, 'MAX_LEVEL should be 7');
    }

    // ================================
    // Basic Creation and Validation Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_level_progress_creation() {
        let progress = create_test_level_progress();
        
        assert(progress.player == contract_address_const::<0x123>(), 'Wrong player address');
        assert(progress.game_id == 1, 'Wrong game ID');
        assert(progress.level == 1, 'Wrong level');
        assert(progress.points_required == 12, 'Wrong points required');
        assert(progress.cheddah_reward == 15, 'Wrong cheddah reward');
        assert(progress.orbs_pulled.len() == 0, 'Should start with no orbs pulled');
    }

    #[test]
    #[available_gas(150000)]
    fn test_initialize_for_level() {
        let player = contract_address_const::<0x456>();
        let game_id = 2;
        let level = 3;
        
        let progress = LevelProgressTrait::initialize_for_level(player, game_id, level);
        
        assert(progress.player == player, 'Wrong player in initialized progress');
        assert(progress.game_id == game_id, 'Wrong game_id in initialized progress');
        assert(progress.level == level, 'Wrong level in initialized progress');
        assert(progress.points_required == 28, 'Wrong points for level 3');
        assert(progress.cheddah_reward == 30, 'Wrong reward for level 3');
        assert(progress.orbs_pulled.len() == 0, 'Should start with no orbs');
    }

    #[test]
    #[available_gas(100000)]
    #[should_panic(expected: ('Invalid level',))]
    fn test_initialize_invalid_level() {
        let player = contract_address_const::<0x789>();
        let game_id = 3;
        
        // Try to initialize with invalid level
        let _progress = LevelProgressTrait::initialize_for_level(player, game_id, 8);
    }

    // ================================
    // Orb Tracking Tests
    // ================================

    #[test]
    #[available_gas(150000)]
    fn test_record_orb_pull() {
        let mut progress = create_test_level_progress();
        
        // Test recording single orb
        progress.record_orb_pull(OrbType::FivePoints);
        assert(progress.orbs_pulled.len() == 1, 'Should have 1 orb recorded');
        
        // Test recording multiple orbs
        progress.record_orb_pull(OrbType::SingleBomb);
        progress.record_orb_pull(OrbType::Health);
        assert(progress.orbs_pulled.len() == 3, 'Should have 3 orbs recorded');
        
        // Verify orb order
        let orb_span = progress.orbs_pulled.span();
        assert(*orb_span.at(0) == OrbType::FivePoints, 'First orb wrong');
        assert(*orb_span.at(1) == OrbType::SingleBomb, 'Second orb wrong');
        assert(*orb_span.at(2) == OrbType::Health, 'Third orb wrong');
    }

    #[test]
    #[available_gas(200000)]
    fn test_record_many_orbs() {
        let mut progress = create_test_level_progress();
        
        // Record many orbs
        let orb_types = array![
            OrbType::FivePoints,
            OrbType::SingleBomb,
            OrbType::FivePoints,
            OrbType::DoubleMultiplier,
            OrbType::FivePoints,
            OrbType::Health,
            OrbType::FivePoints,
            OrbType::RemainingOrbs,
            OrbType::FivePoints,
            OrbType::DoubleBomb
        ];
        
        let orb_span = orb_types.span();
        let mut i = 0;
        while i < orb_types.len() {
            progress.record_orb_pull(*orb_span.at(i));
            i += 1;
        };
        
        assert(progress.orbs_pulled.len() == 10, 'Should have 10 orbs recorded');
        
        // Verify all orbs are recorded correctly
        let recorded_span = progress.orbs_pulled.span();
        let mut j = 0;
        while j < progress.orbs_pulled.len() {
            assert(*recorded_span.at(j) == *orb_span.at(j), 'Orb mismatch at index');
            j += 1;
        };
    }

    #[test]
    #[available_gas(150000)]
    fn test_get_orbs_pulled_count() {
        let mut progress = create_test_level_progress();
        
        // Test initial count
        assert(progress.get_orbs_pulled_count() == 0, 'Initial count should be 0');
        
        // Add orbs and test count
        progress.record_orb_pull(OrbType::FivePoints);
        assert(progress.get_orbs_pulled_count() == 1, 'Count should be 1');
        
        progress.record_orb_pull(OrbType::SingleBomb);
        assert(progress.get_orbs_pulled_count() == 2, 'Count should be 2');
        
        progress.record_orb_pull(OrbType::Health);
        assert(progress.get_orbs_pulled_count() == 3, 'Count should be 3');
    }

    // ================================
    // Points and Progress Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_add_points() {
        let mut progress = create_test_level_progress();
        let initial_required = progress.points_required;
        
        // Test adding points
        progress.add_points(5);
        assert(progress.points_required == initial_required - 5, 'Points should decrease requirement');
        
        // Test adding more points
        progress.add_points(3);
        assert(progress.points_required == initial_required - 8, 'Points should decrease further');
    }

    #[test]
    #[available_gas(100000)]
    fn test_add_points_overflow() {
        let mut progress = create_test_level_progress();
        
        // Add more points than required
        progress.add_points(20); // More than the 12 required
        assert(progress.points_required == 0, 'Should not go below 0');
    }

    #[test]
    #[available_gas(100000)]
    fn test_get_remaining_points() {
        let mut progress = create_test_level_progress();
        
        // Test initial remaining
        assert(progress.get_remaining_points() == 12, 'Initial remaining should be 12');
        
        // Add points and test remaining
        progress.add_points(4);
        assert(progress.get_remaining_points() == 8, 'Remaining should be 8');
        
        progress.add_points(8);
        assert(progress.get_remaining_points() == 0, 'Remaining should be 0');
    }

    #[test]
    #[available_gas(100000)]
    fn test_is_level_complete() {
        let mut progress = create_test_level_progress();
        
        // Test incomplete level
        assert(!progress.is_level_complete(), 'Level should not be complete initially');
        
        // Add some points but not enough
        progress.add_points(5);
        assert(!progress.is_level_complete(), 'Level should not be complete yet');
        
        // Add enough points to complete
        progress.add_points(7);
        assert(progress.is_level_complete(), 'Level should be complete');
        
        // Add extra points (should still be complete)
        progress.add_points(5);
        assert(progress.is_level_complete(), 'Level should still be complete');
    }

    // ================================
    // Progress Analysis Tests
    // ================================

    #[test]
    #[available_gas(150000)]
    fn test_get_completion_percentage() {
        let mut progress = create_test_level_progress();
        
        // Test 0% completion
        assert(progress.get_completion_percentage() == 0, 'Should be 0% initially');
        
        // Test partial completion
        progress.add_points(3); // 3/12 = 25%
        assert(progress.get_completion_percentage() == 25, 'Should be 25%');
        
        progress.add_points(3); // 6/12 = 50%
        assert(progress.get_completion_percentage() == 50, 'Should be 50%');
        
        progress.add_points(3); // 9/12 = 75%
        assert(progress.get_completion_percentage() == 75, 'Should be 75%');
        
        // Test 100% completion
        progress.add_points(3); // 12/12 = 100%
        assert(progress.get_completion_percentage() == 100, 'Should be 100%');
        
        // Test over 100%
        progress.add_points(6); // More than required
        assert(progress.get_completion_percentage() == 100, 'Should cap at 100%');
    }

    #[test]
    #[available_gas(200000)]
    fn test_different_level_percentages() {
        // Test level 3 (28 points required)
        let mut progress3 = LevelProgressTrait::initialize_for_level(
            contract_address_const::<0x123>(), 1, 3
        );
        
        progress3.add_points(7); // 7/28 = 25%
        assert(progress3.get_completion_percentage() == 25, 'Level 3 should be 25%');
        
        progress3.add_points(7); // 14/28 = 50%
        assert(progress3.get_completion_percentage() == 50, 'Level 3 should be 50%');
        
        // Test level 7 (130 points required)
        let mut progress7 = LevelProgressTrait::initialize_for_level(
            contract_address_const::<0x123>(), 1, 7
        );
        
        progress7.add_points(65); // 65/130 = 50%
        assert(progress7.get_completion_percentage() == 50, 'Level 7 should be 50%');
    }

    // ================================
    // Edge Case and Error Handling Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_zero_points_required_edge_case() {
        let mut progress = create_test_level_progress();
        
        // Add exact points required
        progress.add_points(12);
        
        assert(progress.points_required == 0, 'Should have 0 points required');
        assert(progress.get_remaining_points() == 0, 'Should have 0 remaining');
        assert(progress.is_level_complete(), 'Should be complete');
        assert(progress.get_completion_percentage() == 100, 'Should be 100%');
    }

    #[test]
    #[available_gas(150000)]
    fn test_large_points_addition() {
        let mut progress = create_test_level_progress();
        
        // Add very large number of points
        progress.add_points(1000000);
        
        assert(progress.points_required == 0, 'Should not underflow');
        assert(progress.is_level_complete(), 'Should be complete');
        assert(progress.get_completion_percentage() == 100, 'Should be 100%');
    }

    #[test]
    #[available_gas(200000)]
    fn test_max_level_edge_cases() {
        // Test max level initialization
        let progress = LevelProgressTrait::initialize_for_level(
            contract_address_const::<0x123>(), 1, 7
        );
        
        assert(progress.level == 7, 'Should be level 7');
        assert(progress.points_required == 130, 'Should require 130 points');
        assert(progress.cheddah_reward == 100, 'Should reward 100 cheddah');
        
        // Test that it's still valid
        assert(is_valid_level(progress.level), 'Max level should be valid');
        assert(get_next_level(progress.level) == Option::None, 'Should have no next level');
    }

    // ================================
    // World Integration Tests
    // ================================

    #[test]
    #[available_gas(500000)]
    fn test_level_progress_world_storage() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0x789>();
        let game_id = 3;
        let progress = LevelProgressTrait::initialize_for_level(player, game_id, 2);
        
        // Test writing to world
        world.write_model_test(@progress);
        
        // Test reading from world
        let retrieved_progress: LevelProgress = world.read_model((player, game_id));
        
        assert(retrieved_progress.player == player, 'Retrieved player mismatch');
        assert(retrieved_progress.game_id == game_id, 'Retrieved game_id mismatch');
        assert(retrieved_progress.level == 2, 'Retrieved level mismatch');
        assert(retrieved_progress.points_required == 18, 'Retrieved points mismatch');
        assert(retrieved_progress.cheddah_reward == 20, 'Retrieved reward mismatch');
    }

    #[test]
    #[available_gas(400000)]
    fn test_level_progress_modifications_persistence() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0xABC>();
        let game_id = 4;
        let mut progress = LevelProgressTrait::initialize_for_level(player, game_id, 3);
        
        // Modify progress
        progress.add_points(10);
        progress.record_orb_pull(OrbType::FivePoints);
        progress.record_orb_pull(OrbType::SingleBomb);
        
        // Write and retrieve
        world.write_model_test(@progress);
        let retrieved_progress: LevelProgress = world.read_model((player, game_id));
        
        assert(retrieved_progress.points_required == 18, 'Modified points not persisted'); // 28 - 10
        assert(retrieved_progress.orbs_pulled.len() == 2, 'Modified orbs not persisted');
    }

    #[test]
    #[available_gas(300000)]
    fn test_multiple_level_progress() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player1 = contract_address_const::<0x111>();
        let player2 = contract_address_const::<0x222>();
        let game_id = 5;
        
        let mut progress1 = LevelProgressTrait::initialize_for_level(player1, game_id, 1);
        let mut progress2 = LevelProgressTrait::initialize_for_level(player2, game_id, 5);
        
        // Modify each differently
        progress1.add_points(6);
        progress2.add_points(33);
        
        // Write both
        world.write_model_test(@progress1);
        world.write_model_test(@progress2);
        
        // Verify independent storage
        let retrieved_progress1: LevelProgress = world.read_model((player1, game_id));
        let retrieved_progress2: LevelProgress = world.read_model((player2, game_id));
        
        assert(retrieved_progress1.level == 1, 'Player1 level wrong');
        assert(retrieved_progress2.level == 5, 'Player2 level wrong');
        assert(retrieved_progress1.points_required == 6, 'Player1 points wrong'); // 12 - 6
        assert(retrieved_progress2.points_required == 33, 'Player2 points wrong'); // 66 - 33
    }
}