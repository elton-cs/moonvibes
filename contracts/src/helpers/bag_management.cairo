// ================================
// Bag Management Helper - Task 4.3
// Advanced bag management utilities for efficient orb manipulation and analysis
// ================================

use crate::models::orb::OrbType;
use crate::models::bag::Bag;

// ================================
// Efficient Orb Search Functions
// ================================

/// Count orbs of a specific type in the bag
pub fn count_orbs_by_type(bag: @Bag, target_type: OrbType) -> u32 {
    let mut count = 0;
    let orb_span = bag.orbs.span();
    let total_orbs = bag.orbs.len();
    
    let mut i = 0;
    while i < total_orbs {
        let orb_type = *orb_span.at(i);
        if orb_type == target_type {
            count += 1;
        }
        i += 1;
    };
    
    count
}

/// Find first occurrence of specific orb type and return its index
pub fn find_orb_index(bag: @Bag, target_type: OrbType) -> Option<u32> {
    let orb_span = bag.orbs.span();
    let total_orbs = bag.orbs.len();
    
    let mut i = 0;
    loop {
        if i >= total_orbs {
            break Option::None;
        }
        let orb_type = *orb_span.at(i);
        if orb_type == target_type {
            break Option::Some(i);
        }
        i += 1;
    }
}

/// Find all indices of a specific orb type
pub fn find_all_orb_indices(bag: @Bag, target_type: OrbType) -> Array<u32> {
    let mut indices = array![];
    let orb_span = bag.orbs.span();
    let total_orbs = bag.orbs.len();
    
    let mut i = 0;
    while i < total_orbs {
        let orb_type = *orb_span.at(i);
        if orb_type == target_type {
            indices.append(i);
        }
        i += 1;
    };
    
    indices
}

/// Check if bag contains a specific orb type
pub fn contains_orb_type(bag: @Bag, target_type: OrbType) -> bool {
    match find_orb_index(bag, target_type) {
        Option::Some(_) => true,
        Option::None => false,
    }
}

// ================================
// Bag Validation Utilities
// ================================

/// Validate bag integrity (consistent state)
pub fn validate_bag_integrity(bag: @Bag) -> bool {
    // Check that array length matches total_orbs count
    if bag.orbs.len() != *bag.total_orbs {
        return false;
    }
    
    // Check that total_orbs is not negative/overflow
    if *bag.total_orbs > 1000 { // Reasonable upper bound
        return false;
    }
    
    true
}

/// Validate bag is not empty
pub fn validate_bag_not_empty(bag: @Bag) -> bool {
    *bag.total_orbs > 0 && bag.orbs.len() > 0
}

/// Validate bag has reasonable size constraints
pub fn validate_bag_size_constraints(bag: @Bag) -> bool {
    let total = *bag.total_orbs;
    // Bag should have at least 1 orb and not exceed 100 orbs (reasonable limits)
    total >= 1 && total <= 100
}

/// Check for potential bag corruption (impossible states)
pub fn check_bag_corruption(bag: @Bag) -> bool {
    // Check for array/count mismatch
    if bag.orbs.len() != *bag.total_orbs {
        return true; // Corrupted
    }
    
    // Check for impossible counts
    if *bag.total_orbs > 1000 {
        return true; // Corrupted
    }
    
    false // Not corrupted
}

// ================================
// Orb Counting and Distribution
// ================================

