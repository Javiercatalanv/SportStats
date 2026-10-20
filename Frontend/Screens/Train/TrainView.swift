import SwiftUI

struct TrainView: View {
    @AppStorage(SettingsKey.trainingPlace) private var placeRaw = TrainingPlace.gym.rawValue
    @AppStorage(SettingsKey.trainingDays) private var trainingDaysRaw = TrainingDaysCodec.defaultValue
    @AppStorage(SettingsKey.restSeconds) private var restSeconds = 90

    @State private var loaders: [TrainingGoal: ExerciseLoader] = Dictionary(
        uniqueKeysWithValues: TrainingGoal.allCases.map { ($0, ExerciseLoader()) }
    )
    @State private var activePlan: RoutinePlan?

    private var place: Binding<TrainingPlace> {
        Binding(get: { TrainingPlace(rawValue: placeRaw) ?? .gym }, set: { placeRaw = $0.rawValue })
    }

    private var scheduledGoal: TrainingGoal? {
        TrainingGoal.forToday(trainingDays: TrainingDaysCodec.decode(trainingDaysRaw))
    }

    private func plan(for goal: TrainingGoal) -> RoutinePlan {
        let blocks = loaders[goal]?.blocks(for: place.wrappedValue) ?? []
        return RoutinePlan.make(goal: goal, blocks: blocks, restSeconds: restSeconds)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: Date.now.longSpanish)
                        Text("Entrenar").font(.screenTitle).foregroundStyle(Theme.ink)
                    }
                    Spacer()
                    NavigationLink(value: Route.search) { CircleIconLabel(systemName: "plus") }
                        .buttonStyle(PressableStyle())
                        .padding(.bottom, 4)
                        .accessibilityLabel("Buscar ejercicios")
                }
                .padding(.top, 8)

                PillSegmented(options: TrainingPlace.allCases, selection: place, label: \.label, height: 48, fontSize: 18)

                todayCard

                SectionTitle(text: "Mis rutinas", trailing: AnyView(
                    NavigationLink("Ver todas", value: Route.allRoutines)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.ink)
                ))
                VStack(spacing: 14) {
                    ForEach(TrainingGoal.allCases) { goal in
                        NavigationLink(value: Route.routine(goal)) {
                            IconRow(systemImage: goal.systemImage, title: goal.title, subtitle: rowSubtitle(goal))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }

                SectionTitle(text: "Ejercicios por grupo")
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(MuscleGroup.allCases) { group in
                            NavigationLink(value: Route.muscleGroup(group)) { Chip(title: group.title) }
                                .buttonStyle(PressableStyle())
                        }
                    }
                    .padding(.horizontal, Theme.gutter)
                    .padding(.vertical, 10)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -Theme.gutter)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .task { await loadAll() }
        .fullScreenCover(item: $activePlan) { plan in
            WorkoutSessionView(plan: plan)
        }
    }

    private func rowSubtitle(_ goal: TrainingGoal) -> String {
        if loaders[goal]?.isLoading == true { return "Cargando…" }
        return plan(for: goal).summary
    }

    @ViewBuilder
    private var todayCard: some View {
        let goal = scheduledGoal
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: goal == nil ? "Hoy toca descanso" : "Rutina de hoy")
            if let goal {
                let todaysPlan = plan(for: goal)
                Text(goal.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(loaders[goal]?.isLoading == true ? "Cargando ejercicios…" : todaysPlan.summary)
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.inkSecondary)
                if let error = loaders[goal]?.errorMessage, todaysPlan.exercises.isEmpty {
                    Text(error).font(.system(size: 15)).foregroundStyle(Theme.inkSecondary)
                    Button("Reintentar") { Task { await loadAll() } }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
                HStack(spacing: 14) {
                    PrimaryButton(title: "Empezar", systemImage: "play.fill",
                                  isEnabled: !todaysPlan.exercises.isEmpty, fullWidth: false) {
                        activePlan = todaysPlan
                    }
                    NavigationLink(value: Route.routine(goal)) {
                        Text("Ver ejercicios")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 22)
                            .frame(minHeight: 50)
                            .background(Capsule().fill(Theme.cardRaised).shadow(color: Theme.shadow, radius: 10, x: 0, y: 5))
                    }
                    .buttonStyle(PressableStyle())
                }
                .padding(.top, 8)
            } else {
                Text("Día de recuperación")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Si igual quieres entrenar, elige una rutina abajo. Puedes cambiar tus días en Configuración.")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .card(padding: 24)
    }

    private func loadAll() async {
        // La primera llamada descarga la base; las demás esperan esa misma descarga.
        await withTaskGroup(of: Void.self) { group in
            for (goal, loader) in loaders {
                group.addTask { await loader.load(goal.queries) }
            }
        }
    }
}
