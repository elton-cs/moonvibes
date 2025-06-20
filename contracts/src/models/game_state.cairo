use starknet::ContractAddress;

// ================================
// GameStatus Enum - Game state tracking
// ================================
#[derive(Copy, Drop, Serde, Introspect, PartialEq, Debug)]
pub enum GameStatus {
    NotStarted,
    InProgress,
    LevelComplete,
    GameOver,
    Finished,
}

// Convert GameStatus to felt252 for events and storage
impl GameStatusIntoFelt252 of Into<GameStatus, felt252> {
    fn into(self: GameStatus) -> felt252 {
        match self {
            GameStatus::NotStarted => 0,
            GameStatus::InProgress => 1,
            GameStatus::LevelComplete => 2,
            GameStatus::GameOver => 3,
            GameStatus::Finished => 4,
        }
    }
}

// ================================
// GameState Model - Core game state tracking
// ================================
#[derive(Drop, Serde)]
#[dojo::model]
pub struct GameState {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub game_id: u64,
    pub status: GameStatus,
    pub current_level: u8,
    pub bombs_pulled_this_level: u8,
    pub orbs_pulled_this_level: u8,
    pub started_at: u64,
    pub last_updated: u64,
}

// ================================
// GameState Helper Functions
// ================================
#[generate_trait]
pub impl GameStateImpl of GameStateTrait {
    // Validates game is in progress and can continue
    fn assert_in_progress(self: GameState) {
        assert(self.status == GameStatus::InProgress, 'Game not in progress');
    }
    
    // Validates game is complete and can advance to next level
    fn assert_level_complete(self: GameState) {
        assert(self.status == GameStatus::LevelComplete, 'Level not complete');
    }
    
    // Validates game is not started and can be started
    fn assert_not_started(self: GameState) {
        assert(self.status == GameStatus::NotStarted, 'Game already started');
    }
    
    // Check if game has ended (either GameOver or Finished)
    fn is_ended(self: GameState) -> bool {
        self.status == GameStatus::GameOver || self.status == GameStatus::Finished
    }
    
    // Check if game is active (InProgress or LevelComplete)
    fn is_active(self: GameState) -> bool {
        self.status == GameStatus::InProgress || self.status == GameStatus::LevelComplete
    }
    
    // Update last_updated timestamp
    fn update_timestamp(ref self: GameState, timestamp: u64) {
        self.last_updated = timestamp;
    }
    
    // Advance to next level
    fn advance_level(ref self: GameState) {
        self.current_level += 1;
        self.bombs_pulled_this_level = 0;
        self.orbs_pulled_this_level = 0;
        self.status = GameStatus::InProgress;
    }
    
    // Record orb pull
    fn record_orb_pull(ref self: GameState, is_bomb: bool) {
        self.orbs_pulled_this_level += 1;
        if is_bomb {
            self.bombs_pulled_this_level += 1;
        }
    }
    
    // Set game status
    fn set_status(ref self: GameState, status: GameStatus) {
        self.status = status;
    }
}