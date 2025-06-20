// ================================
// Orb Effects Helper - Task 4.1
// Comprehensive orb effect processing utilities with proper multiplier handling
// ================================

use crate::models::orb::OrbType;
use crate::models::player_stats::PlayerStats;
use crate::models::bag::Bag;
use crate::models::game_state::GameState;

// ================================
// Core Multiplier Functions
// ================================

/// Apply multiplier calculation with proper rounding (always rounds up)
/// Multiplier is stored as fixed point: 100 = 1.0x, 150 = 1.5x, 200 = 2.0x
pub fn apply_points_with_multiplier(base_points: u32, multiplier: u32) -> u32 {
    // Always round up: (base_points * multiplier + 99) / 100
    (base_points * multiplier + 99) / 100
}

/// Validate multiplier is within reasonable bounds (0.1x to 10.0x)
pub fn validate_multiplier(multiplier: u32) -> bool {
    multiplier >= 10 && multiplier <= 1000 // 0.1x to 10.0x
}

/// Apply multiplier change to current multiplier (compound multiplication)
pub fn apply_multiplier_change(current_multiplier: u32, multiplier_change: u32) -> u32 {
    let new_multiplier = (current_multiplier * multiplier_change) / 100;
    
    // Bounds checking - clamp between 0.1x and 10.0x
    if new_multiplier < 10 {
        10 // Minimum 0.1x
    } else if new_multiplier > 1000 {
        1000 // Maximum 10.0x
    } else {
        new_multiplier
    }
}

// ================================
// Health Modification Functions
// ================================

/// Apply health change with proper bounds checking (prevents overflow/underflow)
pub fn apply_health_change(current_health: u8, change: i8) -> u8 {
    if change > 0 {
        let positive_change: u8 = change.try_into().unwrap_or(0);
        // Prevent overflow (max health is 255)
        if current_health > 255 - positive_change {
            255
        } else {
            current_health + positive_change
        }
    } else {
        let negative_change: u8 = (-change).try_into().unwrap_or(0);
        // Prevent underflow (min health is 0)
        if current_health < negative_change {
            0
        } else {
            current_health - negative_change
        }
    }
}

/// Check if health change would be fatal
pub fn would_health_change_be_fatal(current_health: u8, change: i8) -> bool {
    if change >= 0 {
        false // Positive changes can't be fatal
    } else {
        let damage: u8 = (-change).try_into().unwrap_or(0);
        current_health <= damage
    }
}

/// Get maximum safe health increase (to prevent overflow)
pub fn get_max_health_increase(current_health: u8) -> u8 {
    255 - current_health
}

// ================================
// Currency Effect Processing
// ================================

/// Apply moon rocks change with overflow protection
pub fn apply_moon_rocks_change(current_moon_rocks: u32, change: i32) -> u32 {
    if change >= 0 {
        let increase: u32 = change.try_into().unwrap_or(0);
        if current_moon_rocks > 0xFFFFFFFF - increase { 0xFFFFFFFF } else { current_moon_rocks + increase }
    } else {
        let decrease: u32 = (-change).try_into().unwrap_or(0);
        if current_moon_rocks < decrease { 0 } else { current_moon_rocks - decrease }
    }
}

/// Apply cheddah change with overflow protection
pub fn apply_cheddah_change(current_cheddah: u32, change: i32) -> u32 {
    if change >= 0 {
        let increase: u32 = change.try_into().unwrap_or(0);
        if current_cheddah > 0xFFFFFFFF - increase { 0xFFFFFFFF } else { current_cheddah + increase }
    } else {
        let decrease: u32 = (-change).try_into().unwrap_or(0);
        if current_cheddah < decrease { 0 } else { current_cheddah - decrease }
    }
}

/// Apply points change with overflow protection
pub fn apply_points_change(current_points: u32, change: i32) -> u32 {
    if change >= 0 {
        let increase: u32 = change.try_into().unwrap_or(0);
        if current_points > 0xFFFFFFFF - increase { 0xFFFFFFFF } else { current_points + increase }
    } else {
        let decrease: u32 = (-change).try_into().unwrap_or(0);
        if current_points < decrease { 0 } else { current_points - decrease }
    }
}

// ================================
// Special Orb Mechanics
// ================================

/// Process RemainingOrbs effect (points = orbs left in bag)
pub fn process_remaining_orbs_effect(bag: @Bag, multiplier: u32) -> u32 {
    let remaining_count = *bag.total_orbs;
    apply_points_with_multiplier(remaining_count, multiplier)
}

/// Process BombCounter effect (points = bombs pulled this level)
pub fn process_bomb_counter_effect(game_state: @GameState, multiplier: u32) -> u32 {
    let bomb_count: u32 = (*game_state.bombs_pulled_this_level).into();
    apply_points_with_multiplier(bomb_count, multiplier)
}

/// Process NextPoints2x effect (temporary 2x multiplier for next points orb only)
/// Note: This requires special state tracking in the actual game implementation
pub fn calculate_next_points_2x_multiplier(current_multiplier: u32) -> u32 {
    // Apply temporary 2x to current multiplier
    apply_multiplier_change(current_multiplier, 200) // 2.0x
}

// ================================
// Effect Validation and Bounds Checking
// ================================

