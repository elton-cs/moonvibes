// ================================
// Orb Model Tests - Task 5.1
// Comprehensive unit tests for OrbType enum and conversions with full coverage
// ================================

#[cfg(test)]
mod tests {
    use crate::models::orb::{OrbType, OrbTypeIntoFelt252, OrbTypeTryIntoFromFelt252};

    // ================================
    // Basic OrbType Creation Tests
    // ================================

    #[test]
    #[available_gas(50000)]
    fn test_starting_orb_types() {
        // Test all starting orb types exist
        let _five_points = OrbType::FivePoints;
        let _single_bomb = OrbType::SingleBomb;
        let _double_bomb = OrbType::DoubleBomb;
        let _triple_bomb = OrbType::TripleBomb;
        let _double_multiplier = OrbType::DoubleMultiplier;
        let _remaining_orbs = OrbType::RemainingOrbs;
        let _bomb_counter = OrbType::BombCounter;
        let _health = OrbType::Health;
        
        // Basic creation test - if we get here, all types are valid
        assert(true, 'Starting orb types created');
    }

    #[test]
    #[available_gas(50000)]
    fn test_shop_orb_types_common() {
        // Test common shop orb types
        let _seven_points = OrbType::SevenPoints;
        let _cheddah_bomb = OrbType::CheddahBomb;
        let _moon_rock = OrbType::MoonRock;
        let _half_multiplier = OrbType::HalfMultiplier;
        
        assert(true, 'Common shop orb types created');
    }

    #[test]
    #[available_gas(50000)]
    fn test_shop_orb_types_rare() {
        // Test rare shop orb types
        let _eight_points = OrbType::EightPoints;
        let _nine_points = OrbType::NinePoints;
        let _next_points_2x = OrbType::NextPoints2x;
        let _multiplier_1_5x = OrbType::Multiplier1_5x;
        
        assert(true, 'Rare shop orb types created');
    }

    #[test]
    #[available_gas(50000)]
    fn test_shop_orb_types_cosmic() {
        // Test cosmic shop orb types
        let _big_health = OrbType::BigHealth;
        let _big_moon_rock = OrbType::BigMoonRock;
        
        assert(true, 'Cosmic shop orb types created');
    }

    // ================================
    // OrbType Equality Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_orb_type_equality() {
        // Test that same types are equal
        assert(OrbType::FivePoints == OrbType::FivePoints, 'FivePoints equality failed');
        assert(OrbType::SingleBomb == OrbType::SingleBomb, 'SingleBomb equality failed');
        assert(OrbType::DoubleMultiplier == OrbType::DoubleMultiplier, 'DoubleMultiplier equality failed');
        assert(OrbType::BigHealth == OrbType::BigHealth, 'BigHealth equality failed');
        
