import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    let goal: TrainingGoal?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackHeader(title: "Ejercicio")

                if !exercise.imageURLs.isEmpty {
                    ExercisePhotos(urls: exercise.imageURLs, height: 190)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(exercise.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    FlowTags(tags: [exercise.muscleLabel, exercise.categoryLabel, exercise.levelLabel].filter { !$0.isEmpty })
                    if let goal {
                        Text("En \(goal.title.lowercased()): \(goal.sets) × \(goal.reps)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
                .card(padding: 22)

                VStack(alignment: .leading, spacing: 10) {
                    if let equipment = exercise.equipmentLabel {
                        DetailLine(label: "Equipo", value: equipment)
                    }
                    if !exercise.secondaryMuscles.isEmpty {
                        DetailLine(label: "También trabaja",
                                   value: exercise.secondaryMuscles
                                    .map { Exercise.muscleNames[$0] ?? $0.capitalized }
                                    .joined(separator: ", "))
                    }
                    if let mechanic = exercise.mechanic {
                        DetailLine(label: "Tipo de movimiento", value: mechanic == "compound" ? "Multiarticular" : "Aislado")
                    }
                }
                .card(padding: 22)

                if !exercise.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow(text: "Cómo hacerlo")
                        InstructionSteps(steps: exercise.instructions)
                    }
                    .card(padding: 22)
                }

                Text("Ejercicios e imágenes de free-exercise-db (dominio público), en inglés.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkMuted)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
    }
}

private struct DetailLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.inkSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}

/// Pasos numerados.
struct InstructionSteps: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.onInk)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Theme.ink))
                    Text(step)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

struct FlowTags: View {
    let tags: [String]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { ForEach(tags, id: \.self) { TagLabel(text: $0) } }
            VStack(alignment: .leading, spacing: 8) { ForEach(tags, id: \.self) { TagLabel(text: $0) } }
        }
    }
}

/// Fotos de la posición inicial y final, lado a lado.
struct ExercisePhotos: View {
    let urls: [URL]
    var height: CGFloat

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(urls.prefix(2).enumerated()), id: \.offset) { index, url in
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        case .failure: Image(systemName: "photo").foregroundStyle(Theme.inkMuted)
                        default: ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background(Color.white)
                    .clipped()

                    if urls.count > 1 {
                        Text(index == 0 ? "Inicio" : "Final")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.55)))
                            .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous))
            }
        }
        .accessibilityHidden(true)
    }
}