/// Validate orb effect parameters are within safe bounds
pub fn validate_orb_effect_params(
    base_points: u32, 
    multiplier: u32, 
    health_change: i8
) -> bool {
    // Check points are reasonable (max 1000 base points)
    if base_points > 1000 {
        return false;
    }
    
    // Check multiplier is within bounds
    if !validate_multiplier(multiplier) {
        return false;
    }
    
    // Check health change is reasonable (max ±50 health)
    let abs_health_change: u8 = if health_change >= 0 {
        health_change.try_into().unwrap_or(255)
    } else {
        (-health_change).try_into().unwrap_or(255)
    };
    
    if abs_health_change > 50 {
        return false;
    }
    
    true
}

/// Check if effect combination would cause overflow
pub fn check_effect_overflow_safety(
    current_points: u32,
    points_to_add: u32,
    current_moon_rocks: u32,
    moon_rocks_to_add: u32,
    current_cheddah: u32,
    cheddah_to_add: u32
) -> bool {
    // Check points overflow
    if current_points > 0xFFFFFFFF - points_to_add {
        return false;
    }
    
    // Check moon rocks overflow
    if current_moon_rocks > 0xFFFFFFFF - moon_rocks_to_add {
        return false;
    }
    
    // Check cheddah overflow
    if current_cheddah > 0xFFFFFFFF - cheddah_to_add {
        return false;
    }
    
    true
}

// ================================
// Comprehensive Orb Effect Processor
// ================================

/// Complete orb effect processing for all 25 orb types
/// Returns (points_gained, health_change, moon_rocks_change, cheddah_change, new_multiplier)
pub fn process_complete_orb_effect(
    orb_type: OrbType,
    current_stats: @PlayerStats,
    game_state: @GameState,
    bag: @Bag
) -> (u32, i8, i32, i32, u32) {
    let mut points_gained: u32 = 0;
    let mut health_change: i8 = 0;
    let mut moon_rocks_change: i32 = 0;
    let mut cheddah_change: i32 = 0;
    let mut new_multiplier = *current_stats.multiplier;
    
    match orb_type {
        // Starting Orbs - Points
        OrbType::FivePoints => {
            points_gained = apply_points_with_multiplier(5, *current_stats.multiplier);
        },
        
        // Starting Orbs - Bombs
        OrbType::SingleBomb => {
            health_change = -1;
        },
        OrbType::DoubleBomb => {
            health_change = -2;
        },
        OrbType::TripleBomb => {
            health_change = -3;
        },
        
        // Starting Orbs - Multipliers
        OrbType::DoubleMultiplier => {
            new_multiplier = apply_multiplier_change(*current_stats.multiplier, 200); // 2.0x
        },
        
        // Starting Orbs - Special
        OrbType::RemainingOrbs => {
            points_gained = process_remaining_orbs_effect(bag, *current_stats.multiplier);
        },
        OrbType::BombCounter => {
            points_gained = process_bomb_counter_effect(game_state, *current_stats.multiplier);
        },
        OrbType::Health => {
            health_change = 1;
        },
        
        // Shop Orbs - Common Points
        OrbType::SevenPoints => {
            points_gained = apply_points_with_multiplier(7, *current_stats.multiplier);
        },
        
        // Shop Orbs - Common Special
        OrbType::CheddahBomb => {
            health_change = -1;
            cheddah_change = 10; // Gives cheddah despite being a bomb
        },
        OrbType::MoonRock => {
            moon_rocks_change = 2;
        },
        OrbType::HalfMultiplier => {
            new_multiplier = apply_multiplier_change(*current_stats.multiplier, 50); // 0.5x
        },
        
        // Shop Orbs - Rare Points
        OrbType::EightPoints => {
            points_gained = apply_points_with_multiplier(8, *current_stats.multiplier);
        },
        OrbType::NinePoints => {
            points_gained = apply_points_with_multiplier(9, *current_stats.multiplier);
        },
        
        // Shop Orbs - Rare Special
        OrbType::NextPoints2x => {
            // Apply temporary 2x multiplier effect
            new_multiplier = calculate_next_points_2x_multiplier(*current_stats.multiplier);
        },
        OrbType::Multiplier1_5x => {
            new_multiplier = apply_multiplier_change(*current_stats.multiplier, 150); // 1.5x
        },
        
        // Shop Orbs - Cosmic
        OrbType::BigHealth => {
            health_change = 3;
        },
        OrbType::BigMoonRock => {
            moon_rocks_change = 10;
        },
    }
    
    (points_gained, health_change, moon_rocks_change, cheddah_change, new_multiplier)
}

// ================================
// Utility Functions
// ================================

/// Check if orb type is a bomb
pub fn is_bomb_orb(orb_type: OrbType) -> bool {
    match orb_type {
        OrbType::SingleBomb | OrbType::DoubleBomb | OrbType::TripleBomb | OrbType::CheddahBomb => true,
        _ => false,
    }
}

/// Check if orb type gives points
pub fn is_points_orb(orb_type: OrbType) -> bool {
    match orb_type {
        OrbType::FivePoints | OrbType::SevenPoints | OrbType::EightPoints | OrbType::NinePoints |
        OrbType::RemainingOrbs | OrbType::BombCounter => true,
        _ => false,
    }
}

/// Check if orb type affects multiplier
pub fn is_multiplier_orb(orb_type: OrbType) -> bool {
    match orb_type {
        OrbType::DoubleMultiplier | OrbType::HalfMultiplier | OrbType::NextPoints2x | OrbType::Multiplier1_5x => true,
        _ => false,
    }
}

/// Get orb effect category for analysis
pub fn get_orb_effect_category(orb_type: OrbType) -> felt252 {
    if is_bomb_orb(orb_type) {
        'bomb'
    } else if is_points_orb(orb_type) {
        'points'
    } else if is_multiplier_orb(orb_type) {
        'multiplier'
    } else {
        'utility'
    }
}