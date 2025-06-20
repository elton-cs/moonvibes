use starknet::ContractAddress;
use super::orb::OrbType;

// ================================
// Bag Model - Dynamic orb array management
// ================================
#[derive(Drop, Serde)]
#[dojo::model]
pub struct Bag {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub game_id: u64,
    pub orbs: Array<OrbType>,        // Dynamic array of orb types
    pub total_orbs: u32,             // Stored separately for efficiency
}

// ================================
// Bag Helper Functions
// ================================
#[generate_trait]
pub impl BagImpl of BagTrait {
    // Add orb to bag
    fn add_orb(ref self: Bag, orb_type: OrbType) {
        self.orbs.append(orb_type);
        self.total_orbs += 1;
    }
    
    // Remove orb at specific index and return the orb type
    fn remove_orb_at_index(ref self: Bag, index: u32) -> OrbType {
        assert(index < self.total_orbs, 'Index out of bounds');
        assert(self.total_orbs > 0, 'Bag is empty');
        
        // Create new array without the selected orb
        let mut new_orbs = array![];
        let mut current_index = 0;
        let mut selected_orb = Option::None;
        
        let span = self.orbs.span();
        while current_index < self.total_orbs {
            let orb = *span.at(current_index);
            
            if current_index == index {
                selected_orb = Option::Some(orb);
            } else {
                new_orbs.append(orb);
            }
            
            current_index += 1;
        };
        
        // Update bag
        self.orbs = new_orbs;
        self.total_orbs -= 1;
        
        selected_orb.unwrap()
    }
    
    // Get random orb index using provided seed
    fn get_random_orb_index(self: @Bag, seed: felt252) -> u32 {
        assert(*self.total_orbs > 0, 'Bag is empty');
        
        // Convert felt252 to u256 for modulo operation
        let random_value: u256 = seed.into();
        let bag_size_u256: u256 = (*self.total_orbs).into();
        let random_index = (random_value % bag_size_u256).try_into().unwrap();
        
        random_index
    }
    
    // Check if bag is empty
    fn is_empty(self: @Bag) -> bool {
        *self.total_orbs == 0
    }
    
    // Get bag size
    fn size(self: @Bag) -> u32 {
        *self.total_orbs
    }
    
    // Count specific orb type in bag
    fn count_orb_type(self: @Bag, target_orb: OrbType) -> u32 {
        let mut count = 0;
        let mut current_index = 0;
        let span = self.orbs.span();
        
        while current_index < *self.total_orbs {
            let orb = *span.at(current_index);
            if orb == target_orb {
                count += 1;
            }
            current_index += 1;
        };
        
        count
    }
    
    // Check if bag contains specific orb type
    fn contains_orb_type(self: @Bag, target_orb: OrbType) -> bool {
        self.count_orb_type(target_orb) > 0
    }
    
    // Get all orb types in bag as array (for viewing)
    fn get_all_orb_types(self: @Bag) -> Array<OrbType> {
        let mut result = array![];
        let mut current_index = 0;
        let span = self.orbs.span();
        
        while current_index < *self.total_orbs {
            let orb = *span.at(current_index);
            result.append(orb);
            current_index += 1;
        };
        
        result
    }
    
    // Add multiple orbs of same type
    fn add_multiple_orbs(ref self: Bag, orb_type: OrbType, quantity: u32) {
        let mut i = 0;
        while i < quantity {
            self.add_orb(orb_type);
            i += 1;
        };
    }
    
    // Validate bag integrity
    fn validate_integrity(self: @Bag) -> bool {
        self.orbs.len() == *self.total_orbs
    }
    
    // Initialize empty bag
    fn initialize_empty(ref self: Bag) {
        self.orbs = array![];
        self.total_orbs = 0;
    }
    
    // Draw random orb and remove it from bag
    fn draw_random_orb(ref self: Bag, seed: felt252) -> OrbType {
        let random_index = self.get_random_orb_index(seed);
        self.remove_orb_at_index(random_index)
    }
}

// ================================
// Starting Bag Configuration
// ================================
pub fn create_starting_bag() -> Array<OrbType> {
    let mut starting_orbs = array![];
    
    // Add 2x Single Bomb
    starting_orbs.append(OrbType::SingleBomb);
    starting_orbs.append(OrbType::SingleBomb);
    
    // Add 2x Double Bomb
    starting_orbs.append(OrbType::DoubleBomb);
    starting_orbs.append(OrbType::DoubleBomb);
    
    // Add 1x Triple Bomb
    starting_orbs.append(OrbType::TripleBomb);
    
    // Add 3x Five Points
    starting_orbs.append(OrbType::FivePoints);
    starting_orbs.append(OrbType::FivePoints);
    starting_orbs.append(OrbType::FivePoints);
    
    // Add 1x Double Multiplier
    starting_orbs.append(OrbType::DoubleMultiplier);
    
    // Add 1x Remaining Orbs
    starting_orbs.append(OrbType::RemainingOrbs);
    
    // Add 1x Bomb Counter
    starting_orbs.append(OrbType::BombCounter);
    
    // Add 1x Health
    starting_orbs.append(OrbType::Health);
    
    starting_orbs
}

pub const STARTING_BAG_SIZE: u32 = 12;