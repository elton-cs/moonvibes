use dojo_starter::models::{OrbType, Bag};

// Initialize the starting bag with exactly 12 orbs
pub fn initialize_starting_bag() -> Array<OrbType> {
    let mut bag = array![];
    
    // Add 2x Single Bomb
    bag.append(OrbType::SingleBomb);
    bag.append(OrbType::SingleBomb);
    
    // Add 2x Double Bomb
    bag.append(OrbType::DoubleBomb);
    bag.append(OrbType::DoubleBomb);
    
    // Add 1x Triple Bomb
    bag.append(OrbType::TripleBomb);
    
    // Add 3x Five Points
    bag.append(OrbType::FivePoints);
    bag.append(OrbType::FivePoints);
    bag.append(OrbType::FivePoints);
    
    // Add 1x Double Multiplier
    bag.append(OrbType::DoubleMultiplier);
    
    // Add 1x Remaining Orbs
    bag.append(OrbType::RemainingOrbs);
    
    // Add 1x Bomb Counter
    bag.append(OrbType::BombCounter);
    
    // Add 1x Health
    bag.append(OrbType::Health);
    
    bag
}

// Draw a random orb from the bag and return updated bag
pub fn draw_random_orb(mut bag: Bag, random_seed: felt252) -> (OrbType, Bag) {
    let bag_size = bag.orb_ids.len();
    assert(bag_size > 0, 'Bag is empty');
    
    // Simple random index based on seed
    // Convert felt252 to u256 first, then take modulo
    let random_value: u256 = random_seed.into();
    let bag_size_u256: u256 = bag_size.into();
    let random_index = (random_value % bag_size_u256).try_into().unwrap();
    
    // Create new array without the selected orb
    let mut new_orb_ids = array![];
    let mut selected_orb = Option::None;
    let mut current_index = 0;
    
    let span = bag.orb_ids.span();
    loop {
        if current_index >= bag_size {
            break;
        }
        
        let orb = *span.at(current_index);
        
        if current_index == random_index {
            selected_orb = Option::Some(orb);
        } else {
            new_orb_ids.append(orb);
        }
        
        current_index += 1;
    };
    
    // Update bag with new orb list
    bag.orb_ids = new_orb_ids;
    
    (selected_orb.unwrap(), bag)
}

// Add orbs to bag (for future shop implementation)
pub fn add_orbs_to_bag(mut bag: Bag, orb_type: OrbType, quantity: u8) -> Bag {
    let mut i = 0;
    loop {
        if i >= quantity {
            break;
        }
        bag.orb_ids.append(orb_type);
        i += 1;
    };
    
    bag
}