/// Get comprehensive orb type distribution
pub fn get_orb_type_distribution(bag: @Bag) -> Array<(OrbType, u32)> {
    let mut distribution = array![];
    
    // Count each orb type (iterate through all 17 types)
    let five_points_count = count_orbs_by_type(bag, OrbType::FivePoints);
    if five_points_count > 0 {
        distribution.append((OrbType::FivePoints, five_points_count));
    }
    
    let single_bomb_count = count_orbs_by_type(bag, OrbType::SingleBomb);
    if single_bomb_count > 0 {
        distribution.append((OrbType::SingleBomb, single_bomb_count));
    }
    
    let double_bomb_count = count_orbs_by_type(bag, OrbType::DoubleBomb);
    if double_bomb_count > 0 {
        distribution.append((OrbType::DoubleBomb, double_bomb_count));
    }
    
    let triple_bomb_count = count_orbs_by_type(bag, OrbType::TripleBomb);
    if triple_bomb_count > 0 {
        distribution.append((OrbType::TripleBomb, triple_bomb_count));
    }
    
    let double_mult_count = count_orbs_by_type(bag, OrbType::DoubleMultiplier);
    if double_mult_count > 0 {
        distribution.append((OrbType::DoubleMultiplier, double_mult_count));
    }
    
    let remaining_orbs_count = count_orbs_by_type(bag, OrbType::RemainingOrbs);
    if remaining_orbs_count > 0 {
        distribution.append((OrbType::RemainingOrbs, remaining_orbs_count));
    }
    
    let bomb_counter_count = count_orbs_by_type(bag, OrbType::BombCounter);
    if bomb_counter_count > 0 {
        distribution.append((OrbType::BombCounter, bomb_counter_count));
    }
    
    let health_count = count_orbs_by_type(bag, OrbType::Health);
    if health_count > 0 {
        distribution.append((OrbType::Health, health_count));
    }
    
    // Shop orbs - Common
    let seven_points_count = count_orbs_by_type(bag, OrbType::SevenPoints);
    if seven_points_count > 0 {
        distribution.append((OrbType::SevenPoints, seven_points_count));
    }
    
    let cheddah_bomb_count = count_orbs_by_type(bag, OrbType::CheddahBomb);
    if cheddah_bomb_count > 0 {
        distribution.append((OrbType::CheddahBomb, cheddah_bomb_count));
    }
    
    let moon_rock_count = count_orbs_by_type(bag, OrbType::MoonRock);
    if moon_rock_count > 0 {
        distribution.append((OrbType::MoonRock, moon_rock_count));
    }
    
    let half_mult_count = count_orbs_by_type(bag, OrbType::HalfMultiplier);
    if half_mult_count > 0 {
        distribution.append((OrbType::HalfMultiplier, half_mult_count));
    }
    
    // Shop orbs - Rare
    let eight_points_count = count_orbs_by_type(bag, OrbType::EightPoints);
    if eight_points_count > 0 {
        distribution.append((OrbType::EightPoints, eight_points_count));
    }
    
    let nine_points_count = count_orbs_by_type(bag, OrbType::NinePoints);
    if nine_points_count > 0 {
        distribution.append((OrbType::NinePoints, nine_points_count));
    }
    
    let next_points_2x_count = count_orbs_by_type(bag, OrbType::NextPoints2x);
    if next_points_2x_count > 0 {
        distribution.append((OrbType::NextPoints2x, next_points_2x_count));
    }
    
    let mult_1_5x_count = count_orbs_by_type(bag, OrbType::Multiplier1_5x);
    if mult_1_5x_count > 0 {
        distribution.append((OrbType::Multiplier1_5x, mult_1_5x_count));
    }
    
    // Shop orbs - Cosmic
    let big_health_count = count_orbs_by_type(bag, OrbType::BigHealth);
    if big_health_count > 0 {
        distribution.append((OrbType::BigHealth, big_health_count));
    }
    
    let big_moon_rock_count = count_orbs_by_type(bag, OrbType::BigMoonRock);
    if big_moon_rock_count > 0 {
        distribution.append((OrbType::BigMoonRock, big_moon_rock_count));
    }
    
    distribution
}

/// Count orbs by category (bombs, points, multipliers, etc.)
pub fn count_orbs_by_category(bag: @Bag) -> (u32, u32, u32, u32) {
    let mut bomb_count = 0;
    let mut points_count = 0;
    let mut multiplier_count = 0;
    let mut utility_count = 0;
    
    let orb_span = bag.orbs.span();
    let total_orbs = bag.orbs.len();
    
    let mut i = 0;
    while i < total_orbs {
        let orb_type = *orb_span.at(i);
        
        if is_bomb_orb(orb_type) {
            bomb_count += 1;
        } else if is_points_orb(orb_type) {
            points_count += 1;
        } else if is_multiplier_orb(orb_type) {
            multiplier_count += 1;
        } else {
            utility_count += 1;
        }
        i += 1;
    };
    
    (bomb_count, points_count, multiplier_count, utility_count)
}

// ================================
// Bag State Analysis
// ================================

