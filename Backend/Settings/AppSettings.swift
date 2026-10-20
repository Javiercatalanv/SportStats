import Foundation

/// Claves de `@AppStorage` compartidas entre pantallas.
enum SettingsKey {
    static let userName = "userName"
    static let weightKg = "weightKg"
    static let heightCm = "heightCm"
    static let age = "age"
    static let units = "units"
    static let theme = "theme"
    static let notificationsEnabled = "notificationsEnabled"
    static let soundsEnabled = "soundsEnabled"
    static let trainingDays = "trainingDays"
    static let restSeconds = "restSeconds"
    static let trainingPlace = "trainingPlace"
    static let exercisesSyncedAt = "exercisesSyncedAt"
}

enum Units: String, CaseIterable {
    case kg, lb

    func format(kg: Double) -> String {
        switch self {
        case .kg: String(format: "%.1f kg", kg)
        case .lb: String(format: "%.0f lb", kg * 2.20462)
        }
    }
}

enum AppTheme: String, CaseIterable {
    case light, dark, auto

    var label: String {
        switch self {
        case .light: "Claro"
        case .dark: "Oscuro"
        case .auto: "Auto"
        }
    }
}

enum TrainingPlace: String, CaseIterable {
    case gym, home

    var label: String { self == .gym ? "Gimnasio" : "Casa" }
}

/// Los días se guardan como texto "1,3,5" (lunes, miércoles, viernes).
enum TrainingDaysCodec {
    static let defaultValue = "1,3,5"

    static func decode(_ raw: String) -> Set<Int> {
        Set(raw.split(separator: ",").compactMap { Int($0) })
    }

    static func encode(_ days: Set<Int>) -> String {
        days.sorted().map(String.init).joined(separator: ",")
    }
}
