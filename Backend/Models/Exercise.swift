import Foundation

/// Ejercicio de free-exercise-db (https://github.com/yuhonas/free-exercise-db).
/// Las claves coinciden con `dist/exercises.json`, por eso basta el Codable automático.
struct Exercise: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let force: String?
    let level: String
    let mechanic: String?
    let equipment: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
    let category: String
    /// Rutas relativas, p. ej. "Box_Jump_Multiple_Response/0.jpg".
    let images: [String]

    static let imageBaseURL = URL(string: "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/")!

    /// Músculo principal.
    var muscle: String { primaryMuscles.first ?? "" }

    var imageURLs: [URL] { images.map { Self.imageBaseURL.appendingPathComponent($0) } }

    /// Se puede hacer en casa: sin equipo o con bandas elásticas.
    var isHomeFriendly: Bool {
        guard let equipment else { return true }
        return ["body only", "bands"].contains(equipment)
    }

    // MARK: Etiquetas en español

    var muscleLabel: String { Self.label(muscle, in: Self.muscleNames) }
    var categoryLabel: String { Self.label(category, in: Self.categoryNames) }
    var levelLabel: String { Self.label(level, in: Self.levelNames) }
    var equipmentLabel: String? { equipment.map { Self.label($0, in: Self.equipmentNames) } }

    private static func label(_ key: String, in names: [String: String]) -> String {
        names[key] ?? key.capitalized
    }

    static let muscleNames: [String: String] = [
        "abdominals": "Abdominales", "abductors": "Abductores", "adductors": "Aductores",
        "biceps": "Bíceps", "calves": "Pantorrillas", "chest": "Pecho", "forearms": "Antebrazos",
        "glutes": "Glúteos", "hamstrings": "Isquiotibiales", "lats": "Dorsales",
        "lower back": "Zona lumbar", "middle back": "Espalda media", "neck": "Cuello",
        "quadriceps": "Cuádriceps", "shoulders": "Hombros", "traps": "Trapecios", "triceps": "Tríceps",
    ]
    static let categoryNames: [String: String] = [
        "cardio": "Cardio", "olympic weightlifting": "Halterofilia", "plyometrics": "Pliometría",
        "powerlifting": "Powerlifting", "strength": "Fuerza", "stretching": "Estiramiento",
        "strongman": "Strongman",
    ]
    static let levelNames: [String: String] = [
        "beginner": "Principiante", "intermediate": "Intermedio", "expert": "Avanzado",
    ]
    static let equipmentNames: [String: String] = [
        "body only": "Peso corporal", "bands": "Bandas elásticas", "barbell": "Barra",
        "dumbbell": "Mancuernas", "cable": "Polea", "machine": "Máquina", "kettlebells": "Pesas rusas",
        "medicine ball": "Balón medicinal", "exercise ball": "Fitball", "foam roll": "Rodillo",
        "e-z curl bar": "Barra Z", "other": "Otro",
    ]
}

/// Filtro local sobre la base de ejercicios. Los campos vacíos no filtran.
struct ExerciseQuery: Hashable {
    /// Coincide si el nombre contiene alguno de estos textos.
    var names: [String] = []
    var categories: Set<String> = []
    /// Músculo principal.
    var muscles: Set<String> = []
    var mechanic: String? = nil

    func matches(_ exercise: Exercise) -> Bool {
        if !names.isEmpty, !names.contains(where: { exercise.name.localizedCaseInsensitiveContains($0) }) { return false }
        if !categories.isEmpty, !categories.contains(exercise.category) { return false }
        if !muscles.isEmpty, !muscles.contains(exercise.muscle) { return false }
        if let mechanic, exercise.mechanic != mechanic { return false }
        return true
    }
}
