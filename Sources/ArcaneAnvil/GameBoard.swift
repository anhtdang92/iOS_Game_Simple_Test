import Foundation

/// A simple structure to represent a coordinate on the game board.
struct Coordinate: Hashable, Equatable {
    let x: Int
    let y: Int
}

/// Manages the state of the game board, including the grid of runes.
class GameBoard: ObservableObject {
    
    let width: Int
    let height: Int
    
    /// The 2D array representing the grid of runes.
    @Published var grid: [[Rune?]]
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.grid = Array(repeating: Array(repeating: nil, count: height), count: width)
        
        fillBoard()
    }
    
    /// Fills the entire board with new, randomly generated runes, ensuring no initial matches.
    func fillBoard() {
        for x in 0..<width {
            for y in 0..<height {
                // To avoid initial matches, we can add more complex logic here later.
                // For now, a simple random fill is fine for building the core logic.
                grid[x][y] = createRandomRune()
            }
        }
    }
    
    /// Swaps two runes on the board.
    /// - Parameters:
    ///   - coord1: The coordinate of the first rune.
    ///   - coord2: The coordinate of the second rune.
    func swapRunes(at coord1: Coordinate, and coord2: Coordinate) {
        guard isCoordinateValid(coord1) && isCoordinateValid(coord2) else { return }
        
        let temp = grid[coord1.x][coord1.y]
        grid[coord1.x][coord1.y] = grid[coord2.x][coord2.y]
        grid[coord2.x][coord2.y] = temp
    }
    
    /// Finds all matches of 3 or more identical runes, both horizontally and vertically.
    /// - Returns: A set of coordinates for all runes that are part of a match.
    func findMatches() -> Set<Coordinate> {
        var matchedCoords = Set<Coordinate>()
        
        // Horizontal matches
        for y in 0..<height {
            for x in 0..<(width - 2) {
                guard let currentRune = grid[x][y] else { continue }
                if grid[x+1][y]?.type == currentRune.type && grid[x+2][y]?.type == currentRune.type {
                    for i in 0...2 {
                        matchedCoords.insert(Coordinate(x: x + i, y: y))
                    }
                    // Check for longer matches
                    for i in 3..<(width - x) {
                        if grid[x+i][y]?.type == currentRune.type {
                            matchedCoords.insert(Coordinate(x: x + i, y: y))
                        } else {
                            break // End of this match
                        }
                    }
                }
            }
        }
        
        // Vertical matches
        for x in 0..<width {
            for y in 0..<(height - 2) {
                guard let currentRune = grid[x][y] else { continue }
                if grid[x][y+1]?.type == currentRune.type && grid[x][y+2]?.type == currentRune.type {
                    for i in 0...2 {
                        matchedCoords.insert(Coordinate(x: x, y: y + i))
                    }
                    // Check for longer matches
                    for i in 3..<(height - y) {
                        if grid[x][y+i]?.type == currentRune.type {
                            matchedCoords.insert(Coordinate(x: x, y: y + i))
                        } else {
                            break // End of this match
                        }
                    }
                }
            }
        }
        
        return matchedCoords
    }
    
    /// Sets a special effect for the rune at a given coordinate.
    func setSpecialEffect(at coordinate: Coordinate, effect: SpecialEffect) {
        guard isCoordinateValid(coordinate) else { return }
        // Ensure the rune exists before trying to modify it.
        if grid[coordinate.x][coordinate.y] != nil {
            grid[coordinate.x][coordinate.y]?.specialEffect = effect
        }
    }
    
    /// Removes the runes at the specified coordinates, handling bomb detonations.
    func removeMatches(at coordinates: Set<Coordinate>) {
        var allCoordsToClear = coordinates
        
        for coord in coordinates {
            guard let rune = grid[coord.x][coord.y] else { continue }
            
            if rune.specialEffect == .bomb {
                let bombArea = areaOfEffect(for: .bomb, at: coord)
                allCoordsToClear.formUnion(bombArea)
            }
        }
        
        for coord in allCoordsToClear {
            if isCoordinateValid(coord) {
                grid[coord.x][coord.y] = nil
            }
        }
    }
    
    /// Determines the set of coordinates affected by a special effect at a central point.
    private func areaOfEffect(for effect: SpecialEffect, at center: Coordinate) -> Set<Coordinate> {
        var affectedCoords = Set<Coordinate>()
        switch effect {
        case .bomb:
            // A 3x3 square centered on the bomb
            for x in (center.x - 1)...(center.x + 1) {
                for y in (center.y - 1)...(center.y + 1) {
                    let coord = Coordinate(x: x, y: y)
                    if isCoordinateValid(coord) {
                        affectedCoords.insert(coord)
                    }
                }
            }
        case .lineClearer(let direction):
            switch direction {
            case .horizontal:
                // Clear entire row
                for x in 0..<width {
                    affectedCoords.insert(Coordinate(x: x, y: center.y))
                }
            case .vertical:
                // Clear entire column
                for y in 0..<height {
                    affectedCoords.insert(Coordinate(x: center.x, y: y))
                }
            case .cross:
                // Clear both row and column
                for x in 0..<width {
                    affectedCoords.insert(Coordinate(x: x, y: center.y))
                }
                for y in 0..<height {
                    affectedCoords.insert(Coordinate(x: center.x, y: y))
                }
            }
        case .colorChanger:
            // Change all runes of the same type on the board
            if let runeType = grid[center.x][center.y]?.type {
                for x in 0..<width {
                    for y in 0..<height {
                        if grid[x][y]?.type == runeType {
                            affectedCoords.insert(Coordinate(x: x, y: y))
                        }
                    }
                }
            }
        case .areaClearer(let radius):
            // Clear a circular area around the center
            for x in (center.x - radius)...(center.x + radius) {
                for y in (center.y - radius)...(center.y + radius) {
                    let coord = Coordinate(x: x, y: y)
                    if isCoordinateValid(coord) {
                        let distance = abs(x - center.x) + abs(y - center.y)
                        if distance <= radius {
                            affectedCoords.insert(coord)
                        }
                    }
                }
            }
        case .multiplier:
            // Multiplier runes don't clear anything, they just provide bonuses
            break
        }
        return affectedCoords
    }
    
    /// Clears an entire row, returning the coordinates of the cleared runes.
    func clearRow(at y: Int) -> Set<Coordinate> {
        var clearedCoords = Set<Coordinate>()
        guard y >= 0 && y < height else { return clearedCoords }
        
        for x in 0..<width {
            let coord = Coordinate(x: x, y: y)
            if grid[x][y] != nil {
                clearedCoords.insert(coord)
                grid[x][y] = nil
            }
        }
        return clearedCoords
    }
    
    /// Shifts runes down to fill any empty spaces below them.
    func shiftRunesDown() {
        for x in 0..<width {
            var emptySpaces = 0
            for y in (0..<height).reversed() { // Iterate from bottom to top
                if grid[x][y] == nil {
                    emptySpaces += 1
                } else if emptySpaces > 0 {
                    // Move the rune down by the number of empty spaces found
                    let runeToMove = grid[x][y]
                    grid[x][y] = nil
                    grid[x][y + emptySpaces] = runeToMove
                }
            }
        }
    }
    
    /// Fills any remaining empty spaces at the top of the board with new runes.
    func refillBoard() {
        for x in 0..<width {
            for y in 0..<height {
                if grid[x][y] == nil {
                    grid[x][y] = createRandomRune()
                }
            }
        }
    }
    
    /// Checks if a given coordinate is within the board's bounds.
    private func isCoordinateValid(_ coord: Coordinate) -> Bool {
        return coord.x >= 0 && coord.x < width && coord.y >= 0 && coord.y < height
    }
    
    /// Creates a single random rune.
    private func createRandomRune() -> Rune {
        guard let randomType = RuneType.allCases.randomElement() else {
            // Fallback to fire rune, though this should never happen.
            return Rune(type: .fire)
        }
        return Rune(type: randomType)
    }
} 