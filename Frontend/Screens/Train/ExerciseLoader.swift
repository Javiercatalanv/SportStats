import Foundation
import Observation

/// Estado de carga de los ejercicios que pide una pantalla.
@Observable
final class ExerciseLoader {
    /// Un bloque de resultados por cada filtro pedido.
    private(set) var blocks: [[Exercise]] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Todos los resultados, sin duplicados, en el orden de los bloques.
    var exercises: [Exercise] {
        var seen = Set<String>()
        return blocks.joined().filter { seen.insert($0.id).inserted }
    }

    /// Filtra la base local (rápido); solo la primera vez en la vida de la app
    /// implica descargar los ejercicios.
    @MainActor
    func load(_ queries: [ExerciseQuery]) async {
        if blocks.isEmpty { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }
        do {
            blocks = try await ExerciseCatalog.shared.exercises(matching: queries)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func blocks(for place: TrainingPlace) -> [[Exercise]] {
        place == .home ? blocks.map { $0.filter(\.isHomeFriendly) } : blocks
    }

    func filtered(for place: TrainingPlace) -> [Exercise] {
        place == .home ? exercises.filter(\.isHomeFriendly) : exercises
    }
}
