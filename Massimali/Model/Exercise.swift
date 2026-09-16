import Foundation
import SwiftData

/// Un macchinario o esercizio di cui si tiene traccia il massimale.
@Model
final class Exercise {
    var uuid: UUID = UUID()
    var name: String = ""
    /// Salvato come stringa per restare compatibile con eventuali nuovi gruppi.
    var muscleGroupRaw: String = MuscleGroup.petto.rawValue
    var notes: String = ""
    /// Incremento minimo del carico su questo macchinario (kg).
    var incrementStep: Double = 2.5
    var sortIndex: Int = 0
    var isArchived: Bool = false
    /// Pittogramma scelto a mano. Vuoto = dedotto dal nome, così gli esercizi
    /// già esistenti e quelli creati da te ne hanno subito uno sensato.
    var glyphRaw: String = ""
    /// Foto del macchinario, già ridotta da `ImageStore`. Fuori dal database
    /// vero e proprio, altrimenti ogni query se la porterebbe dietro.
    @Attribute(.externalStorage) var photo: Data?
    /// Inquadratura della foto nel riquadro quadrato: −1…1 sull'asse che sborda,
    /// 0 al centro. Vedi `PhotoFraming`.
    var photoOffset: Double = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \MaxRecord.exercise)
    var records: [MaxRecord]? = []

    /// Le serie restano nello storico degli allenamenti anche se l'esercizio viene eliminato.
    @Relationship(deleteRule: .nullify, inverse: \WorkoutSet.exercise)
    var sets: [WorkoutSet]? = []

    init(
        name: String,
        muscleGroup: MuscleGroup,
        incrementStep: Double = 2.5,
        notes: String = "",
        sortIndex: Int = 0
    ) {
        self.uuid = UUID()
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.incrementStep = incrementStep
        self.notes = notes
        self.sortIndex = sortIndex
        self.createdAt = Date()
    }

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .petto }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var glyph: MachineGlyph {
        get { MachineGlyph(rawValue: glyphRaw) ?? MachineGlyph.suggested(for: name, group: muscleGroup) }
        set { glyphRaw = newValue.rawValue }
    }

    /// `true` se il pittogramma è stato scelto a mano invece che dedotto.
    var hasCustomGlyph: Bool { MachineGlyph(rawValue: glyphRaw) != nil }

    var recordList: [MaxRecord] { records ?? [] }
    var setList: [WorkoutSet] { sets ?? [] }

    /// Storico dei massimali dal più recente al più vecchio.
    var recordsByDateDesc: [MaxRecord] {
        recordList.sorted { $0.date > $1.date }
    }

    /// Il massimo vero fatto sul macchinario (vedi `MaxRanking`):
    /// più carico, poi più ripetizioni, a parità il più recente.
    var bestRecord: MaxRecord? {
        recordList.reduce(nil) { best, record in
            guard let best else { return record }
            if MaxRanking.beats(weight: record.weight, reps: record.reps, than: (best.weight, best.reps)) {
                return record
            }
            let samePerformance = abs(record.weight - best.weight) < MaxRanking.epsilon && record.reps == best.reps
            return samePerformance && record.date > best.date ? record : best
        }
    }

    /// Massimale attuale in kg: il carico vero sollevato, non una stima.
    var currentMax: Double? { bestRecord?.weight }

    /// Rampa di riscaldamento suggerita, calcolata sul carico vero e arrotondata
    /// al passo di questo macchinario. Vuota finché non c'è un massimale.
    var warmupPlan: [Warmup.Step] {
        Warmup.plan(base: currentMax, step: incrementStep)
    }

    /// Miglior carico registrato prima di una certa data, per i badge di variazione.
    func bestWeight(before date: Date) -> Double? {
        recordList.filter { $0.date < date }.map(\.weight).max()
    }
}
