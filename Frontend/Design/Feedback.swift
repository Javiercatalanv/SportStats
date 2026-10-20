import AudioToolbox
import UIKit

/// Sonido + vibración al marcar series y suplementos (se apaga en Configuración).
enum Feedback {
    static func success() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        playIfEnabled(1407)
    }

    static func tap() {
        UISelectionFeedbackGenerator().selectionChanged()
        playIfEnabled(1104)
    }

    private static func playIfEnabled(_ soundID: SystemSoundID) {
        let enabled = UserDefaults.standard.object(forKey: SettingsKey.soundsEnabled) as? Bool ?? true
        if enabled { AudioServicesPlaySystemSound(soundID) }
    }
}
