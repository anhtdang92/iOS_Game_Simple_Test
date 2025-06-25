import Foundation

/// Represents the current state of the game session.
enum GameState {
    case playing
    case shop
    case levelComplete // This will now be more of a transition state
    case gameOver
}

/// A structure to hold the results of processing a set of matches.
struct TurnResult {
    let score: Int
    let newBombs: Set<Coordinate>
    let lightningStrikes: Int
    let matchCenter: Coordinate?
    let newMultiplierBonus: Double
}

/// Manages the overall game state, including score, level progression, and enchantments.
class GameManager: ObservableObject {
    
    @Published var score: Int = 0
    @Published var gold: Int = 0
    @Published var currentLevel: Int = 1
    @Published var scoreTarget: Int = 1000 // The score needed to clear the level
    @Published var movesRemaining: Int = 20 // Starting moves for the first level
    @Published var highScore: Int = 0
    @Published var gameState: GameState = .playing
    
    /// The player's currently active enchantment cards.
    @Published var activeEnchantments: [EnchantmentCard] = []
    
    /// The cards currently available for purchase in the shop.
    @Published var shopSelection: [EnchantmentCard] = []
    
    init() {
        // Start with our enchantments for testing.
        self.activeEnchantments = [.volcanicHeart, .tidalAffinity, .chainReaction, .stonemasonsSecret]
        self.highScore = PersistenceManager.shared.loadHighScore()
    }
    
    /// Decrements the move counter by one.
    func useMove() {
        if movesRemaining > 0 {
            movesRemaining -= 1
        }
    }
    
    /// Sets the game state to game over and checks for a new high score.
    func gameOver() {
        if score > highScore {
            highScore = score
            PersistenceManager.shared.saveHighScore(score)
        }
        gameState = .gameOver
    }
    
    /// Processes a set of matched runes to calculate score and determine resulting special effects.
    /// - Returns: A `TurnResult` containing the score and any new special effects to be triggered.
    func processMatches(matches: Set<Coordinate>, on board: GameBoard, comboCount: Int, currentMultiplier: Double, currentMultiplierBonus: Double) -> TurnResult {
        var pointsToAdd = 0
        var newBombs = Set<Coordinate>()
        var lightningStrikes = 0
        var newMultiplierBonus = currentMultiplierBonus
        
        // --- BASE SCORING ---
        // Base points are now modified by the current combo multiplier AND the turn-specific bonus.
        let totalMultiplier = currentMultiplier + currentMultiplierBonus
        let basePoints = matches.count * 10
        pointsToAdd += Int(Double(basePoints) * totalMultiplier)
        
        // --- ENCHANTMENT MODIFIERS ---
        for enchantment in activeEnchantments {
            switch enchantment.name {
                
            case "Chain Reaction":
                // Trigger on the first cascade (the second match in a sequence)
                if comboCount == 1 {
                    lightningStrikes += 1
                }
                
            case "Volcanic Heart":
                let fireRunes = matches.filter { board.grid[$0.x][$0.y]?.type == .fire }
                if fireRunes.count >= 5 {
                    // Turn one of the matched fire runes into a bomb.
                    // We'll pick the first one for simplicity.
                    if let bombCoord = fireRunes.first {
                        newBombs.insert(bombCoord)
                    }
                }
                
            case "Tidal Affinity":
                let waterRunesMatched = matches.filter { board.grid[$0.x][$0.y]?.type == .water }.count
                if waterRunesMatched > 0 {
                    // Also apply all multipliers to the bonus points.
                    pointsToAdd += Int(Double(waterRunesMatched * 10) * totalMultiplier)
                }
                
            case "Stonemason's Secret":
                let earthRunesMatched = matches.filter { board.grid[$0.x][$0.y]?.type == .earth }.count
                if earthRunesMatched > 0 {
                    // Increase the bonus for the *next* match in this turn.
                    newMultiplierBonus += 1.0
                }
                
            default:
                break
            }
        }
        
        // The final score for this specific match is calculated and returned.
        // The view loop will be responsible for updating the manager's state.
        let finalScore = pointsToAdd
        
        return TurnResult(score: finalScore, newBombs: newBombs, lightningStrikes: lightningStrikes, matchCenter: matches.first, newMultiplierBonus: newMultiplierBonus)
    }
    
    /// Updates the game state to show the level is complete and prepares the shop.
    func completeLevel() {
        if gameState == .playing {
            gameState = .shop
            prepareShop()
        }
    }
    
    /// Generates a new, random selection of cards for the shop.
    func prepareShop() {
        let allCards = EnchantmentCard.allCards
        // Filter out cards the player already owns
        let availableForPurchase = allCards.filter { card in !activeEnchantments.contains(where: { $0.name == card.name }) }
        
        // Shuffle and take a few to display
        shopSelection = Array(availableForPurchase.shuffled().prefix(3))
    }
    
    /// Logic for purchasing a card from the shop.
    func buyCard(_ card: EnchantmentCard) {
        let cost = 10 // Let's say all cards cost 10 for now
        if gold >= cost {
            gold -= cost
            activeEnchantments.append(card)
            // Remove the card from the selection so it can't be bought again
            shopSelection.removeAll { $0.id == card.id }
        }
    }
    
    /// Resets the game to its initial state for a new run.
    func startNewRun() {
        score = 0
        gold = 0
        currentLevel = 1
        scoreTarget = 1000
        movesRemaining = 20
        activeEnchantments.removeAll()
        gameState = .playing
        // TODO: Add logic to let the player choose a starting enchantment.
    }
    
    /// Called when the player successfully clears a level.
    func levelCleared() {
        currentLevel += 1
        // Give slightly fewer moves for higher levels to increase difficulty
        movesRemaining = max(10, 20 - currentLevel)
        scoreTarget = Int(Double(scoreTarget) * 1.5)
        gameState = .playing
    }
} 