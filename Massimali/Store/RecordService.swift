import Foundation
import SwiftData

/// Regole di creazione dei massimali a partire dagli allenamenti.
enum RecordService {

    /// Tolleranza per evitare che un arrotondamento faccia scattare un falso record.
    private static let epsilon = MaxRanking.epsilon

    /// Registra una serie in coda all'allenamento e valuta subito il record.
    /// Unico percorso sia per la sessione sull'iPhone sia per le serie dal Watch.
    /// Restituisce `true` se è scattato un nuovo record.
    @discardableResult
    static func addSet(
        to workout: Workout,
        exercise: Exercise,
        weight: Double,
        reps: Int,
        isWarmup: Bool,
        context: ModelContext
    ) -> Bool {
        let order = (workout.setList.map(\.order).max() ?? -1) + 1
        let set = WorkoutSet(weight: weight, reps: reps, isWarmup: isWarmup, order: order)
        context.insert(set)
        set.exercise = exercise
        set.workout = workout
        let isRecord = evaluatePersonalRecord(for: set, context: context)
        try? context.save()
        return isRecord
    }

    /// Valuta una serie appena registrata: se batte il massimo vero fatto finora sul
    /// macchinario (più carico, o stesso carico con più ripetizioni), crea un
    /// `MaxRecord` automatico e marca la serie come PR.
    /// Restituisce `true` se è scattato un nuovo record.
    @discardableResult
    static func evaluatePersonalRecord(
        for set: WorkoutSet,
        context: ModelContext
    ) -> Bool {
        guard let exercise = set.exercise, !set.isWarmup, set.weight > 0, set.reps >= 1 else {
            return false
        }

        let best = exercise.bestRecord.map { (weight: $0.weight, reps: $0.reps) }
        guard MaxRanking.beats(weight: set.weight, reps: set.reps, than: best) else { return false }

        // Prima l'inserimento, poi la relazione: così l'oggetto è già gestito dal
        // contesto quando viene agganciato all'esercizio.
        let record = MaxRecord(
            weight: set.weight,
            reps: set.reps,
            date: set.createdAt,
            isEstimated: true,
            note: "Da allenamento"
        )
        context.insert(record)
        record.exercise = exercise
        set.isPersonalRecord = true
        return true
    }

    /// Rimuove il record automatico nato da questa serie, se esiste.
    /// Serve quando si cancella una serie per non lasciare in giro un massimale fantasma.
    static func removeAutomaticRecord(for set: WorkoutSet, context: ModelContext) {
        guard set.isPersonalRecord, let exercise = set.exercise else { return }
        let match = exercise.recordList.first { record in
            record.isEstimated
                && record.reps == set.reps
                && abs(record.weight - set.weight) < epsilon
                && abs(record.date.timeIntervalSince(set.createdAt)) < 1
        }
        if let match {
            context.delete(match)
        }
        set.isPersonalRecord = false
    }

    /// Massimali toccati durante una sessione, per il riepilogo di fine allenamento.
    static func personalRecords(in workout: Workout) -> [WorkoutSet] {
        workout.orderedSets.filter(\.isPersonalRecord)
    }
}
