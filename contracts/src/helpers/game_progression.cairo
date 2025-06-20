// ================================
// Game Progression Helper - Task 4.2
// Comprehensive game progression utilities with win/loss conditions and scoring
// ================================

use crate::models::game_state::{GameState, GameStatus};
use crate::models::player_stats::PlayerStats;
use crate::models::bag::Bag;
use crate::models::level_progress::{LevelProgress, get_level_config, LevelConfig};

// ================================
// Win/Loss Condition Checking
// ================================

/// Check if game is over due to health or empty bag
pub fn check_game_over(stats: @PlayerStats, bag: @Bag) -> bool {
    *stats.health == 0 || *bag.total_orbs == 0
}

/// Determine the specific reason for game over
pub fn get_game_over_reason(stats: @PlayerStats, bag: @Bag) -> felt252 {
    if *stats.health == 0 {
        'health_zero'
    } else if *bag.total_orbs == 0 {
        'bag_empty'
    } else {
        'not_game_over'
    }
}

/// Check if player can continue playing (not game over)
pub fn can_continue_playing(stats: @PlayerStats, bag: @Bag) -> bool {
    *stats.health > 0 && *bag.total_orbs > 0
}

/// Check if level requirements are met
pub fn check_level_requirements_met(stats: @PlayerStats, required_points: u32) -> bool {
    *stats.points >= required_points
}

/// Check if current level is complete based on progress
pub fn check_level_complete(stats: @PlayerStats, level_progress: @LevelProgress) -> bool {
    *stats.points >= *level_progress.points_required
}

/// Check if player has reached maximum level (game completion)
pub fn check_max_level_reached(current_level: u8) -> bool {
    current_level >= LevelConfig::MAX_LEVEL
}

// ================================
// Game Status Determination
// ================================

/// Determine the current game outcome/status
pub fn determine_game_outcome(
    game_state: @GameState,
    stats: @PlayerStats,
    bag: @Bag,
    level_progress: @LevelProgress
) -> GameStatus {
    // Check for game over conditions first
    if check_game_over(stats, bag) {
        return GameStatus::GameOver;
    }
    
    // Check if max level completed (game finished)
    if check_max_level_reached(*game_state.current_level) && check_level_complete(stats, level_progress) {
        return GameStatus::Finished;
    }
    
    // Check if current level is complete
    if check_level_complete(stats, level_progress) {
        return GameStatus::LevelComplete;
    }
    
    // Default to in progress
    GameStatus::InProgress
}

/// Get detailed game status info
pub fn get_game_status_info(
    game_state: @GameState,
    stats: @PlayerStats,
    bag: @Bag,
    level_progress: @LevelProgress
) -> (GameStatus, felt252, bool, bool) {
    let status = determine_game_outcome(game_state, stats, bag, level_progress);
    let reason = if status == GameStatus::GameOver {
        get_game_over_reason(stats, bag)
    } else {
        'none'
    };
    let can_continue = can_continue_playing(stats, bag);
    let level_complete = check_level_complete(stats, level_progress);
    
    (status, reason, can_continue, level_complete)
}

// ================================
// Final Score Calculation
// ================================

/// Calculate final rewards when game ends (points to moon rocks conversion)
pub fn calculate_final_rewards(stats: @PlayerStats) -> u32 {
    // Convert points to moon rocks at 1:1 ratio
    *stats.points
}

/// Calculate total final score including all currencies
pub fn calculate_total_final_score(stats: @PlayerStats) -> u32 {
    let moon_rocks_from_points = calculate_final_rewards(stats);
    let total_moon_rocks = *stats.moon_rocks + moon_rocks_from_points;
    let cheddah_value = *stats.cheddah; // Cheddah has separate value
    
    // Total score combines moon rocks and cheddah
    total_moon_rocks + cheddah_value
}

/// Calculate bonus score based on efficiency (health remaining, level reached)
pub fn calculate_bonus_score(
    stats: @PlayerStats,
    game_state: @GameState,
    final_status: GameStatus
) -> u32 {
    let mut bonus = 0;
    
    // Bonus for health remaining when game completes successfully
    if final_status == GameStatus::Finished {
        bonus += (*stats.health).into() * 10; // 10 points per health remaining
    }
    
    // Bonus for reaching higher levels
    let level_bonus = (*game_state.current_level).into() * 50; // 50 points per level reached
    bonus += level_bonus;
    
    // Efficiency bonus: fewer orbs pulled is better
    if *game_state.orbs_pulled_this_level < 10 {
        bonus += (10 - *game_state.orbs_pulled_this_level).into() * 5;
    }
    
    bonus
}

// ================================
// Reward Conversion
// ================================

/// Convert points to moon rocks with 1:1 ratio
pub fn convert_points_to_moon_rocks(points: u32) -> u32 {
    points // Direct 1:1 conversion
}

/// Apply points to moon rocks conversion to player stats
pub fn apply_final_conversion(ref stats: PlayerStats) -> u32 {
    let moon_rocks_earned = convert_points_to_moon_rocks(stats.points);
    stats.moon_rocks += moon_rocks_earned;
    stats.points = 0; // Points are converted, so reset to 0
    moon_rocks_earned
}

