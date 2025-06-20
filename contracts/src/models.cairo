use starknet::{ContractAddress};

// ================================
// Orb Type Enum - All consumable orbs
// ================================
#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
pub enum OrbType {
    // Points Orbs
    FivePoints,
    SevenPoints,
    EightPoints,
    NinePoints,
    // Bomb Orbs
    SingleBomb,
    DoubleBomb,
    TripleBomb,
    // Health Orbs
    Health,
    BigHealth,
    // Multiplier Orbs
    DoubleMultiplier,
    Multiplier1_5x,
    HalfMultiplier,
    // Special Orbs
    RemainingOrbs,
    BombCounter,
    // Currency Orbs
    MoonRock,
    BigMoonRock,
    CheddahBomb,
}

// ================================
// Game State Model
// ================================
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct GameState {
    #[key]
    pub player: ContractAddress,
    pub is_active: bool,
    pub current_level: u8,
    pub bombs_pulled: u8,
}

// ================================
// Player Stats Model
// ================================
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct PlayerStats {
    #[key]
    pub player: ContractAddress,
    pub health: u8,
    pub points: u32,
    pub multiplier: u32, // Fixed point: 100 = 1.0x
    pub moon_rocks: u32,
    pub cheddah: u32,
}

// ================================
// Bag Model - Stores orb IDs
// ================================
#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct Bag {
    #[key]
    pub player: ContractAddress,
    pub orb_ids: Array<OrbType>,
}

// ================================
// Level Progress Model
// ================================
#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct LevelProgress {
    #[key]
    pub player: ContractAddress,
    pub orbs_pulled: Array<OrbType>,
}

// ================================
// Helper implementations
// ================================
impl OrbTypeIntoFelt252 of Into<OrbType, felt252> {
    fn into(self: OrbType) -> felt252 {
        match self {
            OrbType::FivePoints => 1,
            OrbType::SevenPoints => 2,
            OrbType::EightPoints => 3,
            OrbType::NinePoints => 4,
            OrbType::SingleBomb => 5,
            OrbType::DoubleBomb => 6,
            OrbType::TripleBomb => 7,
            OrbType::Health => 8,
            OrbType::BigHealth => 9,
            OrbType::DoubleMultiplier => 10,
            OrbType::Multiplier1_5x => 11,
            OrbType::HalfMultiplier => 12,
            OrbType::RemainingOrbs => 13,
            OrbType::BombCounter => 14,
            OrbType::MoonRock => 15,
            OrbType::BigMoonRock => 16,
            OrbType::CheddahBomb => 17,
        }
    }
}

// ================================
// Level Configuration
// ================================
pub fn get_level_config(level: u8) -> (u32, u32) {
    // Returns (milestone_points, moon_rock_cost)
    if level == 1 {
        (12, 5)
    } else if level == 2 {
        (18, 6)
    } else if level == 3 {
        (28, 8)
    } else if level == 4 {
        (44, 10)
    } else if level == 5 {
        (66, 12)
    } else if level == 6 {
        (94, 16)
    } else if level == 7 {
        (130, 20)
    } else {
        (999999, 999999) // Impossible level
    }
}

// ================================
// Constants
// ================================
pub const STARTING_HEALTH: u8 = 5;
pub const STARTING_MOON_ROCKS: u32 = 304;
pub const STARTING_CHEDDAH: u32 = 0;
pub const STARTING_POINTS: u32 = 0;
pub const BASE_MULTIPLIER: u32 = 100; // 1.0x