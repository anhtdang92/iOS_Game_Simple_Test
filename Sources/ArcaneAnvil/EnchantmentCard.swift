import Foundation

/// Defines the structure for an enchantment card, which provides passive buffs.
struct EnchantmentCard: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let cost: Int
    var level: Int = 1
    
    var maxLevel: Int {
        // Most cards will have 3 levels, but we could vary this later.
        return 3
    }
    
    var upgradeCost: Int? {
        if level >= maxLevel { return nil }
        // Cost to upgrade gets progressively more expensive.
        return cost * (level + 1)
    }
    
    var displayName: String {
        if level > 1 {
            return "\(name) Lvl. \(level)"
        }
        return name
    }
    
    // Conformance to Equatable should be based on the unique ID.
    static func == (lhs: EnchantmentCard, rhs: EnchantmentCard) -> Bool {
        lhs.id == rhs.id
    }
    
    // This is where we'll eventually add logic for the card's effect.
    // For now, it's just data.
}

// MARK: - Example Enchantments
extension EnchantmentCard {
    static let volcanicHeart = EnchantmentCard(
        name: "Volcanic Heart",
        description: "Matching 5 or more Fire runes creates a bomb that clears all surrounding runes.",
        cost: 25
    )
    
    static let tidalAffinity = EnchantmentCard(
        name: "Tidal Affinity",
        description: "All points from Water rune matches are worth 2x.",
        cost: 20
    )
    
    static let stonemasonsSecret = EnchantmentCard(
        name: "Stonemason's Secret",
        description: "Matching Earth runes also adds +1 to the score multiplier for the rest of the round.",
        cost: 30
    )
    
    static let chainReaction = EnchantmentCard(
        name: "Chain Reaction",
        description: "The first match in a cascade creates a lightning bolt that clears a random row.",
        cost: 25
    )
    
    static let earthenPact = EnchantmentCard(
        name: "Earthen Pact",
        description: "Matching Earth runes has a 25% chance to also create a random Gold Coin rune on the board.",
        cost: 15
    )
    
    static let galeForce = EnchantmentCard(
        name: "Gale Force",
        description: "Matching Air runes pushes all runes in the same row away from the match.",
        cost: 15
    )
    
    // The master list of all cards available in the game.
    static let allCards: [EnchantmentCard] = [
        .volcanicHeart,
        .tidalAffinity,
        .stonemasonsSecret,
        .chainReaction,
        .earthenPact,
        .galeForce
    ]
} 