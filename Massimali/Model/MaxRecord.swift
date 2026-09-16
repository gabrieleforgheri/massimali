import Foundation
import SwiftData

/// Una misurazione del massimale: peso × ripetizioni in una certa data.
/// Il 1RM non viene mai salvato, si ricalcola sempre dalla formula scelta.
@Model
final class MaxRecord {
    var uuid: UUID = UUID()
    var date: Date = Date()
    var weight: Double = 0
    var reps: Int = 1
    /// `true` quando il record nasce automaticamente da una serie di allenamento.
    var isEstimated: Bool = false
    var note: String = ""

    var exercise: Exercise?

    init(
        weight: Double,
        reps: Int = 1,
        date: Date = Date(),
        isEstimated: Bool = false,
        note: String = "",
        exercise: Exercise? = nil
    ) {
        self.uuid = UUID()
        self.weight = weight
        self.reps = reps
        self.date = date
        self.isEstimated = isEstimated
        self.note = note
        self.exercise = exercise
    }

    func estimatedOneRepMax(using formula: OneRepMaxFormula) -> Double {
        formula.oneRepMax(weight: weight, reps: reps)
    }
}
