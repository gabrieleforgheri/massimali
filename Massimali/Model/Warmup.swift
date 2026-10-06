import Foundation

/// Serie di riscaldamento suggerite a partire dal carico vero dell'esercizio.
///
/// La rampa è quella classica in palestra: si sale in tre serie scaricando le
/// ripetizioni, così ci si scalda senza arrivare stanchi alla serie vera.
/// I pesi stanno **sulla griglia del macchinario**: si parte dal massimale, che è un
/// peso che hai davvero inserito, e si scende di N passi fino al più vicino a quello
/// calcolato. Così anche un pacco sfalsato (5 → 8,75 → 12,5…) dà pesi inseribili.
enum Warmup {

    struct Step: Identifiable {
        let id = UUID()
        /// Frazione del massimale, es. 0.4 per il 40%.
        let percent: Double
        let reps: Int
        /// Peso in kg, già portato sulla griglia del macchinario.
        let weight: Double

        var percentLabel: String { "\(Int((percent * 100).rounded()))%" }
    }

    /// 40% × 10 → 60% × 6 → 80% × 3.
    static let ramp: [(percent: Double, reps: Int)] = [
        (0.40, 10),
        (0.60, 6),
        (0.80, 3)
    ]

    /// Il peso della griglia `anchor − n·step` più vicino a `weight`, mai sotto zero:
    /// se il più vicino fosse ≤ 0 si prende il più piccolo positivo della griglia.
    static func nearest(_ weight: Double, anchor: Double, step: Double) -> Double {
        guard step > 0 else { return max(0, (weight * 2).rounded() / 2) }
        let n = ((anchor - weight) / step).rounded()
        var candidate = anchor - n * step
        if candidate <= 0.0001 {
            candidate = anchor - ((anchor - 0.0001) / step).rounded(.down) * step
        }
        // Via il rumore della virgola mobile: 47,4999… resta 47,5.
        return (candidate * 100).rounded() / 100
    }

    /// La rampa completa, in percentuale del carico di riferimento (il massimale
    /// vero del macchinario). Vuota se non c'è ancora niente su cui calcolarla.
    static func plan(base: Double?, step: Double) -> [Step] {
        guard let base, base > 0 else { return [] }
        return ramp.map { entry in
            Step(
                percent: entry.percent,
                reps: entry.reps,
                weight: nearest(base * entry.percent, anchor: base, step: step)
            )
        }
    }
}
