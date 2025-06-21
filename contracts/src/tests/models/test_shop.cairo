// ================================
// Shop Model Tests - Task 5.1  
// Comprehensive unit tests for Shop models with purchase system validation
// ================================

#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, contract_address_const};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource};
    
    use crate::models::shop::{
        Shop, ShopTrait, PurchaseHistory, PurchaseHistoryTrait, ShopConfig,
        get_base_orb_price, calculate_scaled_price, m_Shop, m_PurchaseHistory
    };
    use crate::models::orb::OrbType;

    // ================================
    // Test Helper Functions
    // ================================

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_Shop::TEST_CLASS_HASH),
                TestResource::Model(m_PurchaseHistory::TEST_CLASS_HASH),
            ].span()
        }
    }

    fn create_test_shop() -> Shop {
        Shop {
            player: contract_address_const::<0x123>(),
            game_id: 1,
            level: 1,
            available_orbs: array![],
            orb_prices: array![],
            shop_generated: false,
        }
    }

    fn create_test_purchase_history() -> PurchaseHistory {
        PurchaseHistory {
            player: contract_address_const::<0x123>(),
            orb_type: OrbType::SevenPoints,
            purchase_count: 0,
            total_spent: 0,
            last_purchase_price: 0,
        }
    }

    // ================================
    // Shop Configuration Tests
    // ================================

    #[test]
    #[available_gas(50000)]
    fn test_shop_config_constants() {
        assert(ShopConfig::TOTAL_SHOP_ORBS == 6, 'Total shop orbs should be 6');
        assert(ShopConfig::COMMON_ORBS == 3, 'Common orbs should be 3');
        assert(ShopConfig::RARE_ORBS == 2, 'Rare orbs should be 2'); 
        assert(ShopConfig::COSMIC_ORBS == 1, 'Cosmic orbs should be 1');
    }

    #[test]
    #[available_gas(200000)]
    fn test_get_base_orb_price() {
        // Test common shop orbs (should cost 15)
        assert(get_base_orb_price(OrbType::SevenPoints) == 15, 'SevenPoints price wrong');
        assert(get_base_orb_price(OrbType::CheddahBomb) == 15, 'CheddahBomb price wrong');
        assert(get_base_orb_price(OrbType::MoonRock) == 15, 'MoonRock price wrong');
        assert(get_base_orb_price(OrbType::HalfMultiplier) == 15, 'HalfMultiplier price wrong');
        
        // Test rare shop orbs (should cost 30)
        assert(get_base_orb_price(OrbType::EightPoints) == 30, 'EightPoints price wrong');
        assert(get_base_orb_price(OrbType::NinePoints) == 30, 'NinePoints price wrong');
        assert(get_base_orb_price(OrbType::NextPoints2x) == 30, 'NextPoints2x price wrong');
        assert(get_base_orb_price(OrbType::Multiplier1_5x) == 30, 'Multiplier1_5x price wrong');
        
        // Test cosmic shop orbs (should cost 50)
        assert(get_base_orb_price(OrbType::BigHealth) == 50, 'BigHealth price wrong');
        assert(get_base_orb_price(OrbType::BigMoonRock) == 50, 'BigMoonRock price wrong');
    }

    #[test]
    #[available_gas(100000)]
    #[should_panic(expected: ('Not a shop orb',))]
    fn test_get_base_orb_price_invalid_orb() {
        // Starting orbs should not have shop prices
        let _price = get_base_orb_price(OrbType::FivePoints);
    }

    #[test]
    #[available_gas(150000)]
    fn test_calculate_scaled_price() {
        let base_price = 15;
        
        // Test no purchases (no scaling)
        assert(calculate_scaled_price(base_price, 0) == 15, 'No scaling should be base price');
        
        // Test first purchase (20% increase)
        assert(calculate_scaled_price(base_price, 1) == 18, 'First purchase should be 20% more');
        
        // Test second purchase (44% total increase)
        assert(calculate_scaled_price(base_price, 2) == 21, 'Second purchase should be more expensive');
        
        // Test third purchase
        assert(calculate_scaled_price(base_price, 3) == 25, 'Third purchase should be more expensive');
        
        // Test many purchases
        assert(calculate_scaled_price(base_price, 10) > 50, 'Many purchases should be very expensive');
    }

    #[test]
    #[available_gas(100000)]
    fn test_calculate_scaled_price_different_bases() {
        // Test with rare orb base price
        assert(calculate_scaled_price(30, 0) == 30, 'Rare base price wrong');
        assert(calculate_scaled_price(30, 1) == 36, 'Rare first purchase wrong');
        
        // Test with cosmic orb base price
        assert(calculate_scaled_price(50, 0) == 50, 'Cosmic base price wrong');
        assert(calculate_scaled_price(50, 1) == 60, 'Cosmic first purchase wrong');
    }

    // ================================
    // Shop Basic Creation Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_shop_creation() {
        let shop = create_test_shop();
        
        assert(shop.player == contract_address_const::<0x123>(), 'Wrong player address');
        assert(shop.game_id == 1, 'Wrong game ID');
        assert(shop.level == 1, 'Wrong level');
        assert(shop.available_orbs.len() == 0, 'Should start with no orbs');
        assert(shop.orb_prices.len() == 0, 'Should start with no prices');
        assert(!shop.shop_generated, 'Should not be generated initially');
    }

    #[test]
    #[available_gas(150000)]
    fn test_shop_creation_for_level() {
        let player = contract_address_const::<0x456>();
        let game_id = 2;
        let level = 3;
        
        let shop = ShopTrait::create_for_level(player, game_id, level);
        
        assert(shop.player == player, 'Wrong player in shop creation');
        assert(shop.game_id == game_id, 'Wrong game_id in shop creation');
        assert(shop.level == level, 'Wrong level in shop creation');
        assert(shop.available_orbs.len() == 0, 'Should start with no orbs');
        assert(shop.orb_prices.len() == 0, 'Should start with no prices');
        assert(!shop.shop_generated, 'Should not be generated initially');
    }

    // ================================
    // Shop Generation Tests
    // ================================

    #[test]
    #[available_gas(400000)]
    fn test_generate_shop_inventory() {
        let mut shop = create_test_shop();
        let seed = 12345;
        
        shop.generate_shop_inventory(seed);
        
        assert(shop.shop_generated, 'Shop should be marked as generated');
        assert(shop.available_orbs.len() == 6, 'Should have 6 orbs');
        assert(shop.orb_prices.len() == 6, 'Should have 6 prices');
        
        // Verify prices match orb types
        let orb_span = shop.available_orbs.span();
        let price_span = shop.orb_prices.span();
        let mut i = 0;
        while i < shop.available_orbs.len() {
            let orb = *orb_span.at(i);
            let price = *price_span.at(i);
            let base_price = get_base_orb_price(orb);
            assert(price == base_price, 'Price should match base price');
            i += 1;
        };
    }

    #[test]
    #[available_gas(300000)]
    fn test_generate_shop_inventory_deterministic() {
        let mut shop1 = create_test_shop();
        let mut shop2 = create_test_shop();
        let seed = 54321;
        
        // Same seed should produce same shop
        shop1.generate_shop_inventory(seed);
        shop2.generate_shop_inventory(seed);
        
        assert(shop1.available_orbs.len() == shop2.available_orbs.len(), 'Shop sizes should match');
        
        // Verify same orbs (order matters for determinism)
        let orb_span1 = shop1.available_orbs.span();
        let orb_span2 = shop2.available_orbs.span();
        let mut i = 0;
        while i < shop1.available_orbs.len() {
            assert(*orb_span1.at(i) == *orb_span2.at(i), 'Orbs should match with same seed');
            i += 1;
        };
    }

    #[test]
    #[available_gas(300000)]
    fn test_generate_shop_inventory_different_seeds() {
        let mut shop1 = create_test_shop();
        let mut shop2 = create_test_shop();
        
        // Different seeds should potentially produce different shops
        shop1.generate_shop_inventory(1111);
        shop2.generate_shop_inventory(9999);
        
        // Both should have valid shops
        assert(shop1.shop_generated, 'Shop1 should be generated');
        assert(shop2.shop_generated, 'Shop2 should be generated');
        assert(shop1.available_orbs.len() == 6, 'Shop1 should have 6 orbs');
        assert(shop2.available_orbs.len() == 6, 'Shop2 should have 6 orbs');
    }

    // ================================
    // Shop Query Tests
    // ================================

    #[test]
    #[available_gas(200000)]
    fn test_has_orb_available() {
        let mut shop = create_test_shop();
        shop.generate_shop_inventory(12345);
        
        // Check for orbs that should be in shop
        let orb_span = shop.available_orbs.span();
        let first_orb = *orb_span.at(0);
        assert(shop.has_orb_available(first_orb), 'Should have first orb available');
        
        // Check for orb that definitely won't be in shop (starting orb)
        assert(!shop.has_orb_available(OrbType::FivePoints), 'Should not have starting orb');
    }

    #[test]
    #[available_gas(300000)]
    fn test_get_shop_inventory() {
        let mut shop = create_test_shop();
        shop.generate_shop_inventory(12345);
        
        let (orbs, prices) = shop.get_shop_inventory();
        
        assert(orbs.len() == 6, 'Should return 6 orbs');
        assert(prices.len() == 6, 'Should return 6 prices');
        
        // Verify returned data matches shop data
        let shop_orb_span = shop.available_orbs.span();
        let shop_price_span = shop.orb_prices.span();
        let return_orb_span = orbs.span();
        let return_price_span = prices.span();
        
        let mut i = 0;
        while i < orbs.len() {
            assert(*shop_orb_span.at(i) == *return_orb_span.at(i), 'Returned orbs should match');
            assert(*shop_price_span.at(i) == *return_price_span.at(i), 'Returned prices should match');
            i += 1;
        };
    }

    #[test]
    #[available_gas(100000)]
    fn test_get_shop_inventory_not_generated() {
        let shop = create_test_shop();
        
        let (orbs, prices) = shop.get_shop_inventory();
        
        assert(orbs.len() == 0, 'Should return empty orbs');
        assert(prices.len() == 0, 'Should return empty prices');
    }

    #[test]
    #[available_gas(200000)]
    fn test_clear_shop() {
        let mut shop = create_test_shop();
        shop.generate_shop_inventory(12345);
        
        // Verify shop is generated
        assert(shop.shop_generated, 'Shop should be generated');
        assert(shop.available_orbs.len() == 6, 'Shop should have orbs');
        
        // Clear shop
        shop.clear_shop();
        
        assert(!shop.shop_generated, 'Shop should not be generated after clear');
        assert(shop.available_orbs.len() == 0, 'Shop should have no orbs after clear');
        assert(shop.orb_prices.len() == 0, 'Shop should have no prices after clear');
    }

    // ================================
    // Purchase History Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_purchase_history_creation() {
        let history = create_test_purchase_history();
        
        assert(history.player == contract_address_const::<0x123>(), 'Wrong player address');
        assert(history.orb_type == OrbType::SevenPoints, 'Wrong orb type');
        assert(history.purchase_count == 0, 'Should start with 0 purchases');
        assert(history.total_spent == 0, 'Should start with 0 spent');
        assert(history.last_purchase_price == 0, 'Should start with 0 last price');
    }

    #[test]
    #[available_gas(150000)]
    fn test_purchase_history_create_new() {
        let player = contract_address_const::<0x456>();
        let orb_type = OrbType::BigHealth;
        
        let history = PurchaseHistoryTrait::create_new(player, orb_type);
        
        assert(history.player == player, 'Wrong player in new history');
        assert(history.orb_type == orb_type, 'Wrong orb type in new history');
        assert(history.purchase_count == 0, 'Should start with 0 purchases');
        assert(history.total_spent == 0, 'Should start with 0 spent');
        assert(history.last_purchase_price == 0, 'Should start with 0 last price');
    }

    #[test]
    #[available_gas(150000)]
    fn test_record_purchase() {
        let mut history = create_test_purchase_history();
        let price = 18;
        
        // Record first purchase
        history.record_purchase(price);
        
        assert(history.purchase_count == 1, 'Should have 1 purchase');
        assert(history.total_spent == 18, 'Should have spent 18');
        assert(history.last_purchase_price == 18, 'Last price should be 18');
        
        // Record second purchase
        history.record_purchase(21);
        
        assert(history.purchase_count == 2, 'Should have 2 purchases');
        assert(history.total_spent == 39, 'Should have spent 39 total');
        assert(history.last_purchase_price == 21, 'Last price should be 21');
    }

    #[test]
    #[available_gas(200000)]
    fn test_record_multiple_purchases() {
        let mut history = create_test_purchase_history();
        
        // Record many purchases
        let prices = array![15, 18, 21, 25, 30];
        let price_span = prices.span();
        let mut total_expected = 0;
        
        let mut i = 0;
        while i < prices.len() {
            let price = *price_span.at(i);
            history.record_purchase(price);
            total_expected += price;
            i += 1;
        };
        
        assert(history.purchase_count == 5, 'Should have 5 purchases');
        assert(history.total_spent == total_expected, 'Total spent should match');
        assert(history.last_purchase_price == 30, 'Last price should be 30');
    }

    #[test]
    #[available_gas(100000)]
    fn test_get_average_price() {
        let mut history = create_test_purchase_history();
        
        // Test with no purchases
        assert(history.get_average_price() == 0, 'Average should be 0 with no purchases');
        
        // Record purchases
        history.record_purchase(15);
        assert(history.get_average_price() == 15, 'Average should be 15 with one purchase');
        
        history.record_purchase(25);
        assert(history.get_average_price() == 20, 'Average should be 20 with two purchases');
        
        history.record_purchase(30);
        assert(history.get_average_price() == 23, 'Average should be 23 with three purchases'); // (15+25+30)/3 = 23.33... truncated
    }

    #[test]
    #[available_gas(100000)]
    fn test_has_purchased() {
        let mut history = create_test_purchase_history();
        
        assert(!history.has_purchased(), 'Should not have purchased initially');
        
        history.record_purchase(15);
        assert(history.has_purchased(), 'Should have purchased after recording');
    }

    // ================================
    // Edge Case and Error Handling Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_purchase_history_overflow_protection() {
        let mut history = create_test_purchase_history();
        
        // Set high values to test overflow protection
        history.purchase_count = 0xFFFFFFF0; // Close to u32 max
        history.total_spent = 0xFFFFFFF0;
        
        // Recording purchase should handle overflow gracefully
        history.record_purchase(100);
        
        // Values should either wrap or be handled safely
        assert(history.purchase_count > 0xFFFFFFF0, 'Purchase count should increase');
    }

    #[test]
    #[available_gas(200000)]
    fn test_shop_generation_consistency() {
        let mut shop = create_test_shop();
        
        // Generate shop multiple times with same seed should not change it
        shop.generate_shop_inventory(99999);
        let first_orbs = shop.available_orbs.span();
        let first_orb = *first_orbs.at(0);
        
        // Try to generate again (should not change since already generated)
        shop.generate_shop_inventory(11111); // Different seed
        let second_orbs = shop.available_orbs.span();
        let second_orb = *second_orbs.at(0);
        
        assert(first_orb == second_orb, 'Shop should not regenerate if already generated');
    }

    // ================================
    // World Integration Tests
    // ================================

    #[test]
    #[available_gas(500000)]
    fn test_shop_world_storage() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0x789>();
        let game_id = 3;
        let level = 2;
        let mut shop = ShopTrait::create_for_level(player, game_id, level);
        shop.generate_shop_inventory(54321);
        
        // Test writing to world
        world.write_model_test(@shop);
        
        // Test reading from world
        let retrieved_shop: Shop = world.read_model((player, game_id, level));
        
        assert(retrieved_shop.player == player, 'Retrieved player mismatch');
        assert(retrieved_shop.game_id == game_id, 'Retrieved game_id mismatch');
        assert(retrieved_shop.level == level, 'Retrieved level mismatch');
        assert(retrieved_shop.shop_generated, 'Retrieved shop should be generated');
        assert(retrieved_shop.available_orbs.len() == 6, 'Retrieved shop should have 6 orbs');
    }

    #[test]
    #[available_gas(400000)]
    fn test_purchase_history_world_storage() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player = contract_address_const::<0xABC>();
        let orb_type = OrbType::EightPoints;
        let mut history = PurchaseHistoryTrait::create_new(player, orb_type);
        
        // Modify history
        history.record_purchase(30);
        history.record_purchase(36);
        
        // Write and retrieve
        world.write_model_test(@history);
        let retrieved_history: PurchaseHistory = world.read_model((player, orb_type));
        
        assert(retrieved_history.player == player, 'Retrieved player mismatch');
        assert(retrieved_history.orb_type == orb_type, 'Retrieved orb_type mismatch');
        assert(retrieved_history.purchase_count == 2, 'Retrieved purchase_count mismatch');
        assert(retrieved_history.total_spent == 66, 'Retrieved total_spent mismatch');
        assert(retrieved_history.last_purchase_price == 36, 'Retrieved last_price mismatch');
    }

    #[test]
    #[available_gas(600000)]
    fn test_multiple_shops_and_histories() {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        
        let player1 = contract_address_const::<0x111>();
        let player2 = contract_address_const::<0x222>();
        let game_id = 5;
        
        // Create shops for different levels
        let mut shop1_l1 = ShopTrait::create_for_level(player1, game_id, 1);
        let mut shop1_l2 = ShopTrait::create_for_level(player1, game_id, 2);
        let mut shop2_l1 = ShopTrait::create_for_level(player2, game_id, 1);
        
        shop1_l1.generate_shop_inventory(1111);
        shop1_l2.generate_shop_inventory(2222);
        shop2_l1.generate_shop_inventory(3333);
        
        // Create purchase histories
        let mut history1 = PurchaseHistoryTrait::create_new(player1, OrbType::SevenPoints);
        let mut history2 = PurchaseHistoryTrait::create_new(player2, OrbType::BigHealth);
        
        history1.record_purchase(15);
        history2.record_purchase(50);
        
        // Write all
        world.write_model_test(@shop1_l1);
        world.write_model_test(@shop1_l2);
        world.write_model_test(@shop2_l1);
        world.write_model_test(@history1);
        world.write_model_test(@history2);
        
        // Verify independent storage
        let retrieved_shop1_l1: Shop = world.read_model((player1, game_id, 1_u8));
        let retrieved_shop1_l2: Shop = world.read_model((player1, game_id, 2_u8));
        let retrieved_shop2_l1: Shop = world.read_model((player2, game_id, 1_u8));
        let retrieved_history1: PurchaseHistory = world.read_model((player1, OrbType::SevenPoints));
        let retrieved_history2: PurchaseHistory = world.read_model((player2, OrbType::BigHealth));
        
        assert(retrieved_shop1_l1.level == 1, 'Shop1 L1 level wrong');
        assert(retrieved_shop1_l2.level == 2, 'Shop1 L2 level wrong');
        assert(retrieved_shop2_l1.level == 1, 'Shop2 L1 level wrong');
        assert(retrieved_history1.total_spent == 15, 'History1 spent wrong');
        assert(retrieved_history2.total_spent == 50, 'History2 spent wrong');
    }
}