import Foundation

/// Represents the current state of the game session.
enum GameState {
    case choosingStarter
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
    @Published var gameState: GameState = .choosingStarter
    
    // Achievement tracking
    @Published var totalMatches: Int = 0
    @Published var maxCombo: Int = 0
    @Published var specialRunesCreated: Int = 0
    @Published var specialRuneTypes: Set<String> = []
    
    /// The player's currently active enchantment cards.
    @Published var activeEnchantments: [EnchantmentCard] = []
    
    /// The cards currently available for purchase in the shop.
    @Published var shopSelection: [EnchantmentCard] = []
    
    /// The cards available for the player to choose from at the start of a run.
    @Published var starterSelection: [EnchantmentCard] = []
    
    // A weak reference to the game board to avoid retain cycles.
    private weak var gameBoard: GameBoard?
    
    // Achievement manager reference
    private weak var achievementManager: AchievementManager?
    
    // Daily challenge manager reference
    private weak var dailyChallengeManager: DailyChallengeManager?
    
    init() {
        self.highScore = PersistenceManager.shared.loadHighScore()
    }
    
    func setup(with gameBoard: GameBoard) {
        self.gameBoard = gameBoard
    }
    
    func setupAchievements(with achievementManager: AchievementManager) {
        self.achievementManager = achievementManager
    }
    
