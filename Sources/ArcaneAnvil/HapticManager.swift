import Foundation

/// Defines the different types of haptic feedback the game can produce.
enum HapticType {
    case light
    case medium
    case heavy
    case success
    case error
    case selection
}

/// A simple class to manage triggering haptic feedback.
/// In a real app, this would interact with CoreHaptics or UIImpactFeedbackGenerator.
class HapticManager {
    
    static let shared = HapticManager()
    
    private init() {}
    
    func trigger(_ type: HapticType) {
        // For now, we just print to the console to show the haptic is being triggered.
        // In Xcode, you would replace this with actual haptic engine calls.
        print("📳 Triggering Haptic: \(type)")
    }
} 