/// Calculate cheddah reward for completing a level
pub fn calculate_cheddah_reward(level: u8) -> u32 {
    let (_, _, cheddah_reward) = get_level_config(level);
    cheddah_reward
}

// ================================
// Game Completion Validation
// ================================

/// Validate that game can be completed (all requirements met)
pub fn validate_game_completion(
    game_state: @GameState,
    stats: @PlayerStats,
    level_progress: @LevelProgress
) -> bool {
    // Must be at max level
    if !check_max_level_reached(*game_state.current_level) {
        return false;
    }
    
    // Must have completed the final level requirements
    if !check_level_complete(stats, level_progress) {
        return false;
    }
    
    // Game state should allow completion
    let status = *game_state.status;
    if status != GameStatus::LevelComplete && status != GameStatus::InProgress {
        return false;
    }
    
    true
}

/// Check if player is eligible for level advancement
pub fn validate_level_advancement(
    current_level: u8,
    target_level: u8,
    stats: @PlayerStats,
    level_progress: @LevelProgress
) -> bool {
    // Target level must be exactly one level higher
    if target_level != current_level + 1 {
        return false;
    }
    
    // Must have completed current level
    if !check_level_complete(stats, level_progress) {
        return false;
    }
    
    // Target level must be valid
    if target_level > LevelConfig::MAX_LEVEL {
        return false;
    }
    
    // Must be able to afford next level cost
    let (_, level_cost, _) = get_level_config(target_level);
    if *stats.moon_rocks < level_cost {
        return false;
    }
    
    true
}

// ================================
// Progress Analysis
// ================================

/// Get detailed progress analysis for current game state
pub fn analyze_game_progress(
    game_state: @GameState,
    stats: @PlayerStats,
    bag: @Bag,
    level_progress: @LevelProgress
) -> (u8, u32, u32, u32, u32, bool, bool) {
    let current_level = *game_state.current_level;
    let current_points = *stats.points;
    let points_required = *level_progress.points_required;
    let points_remaining = if points_required > current_points {
        points_required - current_points
    } else {
        0
    };
    let orbs_remaining = *bag.total_orbs;
    let level_complete = check_level_complete(stats, level_progress);
    let game_over = check_game_over(stats, bag);
    
    (current_level, current_points, points_required, points_remaining, orbs_remaining, level_complete, game_over)
}

/// Calculate completion percentage for current level
pub fn calculate_level_completion_percentage(
    stats: @PlayerStats,
    level_progress: @LevelProgress
) -> u32 {
    let current_points = *stats.points;
    let required_points = *level_progress.points_required;
    
    if required_points == 0 {
        return 100; // Avoid division by zero
    }
    
    if current_points >= required_points {
        return 100; // Level complete
    }
    
    // Calculate percentage (multiply by 100 first to avoid precision loss)
    (current_points * 100) / required_points
}

// ================================
// Outcome Prediction
// ================================

/// Predict if player can complete current level with remaining orbs
pub fn predict_level_completion(
    stats: @PlayerStats,
    bag: @Bag,
    level_progress: @LevelProgress
) -> bool {
    let points_needed = if *level_progress.points_required > *stats.points {
        *level_progress.points_required - *stats.points
    } else {
        return true; // Already complete
    };
    
    let orbs_remaining = *bag.total_orbs;
    
    // Simple heuristic: assume average 3 points per orb with current multiplier
    let estimated_points = orbs_remaining * 3 * *stats.multiplier / 100;
    
    estimated_points >= points_needed
}

/// Estimate survival probability based on current state
pub fn estimate_survival_probability(
    stats: @PlayerStats,
    bag: @Bag
) -> u32 {
    // Simple probability calculation based on health and bomb density
    let health = *stats.health;
    let total_orbs = *bag.total_orbs;
    
    if health == 0 || total_orbs == 0 {
        return 0; // No survival chance
    }
    
    if health >= 5 {
        return 90; // High survival chance with good health
    } else if health >= 3 {
        return 70; // Moderate survival chance
    } else if health >= 2 {
        return 50; // Low but possible survival chance
    } else {
        return 25; // Very low survival chance
    }
}

// ================================
// Utility Functions
// ================================

/// Check if game state represents an active game
pub fn is_game_active(game_state: @GameState) -> bool {
    let status = *game_state.status;
    status == GameStatus::InProgress || status == GameStatus::LevelComplete
}

/// Check if game state represents a finished game (won or lost)
pub fn is_game_finished(game_state: @GameState) -> bool {
    let status = *game_state.status;
    status == GameStatus::GameOver || status == GameStatus::Finished
}

/// Get human-readable status description
pub fn get_status_description(status: GameStatus) -> felt252 {
    match status {
        GameStatus::NotStarted => 'not_started',
        GameStatus::InProgress => 'in_progress',
        GameStatus::LevelComplete => 'level_complete',
        GameStatus::GameOver => 'game_over',
        GameStatus::Finished => 'game_finished',
    }
}