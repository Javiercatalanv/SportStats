import SwiftUI

struct ProfileView: View {
    @AppStorage(SettingsKey.userName) private var userName = "Javier Catalán"
    @AppStorage(SettingsKey.weightKg) private var weightKg = 0.0
    @AppStorage(SettingsKey.heightCm) private var heightCm = 0
    @AppStorage(SettingsKey.age) private var age = 0
    @AppStorage(SettingsKey.units) private var unitsRaw = Units.kg.rawValue

    private var units: Units { Units(rawValue: unitsRaw) ?? .kg }

    private var initials: String {
        let letters = userName.split(separator: " ").prefix(2).compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom) {
                    Text("Perfil").font(.screenTitle).foregroundStyle(Theme.ink)
                    Spacer()
                    NavigationLink(value: Route.settings) { CircleIconLabel(systemName: "gearshape") }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel("Configuración")
                }
                .padding(.top, 8)

                HStack(spacing: 18) {
                    Text(initials)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Theme.onInk)
                        .frame(width: 92, height: 92)
                        .background(Circle().fill(Theme.ink).shadow(color: Theme.shadow, radius: 10, x: 0, y: 6))
                    Text(userName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    NavigationLink(value: Route.editProfile) { SecondaryButtonLabel(title: "Editar") }
                        .buttonStyle(PressableStyle())
                }
                .card(padding: 22)

                SectionTitle(text: "Mis datos")
                HStack(spacing: 12) {
                    DataTile(label: "Peso", value: weightKg > 0 ? units.format(kg: weightKg) : "—")
                    DataTile(label: "Altura", value: heightCm > 0 ? "\(heightCm) cm" : "—")
                    DataTile(label: "Edad", value: age > 0 ? "\(age) años" : "—")
                }

                SectionTitle(text: "Cuenta")
                NavigationLink(value: Route.privacy) { SettingsRowLabel(title: "Privacidad") }
                    .buttonStyle(PressableStyle())
                    .card(corner: Theme.cornerMedium + 4, padding: 0)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
    }
}

private struct DataTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .card(corner: Theme.cornerMedium + 4, padding: 16)
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.userName) private var userName = "Javier Catalán"
    @AppStorage(SettingsKey.weightKg) private var weightKg = 0.0
    @AppStorage(SettingsKey.heightCm) private var heightCm = 0
    @AppStorage(SettingsKey.age) private var age = 0
    @AppStorage(SettingsKey.units) private var unitsRaw = Units.kg.rawValue

    @State private var name = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var ageText = ""

    private var units: Units { Units(rawValue: unitsRaw) ?? .kg }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackHeader(title: "Editar perfil")

                VStack(alignment: .leading, spacing: 10) {
                    FieldLabel("Nombre")
                    TextField("Tu nombre", text: $name)
                        .textInputAutocapitalization(.words)
                        .modifier(InputFieldStyle())
                    FieldLabel("Peso (\(units.rawValue))")
                    TextField("Ej.: 78", text: $weight).keyboardType(.decimalPad).modifier(InputFieldStyle())
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            FieldLabel("Altura (cm)")
                            TextField("Ej.: 185", text: $height).keyboardType(.numberPad).modifier(InputFieldStyle())
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            FieldLabel("Edad")
                            TextField("Ej.: 24", text: $ageText).keyboardType(.numberPad).modifier(InputFieldStyle())
                        }
                    }
                    PrimaryButton(title: "Guardar", isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty, action: save)
                        .padding(.top, 8)
                }
                .card(padding: 24)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .onAppear(perform: loadValues)
    }

    private func loadValues() {
        name = userName
        if weightKg > 0 {
            let shown = units == .kg ? weightKg : weightKg * 2.20462
            weight = String(format: units == .kg ? "%.1f" : "%.0f", shown)
        }
        height = heightCm > 0 ? "\(heightCm)" : ""
        ageText = age > 0 ? "\(age)" : ""
    }

    private func save() {
        userName = name.trimmingCharacters(in: .whitespaces)
        if let value = Double(weight.replacingOccurrences(of: ",", with: ".")) {
            weightKg = units == .kg ? value : value / 2.20462
        } else if weight.isEmpty {
            weightKg = 0
        }
        heightCm = Int(height) ?? 0
        age = Int(ageText) ?? 0
        Feedback.success()
        dismiss()
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackHeader(title: "Privacidad")
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tus datos se quedan en tu iPhone")
                        .font(.system(size: 20, weight: .bold))
                    Text("Suplementos, tomas, entrenos y datos del perfil se guardan solo en este dispositivo. No hay cuentas ni servidores propios.")
                    Text("La base de ejercicios se descarga una vez desde GitHub (free-exercise-db, de dominio público) y queda guardada en el iPhone. Las búsquedas se hacen en el dispositivo; la app no envía datos tuyos a ningún servidor.")
                }
                .font(.system(size: 17))
                .foregroundStyle(Theme.ink)
                .card(padding: 24)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
    }
}
