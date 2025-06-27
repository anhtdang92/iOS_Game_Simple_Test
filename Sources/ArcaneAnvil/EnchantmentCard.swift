import Foundation

/// Defines the rarity of enchantment cards
enum CardRarity: CaseIterable {
    case common
    case rare
    case epic
    case legendary
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .common: return 1.0
        case .rare: return 1.5
        case .epic: return 2.0
        case .legendary: return 3.0
        }
    }
}

/// Defines the structure for an enchantment card, which provides passive buffs.
struct EnchantmentCard: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let cost: Int
    let rarity: CardRarity
    var level: Int = 1
    
    var maxLevel: Int {
        // Legendary cards can go higher
        return rarity == .legendary ? 5 : 3
    }
    
    var upgradeCost: Int? {
        if level >= maxLevel { return nil }
        // Cost to upgrade gets progressively more expensive based on rarity
        return Int(Double(cost) * Double(level + 1) * rarity.multiplier)
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
        cost: 25,
        rarity: .rare
    )
    
    static let tidalAffinity = EnchantmentCard(
        name: "Tidal Affinity",
        description: "All points from Water rune matches are worth 2x.",
        cost: 20,
        rarity: .common
    )
    
    static let stonemasonsSecret = EnchantmentCard(
        name: "Stonemason's Secret",
        description: "Matching Earth runes also adds +1 to the score multiplier for the rest of the round.",
        cost: 30,
        rarity: .rare
    )
    
    static let chainReaction = EnchantmentCard(
        name: "Chain Reaction",
        description: "The first match in a cascade creates a lightning bolt that clears a random row.",
        cost: 25,
        rarity: .epic
    )
    
    static let earthenPact = EnchantmentCard(
        name: "Earthen Pact",
        description: "Matching Earth runes has a 25% chance to also create a random Gold Coin rune on the board.",
        cost: 15,
        rarity: .common
    )
    
    static let galeForce = EnchantmentCard(
        name: "Gale Force",
        description: "Matching Air runes pushes all runes in the same row away from the match.",
        cost: 15,
        rarity: .common
    )
    
    // New special rune creation cards
    static let lineMaster = EnchantmentCard(
        name: "Line Master",
        description: "Matching 4 runes in a line creates a line clearer that clears entire rows or columns.",
        cost: 35,
        rarity: .epic
    )
    
    static let colorWeaver = EnchantmentCard(
        name: "Color Weaver",
        description: "Matching 6+ runes creates a color changer that transforms all runes of that type.",
        cost: 40,
        rarity: .legendary
    )
    
    static let blastRadius = EnchantmentCard(
        name: "Blast Radius",
        description: "Bombs now clear a larger area and have a chance to create chain reactions.",
        cost: 30,
        rarity: .rare
    )
    
    static let multiplierMage = EnchantmentCard(
        name: "Multiplier Mage",
        description: "Light runes now act as multipliers, doubling the score of adjacent matches.",
        cost: 50,
        rarity: .legendary
    )
    
    // The master list of all cards available in the game.
    static let allCards: [EnchantmentCard] = [
        .volcanicHeart,
        .tidalAffinity,
        .stonemasonsSecret,
        .chainReaction,
        .earthenPact,
        .galeForce,
        .lineMaster,
        .colorWeaver,
        .blastRadius,
        .multiplierMage
    ]
} 