import SwiftUI
import UIKit

/// Paleta tomada de los prototipos de Claude Design: fondo gris cálido,
/// tarjetas casi blancas con sombra suave y tinta casi negra.
enum Theme {
    static let background = Color(light: 0xEDECEC, dark: 0x111113)
    static let card = Color(light: 0xF7F7F7, dark: 0x1D1D20)
    static let cardRaised = Color(light: 0xFFFFFF, dark: 0x2A2A2E)
    static let field = Color(light: 0xFFFFFF, dark: 0x26262A)
    static let ink = Color(light: 0x1C1C1F, dark: 0xF4F4F5)
    static let inkSecondary = Color(light: 0x6B6B70, dark: 0xA1A1A8)
    static let inkMuted = Color(light: 0x9A9AA0, dark: 0x6E6E75)
    static let stroke = Color(light: 0xE2E2E4, dark: 0x34343A)
    static let disabled = Color(light: 0x98979B, dark: 0x4A4A50)
    static let selection = Color(light: 0xE6E5E6, dark: 0x2E2E33)
    static let shadow = Color(light: 0x000000, dark: 0x000000).opacity(0.08)
    /// Tinta invertida (texto sobre botones negros).
    static let onInk = Color(light: 0xFFFFFF, dark: 0x111113)

    static let cornerLarge: CGFloat = 32
    static let cornerMedium: CGFloat = 24
    static let gutter: CGFloat = 20
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Tarjetas

struct CardModifier: ViewModifier {
    var corner: CGFloat = Theme.cornerLarge
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: Theme.shadow, radius: 18, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                    .blendMode(.overlay)
            )
    }
}

extension View {
    func card(corner: CGFloat = Theme.cornerLarge, padding: CGFloat = 20) -> some View {
        modifier(CardModifier(corner: corner, padding: padding))
    }

    /// Fondo de pantalla común a todas las vistas.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}

// MARK: - Tipografía

extension Font {
    static let screenTitle = Font.system(size: 40, weight: .bold)
    static let sectionTitle = Font.system(size: 22, weight: .bold)
    static let eyebrow = Font.system(size: 13, weight: .semibold)
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.eyebrow)
            .tracking(1.4)
            .foregroundStyle(Theme.inkSecondary)
    }
}

struct SectionTitle: View {
    let text: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text).font(.sectionTitle).foregroundStyle(Theme.ink)
            Spacer()
            if let trailing { trailing }
        }
        .padding(.top, 8)
    }
}
