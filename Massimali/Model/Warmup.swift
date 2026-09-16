import Foundation

/// Serie di riscaldamento suggerite a partire dal carico vero dell'esercizio.
///
/// La rampa è quella classica in palestra: si sale in tre serie scaricando le
/// ripetizioni, così ci si scalda senza arrivare stanchi alla serie vera.
/// I pesi vengono **arrotondati per difetto al passo del macchinario**: su una leg
/// press da 10 kg non ha senso suggerire 47,5 kg.
enum Warmup {

    struct Step: Identifiable {
        let id = UUID()
        /// Frazione del massimale, es. 0.4 per il 40%.
        let percent: Double
        let reps: Int
        /// Peso in kg, già arrotondato al passo del macchinario.
        let weight: Double

        var percentLabel: String { "\(Int((percent * 100).rounded()))%" }
    }

    /// 40% × 10 → 60% × 6 → 80% × 3.
    static let ramp: [(percent: Double, reps: Int)] = [
        (0.40, 10),
        (0.60, 6),
        (0.80, 3)
    ]

    /// Arrotonda al multiplo inferiore del passo, senza mai scendere sotto un passo.
    static func rounded(_ weight: Double, step: Double) -> Double {
        guard step > 0 else { return max(0, (weight * 2).rounded() / 2) }
        let multiples = (weight / step).rounded(.down)
        return Swift.max(step, multiples * step)
    }

    /// La rampa completa, in percentuale del carico di riferimento (il massimale
    /// vero del macchinario). Vuota se non c'è ancora niente su cui calcolarla.
    static func plan(base: Double?, step: Double) -> [Step] {
        guard let base, base > 0 else { return [] }
        return ramp.map { entry in
            Step(
                percent: entry.percent,
                reps: entry.reps,
                weight: rounded(base * entry.percent, step: step)
            )
        }
    }
}
