import SwiftData
import SwiftUI

struct SupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Supplement.reminderHour), SortDescriptor(\Supplement.reminderMinute)])
    private var supplements: [Supplement]

    @State private var name = ""
    @State private var dose = ""
    @State private var time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    @FocusState private var focusedField: Field?

    private enum Field { case name, dose }

    private var canAdd: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackHeader(title: "Suplementos")

                addForm

                SectionTitle(text: "Mis suplementos")
                if supplements.isEmpty {
                    EmptyStateCard(
                        systemImage: "pills",
                        title: "Aún no tienes suplementos",
                        message: "Añade los que estás tomando para activar recordatorios y marcar cuándo los tomas."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(supplements.enumerated()), id: \.element.id) { index, supplement in
                            SupplementCheckRow(supplement: supplement, showsMenu: true)
                            if index < supplements.count - 1 {
                                Divider().overlay(Theme.stroke).padding(.leading, 56)
                            }
                        }
                    }
                    .card(padding: 16)

                    Text("Te avisaremos cada día a la hora indicada. Si ya lo marcaste, no te llega el aviso de ese día.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
    }

    private var addForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Añadir suplemento")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Theme.ink)

            FieldLabel("Nombre")
            TextField("Ej.: Creatina", text: $name)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($focusedField, equals: .name)
                .onSubmit { focusedField = .dose }
                .modifier(InputFieldStyle())

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel("Dosis")
                    TextField("Ej.: 5 g", text: $dose)
                        .focused($focusedField, equals: .dose)
                        .submitLabel(.done)
                        .modifier(InputFieldStyle())
                }
                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel("Hora")
                    HStack {
                        DatePicker("Hora", selection: $time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "es_CL"))
                        Spacer(minLength: 0)
                        Image(systemName: "clock").foregroundStyle(Theme.ink)
                    }
                    .padding(.leading, 6)
                    .padding(.trailing, 16)
                    .frame(minHeight: 54)
                    .background(fieldBackground)
                }
            }

            PrimaryButton(title: "Añadir", systemImage: "plus", isEnabled: canAdd, action: add)
                .padding(.top, 6)
        }
        .card(padding: 24)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Theme.field)
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.stroke))
    }

    private func add() {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        let supplement = Supplement(
            name: name.trimmingCharacters(in: .whitespaces),
            dose: dose.trimmingCharacters(in: .whitespaces),
            hour: parts.hour ?? 9,
            minute: parts.minute ?? 0
        )
        modelContext.insert(supplement)
        try? modelContext.save()
        Feedback.success()
        name = ""
        dose = ""
        focusedField = nil
        Task { await NotificationManager.rescheduleAll(in: modelContext) }
    }
}

struct FieldLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.inkSecondary)
    }
}

struct InputFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.field)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.stroke))
            )
    }
}

/// Fila con círculo para marcar la toma del día.
struct SupplementCheckRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var supplement: Supplement
    var showsMenu = false

    var body: some View {
        HStack(spacing: 14) {
            Button(action: toggle) {
                Image(systemName: supplement.isTakenToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(supplement.isTakenToday ? Theme.ink : Theme.inkMuted)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(supplement.isTakenToday ? "Marcar como no tomado" : "Marcar como tomado")

            VStack(alignment: .leading, spacing: 2) {
                Text(supplement.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .strikethrough(supplement.isTakenToday, color: Theme.inkMuted)
                HStack(spacing: 6) {
                    if !supplement.dose.isEmpty {
                        Text(supplement.dose)
                        Text("·")
                    }
                    Image(systemName: supplement.remindersEnabled ? "bell" : "bell.slash")
                        .font(.system(size: 12))
                    Text(supplement.timeText)
                }
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()

            if showsMenu {
                Menu {
                    Toggle("Recordatorio", isOn: Binding(
                        get: { supplement.remindersEnabled },
                        set: { newValue in
                            supplement.remindersEnabled = newValue
                            try? modelContext.save()
                            Task { await NotificationManager.rescheduleAll(in: modelContext) }
                        }
                    ))
                    Button("Eliminar", systemImage: "trash", role: .destructive, action: delete)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func toggle() {
        if supplement.isTakenToday {
            supplement.logs
                .filter { Calendar.current.isDateInToday($0.date) }
                .forEach { modelContext.delete($0) }
        } else {
            supplement.logs.append(SupplementLog())
            Feedback.success()
        }
        try? modelContext.save()
        Task { await NotificationManager.rescheduleAll(in: modelContext) }
    }

    private func delete() {
        modelContext.delete(supplement)
        try? modelContext.save()
        Task { await NotificationManager.rescheduleAll(in: modelContext) }
    }
}
