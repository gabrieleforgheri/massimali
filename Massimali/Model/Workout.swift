import Foundation
import SwiftData

/// Una sessione di allenamento.
@Model
final class Workout {
    var uuid: UUID = UUID()
    var date: Date = Date()
    /// `nil` finché la sessione è in corso.
    var endedAt: Date?
    var note: String = ""

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workout)
    var sets: [WorkoutSet]? = []

    init(date: Date = Date(), note: String = "") {
        self.uuid = UUID()
        self.date = date
        self.note = note
    }

    var setList: [WorkoutSet] { sets ?? [] }

    var isActive: Bool { endedAt == nil }

    var orderedSets: [WorkoutSet] {
        setList.sorted { $0.order < $1.order }
    }

    /// Volume totale (kg × ripetizioni), riscaldamento escluso.
    var totalVolume: Double {
        setList.filter { !$0.isWarmup }.reduce(0) { $0 + $1.volume }
    }

    var workingSetCount: Int {
        setList.filter { !$0.isWarmup }.count
    }

    /// Esercizi toccati nella sessione, nell'ordine in cui sono comparsi.
    var exercisesInOrder: [Exercise] {
        var seen = Set<PersistentIdentifier>()
        var result: [Exercise] = []
        for set in orderedSets {
            guard let exercise = set.exercise else { continue }
            if seen.insert(exercise.persistentModelID).inserted {
                result.append(exercise)
            }
        }
        return result
    }

    func sets(for exercise: Exercise) -> [WorkoutSet] {
        orderedSets.filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
    }

    var duration: TimeInterval? {
        guard let endedAt else { return nil }
        return endedAt.timeIntervalSince(date)
    }
}