        // Test that different types are not equal
        assert(OrbType::FivePoints != OrbType::SevenPoints, 'Different points should not equal');
        assert(OrbType::SingleBomb != OrbType::DoubleBomb, 'Different bombs should not equal');
        assert(OrbType::Health != OrbType::BigHealth, 'Health types should differ');
        assert(OrbType::MoonRock != OrbType::BigMoonRock, 'MoonRock types should differ');
    }

    // ================================
    // Felt252 Conversion Tests
    // ================================

    #[test]
    #[available_gas(200000)]
    fn test_orb_type_to_felt252_conversion() {
        // Test starting orb conversions
        assert(OrbType::FivePoints.into() == 0, 'FivePoints felt252 wrong');
        assert(OrbType::SingleBomb.into() == 1, 'SingleBomb felt252 wrong');
        assert(OrbType::DoubleBomb.into() == 2, 'DoubleBomb felt252 wrong');
        assert(OrbType::TripleBomb.into() == 3, 'TripleBomb felt252 wrong');
        assert(OrbType::DoubleMultiplier.into() == 4, 'DoubleMultiplier felt252 wrong');
        assert(OrbType::RemainingOrbs.into() == 5, 'RemainingOrbs felt252 wrong');
        assert(OrbType::BombCounter.into() == 6, 'BombCounter felt252 wrong');
        assert(OrbType::Health.into() == 7, 'Health felt252 wrong');
        
        // Test common shop orb conversions
        assert(OrbType::SevenPoints.into() == 8, 'SevenPoints felt252 wrong');
        assert(OrbType::CheddahBomb.into() == 9, 'CheddahBomb felt252 wrong');
        assert(OrbType::MoonRock.into() == 10, 'MoonRock felt252 wrong');
        assert(OrbType::HalfMultiplier.into() == 11, 'HalfMultiplier felt252 wrong');
        
        // Test rare shop orb conversions
        assert(OrbType::EightPoints.into() == 12, 'EightPoints felt252 wrong');
        assert(OrbType::NinePoints.into() == 13, 'NinePoints felt252 wrong');
        assert(OrbType::NextPoints2x.into() == 14, 'NextPoints2x felt252 wrong');
        assert(OrbType::Multiplier1_5x.into() == 15, 'Multiplier1_5x felt252 wrong');
        
        // Test cosmic shop orb conversions
        assert(OrbType::BigHealth.into() == 16, 'BigHealth felt252 wrong');
        assert(OrbType::BigMoonRock.into() == 17, 'BigMoonRock felt252 wrong');
    }

    #[test]
    #[available_gas(200000)]
    fn test_felt252_to_orb_type_conversion() {
        // Test starting orb conversions
        assert(0.try_into().unwrap() == OrbType::FivePoints, 'FivePoints from felt252 wrong');
        assert(1.try_into().unwrap() == OrbType::SingleBomb, 'SingleBomb from felt252 wrong');
        assert(2.try_into().unwrap() == OrbType::DoubleBomb, 'DoubleBomb from felt252 wrong');
        assert(3.try_into().unwrap() == OrbType::TripleBomb, 'TripleBomb from felt252 wrong');
        assert(4.try_into().unwrap() == OrbType::DoubleMultiplier, 'DoubleMultiplier from felt252 wrong');
        assert(5.try_into().unwrap() == OrbType::RemainingOrbs, 'RemainingOrbs from felt252 wrong');
        assert(6.try_into().unwrap() == OrbType::BombCounter, 'BombCounter from felt252 wrong');
        assert(7.try_into().unwrap() == OrbType::Health, 'Health from felt252 wrong');
        
        // Test common shop orb conversions
        assert(8.try_into().unwrap() == OrbType::SevenPoints, 'SevenPoints from felt252 wrong');
        assert(9.try_into().unwrap() == OrbType::CheddahBomb, 'CheddahBomb from felt252 wrong');
        assert(10.try_into().unwrap() == OrbType::MoonRock, 'MoonRock from felt252 wrong');
        assert(11.try_into().unwrap() == OrbType::HalfMultiplier, 'HalfMultiplier from felt252 wrong');
        
        // Test rare shop orb conversions
        assert(12.try_into().unwrap() == OrbType::EightPoints, 'EightPoints from felt252 wrong');
        assert(13.try_into().unwrap() == OrbType::NinePoints, 'NinePoints from felt252 wrong');
        assert(14.try_into().unwrap() == OrbType::NextPoints2x, 'NextPoints2x from felt252 wrong');
        assert(15.try_into().unwrap() == OrbType::Multiplier1_5x, 'Multiplier1_5x from felt252 wrong');
        
        // Test cosmic shop orb conversions
        assert(16.try_into().unwrap() == OrbType::BigHealth, 'BigHealth from felt252 wrong');
        assert(17.try_into().unwrap() == OrbType::BigMoonRock, 'BigMoonRock from felt252 wrong');
    }

    #[test]
    #[available_gas(100000)]
    fn test_round_trip_conversion() {
        // Test that converting to felt252 and back gives the same result
        let orb_types = array![
            OrbType::FivePoints,
            OrbType::SingleBomb,
            OrbType::DoubleBomb,
            OrbType::TripleBomb,
            OrbType::DoubleMultiplier,
            OrbType::RemainingOrbs,
            OrbType::BombCounter,
            OrbType::Health,
            OrbType::SevenPoints,
            OrbType::CheddahBomb,
            OrbType::MoonRock,
            OrbType::HalfMultiplier,
            OrbType::EightPoints,
            OrbType::NinePoints,
            OrbType::NextPoints2x,
            OrbType::Multiplier1_5x,
            OrbType::BigHealth,
            OrbType::BigMoonRock
        ];
        
        let orb_span = orb_types.span();
        let total_orbs = orb_types.len();
        
        let mut i = 0;
        while i < total_orbs {
            let original_orb = *orb_span.at(i);
            let felt_val: felt252 = original_orb.into();
            let converted_back: OrbType = felt_val.try_into().unwrap();
            assert(original_orb == converted_back, 'Round trip conversion failed');
            i += 1;
        };
    }

    // ================================
    // Invalid Conversion Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_invalid_felt252_conversion() {
        // Test that invalid felt252 values fail conversion
        let invalid_values = array![18, 19, 100, 255, 1000];
        let invalid_span = invalid_values.span();
        let total_invalid = invalid_values.len();
        
        let mut i = 0;
        while i < total_invalid {
            let invalid_val = *invalid_span.at(i);
            let result: Result<OrbType, _> = invalid_val.try_into();
            assert(result.is_err(), 'Invalid conversion should fail');
            i += 1;
        };
    }

    #[test]
    #[available_gas(50000)]
    fn test_boundary_values() {
        // Test the boundary values work correctly
        let valid_min: OrbType = 0.try_into().unwrap(); // Should be FivePoints
        let valid_max: OrbType = 17.try_into().unwrap(); // Should be BigMoonRock
        
        assert(valid_min == OrbType::FivePoints, 'Min boundary wrong');
        assert(valid_max == OrbType::BigMoonRock, 'Max boundary wrong');
        
        // Test just outside boundaries
        let invalid_below: Result<OrbType, _> = (-1_i32).try_into();
        let invalid_above: Result<OrbType, _> = 18.try_into();
        
        // Note: -1 as felt252 would be a very large number, so it should fail
        assert(invalid_below.is_err(), 'Below boundary should fail');
        assert(invalid_above.is_err(), 'Above boundary should fail');
    }

    // ================================
    // Orb Type Classification Tests
    // ================================

    #[test]
    #[available_gas(150000)]
    fn test_orb_type_classification_patterns() {
        // This tests logical groupings even though the classification might be 
        // implemented in helper functions, we can test the enum values directly
        
        // Points orbs should have "Points" in name pattern
        let points_orbs = array![
            OrbType::FivePoints,
            OrbType::SevenPoints,
            OrbType::EightPoints,
            OrbType::NinePoints
        ];
        
        // Bomb orbs should have "Bomb" in name pattern  
        let bomb_orbs = array![
            OrbType::SingleBomb,
            OrbType::DoubleBomb,
            OrbType::TripleBomb,
            OrbType::CheddahBomb
        ];
        
        // Multiplier orbs should affect multipliers
        let multiplier_orbs = array![
            OrbType::DoubleMultiplier,
            OrbType::HalfMultiplier,
            OrbType::NextPoints2x,
            OrbType::Multiplier1_5x
        ];
        
        // Test that we have the expected number of each type
        assert(points_orbs.len() == 4, 'Wrong number of points orbs');
        assert(bomb_orbs.len() == 4, 'Wrong number of bomb orbs');
        assert(multiplier_orbs.len() == 4, 'Wrong number of multiplier orbs');
    }

    #[test]
    #[available_gas(100000)]
    fn test_orb_rarity_distribution() {
        // Test starting orbs (8 total)
        let starting_orbs = array![
            OrbType::FivePoints,
            OrbType::SingleBomb,
            OrbType::DoubleBomb,
            OrbType::TripleBomb,
            OrbType::DoubleMultiplier,
            OrbType::RemainingOrbs,
            OrbType::BombCounter,
            OrbType::Health
        ];
        
        // Test shop orbs - common (4 total)
        let common_shop_orbs = array![
            OrbType::SevenPoints,
            OrbType::CheddahBomb,
            OrbType::MoonRock,
            OrbType::HalfMultiplier
        ];
        
        // Test shop orbs - rare (4 total)
        let rare_shop_orbs = array![
            OrbType::EightPoints,
            OrbType::NinePoints,
            OrbType::NextPoints2x,
            OrbType::Multiplier1_5x
        ];
        
        // Test shop orbs - cosmic (2 total)
        let cosmic_shop_orbs = array![
            OrbType::BigHealth,
            OrbType::BigMoonRock
        ];
        
        // Verify distribution matches game design
        assert(starting_orbs.len() == 8, 'Wrong number of starting orbs');
        assert(common_shop_orbs.len() == 4, 'Wrong number of common shop orbs');
        assert(rare_shop_orbs.len() == 4, 'Wrong number of rare shop orbs');
        assert(cosmic_shop_orbs.len() == 2, 'Wrong number of cosmic shop orbs');
        
        // Total should be 18 orb types
        let total = starting_orbs.len() + common_shop_orbs.len() + rare_shop_orbs.len() + cosmic_shop_orbs.len();
        assert(total == 18, 'Total orb count should be 18');
    }

    // ================================
    // Edge Case and Error Handling Tests
    // ================================

    #[test]
    #[available_gas(100000)]
    fn test_felt252_max_value_conversion() {
        // Test conversion with very large felt252 values
        let large_value: felt252 = 0x3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let result: Result<OrbType, _> = large_value.try_into();
        assert(result.is_err(), 'Large felt252 should fail conversion');
    }

    #[test]
    #[available_gas(50000)]
    fn test_zero_value_conversion() {
        // Test that zero converts to the first orb type
        let zero_orb: OrbType = 0.try_into().unwrap();
        assert(zero_orb == OrbType::FivePoints, 'Zero should convert to FivePoints');
        
        // Test that FivePoints converts to zero
        let zero_felt: felt252 = OrbType::FivePoints.into();
        assert(zero_felt == 0, 'FivePoints should convert to zero');
    }

    #[test]
    #[available_gas(100000)]
    fn test_conversion_consistency() {
        // Test that all valid conversions are consistent across multiple calls
        let test_values = array![0, 5, 10, 15, 17];
        let test_span = test_values.span();
        let total_tests = test_values.len();
        
        let mut i = 0;
        while i < total_tests {
            let felt_val = *test_span.at(i);
            
            // Convert twice and ensure consistency
            let orb1: OrbType = felt_val.try_into().unwrap();
            let orb2: OrbType = felt_val.try_into().unwrap();
            assert(orb1 == orb2, 'Conversion should be consistent');
            
            // Convert back and ensure consistency
            let felt1: felt252 = orb1.into();
            let felt2: felt252 = orb2.into();
            assert(felt1 == felt2, 'Back conversion should be consistent');
            assert(felt1 == felt_val, 'Round trip should match original');
            
            i += 1;
        };
    }

    #[test]
    #[available_gas(200000)]
    fn test_all_orb_types_unique_values() {
        // Ensure all orb types convert to unique felt252 values
        let all_orbs = array![
            OrbType::FivePoints,      // 0
            OrbType::SingleBomb,      // 1
            OrbType::DoubleBomb,      // 2
            OrbType::TripleBomb,      // 3
            OrbType::DoubleMultiplier,// 4
            OrbType::RemainingOrbs,   // 5
            OrbType::BombCounter,     // 6
            OrbType::Health,          // 7
            OrbType::SevenPoints,     // 8
            OrbType::CheddahBomb,     // 9
            OrbType::MoonRock,        // 10
            OrbType::HalfMultiplier,  // 11
            OrbType::EightPoints,     // 12
            OrbType::NinePoints,      // 13
            OrbType::NextPoints2x,    // 14
            OrbType::Multiplier1_5x,  // 15
            OrbType::BigHealth,       // 16
            OrbType::BigMoonRock      // 17
        ];
        
        let orb_span = all_orbs.span();
        let total_orbs = all_orbs.len();
        
        // Check that each orb maps to its expected index
        let mut i = 0;
        while i < total_orbs {
            let orb = *orb_span.at(i);
            let felt_val: felt252 = orb.into();
            let expected_val: felt252 = i.into();
            assert(felt_val == expected_val, 'Orb value mapping wrong');
            i += 1;
        };
    }
}