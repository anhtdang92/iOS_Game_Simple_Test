import Foundation

/// Represents a daily challenge
struct DailyChallenge: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let type: ChallengeType
    let target: Int
    let reward: Int
    var isCompleted: Bool = false
    var progress: Int = 0
    
    enum ChallengeType: String, Codable, CaseIterable {
        case score = "Score"
        case matches = "Matches"
        case combos = "Combos"
        case specialRunes = "Special Runes"
        case levels = "Levels"
        
        var icon: String {
            switch self {
            case .score: return "star.fill"
            case .matches: return "square.grid.3x3.fill"
            case .combos: return "bolt.fill"
            case .specialRunes: return "sparkles"
            case .levels: return "arrow.up.circle.fill"
            }
        }
    }
}

/// Manages daily challenges
class DailyChallengeManager: ObservableObject {
    @Published var todaysChallenges: [DailyChallenge] = []
    @Published var lastChallengeDate: Date?
    
    private let calendar = Calendar.current
    
    init() {
        loadChallenges()
        checkAndUpdateChallenges()
    }
    
    private func loadChallenges() {
        if let data = UserDefaults.standard.data(forKey: "DailyChallenges"),
           let challenges = try? JSONDecoder().decode([DailyChallenge].self, from: data) {
            todaysChallenges = challenges
        }
        
        if let dateData = UserDefaults.standard.data(forKey: "LastChallengeDate"),
           let date = try? JSONDecoder().decode(Date.self, from: dateData) {
            lastChallengeDate = date
        }
    }
    
    private func saveChallenges() {
        if let encoded = try? JSONEncoder().encode(todaysChallenges) {
            UserDefaults.standard.set(encoded, forKey: "DailyChallenges")
        }
        
        if let encoded = try? JSONEncoder().encode(lastChallengeDate) {
            UserDefaults.standard.set(encoded, forKey: "LastChallengeDate")
        }
    }
    
    private func checkAndUpdateChallenges() {
        let today = Date()
        
        if lastChallengeDate == nil || !calendar.isDate(lastChallengeDate!, inSameDayAs: today) {
            generateNewChallenges()
            lastChallengeDate = today
            saveChallenges()
        }
    }
    
    private func generateNewChallenges() {
        todaysChallenges = [
            DailyChallenge(
                title: "Score Master",
                description: "Score \(Int.random(in: 2000...5000)) points in a single run",
                type: .score,
                target: Int.random(in: 2000...5000),
                reward: 50
            ),
            DailyChallenge(
                title: "Match Maker",
                description: "Make \(Int.random(in: 30...80)) matches in a single run",
                type: .matches,
                target: Int.random(in: 30...80),
                reward: 30
            ),
            DailyChallenge(
                title: "Combo King",
                description: "Achieve a \(Int.random(in: 4...8))x combo",
                type: .combos,
                target: Int.random(in: 4...8),
                reward: 40
            )
        ]
    }
    
    func updateProgress(type: DailyChallenge.ChallengeType, value: Int) {
        for i in 0..<todaysChallenges.count {
            if todaysChallenges[i].type == type && !todaysChallenges[i].isCompleted {
                todaysChallenges[i].progress = max(todaysChallenges[i].progress, value)
                
                if todaysChallenges[i].progress >= todaysChallenges[i].target {
                    todaysChallenges[i].isCompleted = true
                    // Trigger achievement notification
                    SoundManager.shared.playSound(.achievement)
                    HapticManager.shared.trigger(.success)
                }
            }
        }
        saveChallenges()
    }
    
    var completedChallenges: [DailyChallenge] {
        return todaysChallenges.filter { $0.isCompleted }
    }
    
    var totalRewards: Int {
        return completedChallenges.reduce(0) { $0 + $1.reward }
    }
    
    var completionPercentage: Double {
        let completed = completedChallenges.count
        return Double(completed) / Double(todaysChallenges.count) * 100.0
    }
} 