import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.units) private var unitsRaw = Units.kg.rawValue
    @AppStorage(SettingsKey.theme) private var themeRaw = AppTheme.light.rawValue
    @AppStorage(SettingsKey.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(SettingsKey.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsKey.trainingDays) private var trainingDaysRaw = TrainingDaysCodec.defaultValue
    @AppStorage(SettingsKey.restSeconds) private var restSeconds = 90

    private let restOptions = [30, 45, 60, 90, 120, 150, 180]

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                BackHeader(title: "Configuración")

                GroupHeader("General")
                VStack(spacing: 0) {
                    SettingsRow(title: "Unidades") {
                        PillSegmented(options: Units.allCases, selection: binding($unitsRaw, default: Units.kg),
                                      label: \.rawValue, height: 38)
                            .frame(width: 150)
                    }
                    RowDivider()
                    SettingsRow(title: "Tema") {
                        PillSegmented(options: AppTheme.allCases, selection: binding($themeRaw, default: AppTheme.light),
                                      label: \.label, height: 38, fontSize: 16)
                            .frame(width: 240)
                    }
                    RowDivider()
                    ToggleRow(title: "Notificaciones", subtitle: "Recordatorios de suplementos", isOn: $notificationsEnabled)
                    RowDivider()
                    ToggleRow(title: "Sonidos", subtitle: "Al marcar series y suplementos", isOn: $soundsEnabled)
                }
                .card(padding: 0)

                GroupHeader("Entrenamiento")
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Días de entrenamiento").font(.system(size: 18)).foregroundStyle(Theme.ink)
                        TrainingDaysPicker(raw: $trainingDaysRaw)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                    RowDivider()
                    SettingsRow(title: "Descanso entre series") {
                        Menu {
                            Picker("Descanso", selection: $restSeconds) {
                                ForEach(restOptions, id: \.self) { Text("\($0) s").tag($0) }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(restSeconds) s")
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 13))
                            }
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                }
                .card(padding: 0)

                GroupHeader("Base de ejercicios")
                ExerciseDatabaseSection()

                GroupHeader("Cuenta")
                VStack(spacing: 0) {
                    NavigationLink(value: Route.editProfile) { SettingsRowLabel(title: "Editar perfil") }
                    RowDivider()
                    NavigationLink(value: Route.privacy) { SettingsRowLabel(title: "Privacidad") }
                }
                .buttonStyle(PressableStyle())
                .card(padding: 0)

                Text("Versión \(version)")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .onChange(of: notificationsEnabled) { _, _ in
            Task { await NotificationManager.rescheduleAll(in: modelContext) }
        }
    }

    private func binding<T: RawRepresentable>(_ raw: Binding<String>, default fallback: T) -> Binding<T> where T.RawValue == String {
        Binding(get: { T(rawValue: raw.wrappedValue) ?? fallback }, set: { raw.wrappedValue = $0.rawValue })
    }
}

// MARK: - Piezas

/// Estado de la copia local de free-exercise-db y opción de volver a descargarla.
private struct ExerciseDatabaseSection: View {
    @State private var count = 0
    @State private var lastSync: Date?
    @State private var isDownloading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(count > 0 ? "\(count) ejercicios guardados en el iPhone" : "Aún no se descargan los ejercicios")
                .font(.system(size: 18))
                .foregroundStyle(Theme.ink)
            Text(statusText)
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSecondary)
            SecondaryButton(title: isDownloading ? "Descargando…" : (count > 0 ? "Volver a descargar" : "Descargar ahora")) {
                Task { await download() }
            }
            .disabled(isDownloading)
        }
        .card(padding: 22)
        .task { await refreshStatus() }
    }

    private var statusText: String {
        if let errorMessage { return errorMessage }
        guard let lastSync else { return "Se descargan una sola vez (~1 MB) y luego funcionan sin internet." }
        let date = lastSync.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_CL")))
        return "Descargados el \(date). Solo hace falta volver a descargar si quieres ejercicios nuevos."
    }

    @MainActor
    private func refreshStatus() {
        count = ExerciseCatalog.shared.storedCount
        lastSync = ExerciseCatalog.shared.lastSync
    }

    @MainActor
    private func download() async {
        isDownloading = true
        errorMessage = nil
        do {
            try await ExerciseCatalog.shared.download()
            Feedback.success()
        } catch {
            errorMessage = error.localizedDescription
        }
        refreshStatus()
        isDownloading = false
    }
}

private struct GroupHeader: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Eyebrow(text: text)
            .padding(.leading, 12)
            .padding(.top, 14)
    }
}

private struct RowDivider: View {
    var body: some View {
        Divider().overlay(Theme.stroke).padding(.horizontal, 22)
    }
}

private struct SettingsRow<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Text(title).font(.system(size: 18)).foregroundStyle(Theme.ink)
            Spacer(minLength: 12)
            trailing
        }
        .padding(.horizontal, 22)
        .frame(minHeight: 72)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 18)).foregroundStyle(Theme.ink)
                Text(subtitle).font(.system(size: 15)).foregroundStyle(Theme.inkSecondary)
            }
        }
        .tint(Theme.ink)
        .padding(.horizontal, 22)
        .frame(minHeight: 76)
    }
}

/// Fila con chevron, usada como etiqueta de NavigationLink.
struct SettingsRowLabel: View {
    let title: String

    var body: some View {
        HStack {
            Text(title).font(.system(size: 18)).foregroundStyle(Theme.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.horizontal, 22)
        .frame(minHeight: 68)
        .contentShape(Rectangle())
    }
}

private struct TrainingDaysPicker: View {
    @Binding var raw: String

    var body: some View {
        let days = TrainingDaysCodec.decode(raw)
        HStack(spacing: 6) {
            ForEach(Weekday.allCases) { day in
                let selected = days.contains(day.rawValue)
                Button {
                    var updated = days
                    if selected { updated.remove(day.rawValue) } else { updated.insert(day.rawValue) }
                    raw = TrainingDaysCodec.encode(updated)
                    Feedback.tap()
                } label: {
                    Text(day.initial)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(selected ? Theme.onInk : Theme.ink)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(
                            Circle()
                                .fill(selected ? Theme.ink : Theme.cardRaised)
                                .overlay(Circle().strokeBorder(selected ? Color.clear : Theme.stroke))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.name)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
