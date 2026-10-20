import Foundation

/// Sesión del día armada a partir de los ejercicios del objetivo.
struct RoutinePlan: Identifiable {
    let goal: TrainingGoal
    let exercises: [Exercise]
    let restSeconds: Int

    var id: String { goal.rawValue }

    /// Elige los ejercicios de forma estable para el día (misma rutina si
    /// vuelves a abrir la app, distinta mañana), tomando uno de cada bloque
    /// por turnos para que la sesión quede equilibrada.
    static func make(goal: TrainingGoal, blocks: [[Exercise]], restSeconds: Int, date: Date = .now) -> RoutinePlan {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        var queues = blocks.map { block in
            block.sorted { stableHash($0.id, salt: day) < stableHash($1.id, salt: day) }
        }
        var picked: [Exercise] = []
        var used = Set<String>()
        while picked.count < goal.exercisesPerSession, queues.contains(where: { !$0.isEmpty }) {
            for index in queues.indices where picked.count < goal.exercisesPerSession {
                while let next = queues[index].first {
                    queues[index].removeFirst()
                    if used.insert(next.id).inserted {
                        picked.append(next)
                        break
                    }
                }
            }
        }
        return RoutinePlan(goal: goal, exercises: picked, restSeconds: restSeconds)
    }

    /// ~40 s por serie + descanso entre series.
    var estimatedMinutes: Int {
        let totalSets = exercises.count * goal.sets
        return max(1, totalSets * (40 + restSeconds) / 60)
    }

    var summary: String {
        exercises.isEmpty ? "Sin ejercicios cargados" : "\(estimatedMinutes) min · \(exercises.count) ejercicios"
    }

    private static func stableHash(_ text: String, salt: Int) -> UInt64 {
        // djb2: el hashValue de Swift cambia entre ejecuciones, este no.
        var hash: UInt64 = 5381 &+ UInt64(truncatingIfNeeded: salt)
        for byte in text.utf8 { hash = (hash &<< 5) &+ hash &+ UInt64(byte) }
        return hash
    }
}
