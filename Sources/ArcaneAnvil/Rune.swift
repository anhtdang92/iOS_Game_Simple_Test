import Foundation

/// Defines special properties a rune can have, like being a bomb.
enum SpecialEffect: Equatable {
    case bomb
    case lineClearer(direction: LineDirection)
    case colorChanger
    case areaClearer(radius: Int)
    case multiplier
}

/// Defines the direction for line clearing effects
enum LineDirection: CaseIterable {
    case horizontal
    case vertical
    case cross // Both horizontal and vertical
}

/// Represents the different types of elemental runes in the game.
enum RuneType: CaseIterable {
    case fire, water, earth, air, light
    
    var displayName: String {
        switch self {
        case .fire: return "Fire"
        case .water: return "Water"
        case .earth: return "Earth"
        case .air: return "Air"
        case .light: return "Light"
        }
    }
    
    var emoji: String {
        switch self {
        case .fire: return "🔥"
        case .water: return "💧"
        case .earth: return "🌍"
        case .air: return "💨"
        case .light: return "✨"
        }
    }
    
    var color: String {
        switch self {
        case .fire: return "red"
        case .water: return "blue"
        case .earth: return "brown"
        case .air: return "cyan"
        case .light: return "yellow"
        }
    }
}

/// Represents a single rune on the game board.
struct Rune: Identifiable, Equatable {
    let id = UUID()
    let type: RuneType
    var specialEffect: SpecialEffect?
    var powerLevel: Int = 1 // For future enhancement system
    
    /// Creates a special rune with enhanced effects
    static func createSpecial(type: RuneType, effect: SpecialEffect) -> Rune {
        return Rune(type: type, specialEffect: effect, powerLevel: 2)
    }
    
    /// Creates a basic rune
    static func createBasic(type: RuneType) -> Rune {
        return Rune(type: type, specialEffect: nil, powerLevel: 1)
    }
} 