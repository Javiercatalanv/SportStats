import SwiftUI

/// Detalle de una rutina: enfoque para voleibol, sesión de hoy y todos sus ejercicios.
struct RoutineDetailView: View {
    let goal: TrainingGoal

    @AppStorage(SettingsKey.trainingPlace) private var placeRaw = TrainingPlace.gym.rawValue
    @AppStorage(SettingsKey.restSeconds) private var restSeconds = 90
    @State private var loader = ExerciseLoader()
    @State private var activePlan: RoutinePlan?

    private var place: TrainingPlace { TrainingPlace(rawValue: placeRaw) ?? .gym }
    private var todaysPlan: RoutinePlan {
        RoutinePlan.make(goal: goal, blocks: loader.blocks(for: place), restSeconds: restSeconds)
    }

    var body: some View {
        let plan = todaysPlan
        let pool = loader.filtered(for: place)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackHeader(title: goal.title)

                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "Para el voleibol")
                    Text(goal.volleyballFocus)
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.ink)
                    HStack(spacing: 8) {
                        TagLabel(text: "\(goal.sets) series")
                        TagLabel(text: goal.reps)
                        TagLabel(text: "\(restSeconds) s descanso")
                    }
                    PrimaryButton(title: "Empezar sesión", systemImage: "play.fill",
                                  isEnabled: !plan.exercises.isEmpty) {
                        activePlan = plan
                    }
                    .padding(.top, 6)
                }
                .card(padding: 24)

                if !plan.exercises.isEmpty {
                    SectionTitle(text: "Sesión de hoy")
                    ExerciseRows(exercises: plan.exercises, goal: goal)
                }

                SectionTitle(text: place == .home ? "Todos los ejercicios para casa" : "Todos los ejercicios")
                ExerciseList(loader: loader, exercises: pool, goal: goal,
                             emptyMessage: place == .home
                                ? "No hay ejercicios sin equipo para este objetivo. Cambia a Gimnasio en Entrenar."
                                : "No hay ejercicios para este objetivo.",
                             retry: { await loader.load(goal.queries) })
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .task { await loader.load(goal.queries) }
        .fullScreenCover(item: $activePlan) { WorkoutSessionView(plan: $0) }
    }
}

struct AllRoutinesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackHeader(title: "Rutinas")
                ForEach(TrainingGoal.allCases) { goal in
                    NavigationLink(value: Route.routine(goal)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: goal.systemImage).font(.system(size: 22))
                                Text(goal.title).font(.system(size: 22, weight: .bold))
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSecondary)
                            }
                            Text(goal.volleyballFocus)
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.inkSecondary)
                                .multilineTextAlignment(.leading)
                            HStack(spacing: 8) {
                                TagLabel(text: "\(goal.sets) series")
                                TagLabel(text: goal.reps)
                            }
                        }
                        .foregroundStyle(Theme.ink)
                        .card(padding: 22)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
    }
}

struct MuscleGroupView: View {
    let group: MuscleGroup

    @AppStorage(SettingsKey.trainingPlace) private var placeRaw = TrainingPlace.gym.rawValue
    @State private var loader = ExerciseLoader()

    private var place: TrainingPlace { TrainingPlace(rawValue: placeRaw) ?? .gym }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackHeader(title: group.title)
                ExerciseList(loader: loader, exercises: loader.filtered(for: place), goal: nil,
                             emptyMessage: "No hay ejercicios para \(group.title.lowercased()) en modo \(place.label.lowercased()).",
                             retry: { await loader.load(group.queries) })
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .task { await loader.load(group.queries) }
    }
}

/// Búsqueda libre (botón "+" de Entrenar). Filtra la base local mientras escribes.
struct ExerciseSearchView: View {
    @State private var loader = ExerciseLoader()
    @State private var text = ""
    @State private var muscle = ""
    @State private var category = ""

    private let maxShown = 60

    private var query: ExerciseQuery {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return ExerciseQuery(names: trimmed.isEmpty ? [] : [trimmed],
                             categories: category.isEmpty ? [] : [category],
                             muscles: muscle.isEmpty ? [] : [muscle])
    }

    var body: some View {
        let results = loader.exercises.filter(query.matches)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackHeader(title: "Buscar")

                VStack(alignment: .leading, spacing: 14) {
                    TextField("Nombre en inglés (ej.: squat, jump)", text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .modifier(InputFieldStyle())
                    HStack(spacing: 12) {
                        filterMenu(title: "Músculo", selection: $muscle, options: Exercise.muscleNames)
                        filterMenu(title: "Tipo", selection: $category, options: Exercise.categoryNames)
                    }
                }
                .card(padding: 20)

                if !loader.exercises.isEmpty {
                    Text(results.count > maxShown
                         ? "\(results.count) resultados · mostrando \(maxShown)"
                         : "\(results.count) resultados")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                ExerciseList(loader: loader, exercises: Array(results.prefix(maxShown)), goal: nil,
                             emptyMessage: "Sin resultados. Prueba otro nombre o filtro.",
                             retry: { await loader.load([ExerciseQuery()]) })
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        // Un filtro vacío trae toda la base.
        .task { await loader.load([ExerciseQuery()]) }
    }

    private func filterMenu(title: String, selection: Binding<String>, options: [String: String]) -> some View {
        Menu {
            Picker(title, selection: selection) {
                Text("Cualquiera").tag("")
                ForEach(options.sorted { $0.value < $1.value }, id: \.key) { option in
                    Text(option.value).tag(option.key)
                }
            }
        } label: {
            HStack {
                Text(selection.wrappedValue.isEmpty ? title : (options[selection.wrappedValue] ?? title))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 13))
            }
            .modifier(InputFieldStyle())
        }
    }
}

// MARK: - Lista de ejercicios

/// Lista con estados de carga, error y vacío.
struct ExerciseList: View {
    let loader: ExerciseLoader
    let exercises: [Exercise]
    let goal: TrainingGoal?
    let emptyMessage: String
    var retry: (() async -> Void)? = nil

    var body: some View {
        if loader.isLoading && exercises.isEmpty {
            VStack(spacing: 10) {
                ProgressView()
                Text("Descargando la base de ejercicios…")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        } else if let error = loader.errorMessage, exercises.isEmpty {
            VStack(spacing: 14) {
                EmptyStateCard(systemImage: "wifi.exclamationmark", title: "No se pudieron cargar", message: error)
                if let retry {
                    SecondaryButton(title: "Reintentar") { Task { await retry() } }
                }
            }
        } else if exercises.isEmpty {
            EmptyStateCard(systemImage: "dumbbell", title: "Sin ejercicios", message: emptyMessage)
        } else {
            ExerciseRows(exercises: exercises, goal: goal)
        }
    }
}

struct ExerciseRows: View {
    let exercises: [Exercise]
    let goal: TrainingGoal?

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(exercises) { exercise in
                NavigationLink(value: Route.exercise(exercise, goal)) {
                    ExerciseRow(exercise: exercise)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 14) {
            ExerciseThumbnail(url: exercise.imageURLs.first, size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Text([exercise.muscleLabel, exercise.categoryLabel, exercise.levelLabel]
                    .filter { !$0.isEmpty }
                    .joined(separator: " · "))
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(10)
        .padding(.trailing, 8)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Theme.shadow, radius: 10, x: 0, y: 4)
        )
    }
}

/// Foto del ejercicio (se descarga al verla y queda en caché).
struct ExerciseThumbnail: View {
    let url: URL?
    var size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(Theme.inkMuted)
            }
        }
        .frame(width: size, height: size)
        .background(Theme.cardRaised)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
