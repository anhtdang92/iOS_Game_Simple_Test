import Foundation

/// Defines all the sound effects that can be played in the game.
enum SoundEffect {
    case swap
    case match(comboCount: Int)
    case bombExplode
    case lightning
    case buyCard
    case levelComplete
    case gameOver
    case buttonClick
}

/// A simple class to manage playing sound effects.
/// In a real app, this would interact with AVFoundation or a similar audio engine.
class SoundManager {
    
    static let shared = SoundManager()
    
    private init() {}
    
    func playSound(_ effect: SoundEffect) {
        // For now, we just print to the console to show the sound is being triggered.
        // In Xcode, you would replace this with actual audio playback logic.
        print("🔊 Playing Sound: \(debugDescription(for: effect))")
    }
    
    private func debugDescription(for effect: SoundEffect) -> String {
        switch effect {
        case .swap:
            return "Swap"
        case .match(let comboCount):
            return "Match (Combo x\(comboCount))"
        case .bombExplode:
            return "Bomb Explosion"
        case .lightning:
            return "Lightning Strike"
        case .buyCard:
            return "Buy Card"
        case .levelComplete:
            return "Level Complete"
        case .gameOver:
            return "Game Over"
        case .buttonClick:
            return "UI Button Click"
        }
    }
} 