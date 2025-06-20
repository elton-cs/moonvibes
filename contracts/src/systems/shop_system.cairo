use starknet::ContractAddress;
use crate::models::orb::OrbType;

// Define the interface
#[starknet::interface]
pub trait IShopSystem<T> {
    fn generate_shop(ref self: T, game_id: u64);
    fn purchase_orb(ref self: T, game_id: u64, orb_type: OrbType);
    fn get_shop_contents(self: @T, player: ContractAddress, game_id: u64, level: u8) -> (Array<OrbType>, Array<u32>);
    fn get_orb_price(self: @T, player: ContractAddress, orb_type: OrbType) -> u32;
    fn refresh_shop(ref self: T, game_id: u64);
}

// Dojo contract implementation
#[dojo::contract]
pub mod shop_system {
    use super::IShopSystem;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;
    use dojo::world::{WorldStorage};
    
    // Import models and types
    use crate::models::orb::OrbType;
    use crate::models::game_state::{GameState, GameStatus};
    use crate::models::player_stats::{PlayerStats, PlayerStatsTrait};
    use crate::models::bag::{Bag, BagTrait};
    use crate::models::shop::{
        Shop, ShopTrait, PurchaseHistory, PurchaseHistoryTrait, ShopConfig,
        get_base_orb_price, calculate_scaled_price
    };

