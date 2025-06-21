// ================================
// PlayerStats Model Tests - Task 5.1
// Comprehensive unit tests for PlayerStats model with edge cases and validation
// ================================

#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, contract_address_const};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource};
    
    use crate::models::player_stats::{PlayerStats, PlayerStatsTrait, m_PlayerStats};

    // ================================
    // Test Helper Functions
    // ================================

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_PlayerStats::TEST_CLASS_HASH),
            ].span()
        }
    }

    fn create_test_player_stats() -> PlayerStats {
        PlayerStats {
            player: contract_address_const::<0x123>(),
            game_id: 1,
            health: 5,
            points: 0,
            multiplier: 100, // 1.0x
            moon_rocks: 304,
            cheddah: 0,
        }
    }

    // ================================
    // Basic Creation and Validation Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_player_stats_creation() {
        let stats = create_test_player_stats();
        
        assert(stats.player == contract_address_const::<0x123>(), 'Wrong player address');
        assert(stats.game_id == 1, 'Wrong game ID');
        assert(stats.health == 5, 'Wrong initial health');
        assert(stats.points == 0, 'Wrong initial points');
        assert(stats.multiplier == 100, 'Wrong initial multiplier');
        assert(stats.moon_rocks == 304, 'Wrong initial moon rocks');
        assert(stats.cheddah == 0, 'Wrong initial cheddah');
    }

    #[test]
    #[available_gas(150000)]
    fn test_create_starting_stats() {
        let player = contract_address_const::<0x456>();
        let game_id = 2;
        
        let stats = PlayerStatsTrait::create_starting_stats(player, game_id);
        
        assert(stats.player == player, 'Wrong player in starting stats');
        assert(stats.game_id == game_id, 'Wrong game_id in starting stats');
        assert(stats.health == 5, 'Wrong starting health');
        assert(stats.points == 0, 'Wrong starting points');
        assert(stats.multiplier == 100, 'Wrong starting multiplier');
        assert(stats.moon_rocks == 304, 'Wrong starting moon rocks');
        assert(stats.cheddah == 0, 'Wrong starting cheddah');
    }

    // ================================
    // Health Management Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_apply_health_change_positive() {
        let mut stats = create_test_player_stats();
        
        // Test adding health
        stats.apply_health_change(2);
        assert(stats.health == 7, 'Health increase failed');
        
        // Test adding more health
        stats.apply_health_change(3);
        assert(stats.health == 10, 'Second health increase failed');
    }

    #[test]
    #[available_gas(100000)]
    fn test_apply_health_change_negative() {
        let mut stats = create_test_player_stats();
        
        // Test reducing health
        stats.apply_health_change(-2);
        assert(stats.health == 3, 'Health decrease failed');
        
        // Test reducing to exactly zero
        stats.apply_health_change(-3);
        assert(stats.health == 0, 'Health should reach zero');
    }

    #[test]
    #[available_gas(100000)]
    fn test_health_underflow_protection() {
        let mut stats = create_test_player_stats();
        
        // Try to reduce health below zero
        stats.apply_health_change(-10);
        assert(stats.health == 0, 'Health should not go below zero');
    }

    #[test]
    #[available_gas(100000)]
    fn test_health_overflow_protection() {
        let mut stats = create_test_player_stats();
        
        // Try to add health beyond u8 max
        stats.apply_health_change(252); // 5 + 252 = 257 > 255
        assert(stats.health == 255, 'Health should cap at 255');
    }

    #[test]
    #[available_gas(100000)]
    fn test_is_alive() {
        let mut stats = create_test_player_stats();
        
        // Test alive with positive health
        assert(stats.is_alive(), 'Should be alive with health > 0');
        
        // Test alive with health = 1
        stats.health = 1;
        assert(stats.is_alive(), 'Should be alive with health = 1');
        
        // Test dead with health = 0
        stats.health = 0;
        assert(!stats.is_alive(), 'Should be dead with health = 0');
    }

    // ================================
    // Currency Management Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_spend_moon_rocks_valid() {
        let mut stats = create_test_player_stats();
        
        // Test valid spending
        stats.spend_moon_rocks(100);
        assert(stats.moon_rocks == 204, 'Moon rocks spending failed');
        
        // Test spending remaining
        stats.spend_moon_rocks(204);
        assert(stats.moon_rocks == 0, 'Should spend all moon rocks');
    }

    #[test]
    #[available_gas(100000)]
    #[should_panic(expected: ('Insufficient moon rocks',))]
    fn test_spend_moon_rocks_insufficient() {
        let mut stats = create_test_player_stats();
        
        // Try to spend more than available
        stats.spend_moon_rocks(500);
    }

    #[test]
    #[available_gas(100000)]
    fn test_can_afford_moon_rocks() {
        let stats = create_test_player_stats();
        
        // Test affordable amounts
        assert(stats.can_afford_moon_rocks(100), 'Should afford 100 moon rocks');
        assert(stats.can_afford_moon_rocks(304), 'Should afford exact amount');
        
        // Test unaffordable amounts
        assert(!stats.can_afford_moon_rocks(305), 'Should not afford 305 moon rocks');
        assert(!stats.can_afford_moon_rocks(1000), 'Should not afford 1000 moon rocks');
    }

    #[test]
    #[available_gas(100000)]
    fn test_spend_cheddah_valid() {
        let mut stats = create_test_player_stats();
        stats.cheddah = 100;
        
        // Test valid spending
        stats.spend_cheddah(50);
        assert(stats.cheddah == 50, 'Cheddah spending failed');
        
        // Test spending remaining
        stats.spend_cheddah(50);
        assert(stats.cheddah == 0, 'Should spend all cheddah');
    }

    #[test]
    #[available_gas(100000)]
    #[should_panic(expected: ('Insufficient cheddah',))]
    fn test_spend_cheddah_insufficient() {
        let mut stats = create_test_player_stats();
        
        // Try to spend more than available (starts with 0)
        stats.spend_cheddah(10);
    }

    #[test]
    #[available_gas(100000)]
    fn test_can_afford_cheddah() {
        let mut stats = create_test_player_stats();
        stats.cheddah = 100;
        
        // Test affordable amounts
        assert(stats.can_afford_cheddah(50), 'Should afford 50 cheddah');
        assert(stats.can_afford_cheddah(100), 'Should afford exact amount');
        
        // Test unaffordable amounts
        assert(!stats.can_afford_cheddah(101), 'Should not afford 101 cheddah');
        assert(!stats.can_afford_cheddah(500), 'Should not afford 500 cheddah');
        
        // Test with zero cheddah
        stats.cheddah = 0;
        assert(!stats.can_afford_cheddah(1), 'Should not afford with zero cheddah');
        assert(stats.can_afford_cheddah(0), 'Should afford zero cheddah');
    }

    // ================================
    // Points and Scoring Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_add_points() {
        let mut stats = create_test_player_stats();
        
        // Test adding points
        stats.add_points(50);
        assert(stats.points == 50, 'Points addition failed');
        
        // Test adding more points
        stats.add_points(25);
        assert(stats.points == 75, 'Second points addition failed');
    }

    #[test]
    #[available_gas(100000)]
    fn test_points_overflow_protection() {
        let mut stats = create_test_player_stats();
        stats.points = 0xFFFFFFF0; // Close to u32 max
        
        // Adding should not panic, should handle overflow gracefully
        stats.add_points(100);
        // Implementation should either cap or handle overflow appropriately
        assert(stats.points >= 0xFFFFFFF0, 'Points overflow not handled');
    }

    #[test]
    #[available_gas(100000)]
    fn test_convert_points_to_moon_rocks() {
        let mut stats = create_test_player_stats();
        stats.points = 150;
        
        let converted = stats.convert_points_to_moon_rocks();
        
        assert(converted == 150, 'Conversion should be 1:1');
        assert(stats.moon_rocks == 304 + 150, 'Moon rocks should increase');
        assert(stats.points == 0, 'Points should be reset to zero');
    }

    #[test]
    #[available_gas(100000)]
    fn test_convert_zero_points() {
        let mut stats = create_test_player_stats();
        
        let converted = stats.convert_points_to_moon_rocks();
        
        assert(converted == 0, 'Should convert zero points');
        assert(stats.moon_rocks == 304, 'Moon rocks should not change');
        assert(stats.points == 0, 'Points should remain zero');
    }

    // ================================
    // Multiplier Management Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_multiplier_boundaries() {
        let mut stats = create_test_player_stats();
        
        // Test various multiplier values
        stats.multiplier = 50; // 0.5x
        assert(stats.multiplier == 50, 'Half multiplier failed');
        
        stats.multiplier = 150; // 1.5x
        assert(stats.multiplier == 150, '1.5x multiplier failed');
        
        stats.multiplier = 200; // 2.0x
        assert(stats.multiplier == 200, '2x multiplier failed');
        
        stats.multiplier = 1000; // 10.0x
        assert(stats.multiplier == 1000, '10x multiplier failed');
    }

    #[test]
    #[available_gas(100000)]
    fn test_reset_multiplier() {
        let mut stats = create_test_player_stats();
        stats.multiplier = 300; // 3.0x
        
        stats.reset_multiplier();
        assert(stats.multiplier == 100, 'Multiplier should reset to 1.0x');
    }

    // ================================
    // Edge Case and Validation Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_extreme_values() {
        let mut stats = create_test_player_stats();
        
        // Test with maximum values
        stats.health = 255;
        stats.points = 0xFFFFFFFF;
        stats.moon_rocks = 0xFFFFFFFF;
        stats.cheddah = 0xFFFFFFFF;
        stats.multiplier = 1000;
        
        assert(stats.health == 255, 'Max health failed');
        assert(stats.points == 0xFFFFFFFF, 'Max points failed');
        assert(stats.moon_rocks == 0xFFFFFFFF, 'Max moon rocks failed');
        assert(stats.cheddah == 0xFFFFFFFF, 'Max cheddah failed');
        assert(stats.multiplier == 1000, 'Max multiplier failed');
    }

    #[test]
    #[available_gas(100000)]
    fn test_zero_values() {
        let mut stats = create_test_player_stats();
        
        // Set all values to zero
        stats.health = 0;
        stats.points = 0;
        stats.moon_rocks = 0;
        stats.cheddah = 0;
        stats.multiplier = 0; // This might be invalid in real game, but testing boundary
        
        assert(stats.health == 0, 'Zero health failed');
        assert(stats.points == 0, 'Zero points failed');
        assert(stats.moon_rocks == 0, 'Zero moon rocks failed');
        assert(stats.cheddah == 0, 'Zero cheddah failed');
        assert(stats.multiplier == 0, 'Zero multiplier failed');
        assert(!stats.is_alive(), 'Should not be alive with zero health');
    }

    // ================================
    // World Integration Tests
    // ================================

    #[test]
    #[available_gas(500000)]
    fn test_player_stats_world_storage() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0x789>();
        let game_id = 3;
        let stats = PlayerStatsTrait::create_starting_stats(player, game_id);
        
        // Test writing to world
        world.write_model_test(@stats);
        
        // Test reading from world
        let retrieved_stats: PlayerStats = world.read_model((player, game_id));
        
        assert(retrieved_stats.player == player, 'Retrieved player mismatch');
        assert(retrieved_stats.game_id == game_id, 'Retrieved game_id mismatch');
        assert(retrieved_stats.health == 5, 'Retrieved health mismatch');
        assert(retrieved_stats.moon_rocks == 304, 'Retrieved moon rocks mismatch');
    }

    #[test]
    #[available_gas(400000)]
    fn test_player_stats_modifications_persistence() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0xABC>();
        let game_id = 4;
        let mut stats = PlayerStatsTrait::create_starting_stats(player, game_id);
        
        // Modify stats
        stats.apply_health_change(2);
        stats.add_points(100);
        stats.spend_moon_rocks(50);
        stats.multiplier = 200;
        stats.cheddah = 25;
        
        // Write and retrieve
        world.write_model_test(@stats);
        let retrieved_stats: PlayerStats = world.read_model((player, game_id));
        
        assert(retrieved_stats.health == 7, 'Modified health not persisted');
        assert(retrieved_stats.points == 100, 'Modified points not persisted');
        assert(retrieved_stats.moon_rocks == 254, 'Modified moon rocks not persisted');
        assert(retrieved_stats.multiplier == 200, 'Modified multiplier not persisted');
        assert(retrieved_stats.cheddah == 25, 'Modified cheddah not persisted');
    }

    #[test]
    #[available_gas(300000)]
    fn test_multiple_player_stats() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player1 = contract_address_const::<0x111>();
        let player2 = contract_address_const::<0x222>();
        let game_id = 5;
        
        let mut stats1 = PlayerStatsTrait::create_starting_stats(player1, game_id);
        let mut stats2 = PlayerStatsTrait::create_starting_stats(player2, game_id);
        
        // Modify each differently
        stats1.add_points(50);
        stats2.add_points(100);
        stats1.apply_health_change(-1);
        stats2.apply_health_change(2);
        
        // Write both
        world.write_model_test(@stats1);
        world.write_model_test(@stats2);
        
        // Verify independent storage
        let retrieved_stats1: PlayerStats = world.read_model((player1, game_id));
        let retrieved_stats2: PlayerStats = world.read_model((player2, game_id));
        
        assert(retrieved_stats1.points == 50, 'Player1 points wrong');
        assert(retrieved_stats2.points == 100, 'Player2 points wrong');
        assert(retrieved_stats1.health == 4, 'Player1 health wrong');
        assert(retrieved_stats2.health == 7, 'Player2 health wrong');
    }
}