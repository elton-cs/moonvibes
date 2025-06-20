use dojo_starter::models::{get_level_config};

// Check if player has reached the milestone for current level
pub fn check_level_complete(points: u32, level: u8) -> bool {
    let (milestone_points, _) = get_level_config(level);
    points >= milestone_points
}

// Check if game is over (health 0 or bag empty)
pub fn check_game_over(health: u8, bag_size: u32) -> bool {
    health == 0 || bag_size == 0
}

// Calculate cheddah reward based on level
pub fn calculate_cheddah_reward(level: u8) -> u32 {
    if level == 1 {
        10
    } else if level == 2 {
        12
    } else if level == 3 {
        15
    } else if level == 4 {
        18
    } else if level == 5 {
        22
    } else if level == 6 {
        26
    } else if level == 7 {
        30
    } else {
        0
    }
}