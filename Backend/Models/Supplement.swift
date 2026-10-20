import Foundation
import SwiftData

@Model
final class Supplement {
    /// Identificador estable para enlazar la notificación con el suplemento.
    var uid: UUID
    var name: String
    var dose: String
    var reminderHour: Int
    var reminderMinute: Int
    var remindersEnabled: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SupplementLog.supplement)
    var logs: [SupplementLog] = []

    init(name: String, dose: String, hour: Int, minute: Int) {
        self.uid = UUID()
        self.name = name
        self.dose = dose
        self.reminderHour = hour
        self.reminderMinute = minute
        self.remindersEnabled = true
        self.createdAt = .now
    }

    var timeText: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    func wasTaken(on day: Date) -> Bool {
        logs.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    var isTakenToday: Bool { wasTaken(on: .now) }
}

@Model
final class SupplementLog {
    var date: Date
    var supplement: Supplement?

    /// Se enlaza al suplemento con `supplement.logs.append(_:)`.
    init(date: Date = .now) {
        self.date = date
    }
}

/// Entrenamiento completado, para la pantalla de Progreso.
@Model
final class WorkoutSession {
    var date: Date
    var goalRaw: String
    var exerciseCount: Int
    var setsCompleted: Int
    var durationSeconds: Int

    init(goal: TrainingGoal, exerciseCount: Int, setsCompleted: Int, durationSeconds: Int) {
        self.date = .now
        self.goalRaw = goal.rawValue
        self.exerciseCount = exerciseCount
        self.setsCompleted = setsCompleted
        self.durationSeconds = durationSeconds
    }

    var goal: TrainingGoal? { TrainingGoal(rawValue: goalRaw) }
}
