use starknet::ContractAddress;
use super::orb::OrbType;

// ================================
// Shop Model - Available orbs for purchase
// ================================
#[derive(Drop, Serde)]
#[dojo::model]
pub struct Shop {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub game_id: u64,
    #[key]
    pub level: u8,
    pub available_orbs: Array<OrbType>,     // Array of available orb types
    pub orb_prices: Array<u32>,             // Corresponding prices for each orb
    pub shop_generated: bool,               // Whether shop has been generated for this level
}

// ================================
// PurchaseHistory Model - Tracks lifetime purchases for price scaling
// ================================
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PurchaseHistory {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub orb_type: OrbType,
    pub purchase_count: u32,                // Total times this orb type has been purchased
    pub total_spent: u32,                   // Total cheddah spent on this orb type
}

// ================================
// Shop Configuration Constants
// ================================
pub mod ShopConfig {
    pub const COMMON_ORBS_COUNT: u32 = 3;
    pub const RARE_ORBS_COUNT: u32 = 2;
    pub const COSMIC_ORBS_COUNT: u32 = 1;
    pub const TOTAL_SHOP_ORBS: u32 = 6;
    
    // Price scaling: each purchase increases price by 20%
    pub const PRICE_SCALING_NUMERATOR: u32 = 120;  // 1.2 in fixed point (100 = 1.0)
    pub const PRICE_SCALING_DENOMINATOR: u32 = 100;
}

// ================================
// Shop Orb Arrays by Rarity
// ================================
pub fn get_common_shop_orbs() -> Array<OrbType> {
    let mut common_orbs = array![];
    common_orbs.append(OrbType::SevenPoints);
    common_orbs.append(OrbType::CheddahBomb);
    common_orbs.append(OrbType::MoonRock);
    common_orbs.append(OrbType::HalfMultiplier);
    common_orbs
}

pub fn get_rare_shop_orbs() -> Array<OrbType> {
    let mut rare_orbs = array![];
    rare_orbs.append(OrbType::EightPoints);
    rare_orbs.append(OrbType::NinePoints);
    rare_orbs.append(OrbType::NextPoints2x);
    rare_orbs.append(OrbType::Multiplier1_5x);
    rare_orbs
}

pub fn get_cosmic_shop_orbs() -> Array<OrbType> {
    let mut cosmic_orbs = array![];
    cosmic_orbs.append(OrbType::BigHealth);
    cosmic_orbs.append(OrbType::BigMoonRock);
    cosmic_orbs
}

// ================================
// Shop Helper Functions
// ================================
#[generate_trait]
pub impl ShopImpl of ShopTrait {
    // Generate shop inventory for current level
    fn generate_shop_inventory(ref self: Shop, seed: felt252) {
        assert(!self.shop_generated, 'Shop already generated');
        
        let mut selected_orbs = array![];
        let mut selected_prices = array![];
        
        // Select 3 common orbs
        let common_orbs = get_common_shop_orbs();
        let mut i = 0;
        while i < ShopConfig::COMMON_ORBS_COUNT {
            let orb_index = self.get_random_orb_from_rarity(seed + i.into(), @common_orbs);
            let orb = *common_orbs.at(orb_index);
            let price = get_orb_price_with_scaling(self.player, orb);
            
            selected_orbs.append(orb);
            selected_prices.append(price);
            i += 1;
        };
        
        // Select 2 rare orbs
        let rare_orbs = get_rare_shop_orbs();
        let mut j = 0;
        while j < ShopConfig::RARE_ORBS_COUNT {
            let orb_index = self.get_random_orb_from_rarity(seed + (3 + j).into(), @rare_orbs);
            let orb = *rare_orbs.at(orb_index);
            let price = get_orb_price_with_scaling(self.player, orb);
            
            selected_orbs.append(orb);
            selected_prices.append(price);
            j += 1;
        };
        
        // Select 1 cosmic orb
        let cosmic_orbs = get_cosmic_shop_orbs();
        let orb_index = self.get_random_orb_from_rarity(seed + 5_u32.into(), @cosmic_orbs);
        let orb = *cosmic_orbs.at(orb_index);
        let price = get_orb_price_with_scaling(self.player, orb);
        
        selected_orbs.append(orb);
        selected_prices.append(price);
        
        // Update shop
        self.available_orbs = selected_orbs;
        self.orb_prices = selected_prices;
        self.shop_generated = true;
    }
    
    // Get random orb from rarity array
    fn get_random_orb_from_rarity(self: @Shop, seed: felt252, orbs: @Array<OrbType>) -> u32 {
        let array_len = orbs.len();
        assert(array_len > 0, 'Empty orb array');
        
        let random_value: u256 = seed.into();
        let array_len_u256: u256 = array_len.into();
        let random_index = (random_value % array_len_u256).try_into().unwrap();
        
        random_index
    }
    
