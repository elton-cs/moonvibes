use dojo_starter::models::{OrbType, PlayerStats, GameState, Bag};

// Apply the effect of a drawn orb to player stats and game state
pub fn apply_orb_effect(
    orb_type: OrbType, 
    mut stats: PlayerStats, 
    mut game_state: GameState,
    bag: @Bag
) -> (PlayerStats, GameState) {
    match orb_type {
        // Points orbs
        OrbType::FivePoints => {
            stats.points += calculate_points_with_multiplier(5, stats.multiplier);
        },
        OrbType::SevenPoints => {
            stats.points += calculate_points_with_multiplier(7, stats.multiplier);
        },
        OrbType::EightPoints => {
            stats.points += calculate_points_with_multiplier(8, stats.multiplier);
        },
        OrbType::NinePoints => {
            stats.points += calculate_points_with_multiplier(9, stats.multiplier);
        },
        
        // Bomb orbs
        OrbType::SingleBomb => {
            stats.health = process_bomb_damage(stats.health, 1);
            game_state.bombs_pulled += 1;
        },
        OrbType::DoubleBomb => {
            stats.health = process_bomb_damage(stats.health, 2);
            game_state.bombs_pulled += 1;
        },
        OrbType::TripleBomb => {
            stats.health = process_bomb_damage(stats.health, 3);
            game_state.bombs_pulled += 1;
        },
        
        // Health orbs
        OrbType::Health => {
            stats.health += 1;
        },
        OrbType::BigHealth => {
            stats.health += 3;
        },
        
        // Multiplier orbs
        OrbType::DoubleMultiplier => {
            stats.multiplier = 200; // 2.0x
        },
        OrbType::Multiplier1_5x => {
            stats.multiplier = 150; // 1.5x
        },
        OrbType::HalfMultiplier => {
            stats.multiplier = 50; // 0.5x
        },
        
        // Special orbs
        OrbType::RemainingOrbs => {
            let remaining_orbs = bag.orb_ids.len();
            stats.points += calculate_points_with_multiplier(remaining_orbs, stats.multiplier);
        },
        OrbType::BombCounter => {
            let bomb_value = game_state.bombs_pulled.into();
            stats.points += calculate_points_with_multiplier(bomb_value, stats.multiplier);
        },
        
        // Currency orbs
        OrbType::MoonRock => {
            stats.moon_rocks += 2;
        },
        OrbType::BigMoonRock => {
            stats.moon_rocks += 10;
        },
        OrbType::CheddahBomb => {
            stats.health = process_bomb_damage(stats.health, 1);
            stats.cheddah += 10;
            game_state.bombs_pulled += 1;
        },
    }
    
    (stats, game_state)
}

// Calculate points with multiplier applied (multiplier is stored as fixed point)
pub fn calculate_points_with_multiplier(base_points: u32, multiplier: u32) -> u32 {
    // multiplier is stored as fixed point where 100 = 1.0x
    let points = (base_points * multiplier) / 100;
    
    // Always round up
    if (base_points * multiplier) % 100 != 0 {
        points + 1
    } else {
        points
    }
}

// Apply bomb damage, ensuring health doesn't go below 0
pub fn process_bomb_damage(current_health: u8, damage: u8) -> u8 {
    if damage >= current_health {
        0
    } else {
        current_health - damage
    }
}