    // Events for shop system
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ShopGenerated {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub level: u8,
        pub orb_count: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct OrbPurchased {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub orb_type: OrbType,
        pub price_paid: u32,
        pub purchase_count: u32, // Total purchases of this orb type
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ShopRefreshed {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        pub level: u8,
    }

    #[abi(embed_v0)]
    impl ShopSystemImpl of IShopSystem<ContractState> {
        fn generate_shop(ref self: ContractState, game_id: u64) {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Get current game state
            let game_state: GameState = world.read_model((player, game_id));
            assert(game_state.status == GameStatus::InProgress, 'Game not in progress');
            
            // Get or create shop for current level
            let mut shop: Shop = world.read_model((player, game_id, game_state.current_level));
            
            // Only generate if not already generated
            if !shop.shop_generated {
                // Use block timestamp + game info as seed for randomness
                let seed = get_block_timestamp().into() + player.into() + game_id.into();
                
                // Generate shop inventory with proper distribution
                shop.generate_shop_inventory(seed);
                
                // Write updated shop
                world.write_model(@shop);
                
                // Emit shop generation event
                world.emit_event(@ShopGenerated { 
                    player, 
                    game_id, 
                    level: game_state.current_level,
                    orb_count: shop.available_orbs.len()
                });
            }
        }

        fn purchase_orb(ref self: ContractState, game_id: u64, orb_type: OrbType) {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Get current game state
            let game_state: GameState = world.read_model((player, game_id));
            assert(game_state.status == GameStatus::InProgress, 'Game not in progress');
            
            // Get shop for current level
            let mut shop: Shop = world.read_model((player, game_id, game_state.current_level));
            assert(shop.shop_generated, 'Shop not generated');
            assert(shop.has_orb_available(orb_type), 'Orb not available');
            
            // Calculate price with scaling
            let price = self.get_orb_price(player, orb_type);
            
            // Get player stats and validate they can afford it
            let mut player_stats: PlayerStats = world.read_model((player, game_id));
            assert(player_stats.can_afford_cheddah(price), 'Insufficient cheddah');
            
            // Deduct payment
            player_stats.spend_cheddah(price);
            
            // Add orb to player's bag
            let mut bag: Bag = world.read_model((player, game_id));
            bag.add_orb(orb_type);
            
            // Update purchase history
            let mut history: PurchaseHistory = world.read_model((player, orb_type));
            history.record_purchase(price);
            
            // Remove orb from shop (find and remove it)
            self.remove_orb_from_shop(ref shop, orb_type);
            
            // Write all updated models
            world.write_model(@player_stats);
            world.write_model(@bag);
            world.write_model(@history);
            world.write_model(@shop);
            
            // Emit purchase event
            world.emit_event(@OrbPurchased { 
                player, 
                game_id, 
                orb_type,
                price_paid: price,
                purchase_count: history.purchase_count
            });
        }

        fn get_shop_contents(self: @ContractState, player: ContractAddress, game_id: u64, level: u8) -> (Array<OrbType>, Array<u32>) {
            let world = self.world_default();
            let shop: Shop = world.read_model((player, game_id, level));
            
            if shop.shop_generated {
                shop.get_shop_inventory()
            } else {
                (array![], array![])
            }
        }

        fn get_orb_price(self: @ContractState, player: ContractAddress, orb_type: OrbType) -> u32 {
            let world = self.world_default();
            let history: PurchaseHistory = world.read_model((player, orb_type));
            let base_price = get_base_orb_price(orb_type);
            
            // Calculate price with 20% scaling per purchase
            calculate_scaled_price(base_price, history.purchase_count)
        }

        fn refresh_shop(ref self: ContractState, game_id: u64) {
            let mut world = self.world_default();
            let player = get_caller_address();
            
            // Get current game state
            let game_state: GameState = world.read_model((player, game_id));
            assert(game_state.status == GameStatus::InProgress, 'Game not in progress');
            
            // Clear and regenerate shop
            let mut shop: Shop = world.read_model((player, game_id, game_state.current_level));
            shop.clear_shop();
            
            // Regenerate with new seed
            let seed = get_block_timestamp().into() + player.into() + game_id.into() + 999_felt252;
            shop.generate_shop_inventory(seed);
            
            // Write updated shop
            world.write_model(@shop);
            
            // Emit refresh event
            world.emit_event(@ShopRefreshed { 
                player, 
                game_id, 
                level: game_state.current_level
            });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter"
        fn world_default(self: @ContractState) -> WorldStorage {
            self.world(@"dojo_starter")
        }
        
        /// Remove specific orb from shop inventory
        fn remove_orb_from_shop(self: @ContractState, ref shop: Shop, target_orb: OrbType) {
            let mut new_orbs = array![];
            let mut new_prices = array![];
            let mut found = false;
            
            let orb_span = shop.available_orbs.span();
            let price_span = shop.orb_prices.span();
            let total_orbs = shop.available_orbs.len();
            
            let mut i = 0;
            while i < total_orbs {
                let orb = *orb_span.at(i);
                let price = *price_span.at(i);
                
                // Skip the first occurrence of target orb
                if orb == target_orb && !found {
                    found = true;
                } else {
                    new_orbs.append(orb);
                    new_prices.append(price);
                }
                i += 1;
            };
            
            // Update shop with new arrays
            shop.available_orbs = new_orbs;
            shop.orb_prices = new_prices;
        }
        
        /// Check if shop is valid and properly configured
        fn validate_shop(self: @ContractState, shop: @Shop) -> bool {
            // Check that orbs and prices arrays have same length
            if shop.available_orbs.len() != shop.orb_prices.len() {
                return false;
            }
            
            // Check that shop has expected number of orbs (should be 6 total)
            if shop.available_orbs.len() != ShopConfig::TOTAL_SHOP_ORBS {
                return false;
            }
            
            true
        }
        
        /// Get shop statistics for a player
        fn get_shop_stats(
            self: @ContractState, 
            player: ContractAddress, 
            game_id: u64
        ) -> (u32, u32, bool) {
            let world = self.world_default();
            let game_state: GameState = world.read_model((player, game_id));
            let shop: Shop = world.read_model((player, game_id, game_state.current_level));
            
            let total_orbs = shop.available_orbs.len();
            let current_level = game_state.current_level;
            let is_generated = shop.shop_generated;
            
            (total_orbs, current_level.into(), is_generated)
        }
        
        /// Calculate total value of current shop
        fn calculate_shop_value(self: @ContractState, player: ContractAddress, game_id: u64) -> u32 {
            let world = self.world_default();
            let game_state: GameState = world.read_model((player, game_id));
            let shop: Shop = world.read_model((player, game_id, game_state.current_level));
            
            let mut total_value = 0;
            let price_span = shop.orb_prices.span();
            let total_orbs = shop.orb_prices.len();
            
            let mut i = 0;
            while i < total_orbs {
                let price = *price_span.at(i);
                total_value += price;
                i += 1;
            };
            
            total_value
        }
    }
}