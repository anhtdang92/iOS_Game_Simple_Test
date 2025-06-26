import Foundation
import CoreHaptics
import UIKit

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
    
    private var engine: CHHapticEngine?
    
    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }
    
    func trigger(_ type: HapticType) {
        guard let engine = engine else {
            // Fallback for devices without CoreHaptics support
            triggerLegacyFeedback(for: type)
            return
        }
        
        var events = [CHHapticEvent]()
        
        switch type {
        case .light:
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0))
        case .medium:
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0))
        case .heavy:
            events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ], relativeTime: 0, duration: 0.2))
        case .success:
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0))
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0.1))
        case .error:
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0))
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ], relativeTime: 0.1))
        case .selection:
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ], relativeTime: 0))
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    private func triggerLegacyFeedback(for type: HapticType) {
        let generator: UIImpactFeedbackGenerator
        switch type {
        case .light, .selection:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            generator = UIImpactFeedbackGenerator(style: .heavy)
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        generator.prepare()
        generator.impactOccurred()
    }
} 