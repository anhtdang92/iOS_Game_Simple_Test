import Foundation
import SwiftUI

/// Represents a tutorial step
struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let highlightArea: CGRect?
    let action: TutorialAction?
    let isRequired: Bool
    
    enum TutorialAction {
        case tapRune
        case buyCard
        case upgradeCard
        case completeLevel
    }
}

/// Manages the tutorial system
class TutorialManager: ObservableObject {
    @Published var currentStep: TutorialStep?
    @Published var isTutorialActive: Bool = false
    @Published var tutorialProgress: Int = 0
    
    private var tutorialSteps: [TutorialStep] = []
    private var hasCompletedTutorial: Bool {
        UserDefaults.standard.bool(forKey: "TutorialCompleted")
    }
    
    init() {
        setupTutorialSteps()
        if !hasCompletedTutorial {
            startTutorial()
        }
    }
    
    private func setupTutorialSteps() {
        tutorialSteps = [
            TutorialStep(
                title: "Welcome to Arcane Anvil!",
                description: "Match runes to create powerful enchantments and forge legendary items.",
                highlightArea: nil,
                action: nil,
                isRequired: true
            ),
            TutorialStep(
                title: "Match Runes",
                description: "Tap two adjacent runes to swap them and create matches of 3 or more.",
                highlightArea: nil,
                action: .tapRune,
                isRequired: true
            ),
            TutorialStep(
                title: "Special Runes",
                description: "Create special runes like bombs, line clearers, and multipliers for bigger scores!",
                highlightArea: nil,
                action: nil,
                isRequired: false
            ),
            TutorialStep(
                title: "Enchantment Cards",
                description: "After completing a level, visit the shop to buy powerful enchantment cards.",
                highlightArea: nil,
                action: .buyCard,
                isRequired: true
            ),
            TutorialStep(
                title: "Card Rarity",
                description: "Cards come in different rarities: Common (Gray), Rare (Blue), Epic (Purple), and Legendary (Orange).",
                highlightArea: nil,
                action: nil,
                isRequired: false
            ),
            TutorialStep(
                title: "Upgrade Cards",
                description: "Spend gold to upgrade your cards and make them more powerful.",
                highlightArea: nil,
                action: .upgradeCard,
                isRequired: false
            ),
            TutorialStep(
                title: "Achievements",
                description: "Complete challenges to unlock achievements and track your progress.",
                highlightArea: nil,
                action: nil,
                isRequired: false
            ),
            TutorialStep(
                title: "You're Ready!",
                description: "You now know the basics. Good luck on your forging journey!",
                highlightArea: nil,
                action: nil,
                isRequired: true
            )
        ]
    }
    
    func startTutorial() {
        isTutorialActive = true
        tutorialProgress = 0
        showNextStep()
    }
    
    func showNextStep() {
        if tutorialProgress < tutorialSteps.count {
            currentStep = tutorialSteps[tutorialProgress]
        } else {
            completeTutorial()
        }
    }
    
    func completeCurrentStep() {
        tutorialProgress += 1
        showNextStep()
    }
    
    func skipTutorial() {
        completeTutorial()
    }
    
    private func completeTutorial() {
        isTutorialActive = false
        currentStep = nil
        UserDefaults.standard.set(true, forKey: "TutorialCompleted")
    }
    
    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: "TutorialCompleted")
        startTutorial()
    }
    
    var progressPercentage: Double {
        return Double(tutorialProgress) / Double(tutorialSteps.count) * 100.0
    }
} 