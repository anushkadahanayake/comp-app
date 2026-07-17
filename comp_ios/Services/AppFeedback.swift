import Foundation
import AudioToolbox
import UIKit

/// Centralized sound + haptic feedback gated by Settings toggles.
enum AppFeedback {
    static var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: "SoundEnabled") as? Bool ?? true
    }

    static var hapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: "HapticsEnabled") as? Bool ?? true
    }

    static func playTap() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    static func playSuccess() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1025)
    }

    static func playError() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1053)
    }

    static func playWarning() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1054)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(type)
        }

        switch type {
        case .success: playSuccess()
        case .error: playError()
        case .warning: playWarning()
        @unknown default: break
        }
    }
}
