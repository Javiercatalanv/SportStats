import SwiftData

enum Persistence {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Supplement.self, SupplementLog.self, WorkoutSession.self, ExerciseRecord.self)
        } catch {
            fatalError("No se pudo abrir la base de datos: \(error)")
        }
    }()
}
