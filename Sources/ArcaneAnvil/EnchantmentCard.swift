import Foundation

/// Defines the structure for an enchantment card, which provides passive buffs.
struct EnchantmentCard: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    
    // This is where we'll eventually add logic for the card's effect.
    // For now, it's just data.
}

// MARK: - Example Enchantments
extension EnchantmentCard {
    static let volcanicHeart = EnchantmentCard(
        name: "Volcanic Heart",
        description: "Matching 5 or more Fire runes creates a bomb that clears all surrounding runes."
    )
    
    static let tidalAffinity = EnchantmentCard(
        name: "Tidal Affinity",
        description: "All points from Water rune matches are worth 2x."
    )
    
    static let stonemasonsSecret = EnchantmentCard(
        name: "Stonemason's Secret",
        description: "Matching Earth runes also adds +1 to the score multiplier for the rest of the round."
    )
    
    static let chainReaction = EnchantmentCard(
        name: "Chain Reaction",
        description: "The first match in a cascade creates a lightning bolt that clears a random row."
    )
    
    static let earthenPact = EnchantmentCard(
        name: "Earthen Pact",
        description: "Matching Earth runes has a 25% chance to also create a random Gold Coin rune on the board."
    )
    
    static let galeForce = EnchantmentCard(
        name: "Gale Force",
        description: "Matching Air runes pushes all runes in the same row away from the match."
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