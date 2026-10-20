import SwiftUI

// MARK: - Botones

/// Botón circular flotante (engranaje, "+", volver).
struct CircleIconButton: View {
    let systemName: String
    var size: CGFloat = 52
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Theme.card)
                        .shadow(color: Theme.shadow, radius: 14, x: 0, y: 6)
                )
        }
        .buttonStyle(PressableStyle())
    }
}

/// Botón principal negro ("Empezar") o gris deshabilitado ("Añadir").
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled = true
    var fullWidth = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(Theme.onInk)
            .padding(.horizontal, 28)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 50)
            .background(Capsule().fill(isEnabled ? Theme.ink : Theme.disabled))
            .shadow(color: Theme.shadow, radius: 10, x: 0, y: 5)
        }
        .disabled(!isEnabled)
        .buttonStyle(PressableStyle())
    }
}

/// Botón blanco secundario ("Ver ejercicios", "Editar").
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { SecondaryButtonLabel(title: title) }
            .buttonStyle(PressableStyle())
    }
}

/// Aspecto del botón secundario, para usarlo también dentro de un NavigationLink.
/// Mantiene su ancho para que palabras cortas no se partan en dos líneas.
struct SecondaryButtonLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .padding(.horizontal, 22)
            .frame(minHeight: 50)
            .background(
                Capsule()
                    .fill(Theme.cardRaised)
                    .shadow(color: Theme.shadow, radius: 10, x: 0, y: 5)
            )
            .fixedSize(horizontal: true, vertical: false)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Control segmentado tipo píldora

struct PillSegmented<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String
    var height: CGFloat = 44
    var fontSize: CGFloat = 17

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.system(size: fontSize, weight: selected ? .semibold : .medium))
                        .foregroundStyle(selected ? Theme.ink : Theme.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, minHeight: height)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(Theme.cardRaised)
                                    .shadow(color: Theme.shadow, radius: 6, x: 0, y: 3)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Theme.selection))
    }
}

// MARK: - Filas y chips

/// Fila con icono circular, título, subtítulo y chevron (Mis rutinas).
struct IconRow: View {
    let systemImage: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Theme.cardRaised).shadow(color: Theme.shadow, radius: 6, x: 0, y: 3))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 19, weight: .medium)).foregroundStyle(Theme.ink)
                if let subtitle {
                    Text(subtitle).font(.system(size: 15)).foregroundStyle(Theme.inkSecondary)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerMedium + 4, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.shadow, radius: 12, x: 0, y: 5)
        )
        .contentShape(Rectangle())
    }
}

struct Chip: View {
    let title: String
    var isSelected = false

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(isSelected ? Theme.onInk : Theme.ink)
            .lineLimit(1)
            .padding(.horizontal, 22)
            .frame(minHeight: 48)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.ink : Theme.card)
                    .shadow(color: Theme.shadow, radius: 8, x: 0, y: 4)
            )
    }
}

struct TagLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.inkSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Theme.selection))
    }
}

struct EmptyStateCard: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Theme.cardRaised).shadow(color: Theme.shadow, radius: 8, x: 0, y: 4))
            Text(title).font(.system(size: 19, weight: .semibold)).foregroundStyle(Theme.ink)
            Text(message)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 28)
    }
}

// MARK: - Encabezados

/// Encabezado con botón "volver" y título grande (Suplementos, Configuración).
struct BackHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 18) {
            CircleIconButton(systemName: "chevron.left", size: 52) { dismiss() }
            Text(title)
                .font(.screenTitle)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer()
        }
        .padding(.top, 8)
    }
}

/// Encabezado con fecha, título y botón opcional a la derecha (Inicio, Entrenar).
struct DateHeader: View {
    let title: String
    var showDate = true
    var trailingIcon: String? = nil
    var trailingAction: () -> Void = {}

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                if showDate { Eyebrow(text: Date.now.longSpanish) }
                Text(title)
                    .font(.screenTitle)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer()
            if let trailingIcon {
                CircleIconButton(systemName: trailingIcon, action: trailingAction)
                    .padding(.bottom, 4)
            }
        }
        .padding(.top, 8)
    }
}

extension Date {
    /// "domingo 18 de octubre"
    var longSpanish: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CL")
        f.dateFormat = "EEEE d 'de' MMMM"
        return f.string(from: self)
    }
}
