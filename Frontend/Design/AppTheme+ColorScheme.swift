import SwiftUI

extension AppTheme {
    /// `nil` sigue el modo del sistema (opción "Auto").
    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .auto: nil
        }
    }
}
