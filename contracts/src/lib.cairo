// Moon Bag - Dojo Game Library
// A push-your-luck bag-building game built on Starknet using Dojo

pub mod models {
    pub mod orb;
    pub mod game_state;
    pub mod player_stats;
    pub mod bag;
    pub mod level_progress;
    pub mod shop;
}

pub mod systems {
    pub mod game_management;
    pub mod orb_drawing;
    pub mod level_progression;
    pub mod shop_system;
}

pub mod helpers {
    pub mod orb_effects;
    pub mod game_progression;
    pub mod bag_management;
}

#[cfg(test)]
pub mod tests {
    pub mod models {
        pub mod test_orb_simple;
    }
    pub mod systems {
        pub mod test_game_management;
    }
}

// Re-export main components that exist
pub use models::orb::{OrbType, Orb};
pub use models::game_state::{GameState, GameStatus};
pub use models::player_stats::PlayerStats;
pub use models::bag::Bag;
pub use models::level_progress::LevelProgress;
pub use models::shop::{Shop, PurchaseHistory};