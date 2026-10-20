import SwiftData
import SwiftUI

struct HomeView: View {
    @AppStorage(SettingsKey.userName) private var userName = "Javier Catalán"
    @AppStorage(SettingsKey.trainingDays) private var trainingDaysRaw = TrainingDaysCodec.defaultValue
    @Query(sort: [SortDescriptor(\Supplement.reminderHour), SortDescriptor(\Supplement.reminderMinute)])
    private var supplements: [Supplement]

    private var firstName: String {
        userName.split(separator: " ").first.map(String.init) ?? userName
    }

    private var todaysGoal: TrainingGoal? {
        TrainingGoal.forToday(trainingDays: TrainingDaysCodec.decode(trainingDaysRaw))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: Date.now.longSpanish)
                        Text("Hola, \(firstName)")
                            .font(.screenTitle)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    Spacer()
                    NavigationLink(value: Route.settings) {
                        CircleIconLabel(systemName: "gearshape")
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.bottom, 4)
                }
                .padding(.top, 8)

                SectionTitle(text: "Menú")
                HStack(spacing: 16) {
                    NavigationLink(value: Route.supplements) {
                        MenuTile(title: "Suplementos", systemImage: "pills")
                    }
                    NavigationLink(value: Route.progress) {
                        MenuTile(title: "Progreso", systemImage: "chart.xyaxis.line")
                    }
                }
                .buttonStyle(PressableStyle())

                SectionTitle(text: "Para hoy")
                TodayRoutineCard(goal: todaysGoal)

                if !supplements.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(supplements.enumerated()), id: \.element.id) { index, supplement in
                            SupplementCheckRow(supplement: supplement)
                            if index < supplements.count - 1 {
                                Divider().overlay(Theme.stroke).padding(.leading, 56)
                            }
                        }
                    }
                    .card(padding: 16)
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
    }
}

/// Versión "solo dibujo" del botón circular, para usar dentro de NavigationLink.
struct CircleIconLabel: View {
    let systemName: String
    var size: CGFloat = 52

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.4, weight: .medium))
            .foregroundStyle(Theme.ink)
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.card).shadow(color: Theme.shadow, radius: 14, x: 0, y: 6))
    }
}

struct MenuTile: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .regular))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
        }
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity, minHeight: 116)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.shadow, radius: 16, x: 0, y: 8)
        )
    }
}

private struct TodayRoutineCard: View {
    let goal: TrainingGoal?

    var body: some View {
        if let goal {
            NavigationLink(value: Route.routine(goal)) {
                IconRow(systemImage: goal.systemImage,
                        title: goal.title,
                        subtitle: "\(goal.exercisesPerSession) ejercicios · \(goal.sets) × \(goal.reps)")
            }
            .buttonStyle(PressableStyle())
        } else {
            HStack(spacing: 16) {
                Image(systemName: "bed.double")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Theme.cardRaised))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Día de descanso").font(.system(size: 19, weight: .medium))
                    Text("Recuperar también es entrenar.").font(.system(size: 15)).foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
            }
            .foregroundStyle(Theme.ink)
            .card(corner: Theme.cornerMedium + 4, padding: 14)
        }
    }
}
