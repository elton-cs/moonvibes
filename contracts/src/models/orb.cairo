// Orb model and enum - no ContractAddress needed for this model

// ================================
// OrbType Enum - All 25 orb types (12 starting + 13 shop orbs)
// ================================
#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
pub enum OrbType {
    // Starting Orbs (12 total) - provided in starting bag
    SingleBomb,      // -1 health
    DoubleBomb,      // -2 health  
    TripleBomb,      // -3 health
    FivePoints,      // +5 points
    DoubleMultiplier, // x2 multiplier
    RemainingOrbs,   // points = orbs left in bag
    BombCounter,     // points = bombs previously pulled
    Health,          // +1 health
    
    // Shop Orbs - Common (5 total)
    SevenPoints,     // +7 points
    CheddahBomb,     // Bomb that gives +10 Cheddah
    MoonRock,        // +2 Moon Rocks
    HalfMultiplier,  // x0.5 multiplier
    
    // Shop Orbs - Rare (4 total)
    EightPoints,     // +8 points
    NinePoints,      // +9 points
    NextPoints2x,    // x2 multiplier for next points orb only
    Multiplier1_5x,  // x1.5 multiplier
    
    // Shop Orbs - Cosmic (4 total)
    BigHealth,       // +3 health
    BigMoonRock,     // +10 Moon Rocks
}

// Convert OrbType to felt252 for events and storage
impl OrbTypeIntoFelt252 of Into<OrbType, felt252> {
    fn into(self: OrbType) -> felt252 {
        match self {
            // Starting Orbs
            OrbType::SingleBomb => 1,
            OrbType::DoubleBomb => 2,
            OrbType::TripleBomb => 3,
            OrbType::FivePoints => 4,
            OrbType::DoubleMultiplier => 5,
            OrbType::RemainingOrbs => 6,
            OrbType::BombCounter => 7,
            OrbType::Health => 8,
            
            // Shop Orbs - Common
            OrbType::SevenPoints => 9,
            OrbType::CheddahBomb => 10,
            OrbType::MoonRock => 11,
            OrbType::HalfMultiplier => 12,
            
            // Shop Orbs - Rare
            OrbType::EightPoints => 13,
            OrbType::NinePoints => 14,
            OrbType::NextPoints2x => 15,
            OrbType::Multiplier1_5x => 16,
            
            // Shop Orbs - Cosmic
            OrbType::BigHealth => 17,
            OrbType::BigMoonRock => 18,
        }
    }
}

// ================================
// Orb Model - Individual orb instances
// ================================
#[derive(Drop, Serde)]
#[dojo::model]
pub struct Orb {
    #[key]
    pub orb_id: u32,
    pub orb_type: OrbType,
    pub value: i32,        // Base value (can be negative for bombs)
    pub rarity: u8,        // 0=common, 1=rare, 2=cosmic
}

// ================================
// Orb Creation Helpers
// ================================
pub fn get_orb_base_value(orb_type: OrbType) -> i32 {
    match orb_type {
        // Points orbs - positive values
        OrbType::FivePoints => 5,
        OrbType::SevenPoints => 7,
        OrbType::EightPoints => 8,
        OrbType::NinePoints => 9,
        
        // Bomb orbs - negative health values
        OrbType::SingleBomb => -1,
        OrbType::DoubleBomb => -2,
        OrbType::TripleBomb => -3,
        
        // Health orbs - positive health values
        OrbType::Health => 1,
        OrbType::BigHealth => 3,
        
        // Currency orbs
        OrbType::MoonRock => 2,
        OrbType::BigMoonRock => 10,
        OrbType::CheddahBomb => 10, // Cheddah value
        
        // Multiplier orbs (stored as 100 = 1.0x)
        OrbType::DoubleMultiplier => 200,    // 2.0x
        OrbType::Multiplier1_5x => 150,      // 1.5x
        OrbType::HalfMultiplier => 50,       // 0.5x
        OrbType::NextPoints2x => 200,        // 2.0x (temporary)
        
        // Special orbs - dynamic values
        OrbType::RemainingOrbs => 0,  // Value calculated at runtime
        OrbType::BombCounter => 0,    // Value calculated at runtime
    }
}

pub fn get_orb_rarity(orb_type: OrbType) -> u8 {
    match orb_type {
        // Starting orbs - no rarity (special category)
        OrbType::SingleBomb | OrbType::DoubleBomb | OrbType::TripleBomb |
        OrbType::FivePoints | OrbType::DoubleMultiplier | OrbType::RemainingOrbs |
        OrbType::BombCounter | OrbType::Health => 3, // Starting orbs
        
        // Common shop orbs
        OrbType::SevenPoints | OrbType::CheddahBomb | 
        OrbType::MoonRock | OrbType::HalfMultiplier => 0,
        
        // Rare shop orbs  
        OrbType::EightPoints | OrbType::NinePoints |
        OrbType::NextPoints2x | OrbType::Multiplier1_5x => 1,
        
        // Cosmic shop orbs
        OrbType::BigHealth | OrbType::BigMoonRock => 2,
    }
}

// ================================
// Shop Pricing System
// ================================
pub fn get_base_shop_price(orb_type: OrbType) -> u32 {
    match orb_type {
        // Common orbs (5 cheddah base)
        OrbType::SevenPoints => 5,
        OrbType::CheddahBomb => 5,
        OrbType::MoonRock => 8,
        OrbType::HalfMultiplier => 9,
        
        // Rare orbs (11-16 cheddah base)
        OrbType::EightPoints => 11,
        OrbType::NinePoints => 13,
        OrbType::NextPoints2x => 14,
        OrbType::Multiplier1_5x => 16,
        
        // Cosmic orbs (21-23 cheddah base)
        OrbType::BigHealth => 21,
        OrbType::BigMoonRock => 23,
        
        // Starting orbs - not sold in shop
        _ => 0,
    }
}

pub fn is_shop_orb(orb_type: OrbType) -> bool {
    match orb_type {
        // Starting orbs are not sold in shop
        OrbType::SingleBomb | OrbType::DoubleBomb | OrbType::TripleBomb |
        OrbType::FivePoints | OrbType::DoubleMultiplier | OrbType::RemainingOrbs |
        OrbType::BombCounter | OrbType::Health => false,
        
        // All other orbs are available in shop
        _ => true,
    }
}