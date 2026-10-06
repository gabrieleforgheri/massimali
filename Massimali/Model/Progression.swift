import Foundation

/// Doppia progressione: si resta sullo stesso carico aggiungendo ripetizioni finché
/// tutte le serie arrivano in cima al range, poi si sale di un passo e si riparte dal fondo.
enum Progression {

    struct Suggestion: Equatable {
        let weight: Double
        let reps: Int
    }

    /// `lastSession`: serie allenanti (niente riscaldamento) dell'ultima sessione.
    /// Conta solo il carico più pesante di quella sessione.
    static func next(
        lastSession: [(weight: Double, reps: Int)],
        step: Double,
        range: ClosedRange<Int>
    ) -> Suggestion? {
        guard let top = lastSession.map(\.weight).max(), top > 0 else { return nil }
        let topReps = lastSession.filter { abs($0.weight - top) < MaxRanking.epsilon }.map(\.reps)
        if topReps.allSatisfy({ $0 >= range.upperBound }) {
            return Suggestion(weight: top + step, reps: range.lowerBound)
        }
        let reps = min(max((topReps.max() ?? 0) + 1, range.lowerBound), range.upperBound)
        return Suggestion(weight: top, reps: reps)
    }
}
