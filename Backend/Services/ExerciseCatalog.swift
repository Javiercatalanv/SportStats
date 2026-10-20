import Foundation
import SwiftData

enum ExerciseCatalogError: LocalizedError {
    case server(Int)
    case network

    var errorDescription: String? {
        switch self {
        case .server(let code):
            "No se pudo descargar la base de ejercicios (error \(code)). Intenta de nuevo más tarde."
        case .network:
            "Sin conexión. Conéctate a internet una vez para descargar los ejercicios; después funcionan sin red."
        }
    }
}

/// Base de ejercicios local.
///
/// La primera vez descarga `exercises.json` de free-exercise-db (una sola
/// petición, ~1 MB) y lo guarda en SwiftData. Después todas las búsquedas se
/// resuelven en el iPhone, sin red. Solo se vuelve a descargar si lo pides
/// desde Configuración.
@MainActor
final class ExerciseCatalog {
    static let shared = ExerciseCatalog()

    nonisolated static let sourceURL = URL(string: "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json")!

    private var cache: [Exercise]?
    private var downloadTask: Task<[Exercise], Error>?
    private var context: ModelContext { Persistence.container.mainContext }

    var lastSync: Date? { UserDefaults.standard.object(forKey: SettingsKey.exercisesSyncedAt) as? Date }
    var storedCount: Int { (try? context.fetchCount(FetchDescriptor<ExerciseRecord>())) ?? 0 }

    /// Todos los ejercicios, ordenados por nombre. Descarga solo si la base está vacía.
    func allExercises() async throws -> [Exercise] {
        if let cache { return cache }
        let stored = (try? context.fetch(FetchDescriptor<ExerciseRecord>(sortBy: [SortDescriptor(\.name)]))) ?? []
        if !stored.isEmpty {
            let exercises = stored.map(\.exercise)
            cache = exercises
            return exercises
        }
        return try await download()
    }

    /// Un grupo de resultados por filtro, en el mismo orden.
    func exercises(matching queries: [ExerciseQuery]) async throws -> [[Exercise]] {
        let all = try await allExercises()
        return queries.map { query in all.filter(query.matches) }
    }

    /// Descarga la base y reemplaza la copia local. Si ya hay una descarga en
    /// curso, espera esa en vez de hacer otra petición.
    @discardableResult
    func download() async throws -> [Exercise] {
        if let downloadTask { return try await downloadTask.value }
        let task = Task { () throws -> [Exercise] in
            let fresh = try await Self.fetchRemote().sorted { $0.name < $1.name }
            self.replaceStored(with: fresh)
            self.cache = fresh
            return fresh
        }
        downloadTask = task
        defer { downloadTask = nil }
        return try await task.value
    }

    private func replaceStored(with exercises: [Exercise]) {
        try? context.delete(model: ExerciseRecord.self)
        for exercise in exercises { context.insert(ExerciseRecord(exercise)) }
        try? context.save()
        UserDefaults.standard.set(Date.now, forKey: SettingsKey.exercisesSyncedAt)
    }

    private nonisolated static func fetchRemote() async throws -> [Exercise] {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: sourceURL)
        } catch {
            throw ExerciseCatalogError.network
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw ExerciseCatalogError.server(status) }
        return try JSONDecoder().decode([Exercise].self, from: data)
    }
}