    // Check if shop has specific orb available
    fn has_orb_available(self: @Shop, target_orb: OrbType) -> bool {
        let mut current_index = 0;
        let span = self.available_orbs.span();
        let total_orbs = self.available_orbs.len();
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
    
    // Get price of specific orb in shop
    fn get_orb_price_in_shop(self: @Shop, target_orb: OrbType) -> Option<u32> {
        let mut current_index = 0;
        let orb_span = self.available_orbs.span();
        let price_span = self.orb_prices.span();
        let total_orbs = self.available_orbs.len();
        let mut result = Option::None;
        
        while current_index < total_orbs {
            let orb = *orb_span.at(current_index);
            if orb == target_orb {
                let price = *price_span.at(current_index);
                result = Option::Some(price);
                break;
            }
            current_index += 1;
        };
        
        result
    }
    
    // Get all available orbs with their prices
    fn get_shop_inventory(self: @Shop) -> (Array<OrbType>, Array<u32>) {
        let mut orbs_copy = array![];
        let mut prices_copy = array![];
        
        let mut current_index = 0;
        let orb_span = self.available_orbs.span();
        let price_span = self.orb_prices.span();
        let total_orbs = self.available_orbs.len();
        
        while current_index < total_orbs {
            let orb = *orb_span.at(current_index);
            let price = *price_span.at(current_index);
            orbs_copy.append(orb);
            prices_copy.append(price);
            current_index += 1;
        };
        
        (orbs_copy, prices_copy)
    }
    
    // Clear shop inventory
    fn clear_shop(ref self: Shop) {
        self.available_orbs = array![];
        self.orb_prices = array![];
        self.shop_generated = false;
    }
    
    // Initialize empty shop
    fn initialize_empty(ref self: Shop) {
        self.available_orbs = array![];
        self.orb_prices = array![];
        self.shop_generated = false;
    }
}

// ================================
// PurchaseHistory Helper Functions
// ================================
#[generate_trait]
pub impl PurchaseHistoryImpl of PurchaseHistoryTrait {
    // Record a purchase
    fn record_purchase(ref self: PurchaseHistory, price_paid: u32) {
        self.purchase_count += 1;
        self.total_spent += price_paid;
    }
    
    // Get average price paid for this orb type
    fn get_average_price(self: @PurchaseHistory) -> u32 {
        if *self.purchase_count == 0 {
            0
        } else {
            *self.total_spent / *self.purchase_count
        }
    }
    
    // Initialize new purchase history
    fn initialize(ref self: PurchaseHistory) {
        self.purchase_count = 0;
        self.total_spent = 0;
    }
}

// ================================
// Global Price Calculation Functions
// ================================
pub fn get_orb_price_with_scaling(player: ContractAddress, orb_type: OrbType) -> u32 {
    // This function will need to read PurchaseHistory from world storage
    // For now, we'll use the base price calculation
    let base_price = get_base_orb_price(orb_type);
    
    // TODO: In actual implementation, read purchase history from world storage
    // let purchase_history: PurchaseHistory = world.read_model((player, orb_type));
    // let scaling_factor = power(120, purchase_history.purchase_count) / power(100, purchase_history.purchase_count);
    // (base_price * scaling_factor + 99) / 100  // Round up
    
    base_price
}

pub fn get_base_orb_price(orb_type: OrbType) -> u32 {
    if orb_type == OrbType::SevenPoints {
        5
    } else if orb_type == OrbType::CheddahBomb {
        5
    } else if orb_type == OrbType::MoonRock {
        8
    } else if orb_type == OrbType::HalfMultiplier {
        9
    } else if orb_type == OrbType::EightPoints {
        11
    } else if orb_type == OrbType::NinePoints {
        13
    } else if orb_type == OrbType::NextPoints2x {
        14
    } else if orb_type == OrbType::Multiplier1_5x {
        16
    } else if orb_type == OrbType::BigHealth {
        21
    } else if orb_type == OrbType::BigMoonRock {
        23
    } else {
        0 // Starting orbs (not sold in shop)
    }
}

pub fn calculate_scaled_price(base_price: u32, purchase_count: u32) -> u32 {
    if purchase_count == 0 {
        return base_price;
    }
    
    // Calculate 1.2^purchase_count using repeated multiplication
    let mut scaling_factor = ShopConfig::PRICE_SCALING_DENOMINATOR; // Start with 1.0 (100)
    let mut i = 0;
    while i < purchase_count {
        scaling_factor = (scaling_factor * ShopConfig::PRICE_SCALING_NUMERATOR) / ShopConfig::PRICE_SCALING_DENOMINATOR;
        i += 1;
    };
    
    // Apply scaling and round up
    (base_price * scaling_factor + ShopConfig::PRICE_SCALING_DENOMINATOR - 1) / ShopConfig::PRICE_SCALING_DENOMINATOR
}