    func setupDailyChallenges(with dailyChallengeManager: DailyChallengeManager) {
        self.dailyChallengeManager = dailyChallengeManager
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
                // Lvl 1: 5 runes, Lvl 2: 4 runes, Lvl 3: 3 runes
                let triggerCount = 6 - enchantment.level
                let fireRunes = matches.filter { board.grid[$0.x][$0.y]?.type == .fire }
                if fireRunes.count >= triggerCount {
                    // Turn one of the matched fire runes into a bomb.
                    if let bombCoord = fireRunes.first {
                        newBombs.insert(bombCoord)
                        specialRunesCreated += 1
                        specialRuneTypes.insert("bomb")
                    }
                }
                
            case "Tidal Affinity":
                let waterRunesMatched = matches.filter { board.grid[$0.x][$0.y]?.type == .water }.count
                if waterRunesMatched > 0 {
                    // Lvl 1: 2x, Lvl 2: 3x, Lvl 3: 4x
                    let bonusMultiplier = Double(enchantment.level)
                    pointsToAdd += Int(Double(waterRunesMatched * 10) * totalMultiplier * bonusMultiplier)
                }
                
            case "Stonemason's Secret":
                let earthRunesMatched = matches.filter { board.grid[$0.x][$0.y]?.type == .earth }.count
                if earthRunesMatched > 0 {
                    // Lvl 1: +1, Lvl 2: +1.5, Lvl 3: +2.0
                    newMultiplierBonus += 0.5 + (Double(enchantment.level) * 0.5)
                }
                
            case "Line Master":
                // Create line clearers for 4+ matches in a line
                if matches.count >= 4 {
                    // Determine if it's a horizontal or vertical line
                    let isHorizontal = matches.allSatisfy { $0.y == matches.first?.y }
                    let isVertical = matches.allSatisfy { $0.x == matches.first?.x }
                    
                    if isHorizontal || isVertical {
                        let direction: LineDirection = isHorizontal ? .horizontal : .vertical
                        if let centerCoord = matches.first {
                            board.setSpecialEffect(at: centerCoord, effect: .lineClearer(direction: direction))
                            specialRunesCreated += 1
                            specialRuneTypes.insert("lineClearer")
                        }
                    }
                }
                
            case "Color Weaver":
                // Create color changers for 6+ matches
                if matches.count >= 6 {
                    if let centerCoord = matches.first {
                        board.setSpecialEffect(at: centerCoord, effect: .colorChanger)
                        specialRunesCreated += 1
                        specialRuneTypes.insert("colorChanger")
                    }
                }
                
            case "Blast Radius":
                // Enhance existing bombs with larger radius
                let bombRunes = matches.filter { board.grid[$0.x][$0.y]?.specialEffect == .bomb }
                for bombCoord in bombRunes {
                    // Upgrade bomb to area clearer with radius 2
                    board.setSpecialEffect(at: bombCoord, effect: .areaClearer(radius: 2))
                    specialRuneTypes.insert("areaClearer")
                }
                
            case "Multiplier Mage":
                // Light runes act as multipliers
                let lightRunes = matches.filter { board.grid[$0.x][$0.y]?.type == .light }
                if lightRunes.count > 0 {
                    // Each light rune adds a multiplier effect
                    for lightCoord in lightRunes {
                        board.setSpecialEffect(at: lightCoord, effect: .multiplier)
                        specialRunesCreated += 1
                        specialRuneTypes.insert("multiplier")
                    }
                    // Bonus points for light rune matches
                    pointsToAdd += Int(Double(lightRunes.count * 15) * totalMultiplier)
                }
                
            default:
                break
            }
        }
        
        // Update achievement tracking
        totalMatches += matches.count
        maxCombo = max(maxCombo, comboCount)
        
        // Update achievements
        achievementManager?.updateProgress(type: .matches, value: totalMatches)
        achievementManager?.updateProgress(type: .combos, value: maxCombo)
        achievementManager?.updateProgress(type: .score, value: score + pointsToAdd)
        achievementManager?.updateProgress(type: .cards, value: activeEnchantments.count)
        achievementManager?.updateProgress(type: .specialRunes, value: specialRuneTypes.count)
        
        // Update daily challenges
        dailyChallengeManager?.updateProgress(type: .matches, value: totalMatches)
        dailyChallengeManager?.updateProgress(type: .combos, value: maxCombo)
        dailyChallengeManager?.updateProgress(type: .score, value: score + pointsToAdd)
        
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
            
            // Update level achievement
            achievementManager?.updateProgress(type: .levels, value: currentLevel)
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
    
    /// Spends gold to refresh the shop selection.
    func rerollShop() {
        let rerollCost = 10
        if gold >= rerollCost {
            gold -= rerollCost
            prepareShop()
        }
    }
    
    /// Logic for purchasing a card from the shop.
    func buyCard(_ card: EnchantmentCard) {
        if gold >= card.cost {
            gold -= card.cost
            activeEnchantments.append(card)
            // Remove the card from the selection so it can't be bought again
            shopSelection.removeAll { $0.id == card.id }
        }
    }
    
    /// Logic for selling an active enchantment.
    func sellCard(_ card: EnchantmentCard) {
        if let index = activeEnchantments.firstIndex(where: { $0.id == card.id }) {
            let soldCard = activeEnchantments.remove(at: index)
            gold += soldCard.cost / 2 // Get half the cost back
            // The card is now available to appear in the shop again
            prepareShop()
        }
    }
    
    /// Logic for upgrading an active enchantment.
    func upgradeCard(_ card: EnchantmentCard) {
        guard let cost = card.upgradeCost, gold >= cost else { return }
        
        if let index = activeEnchantments.firstIndex(where: { $0.id == card.id }) {
            gold -= cost
            activeEnchantments[index].level += 1
            SoundManager.shared.playSound(.levelComplete) // A satisfying upgrade sound
            HapticManager.shared.trigger(.success)
        }
    }
    
    /// Sets the chosen card, gives starting gold, and begins the game.
    func selectStarter(_ card: EnchantmentCard) {
        activeEnchantments = [card]
        gold = 15 // Start with enough gold for a reroll or a cheap card
        gameState = .playing
        gameBoard?.fillBoard()
    }
    
    /// Resets the game to its initial state for a new run.
    func startNewRun() {
        score = 0
        gold = 0
        currentLevel = 1
        scoreTarget = 1000
        movesRemaining = 20
        activeEnchantments.removeAll()
        
        // Prepare a selection of basic cards for the player to choose from.
        starterSelection = EnchantmentCard.allCards.filter { $0.cost <= 15 }.shuffled()
        
        gameState = .choosingStarter
    }
    
    /// Called when the player successfully clears a level.
    func levelCleared() {
        currentLevel += 1
        // Give slightly fewer moves for higher levels to increase difficulty
        movesRemaining = max(10, 20 - (currentLevel / 2)) // Lose a move every two levels
        // Use a more linear scaling for the score target to avoid an impossible curve.
        scoreTarget += 500 + (currentLevel * 150)
        gameState = .playing
    }
} 