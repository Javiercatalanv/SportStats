import Foundation
import SwiftData

/// Copia local de un ejercicio, para no volver a descargar la base.
@Model
final class ExerciseRecord {
    @Attribute(.unique) var exerciseID: String
    var name: String
    var force: String?
    var level: String
    var mechanic: String?
    var equipment: String?
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var instructions: [String]
    var category: String
    var images: [String]

    init(_ exercise: Exercise) {
        exerciseID = exercise.id
        name = exercise.name
        force = exercise.force
        level = exercise.level
        mechanic = exercise.mechanic
        equipment = exercise.equipment
        primaryMuscles = exercise.primaryMuscles
        secondaryMuscles = exercise.secondaryMuscles
        instructions = exercise.instructions
        category = exercise.category
        images = exercise.images
    }

    var exercise: Exercise {
        Exercise(id: exerciseID, name: name, force: force, level: level, mechanic: mechanic,
                 equipment: equipment, primaryMuscles: primaryMuscles, secondaryMuscles: secondaryMuscles,
                 instructions: instructions, category: category, images: images)
    }
}
