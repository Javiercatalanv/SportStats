import SwiftData
import SwiftUI

/// Sesión guiada: serie por serie, con temporizador de descanso.
struct WorkoutSessionView: View {
    let plan: RoutinePlan

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var exerciseIndex = 0
    @State private var setIndex = 0
    @State private var setsCompleted = 0
    @State private var restEndsAt: Date?
    @State private var startedAt = Date.now
    @State private var isFinished = false
    @State private var showInstructions = false
    @State private var confirmExit = false

    private var exercise: Exercise { plan.exercises[exerciseIndex] }
    private var totalSets: Int { plan.exercises.count * plan.goal.sets }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                CircleIconButton(systemName: "xmark", size: 46) {
                    if isFinished || setsCompleted == 0 { dismiss() } else { confirmExit = true }
                }
                Spacer()
                TimelineView(.periodic(from: startedAt, by: 1)) { context in
                    Text(Self.clock(Int(context.date.timeIntervalSince(startedAt))))
                        .font(.system(size: 17, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.inkSecondary)
                }
            }

            ProgressBar(value: Double(setsCompleted) / Double(max(totalSets, 1)))

            if isFinished {
                finishedView
            } else if let restEndsAt {
                restView(until: restEndsAt)
            } else {
                exerciseView
            }
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .screenBackground()
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .task(id: restEndsAt) {
            guard let restEndsAt else { return }
            let remaining = restEndsAt.timeIntervalSinceNow
            if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
            guard !Task.isCancelled, self.restEndsAt == restEndsAt else { return }
            Feedback.success()
            self.restEndsAt = nil
        }
        .confirmationDialog("¿Terminar el entrenamiento?", isPresented: $confirmExit, titleVisibility: .visible) {
            Button("Guardar y salir") { save(); dismiss() }
            Button("Salir sin guardar", role: .destructive) { dismiss() }
            Button("Seguir entrenando", role: .cancel) {}
        }
    }

    // MARK: Pantallas

    private var exerciseView: some View {
        VStack(spacing: 14) {
            ScrollView {
                exerciseContent
            }
            .scrollIndicators(.hidden)

            PrimaryButton(title: "Serie completada", systemImage: "checkmark", action: completeSet)
            Button("Saltar ejercicio", action: skipExercise)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .frame(maxWidth: .infinity)
        }
    }

    private var exerciseContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Eyebrow(text: "Ejercicio \(exerciseIndex + 1) de \(plan.exercises.count) · \(plan.goal.title)")
            if !exercise.imageURLs.isEmpty {
                ExercisePhotos(urls: exercise.imageURLs, height: 130)
            }
            Text(exercise.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            FlowTags(tags: [exercise.muscleLabel, exercise.levelLabel].filter { !$0.isEmpty })

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Serie \(setIndex + 1) de \(plan.goal.sets)")
                        .font(.system(size: 22, weight: .bold))
                    Spacer()
                    Text(plan.goal.reps)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .foregroundStyle(Theme.ink)
                HStack(spacing: 8) {
                    ForEach(0..<plan.goal.sets, id: \.self) { index in
                        Capsule()
                            .fill(index < setIndex ? Theme.ink : Theme.selection)
                            .frame(height: 8)
                    }
                }
            }
            .card(padding: 22)

            DisclosureGroup(isExpanded: $showInstructions) {
                InstructionSteps(steps: exercise.instructions)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } label: {
                Text("Cómo hacerlo").font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.ink)
            }
            .card(corner: Theme.cornerMedium, padding: 18)
        }
        .padding(.bottom, 8)
    }

    private func restView(until end: Date) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Eyebrow(text: "Descanso")
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Self.clock(max(0, Int(end.timeIntervalSince(context.date).rounded(.up)))))
                    .font(.system(size: 88, weight: .bold).monospacedDigit())
                    .foregroundStyle(Theme.ink)
            }
            Text("Siguiente: \(nextLabel)")
                .font(.system(size: 18))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            HStack(spacing: 14) {
                SecondaryButton(title: "+15 s") { restEndsAt = end.addingTimeInterval(15) }
                PrimaryButton(title: "Saltar descanso", systemImage: "forward.fill") { restEndsAt = nil }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var finishedView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.ink)
            Text("¡Sesión completada!")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("\(setsCompleted) series · \(Self.clock(Int(Date.now.timeIntervalSince(startedAt))))")
                .font(.system(size: 18))
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
            PrimaryButton(title: "Listo") { dismiss() }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Lógica

    private var nextLabel: String {
        if setIndex > 0 { return "serie \(setIndex + 1) de \(exercise.name)" }
        return exercise.name
    }

    private func completeSet() {
        Feedback.success()
        setsCompleted += 1
        if setIndex + 1 < plan.goal.sets {
            setIndex += 1
            startRest()
        } else {
            advanceExercise()
        }
    }

    private func skipExercise() {
        Feedback.tap()
        advanceExercise()
    }

    private func advanceExercise() {
        if exerciseIndex + 1 < plan.exercises.count {
            exerciseIndex += 1
            setIndex = 0
            showInstructions = false
            startRest()
        } else {
            finish()
        }
    }

    private func startRest() {
        restEndsAt = Date.now.addingTimeInterval(TimeInterval(plan.restSeconds))
    }

    private func finish() {
        restEndsAt = nil
        save()
        withAnimation { isFinished = true }
    }

    private func save() {
        guard setsCompleted > 0 else { return }
        let session = WorkoutSession(
            goal: plan.goal,
            exerciseCount: exerciseIndex + 1,
            setsCompleted: setsCompleted,
            durationSeconds: Int(Date.now.timeIntervalSince(startedAt))
        )
        modelContext.insert(session)
        try? modelContext.save()
    }

    static func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.selection)
                Capsule().fill(Theme.ink).frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 6)
        .animation(.spring(response: 0.4), value: value)
    }
}