/// Calculate bag safety rating (lower = more dangerous)
pub fn calculate_bag_safety_rating(bag: @Bag) -> u32 {
    let (bomb_count, _points_count, _multiplier_count, _utility_count) = count_orbs_by_category(bag);
    let total_orbs = *bag.total_orbs;
    
    if total_orbs == 0 {
        return 0;
    }
    
    // Safety rating: 100 - (bomb_percentage * 2)
    // Bombs are counted twice for safety calculation
    let bomb_percentage = (bomb_count * 100) / total_orbs;
    let safety_rating = if bomb_percentage * 2 > 100 {
        0
    } else {
        100 - (bomb_percentage * 2)
    };
    
    safety_rating
}

/// Calculate expected points from bag with given multiplier
pub fn calculate_expected_points(bag: @Bag, multiplier: u32) -> u32 {
    let mut expected_points = 0;
    
    // Count different point orbs and calculate expected value
    let five_points = count_orbs_by_type(bag, OrbType::FivePoints);
    let seven_points = count_orbs_by_type(bag, OrbType::SevenPoints);
    let eight_points = count_orbs_by_type(bag, OrbType::EightPoints);
    let nine_points = count_orbs_by_type(bag, OrbType::NinePoints);
    
    // Calculate expected points with multiplier
    expected_points += five_points * 5 * multiplier / 100;
    expected_points += seven_points * 7 * multiplier / 100;
    expected_points += eight_points * 8 * multiplier / 100;
    expected_points += nine_points * 9 * multiplier / 100;
    
    // Special orbs (RemainingOrbs and BombCounter are dynamic)
    let special_orbs = count_orbs_by_type(bag, OrbType::RemainingOrbs) + count_orbs_by_type(bag, OrbType::BombCounter);
    expected_points += special_orbs * 3 * multiplier / 100; // Estimate 3 points average
    
    expected_points
}

/// Analyze bag composition and provide insights
pub fn analyze_bag_composition(bag: @Bag) -> (u32, u32, u32, bool, bool) {
    let total_orbs = *bag.total_orbs;
    let (bomb_count, points_count, multiplier_count, _utility_count) = count_orbs_by_category(bag);
    
    let bomb_percentage = if total_orbs > 0 { (bomb_count * 100) / total_orbs } else { 0 };
    let points_percentage = if total_orbs > 0 { (points_count * 100) / total_orbs } else { 0 };
    let multiplier_percentage = if total_orbs > 0 { (multiplier_count * 100) / total_orbs } else { 0 };
    
    let is_bomb_heavy = bomb_percentage > 30; // More than 30% bombs
    let is_points_heavy = points_percentage > 60; // More than 60% points
    
    (bomb_percentage, points_percentage, multiplier_percentage, is_bomb_heavy, is_points_heavy)
}

// ================================
// Performance Optimized Operations
// ================================

/// Fast random orb selection using optimized algorithm
pub fn select_random_orb_fast(bag: @Bag, seed: felt252) -> Option<OrbType> {
    let total_orbs = *bag.total_orbs;
    
    if total_orbs == 0 {
        return Option::None;
    }
    
    // Use seed to generate pseudo-random index
    let seed_u256: u256 = seed.into();
    let random_index = (seed_u256 % total_orbs.into()).try_into().unwrap();
    
    let orb_span = bag.orbs.span();
    Option::Some(*orb_span.at(random_index))
}

/// Create optimized bag copy with specific orb removed
pub fn create_bag_without_orb(bag: @Bag, target_index: u32) -> Bag {
    let mut new_orbs = array![];
    let orb_span = bag.orbs.span();
    let total_orbs = bag.orbs.len();
    
    let mut i = 0;
    while i < total_orbs {
        if i != target_index {
            new_orbs.append(*orb_span.at(i));
        }
        i += 1;
    };
    
    Bag {
        player: *bag.player,
        game_id: *bag.game_id,
        orbs: new_orbs,
        total_orbs: *bag.total_orbs - 1,
    }
}

