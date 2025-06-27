import Foundation

/// Represents an achievement that can be unlocked by the player
struct Achievement: Identifiable, Codable {
    var id = UUID()
    let name: String
    let description: String
    let icon: String // SF Symbol name
    let type: AchievementType
    let requirement: Int
    var isUnlocked: Bool = false
    var progress: Int = 0
    let rarity: AchievementRarity
    
    enum AchievementType: String, Codable, CaseIterable {
        case score = "Score"
        case matches = "Matches"
        case combos = "Combos"
        case cards = "Cards"
        case levels = "Levels"
        case specialRunes = "Special Runes"
    }
    
    enum AchievementRarity: String, Codable, CaseIterable {
        case bronze = "Bronze"
        case silver = "Silver"
        case gold = "Gold"
        case platinum = "Platinum"
        
        var color: String {
            switch self {
            case .bronze: return "brown"
            case .silver: return "gray"
            case .gold: return "yellow"
            case .platinum: return "cyan"
            }
        }
    }
}

/// Manages achievement tracking and unlocking
class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: [Achievement] = []
    
    init() {
        setupAchievements()
        loadProgress()
    }
    
    private func setupAchievements() {
        achievements = [
            // Score achievements
            Achievement(name: "Novice Forger", description: "Reach 1,000 points in a single run", icon: "star.fill", type: .score, requirement: 1000, rarity: .bronze),
            Achievement(name: "Master Craftsman", description: "Reach 5,000 points in a single run", icon: "star.circle.fill", type: .score, requirement: 5000, rarity: .silver),
            Achievement(name: "Legendary Smith", description: "Reach 10,000 points in a single run", icon: "crown.fill", type: .score, requirement: 10000, rarity: .gold),
            
            // Match achievements
            Achievement(name: "Match Maker", description: "Make 50 matches in a single run", icon: "square.grid.3x3.fill", type: .matches, requirement: 50, rarity: .bronze),
            Achievement(name: "Match Master", description: "Make 100 matches in a single run", icon: "square.grid.3x3.square.fill", type: .matches, requirement: 100, rarity: .silver),
            
            // Combo achievements
            Achievement(name: "Combo Novice", description: "Achieve a 3x combo", icon: "bolt.fill", type: .combos, requirement: 3, rarity: .bronze),
            Achievement(name: "Combo Master", description: "Achieve a 5x combo", icon: "bolt.circle.fill", type: .combos, requirement: 5, rarity: .gold),
            
            // Card achievements
            Achievement(name: "Card Collector", description: "Own 3 enchantment cards", icon: "rectangle.stack.fill", type: .cards, requirement: 3, rarity: .bronze),
            Achievement(name: "Deck Builder", description: "Own 5 enchantment cards", icon: "rectangle.stack.badge.plus", type: .cards, requirement: 5, rarity: .silver),
            
            // Level achievements
            Achievement(name: "Level Climber", description: "Complete 5 levels", icon: "arrow.up.circle.fill", type: .levels, requirement: 5, rarity: .bronze),
            Achievement(name: "Tower Master", description: "Complete 10 levels", icon: "building.2.fill", type: .levels, requirement: 10, rarity: .gold),
            
            // Special rune achievements
            Achievement(name: "Bomb Maker", description: "Create 5 bombs in a single run", icon: "burst.fill", type: .specialRunes, requirement: 5, rarity: .bronze),
            Achievement(name: "Specialist", description: "Create 3 different types of special runes", icon: "sparkles", type: .specialRunes, requirement: 3, rarity: .silver)
        ]
    }
    
    /// Updates progress for a specific achievement type
    func updateProgress(type: Achievement.AchievementType, value: Int) {
        for i in 0..<achievements.count {
            if achievements[i].type == type && !achievements[i].isUnlocked {
                achievements[i].progress = max(achievements[i].progress, value)
                
                if achievements[i].progress >= achievements[i].requirement {
                    unlockAchievement(at: i)
                }
            }
        }
        saveProgress()
    }
    
    /// Unlocks an achievement and adds it to recently unlocked
    private func unlockAchievement(at index: Int) {
        achievements[index].isUnlocked = true
        achievements[index].progress = achievements[index].requirement
        
        let unlockedAchievement = achievements[index]
        recentlyUnlocked.append(unlockedAchievement)
        
        // Remove from recently unlocked after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.recentlyUnlocked.removeAll { $0.id == unlockedAchievement.id }
        }
        
        // Play sound and haptic feedback
        SoundManager.shared.playSound(.achievement)
        HapticManager.shared.trigger(.success)
    }
    
    /// Gets all achievements of a specific type
    func achievements(of type: Achievement.AchievementType) -> [Achievement] {
        return achievements.filter { $0.type == type }
    }
    
    /// Gets unlocked achievements
    var unlockedAchievements: [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    /// Gets locked achievements
    var lockedAchievements: [Achievement] {
        return achievements.filter { !$0.isUnlocked }
    }
    
    /// Calculates completion percentage
    var completionPercentage: Double {
        let unlocked = unlockedAchievements.count
        return Double(unlocked) / Double(achievements.count) * 100.0
    }
    
    // MARK: - Persistence
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "Achievements")
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: "Achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
    }
} 