// ================================
// Simple Orb Model Tests - Task 5.1
// Basic unit tests to validate test framework setup
// ================================

#[cfg(test)]
mod tests {
    use crate::models::orb::OrbType;

    #[test]
    #[available_gas(50000)]
    fn test_orb_creation() {
        let orb = OrbType::FivePoints;
        assert(orb == OrbType::FivePoints, 'Orb creation failed');
    }

    #[test]
    #[available_gas(50000)]
    fn test_orb_conversion() {
        let orb = OrbType::FivePoints;
        let felt_val: felt252 = orb.into();
        assert(felt_val == 4, 'Conversion failed');
    }

    #[test]
    #[available_gas(50000)]
    fn test_orb_equality() {
        let orb1 = OrbType::SingleBomb;
        let orb2 = OrbType::SingleBomb;
        assert(orb1 == orb2, 'Orb equality failed');
    }
}