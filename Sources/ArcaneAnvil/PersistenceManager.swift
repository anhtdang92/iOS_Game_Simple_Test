import Foundation

/// Manages saving and loading persistent data, such as the high score.
class PersistenceManager {
    
    static let shared = PersistenceManager()
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let highScore = "highScore"
    }
    
    private init() {}
    
    /// Saves a new high score to UserDefaults.
    func saveHighScore(_ score: Int) {
        userDefaults.set(score, forKey: Keys.highScore)
        print("💾 New High Score Saved: \(score)")
    }
    
    /// Loads the high score from UserDefaults.
    /// - Returns: The saved high score, or 0 if none exists.
    func loadHighScore() -> Int {
        return userDefaults.integer(forKey: Keys.highScore)
    }
} 