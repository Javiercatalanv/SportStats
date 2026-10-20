import Foundation

/// Objetivos de entrenamiento orientados al voleibol.
enum TrainingGoal: String, CaseIterable, Identifiable, Codable {
    case upper, lower, plyometrics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upper: "Tren superior"
        case .lower: "Tren inferior"
        case .plyometrics: "Pliometría"
        }
    }

    var systemImage: String {
        switch self {
        case .upper: "figure.strengthtraining.traditional"
        case .lower: "figure.strengthtraining.functional"
        case .plyometrics: "figure.jumprope"
        }
    }

    /// Por qué este bloque importa en la cancha.
    var volleyballFocus: String {
        switch self {
        case .upper:
            "Potencia para el remate y el saque, estabilidad de hombro para bloquear y prevenir lesiones del manguito rotador. Prioriza empujes, tracciones y la zona escapular."
        case .lower:
            "La base de tu salto vertical y de los desplazamientos laterales en defensa. Fuerza de cuádriceps, glúteos, isquios y pantorrillas, más aductores para los cambios de dirección."
        case .plyometrics:
            "Convierte la fuerza en altura de salto: aterrizajes, rebotes y saltos reactivos que imitan el ataque y el bloqueo. Calidad por sobre cantidad, descanso completo."
        }
    }

    /// Prescripción sugerida por ejercicio.
    var sets: Int {
        switch self {
        case .upper: 3
        case .lower: 4
        case .plyometrics: 4
        }
    }

    var reps: String {
        switch self {
        case .upper: "8–10 reps"
        case .lower: "5–8 reps"
        case .plyometrics: "4–6 saltos"
        }
    }

    /// Ejercicios por sesión.
    var exercisesPerSession: Int { 6 }

    /// Filtros sobre la base local. Cada filtro es un "bloque" de la sesión:
    /// el plan del día toma ejercicios de cada bloque por turnos, para que no
    /// salgan seis ejercicios de pecho seguidos.
    var queries: [ExerciseQuery] {
        let lift: Set<String> = ["strength", "powerlifting"]
        switch self {
        case .upper:
            return [
                ExerciseQuery(categories: ["strength"], muscles: ["chest"], mechanic: "compound"),
                ExerciseQuery(categories: ["strength"], muscles: ["lats", "middle back"], mechanic: "compound"),
                ExerciseQuery(categories: ["strength"], muscles: ["shoulders"], mechanic: "compound"),
                // Lanzamientos con balón medicinal: transfieren al remate.
                ExerciseQuery(categories: ["plyometrics"],
                              muscles: ["chest", "shoulders", "triceps", "lats", "middle back", "traps", "abdominals"]),
                // Manguito rotador: salud del hombro del atacante.
                ExerciseQuery(names: ["external rotation", "internal rotation"]),
                ExerciseQuery(categories: ["strength"], muscles: ["triceps"]),
                ExerciseQuery(categories: ["strength"], muscles: ["abdominals"]),
            ]
        case .lower:
            return [
                ExerciseQuery(categories: lift, muscles: ["quadriceps"], mechanic: "compound"),
                ExerciseQuery(categories: lift, muscles: ["hamstrings", "glutes"]),
                ExerciseQuery(categories: ["strength"], muscles: ["calves"]),
                // Aductores y abductores: desplazamientos laterales en defensa.
                ExerciseQuery(categories: ["strength"], muscles: ["adductors", "abductors"]),
                ExerciseQuery(categories: ["strength"], muscles: ["abdominals", "lower back"]),
                // Cargadas y arranques: potencia de salto, al final por ser los más técnicos.
                ExerciseQuery(categories: ["olympic weightlifting"]),
            ]
        case .plyometrics:
            return [
                // Saltos verticales (cajón, profundidad, rodillas al pecho): ataque y bloqueo.
                ExerciseQuery(names: ["jump"], categories: ["plyometrics"]),
                // Saltos horizontales y laterales: desplazamientos en defensa.
                ExerciseQuery(names: ["hop", "bound", "skip"], categories: ["plyometrics"]),
                ExerciseQuery(categories: ["plyometrics"], muscles: ["quadriceps"]),
                ExerciseQuery(categories: ["plyometrics"], muscles: ["hamstrings", "glutes", "adductors", "abductors"]),
                // Lanzamientos con balón medicinal: potencia del brazo de remate.
                ExerciseQuery(categories: ["plyometrics"],
                              muscles: ["chest", "shoulders", "triceps", "lats", "middle back", "traps", "abdominals"]),
            ]
        }
    }

    /// Rutina del día: rota entre objetivos según el índice del día de entrenamiento.
    static func forToday(trainingDays: Set<Int>, date: Date = .now) -> TrainingGoal? {
        let weekday = Weekday.from(date)
        guard trainingDays.contains(weekday.rawValue) else { return nil }
        let ordered = trainingDays.sorted()
        let index = ordered.firstIndex(of: weekday.rawValue) ?? 0
        return allCases[index % allCases.count]
    }
}

/// Grupos musculares de los chips "Ejercicios por grupo".
enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest, back, legs, shoulders, arms, core, glutes, calves

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chest: "Pecho"
        case .back: "Espalda"
        case .legs: "Piernas"
        case .shoulders: "Hombros"
        case .arms: "Brazos"
        case .core: "Core"
        case .glutes: "Glúteos"
        case .calves: "Pantorrillas"
        }
    }

    var queries: [ExerciseQuery] {
        switch self {
        case .chest: [ExerciseQuery(muscles: ["chest"])]
        case .back: [ExerciseQuery(muscles: ["lats"]), ExerciseQuery(muscles: ["middle back"]), ExerciseQuery(muscles: ["lower back"])]
        case .legs: [ExerciseQuery(muscles: ["quadriceps"]), ExerciseQuery(muscles: ["hamstrings"]), ExerciseQuery(muscles: ["adductors", "abductors"])]
        case .shoulders: [ExerciseQuery(muscles: ["shoulders"]), ExerciseQuery(muscles: ["traps"])]
        case .arms: [ExerciseQuery(muscles: ["biceps"]), ExerciseQuery(muscles: ["triceps"]), ExerciseQuery(muscles: ["forearms"])]
        case .core: [ExerciseQuery(muscles: ["abdominals"])]
        case .glutes: [ExerciseQuery(muscles: ["glutes"])]
        case .calves: [ExerciseQuery(muscles: ["calves"])]
        }
    }
}

/// Lunes = 1 … Domingo = 7 (como en Configuración: L M M J V S D).
enum Weekday: Int, CaseIterable, Identifiable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    var initial: String { ["L", "M", "M", "J", "V", "S", "D"][rawValue - 1] }
    var name: String { ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"][rawValue - 1] }

    static func from(_ date: Date) -> Weekday {
        // Calendar: domingo = 1, lunes = 2 …
        let system = Calendar.current.component(.weekday, from: date)
        return Weekday(rawValue: system == 1 ? 7 : system - 1)!
    }
}
