import Foundation

/// Defines special properties a rune can have, like being a bomb.
enum SpecialEffect: Equatable {
    case bomb
}

/// Represents the different types of elemental runes in the game.
enum RuneType: CaseIterable {
    case fire, water, earth, air, light
}

/// Represents a single rune on the game board.
struct Rune: Identifiable, Equatable {
    let id = UUID()
    let type: RuneType
    var specialEffect: SpecialEffect?
} 