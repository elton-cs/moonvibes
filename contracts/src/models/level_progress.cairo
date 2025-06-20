use starknet::ContractAddress;
use super::orb::OrbType;

// ================================
// Level Configuration Constants
// ================================
pub mod LevelConfig {
    // Level requirements: (milestone_points, moon_rock_cost, cheddah_reward)
    pub const LEVEL_1_POINTS: u32 = 12;
    pub const LEVEL_1_COST: u32 = 5;
    pub const LEVEL_1_REWARD: u32 = 10;
    
    pub const LEVEL_2_POINTS: u32 = 18;
    pub const LEVEL_2_COST: u32 = 6;
    pub const LEVEL_2_REWARD: u32 = 12;
    
    pub const LEVEL_3_POINTS: u32 = 28;
    pub const LEVEL_3_COST: u32 = 8;
    pub const LEVEL_3_REWARD: u32 = 15;
    
    pub const LEVEL_4_POINTS: u32 = 44;
    pub const LEVEL_4_COST: u32 = 10;
    pub const LEVEL_4_REWARD: u32 = 18;
    
    pub const LEVEL_5_POINTS: u32 = 66;
    pub const LEVEL_5_COST: u32 = 12;
    pub const LEVEL_5_REWARD: u32 = 22;
    
    pub const LEVEL_6_POINTS: u32 = 94;
    pub const LEVEL_6_COST: u32 = 16;
    pub const LEVEL_6_REWARD: u32 = 26;
    
    pub const LEVEL_7_POINTS: u32 = 130;
    pub const LEVEL_7_COST: u32 = 20;
    pub const LEVEL_7_REWARD: u32 = 30;
    
    pub const MAX_LEVEL: u8 = 7;
}

// ================================
// LevelProgress Model - Level-specific progress tracking
// ================================
#[derive(Drop, Serde)]
#[dojo::model]
pub struct LevelProgress {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub game_id: u64,
    pub current_level: u8,
    pub points_required: u32,
    pub points_earned: u32,
    pub level_cost: u32,
    pub cheddah_reward: u32,
    pub orbs_pulled_this_level: Array<OrbType>, // Track orbs pulled this level
}

// ================================
// Level Configuration Helper Functions
// ================================
pub fn get_level_config(level: u8) -> (u32, u32, u32) {
    // Returns (milestone_points, moon_rock_cost, cheddah_reward)
    if level == 1 {
        (LevelConfig::LEVEL_1_POINTS, LevelConfig::LEVEL_1_COST, LevelConfig::LEVEL_1_REWARD)
    } else if level == 2 {
        (LevelConfig::LEVEL_2_POINTS, LevelConfig::LEVEL_2_COST, LevelConfig::LEVEL_2_REWARD)
    } else if level == 3 {
        (LevelConfig::LEVEL_3_POINTS, LevelConfig::LEVEL_3_COST, LevelConfig::LEVEL_3_REWARD)
    } else if level == 4 {
        (LevelConfig::LEVEL_4_POINTS, LevelConfig::LEVEL_4_COST, LevelConfig::LEVEL_4_REWARD)
    } else if level == 5 {
        (LevelConfig::LEVEL_5_POINTS, LevelConfig::LEVEL_5_COST, LevelConfig::LEVEL_5_REWARD)
    } else if level == 6 {
        (LevelConfig::LEVEL_6_POINTS, LevelConfig::LEVEL_6_COST, LevelConfig::LEVEL_6_REWARD)
    } else if level == 7 {
        (LevelConfig::LEVEL_7_POINTS, LevelConfig::LEVEL_7_COST, LevelConfig::LEVEL_7_REWARD)
    } else {
        (999999, 999999, 0) // Invalid level
    }
}

pub fn is_valid_level(level: u8) -> bool {
    level >= 1 && level <= LevelConfig::MAX_LEVEL
}

pub fn get_next_level(current_level: u8) -> Option<u8> {
    if current_level < LevelConfig::MAX_LEVEL {
        Option::Some(current_level + 1)
    } else {
        Option::None
    }
}

// ================================
// LevelProgress Helper Functions
// ================================
#[generate_trait]
pub impl LevelProgressImpl of LevelProgressTrait {
    // Initialize level progress for a specific level
    fn initialize_for_level(ref self: LevelProgress, level: u8) {
        let (points_required, level_cost, cheddah_reward) = get_level_config(level);
        
        self.current_level = level;
        self.points_required = points_required;
        self.points_earned = 0;
        self.level_cost = level_cost;
        self.cheddah_reward = cheddah_reward;
        self.orbs_pulled_this_level = array![];
    }
    
    // Check if level requirements are met
    fn is_level_complete(self: @LevelProgress) -> bool {
        *self.points_earned >= *self.points_required
    }
    
    // Get progress percentage (0-100)
    fn get_progress_percentage(self: @LevelProgress) -> u32 {
        if *self.points_required == 0 {
            return 100;
        }
        
        let percentage = (*self.points_earned * 100) / *self.points_required;
        if percentage > 100 {
            100
        } else {
            percentage
        }
    }
    
    // Get remaining points needed
    fn get_remaining_points(self: @LevelProgress) -> u32 {
        if *self.points_earned >= *self.points_required {
            0
        } else {
            *self.points_required - *self.points_earned
        }
    }
    
    // Add points to current level
    fn add_points(ref self: LevelProgress, points: u32) {
        self.points_earned += points;
    }
    
    // Record orb pull for this level
    fn record_orb_pull(ref self: LevelProgress, orb_type: OrbType) {
        self.orbs_pulled_this_level.append(orb_type);
    }
    
    // Get number of orbs pulled this level
    fn get_orbs_pulled_count(self: @LevelProgress) -> u32 {
        self.orbs_pulled_this_level.len()
    }
    
    // Check if specific orb type was pulled this level
    fn was_orb_pulled_this_level(self: @LevelProgress, target_orb: OrbType) -> bool {
        let mut current_index = 0;
        let span = self.orbs_pulled_this_level.span();
        let total_orbs = self.orbs_pulled_this_level.len();
        let mut found = false;
        
        while current_index < total_orbs {
            let orb = *span.at(current_index);
            if orb == target_orb {
                found = true;
                break;
            }
            current_index += 1;
        };
        
        found
    }
    
    // Count specific orb type pulled this level
    fn count_orb_type_pulled(self: @LevelProgress, target_orb: OrbType) -> u32 {
        let mut count = 0;
        let mut current_index = 0;
        let span = self.orbs_pulled_this_level.span();
        let total_orbs = self.orbs_pulled_this_level.len();
        
        while current_index < total_orbs {
            let orb = *span.at(current_index);
            if orb == target_orb {
                count += 1;
            }
            current_index += 1;
        };
        
        count
    }
    
    // Reset level progress (for next level)
    fn reset_for_next_level(ref self: LevelProgress) {
        if let Option::Some(next_level) = get_next_level(self.current_level) {
            self.initialize_for_level(next_level);
        }
    }
    
    // Validate level data consistency
    fn validate_level_data(self: @LevelProgress) -> bool {
        is_valid_level(*self.current_level) &&
        *self.points_required > 0 &&
        *self.level_cost > 0
    }
}