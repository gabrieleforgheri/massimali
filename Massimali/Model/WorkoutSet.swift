import Foundation
import SwiftData

/// Una singola serie eseguita durante un allenamento.
@Model
final class WorkoutSet {
    var uuid: UUID = UUID()
    var weight: Double = 0
    var reps: Int = 0
    var rpe: Double?
    var isWarmup: Bool = false
    var order: Int = 0
    var createdAt: Date = Date()
    /// `true` se questa serie ha fatto scattare un nuovo massimale.
    var isPersonalRecord: Bool = false

    var exercise: Exercise?
    var workout: Workout?

    init(
        weight: Double,
        reps: Int,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        order: Int = 0,
        exercise: Exercise? = nil,
        workout: Workout? = nil
    ) {
        self.uuid = UUID()
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.order = order
        self.createdAt = Date()
        self.exercise = exercise
        self.workout = workout
    }

    var volume: Double { weight * Double(reps) }

    func estimatedOneRepMax(using formula: OneRepMaxFormula) -> Double {
        formula.oneRepMax(weight: weight, reps: reps)
    }
}
