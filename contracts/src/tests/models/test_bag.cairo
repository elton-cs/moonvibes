// ================================
// Bag Model Tests - Task 5.1
// Comprehensive unit tests for Bag model with dynamic array management
// ================================

#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, contract_address_const};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource};
    
    use crate::models::bag::{Bag, BagTrait, m_Bag};
    use crate::models::orb::OrbType;

    // ================================
    // Test Helper Functions
    // ================================

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_Bag::TEST_CLASS_HASH),
            ].span()
        }
    }

    fn create_test_bag() -> Bag {
        Bag {
            player: contract_address_const::<0x123>(),
            game_id: 1,
            orbs: array![],
            total_orbs: 0,
        }
    }

    fn create_starting_bag() -> Bag {
        let mut orbs = array![];
        
        // Starting bag: 6x FivePoints, 2x SingleBomb, 1x DoubleBomb, 1x DoubleMultiplier, 1x RemainingOrbs, 1x Health
        let mut i = 0;
        while i < 6 {
            orbs.append(OrbType::FivePoints);
            i += 1;
        };
        orbs.append(OrbType::SingleBomb);
        orbs.append(OrbType::SingleBomb);
        orbs.append(OrbType::DoubleBomb);
        orbs.append(OrbType::DoubleMultiplier);
        orbs.append(OrbType::RemainingOrbs);
        orbs.append(OrbType::Health);
        
        Bag {
            player: contract_address_const::<0x123>(),
            game_id: 1,
            orbs,
            total_orbs: 12,
        }
    }

    // ================================
    // Basic Creation and Validation Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_bag_creation() {
        let bag = create_test_bag();
        
        assert(bag.player == contract_address_const::<0x123>(), 'Wrong player address');
        assert(bag.game_id == 1, 'Wrong game ID');
        assert(bag.orbs.len() == 0, 'Should start with empty orbs');
        assert(bag.total_orbs == 0, 'Should start with zero total');
    }

    #[test]
    #[available_gas(150000)]
    fn test_starting_bag_creation() {
        let bag = create_starting_bag();
        
        assert(bag.player == contract_address_const::<0x123>(), 'Wrong player address');
        assert(bag.game_id == 1, 'Wrong game ID');
        assert(bag.orbs.len() == 12, 'Should have 12 orbs');
        assert(bag.total_orbs == 12, 'Total should match length');
    }

    #[test]
    #[available_gas(200000)]
    fn test_create_starting_bag_trait() {
        let player = contract_address_const::<0x456>();
        let game_id = 2;
        
        let bag = BagTrait::create_starting_bag(player, game_id);
        
        assert(bag.player == player, 'Wrong player in starting bag');
        assert(bag.game_id == game_id, 'Wrong game_id in starting bag');
        assert(bag.orbs.len() == 12, 'Starting bag should have 12 orbs');
        assert(bag.total_orbs == 12, 'Starting total should be 12');
        
        // Verify starting composition
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
    // Bag State Query Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_is_empty() {
        let mut bag = create_test_bag();
        
        // Test empty bag
        assert(bag.is_empty(), 'Empty bag should return true');
        
        // Add orb and test
        bag.add_orb(OrbType::FivePoints);
        assert(!bag.is_empty(), 'Non-empty bag should return false');
        
        // Remove orb and test
        let _removed = bag.draw_random_orb(1);
        assert(bag.is_empty(), 'Bag should be empty after drawing last orb');
    }

    #[test]
    #[available_gas(150000)]
    fn test_get_total_orbs() {
        let mut bag = create_test_bag();
        
        // Test initial count
        assert(bag.get_total_orbs() == 0, 'Initial count should be 0');
        
        // Add orbs and test count
        bag.add_orb(OrbType::FivePoints);
        assert(bag.get_total_orbs() == 1, 'Count should be 1 after adding');
        
        bag.add_orb(OrbType::SingleBomb);
        assert(bag.get_total_orbs() == 2, 'Count should be 2 after adding');
        
        bag.add_orb(OrbType::Health);
        assert(bag.get_total_orbs() == 3, 'Count should be 3 after adding');
    }

    #[test]
    #[available_gas(200000)]
    fn test_get_all_orb_types() {
        let bag = create_starting_bag();
        
        let all_orbs = bag.get_all_orb_types();
        assert(all_orbs.len() == 12, 'Should return all 12 orbs');
        
        // Verify it returns the same orbs as in the bag
        let orb_span = bag.orbs.span();
        let all_span = all_orbs.span();
        let mut i = 0;
        while i < bag.orbs.len() {
            assert(*orb_span.at(i) == *all_span.at(i), 'Orb mismatch in get_all_orb_types');
            i += 1;
        };
    }

    // ================================
    // Orb Management Tests
    // ================================

    #[test]
    #[available_gas(150000)]
    fn test_add_orb() {
        let mut bag = create_test_bag();
        
        // Test adding single orb
        bag.add_orb(OrbType::FivePoints);
        assert(bag.orbs.len() == 1, 'Should have 1 orb after adding');
        assert(bag.total_orbs == 1, 'Total should be 1 after adding');
        
        // Test adding different orb
        bag.add_orb(OrbType::SingleBomb);
        assert(bag.orbs.len() == 2, 'Should have 2 orbs after adding');
        assert(bag.total_orbs == 2, 'Total should be 2 after adding');
        
        // Verify orbs are correct
        let orb_span = bag.orbs.span();
        assert(*orb_span.at(0) == OrbType::FivePoints, 'First orb should be FivePoints');
        assert(*orb_span.at(1) == OrbType::SingleBomb, 'Second orb should be SingleBomb');
    }

    #[test]
    #[available_gas(200000)]
    fn test_add_multiple_same_orbs() {
        let mut bag = create_test_bag();
        
        // Add multiple of the same orb type
        bag.add_orb(OrbType::FivePoints);
        bag.add_orb(OrbType::FivePoints);
        bag.add_orb(OrbType::FivePoints);
        
        assert(bag.orbs.len() == 3, 'Should have 3 orbs');
        assert(bag.total_orbs == 3, 'Total should be 3');
        
        // Verify all are the same type
        let orb_span = bag.orbs.span();
        let mut i = 0;
        while i < bag.orbs.len() {
            assert(*orb_span.at(i) == OrbType::FivePoints, 'All orbs should be FivePoints');
            i += 1;
        };
    }

    #[test]
    #[available_gas(300000)]
    fn test_draw_random_orb() {
        let mut bag = create_starting_bag();
        let initial_count = bag.total_orbs;
        
        // Draw orb with seed
        let drawn_orb = bag.draw_random_orb(12345);
        
        // Verify bag state after drawing
        assert(bag.orbs.len() == initial_count - 1, 'Bag should have one less orb');
        assert(bag.total_orbs == initial_count - 1, 'Total should decrease by 1');
        
        // Verify the drawn orb is one of the valid starting orbs
        let valid_orbs = array![
            OrbType::FivePoints,
            OrbType::SingleBomb,
            OrbType::DoubleBomb,
            OrbType::DoubleMultiplier,
            OrbType::RemainingOrbs,
            OrbType::Health
        ];
        
        let valid_span = valid_orbs.span();
        let mut found = false;
        let mut i = 0;
        while i < valid_orbs.len() {
            if drawn_orb == *valid_span.at(i) {
                found = true;
                break;
            }
            i += 1;
        };
        assert(found, 'Drawn orb should be from starting set');
    }

    #[test]
    #[available_gas(200000)]
    fn test_draw_random_orb_deterministic() {
        let mut bag1 = create_starting_bag();
        let mut bag2 = create_starting_bag();
        
        // Drawing with same seed should give same result
        let seed = 54321;
        let orb1 = bag1.draw_random_orb(seed);
        let orb2 = bag2.draw_random_orb(seed);
        
        assert(orb1 == orb2, 'Same seed should give same orb');
    }

    #[test]
    #[available_gas(150000)]
    #[should_panic(expected: ('Bag is empty',))]
    fn test_draw_from_empty_bag() {
        let mut bag = create_test_bag();
        
        // Try to draw from empty bag
        let _orb = bag.draw_random_orb(999);
    }

    #[test]
    #[available_gas(200000)]
    fn test_draw_until_empty() {
        let mut bag = create_test_bag();
        
        // Add a few orbs
        bag.add_orb(OrbType::FivePoints);
        bag.add_orb(OrbType::SingleBomb);
        bag.add_orb(OrbType::Health);
        
        let initial_count = bag.total_orbs;
        let mut drawn_orbs = array![];
        
        // Draw all orbs
        let mut seed = 1;
        while !bag.is_empty() {
            let orb = bag.draw_random_orb(seed);
            drawn_orbs.append(orb);
            seed += 1;
        };
        
        assert(drawn_orbs.len() == initial_count, 'Should draw all orbs');
        assert(bag.is_empty(), 'Bag should be empty');
        assert(bag.total_orbs == 0, 'Total should be 0');
    }

    // ================================
    // Edge Case and Error Handling Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_bag_consistency() {
        let mut bag = create_test_bag();
        
        // Add orbs and check consistency
        bag.add_orb(OrbType::FivePoints);
        bag.add_orb(OrbType::SingleBomb);
        
        assert(bag.orbs.len() == bag.total_orbs, 'Length should match total_orbs');
        
        // Draw orb and check consistency  
        let _orb = bag.draw_random_orb(123);
        assert(bag.orbs.len() == bag.total_orbs, 'Length should still match total_orbs');
    }

    #[test]
    #[available_gas(150000)]
    fn test_large_bag() {
        let mut bag = create_test_bag();
        
        // Add many orbs
        let mut i = 0;
        while i < 50 {
            bag.add_orb(OrbType::FivePoints);
            i += 1;
        };
        
        assert(bag.total_orbs == 50, 'Should have 50 orbs');
        assert(bag.orbs.len() == 50, 'Array length should be 50');
        
        // Draw half the orbs
        let mut drawn = 0;
        while drawn < 25 {
            let _orb = bag.draw_random_orb(drawn.into());
            drawn += 1;
        };
        
        assert(bag.total_orbs == 25, 'Should have 25 orbs remaining');
        assert(bag.orbs.len() == 25, 'Array length should be 25');
    }

    #[test]
    #[available_gas(300000)]
    fn test_orb_type_variety() {
        let mut bag = create_test_bag();
        
        // Add one of each orb type
        bag.add_orb(OrbType::FivePoints);
        bag.add_orb(OrbType::SingleBomb);
        bag.add_orb(OrbType::DoubleBomb);
        bag.add_orb(OrbType::TripleBomb);
        bag.add_orb(OrbType::DoubleMultiplier);
        bag.add_orb(OrbType::RemainingOrbs);
        bag.add_orb(OrbType::BombCounter);
        bag.add_orb(OrbType::Health);
        bag.add_orb(OrbType::SevenPoints);
        bag.add_orb(OrbType::CheddahBomb);
        bag.add_orb(OrbType::MoonRock);
        bag.add_orb(OrbType::HalfMultiplier);
        bag.add_orb(OrbType::EightPoints);
        bag.add_orb(OrbType::NinePoints);
        bag.add_orb(OrbType::NextPoints2x);
        bag.add_orb(OrbType::Multiplier1_5x);
        bag.add_orb(OrbType::BigHealth);
        bag.add_orb(OrbType::BigMoonRock);
        
        assert(bag.total_orbs == 18, 'Should have all 18 orb types');
        
        // Draw all and verify variety
        let mut drawn_types = array![];
        while !bag.is_empty() {
            let orb = bag.draw_random_orb(bag.total_orbs.into());
            drawn_types.append(orb);
        };
        
        assert(drawn_types.len() == 18, 'Should draw all 18 orbs');
    }

    // ================================
    // World Integration Tests
    // ================================

    #[test]
    #[available_gas(500000)]
    fn test_bag_world_storage() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0x789>();
        let game_id = 3;
        let bag = BagTrait::create_starting_bag(player, game_id);
        
        // Test writing to world
        world.write_model_test(@bag);
        
        // Test reading from world
        let retrieved_bag: Bag = world.read_model((player, game_id));
        
        assert(retrieved_bag.player == player, 'Retrieved player mismatch');
        assert(retrieved_bag.game_id == game_id, 'Retrieved game_id mismatch');
        assert(retrieved_bag.total_orbs == 12, 'Retrieved total_orbs mismatch');
        assert(retrieved_bag.orbs.len() == 12, 'Retrieved orbs length mismatch');
    }

    #[test]
    #[available_gas(400000)]
    fn test_bag_modifications_persistence() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0xABC>();
        let game_id = 4;
        let mut bag = BagTrait::create_starting_bag(player, game_id);
        
        // Modify bag by drawing orbs
        let _orb1 = bag.draw_random_orb(111);
        let _orb2 = bag.draw_random_orb(222);
        bag.add_orb(OrbType::SevenPoints);
        
        // Write and retrieve
        world.write_model_test(@bag);
        let retrieved_bag: Bag = world.read_model((player, game_id));
        
        assert(retrieved_bag.total_orbs == 11, 'Modified total not persisted'); // 12 - 2 + 1
        assert(retrieved_bag.orbs.len() == 11, 'Modified length not persisted');
    }

    #[test]
    #[available_gas(300000)]
    fn test_multiple_player_bags() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player1 = contract_address_const::<0x111>();
        let player2 = contract_address_const::<0x222>();
        let game_id = 5;
        
        let mut bag1 = BagTrait::create_starting_bag(player1, game_id);
        let mut bag2 = BagTrait::create_starting_bag(player2, game_id);
        
        // Modify each differently
        let _orb1 = bag1.draw_random_orb(333);
        bag2.add_orb(OrbType::BigHealth);
        
        // Write both
        world.write_model_test(@bag1);
        world.write_model_test(@bag2);
        
        // Verify independent storage
        let retrieved_bag1: Bag = world.read_model((player1, game_id));
        let retrieved_bag2: Bag = world.read_model((player2, game_id));
        
        assert(retrieved_bag1.total_orbs == 11, 'Player1 bag wrong');
        assert(retrieved_bag2.total_orbs == 13, 'Player2 bag wrong');
        assert(retrieved_bag1.player != retrieved_bag2.player, 'Players should differ');
    }

    #[test]
    #[available_gas(200000)]
    fn test_bag_deletion() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0xDEF>();
        let game_id = 6;
        let bag = BagTrait::create_starting_bag(player, game_id);
        
        // Write and verify
        world.write_model_test(@bag);
        let retrieved_bag: Bag = world.read_model((player, game_id));
        assert(retrieved_bag.total_orbs == 12, 'Bag not written correctly');
        
        // Delete and verify
        world.erase_model(@bag);
        let deleted_bag: Bag = world.read_model((player, game_id));
        assert(deleted_bag.total_orbs == 0, 'Bag not deleted correctly');
        assert(deleted_bag.orbs.len() == 0, 'Orbs not cleared after deletion');
    }
}