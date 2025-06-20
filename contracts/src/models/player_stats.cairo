use starknet::ContractAddress;

// ================================
// PlayerStats Model - All player currencies and statistics  
// ================================
#[derive(Drop, Serde)]
#[dojo::model]
pub struct PlayerStats {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub game_id: u64,
    pub health: u8,
    pub points: u32,
    pub multiplier: u32,        // Fixed point: 100 = 1.0x, 150 = 1.5x, 200 = 2.0x
    pub cheddah: u32,
    pub moon_rocks: u32,
    pub badges: u32,
}

// ================================
// Constants for starting values
// ================================
pub const STARTING_HEALTH: u8 = 5;
pub const STARTING_MOON_ROCKS: u32 = 304;
pub const STARTING_CHEDDAH: u32 = 0;
pub const STARTING_POINTS: u32 = 0;
pub const BASE_MULTIPLIER: u32 = 100;  // 1.0x
pub const STARTING_BADGES: u32 = 0;

// ================================
// PlayerStats Helper Functions
// ================================
#[generate_trait]
pub impl PlayerStatsImpl of PlayerStatsTrait {
    // Apply multiplier to base points (always rounds up)
    fn apply_multiplier(self: @PlayerStats, base_points: u32) -> u32 {
        let points = (base_points * *self.multiplier + 99) / 100;
        points
    }
    
    // Check if player is alive
    fn is_alive(self: @PlayerStats) -> bool {
        *self.health > 0
    }
    
    // Check if player can afford a given cost in moon rocks
    fn can_afford_moon_rocks(self: @PlayerStats, cost: u32) -> bool {
        *self.moon_rocks >= cost
    }
    
    // Check if player can afford a given cost in cheddah
    fn can_afford_cheddah(self: @PlayerStats, cost: u32) -> bool {
        *self.cheddah >= cost
    }
    
    // Apply health change (with bounds checking)
    fn apply_health_change(ref self: PlayerStats, change: i8) {
        if change > 0 {
            let positive_change: u8 = change.try_into().unwrap();
            // Prevent overflow
            if self.health > 255 - positive_change {
                self.health = 255;
            } else {
                self.health += positive_change;
            }
        } else {
            let negative_change: u8 = (-change).try_into().unwrap();
            // Prevent underflow
            if self.health < negative_change {
                self.health = 0;
            } else {
                self.health -= negative_change;
            }
        }
    }
    
    // Add points with current multiplier applied
    fn add_points(ref self: PlayerStats, base_points: u32) {
        let points_to_add = (@self).apply_multiplier(base_points);
        self.points += points_to_add;
    }
    
    // Set multiplier (fixed point: 100 = 1.0x)
    fn set_multiplier(ref self: PlayerStats, multiplier: u32) {
        self.multiplier = multiplier;
    }
    
    // Reset multiplier to base (1.0x)
    fn reset_multiplier(ref self: PlayerStats) {
        self.multiplier = BASE_MULTIPLIER;
    }
    
    // Spend moon rocks (with validation)
    fn spend_moon_rocks(ref self: PlayerStats, amount: u32) {
        assert((@self).can_afford_moon_rocks(amount), 'Insufficient moon rocks');
        self.moon_rocks -= amount;
    }
    
    // Spend cheddah (with validation)
    fn spend_cheddah(ref self: PlayerStats, amount: u32) {
        assert((@self).can_afford_cheddah(amount), 'Insufficient cheddah');
        self.cheddah -= amount;
    }
    
    // Add moon rocks
    fn add_moon_rocks(ref self: PlayerStats, amount: u32) {
        self.moon_rocks += amount;
    }
    
    // Add cheddah
    fn add_cheddah(ref self: PlayerStats, amount: u32) {
        self.cheddah += amount;
    }
    
    // Convert points to moon rocks at game end (1:1 ratio)
    fn convert_points_to_moon_rocks(ref self: PlayerStats) -> u32 {
        let moon_rocks_earned = self.points;
        self.add_moon_rocks(moon_rocks_earned);
        self.points = 0; // Reset points after conversion
        moon_rocks_earned
    }
    
    // Initialize stats for new game
    fn initialize_for_new_game(ref self: PlayerStats) {
        self.health = STARTING_HEALTH;
        self.points = STARTING_POINTS;
        self.multiplier = BASE_MULTIPLIER;
        self.cheddah = STARTING_CHEDDAH;
        // Note: moon_rocks and badges persist across games
    }
    
    // Initialize stats for first-time player
    fn initialize_new_player(ref self: PlayerStats) {
        self.health = STARTING_HEALTH;
        self.points = STARTING_POINTS;
        self.multiplier = BASE_MULTIPLIER;
        self.cheddah = STARTING_CHEDDAH;
        self.moon_rocks = STARTING_MOON_ROCKS;
        self.badges = STARTING_BADGES;
    }
}