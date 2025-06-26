import Foundation
import AVFoundation

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
    
    // A dictionary to cache audio players to avoid re-creating them.
    private var audioPlayers: [String: AVAudioPlayerNode] = [:]
    private let audioEngine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()

    private init() {
        audioEngine.attach(mixer)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    func playSound(_ effect: SoundEffect) {
        let (fileName, pitch): (String, Float) = {
            switch effect {
            case .swap:
                return ("swap.wav", 1.0) // Assume a default sound file name
            case .match(let comboCount):
                // Increase pitch for higher combos for a satisfying effect
                let pitch = 1.0 + (Float(comboCount) * 0.1)
                return ("match.wav", pitch)
            case .bombExplode:
                return ("explosion.mp3", 1.0)
            case .lightning:
                return ("lightning.wav", 1.0)
            case .buyCard:
                return ("buy.wav", 1.0)
            case .levelComplete:
                return ("levelComplete.mp3", 1.0)
            case .gameOver:
                return ("gameOver.mp3", 1.0)
            case .buttonClick:
                return ("click.wav", 1.0)
            }
        }()
        
        playSound(fileName: fileName, pitch: pitch)
    }

    private func playSound(fileName: String, pitch: Float) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("🔊 Could not find sound file: \(fileName)")
            return
        }
        
        do {
            let file = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return }
            try file.read(into: buffer)
            
            let player = AVAudioPlayerNode()
            let pitchEffect = AVAudioUnitTimePitch()
            
            pitchEffect.pitch = pitch * 1200 // Pitch is in cents
            
            audioEngine.attach(player)
            audioEngine.attach(pitchEffect)
            
            audioEngine.connect(player, to: pitchEffect, format: buffer.format)
            audioEngine.connect(pitchEffect, to: mixer, format: buffer.format)
            
            player.scheduleBuffer(buffer, at: nil, options: .interrupts) {
                // Disconnect and detach the node when it's done playing
                // to free up memory.
                self.audioEngine.disconnectNodeOutput(player)
                self.audioEngine.disconnectNodeOutput(pitchEffect)
                self.audioEngine.detach(player)
                self.audioEngine.detach(pitchEffect)
            }
            
            player.play()

        } catch {
            print("🔊 Could not play sound file: \(fileName), error: \(error)")
        }
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