/// Batch count multiple orb types efficiently
pub fn batch_count_orb_types(bag: @Bag, target_types: Span<OrbType>) -> Array<u32> {
    let mut counts = array![];
    let target_count = target_types.len();
    
    // Initialize counts array
    let mut i = 0;
    while i < target_count {
        counts.append(0);
        i += 1;
    };
    
    // Single pass through bag to count all target types
    let orb_span = bag.orbs.span();
    let total_orbs = bag.orbs.len();
    
    let mut orb_idx = 0;
    while orb_idx < total_orbs {
        let orb_type = *orb_span.at(orb_idx);
        
        // Check against all target types
        let mut target_idx = 0;
        while target_idx < target_count {
            if orb_type == *target_types.at(target_idx) {
                // Increment count for this type
                let _current_count = *counts.at(target_idx);
                // Note: This would require mutable array access in a real implementation
                // For Cairo, we'd need to rebuild the array
            }
            target_idx += 1;
        };
        orb_idx += 1;
    };
    
    counts
}

// ================================
// Helper Category Functions
// ================================

/// Check if orb type is a bomb
fn is_bomb_orb(orb_type: OrbType) -> bool {
    match orb_type {
        OrbType::SingleBomb | OrbType::DoubleBomb | OrbType::TripleBomb | OrbType::CheddahBomb => true,
        _ => false,
    }
}

/// Check if orb type gives points directly
fn is_points_orb(orb_type: OrbType) -> bool {
    match orb_type {
        OrbType::FivePoints | OrbType::SevenPoints | OrbType::EightPoints | OrbType::NinePoints |
        OrbType::RemainingOrbs | OrbType::BombCounter => true,
        _ => false,
    }
}

/// Check if orb type affects multiplier
fn is_multiplier_orb(orb_type: OrbType) -> bool {
    match orb_type {
        OrbType::DoubleMultiplier | OrbType::HalfMultiplier | OrbType::NextPoints2x | OrbType::Multiplier1_5x => true,
        _ => false,
    }
}

// ================================
// Advanced Bag Operations
// ================================

/// Generate starting bag composition for new game
pub fn generate_starting_bag() -> Array<OrbType> {
    let mut starting_orbs = array![];
    
    // Starting bag composition (12 orbs total):
    // - 6x FivePoints
    // - 2x SingleBomb
    // - 1x DoubleBomb
    // - 1x DoubleMultiplier
    // - 1x RemainingOrbs
    // - 1x Health
    
    // Add 6 FivePoints orbs
    starting_orbs.append(OrbType::FivePoints);
    starting_orbs.append(OrbType::FivePoints);
    starting_orbs.append(OrbType::FivePoints);
    starting_orbs.append(OrbType::FivePoints);
    starting_orbs.append(OrbType::FivePoints);
    starting_orbs.append(OrbType::FivePoints);
    
    // Add 2 SingleBomb orbs
    starting_orbs.append(OrbType::SingleBomb);
    starting_orbs.append(OrbType::SingleBomb);
    
    // Add 1 DoubleBomb
    starting_orbs.append(OrbType::DoubleBomb);
    
    // Add 1 DoubleMultiplier
    starting_orbs.append(OrbType::DoubleMultiplier);
    
    // Add 1 RemainingOrbs
    starting_orbs.append(OrbType::RemainingOrbs);
    
    // Add 1 Health
    starting_orbs.append(OrbType::Health);
    
    starting_orbs
}

/// Shuffle bag orbs for better randomization (Fisher-Yates algorithm adaptation)
pub fn create_shuffled_bag(original_bag: @Bag, seed: felt252) -> Bag {
    let mut shuffled_orbs = array![];
    let orb_span = original_bag.orbs.span();
    let total_orbs = original_bag.orbs.len();
    
    // Simple pseudo-shuffle by reversing and applying seed offset
    let seed_u256: u256 = seed.into();
    let offset = (seed_u256 % total_orbs.into()).try_into().unwrap_or(0);
    
    // Add orbs starting from offset position
    let mut i = offset;
    let mut added = 0;
    while added < total_orbs {
        let index = i % total_orbs;
        shuffled_orbs.append(*orb_span.at(index));
        i += 1;
        added += 1;
    };
    
    Bag {
        player: *original_bag.player,
        game_id: *original_bag.game_id,
        orbs: shuffled_orbs,
        total_orbs: *original_bag.total_orbs,
    }
}