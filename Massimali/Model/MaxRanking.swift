import Foundation

/// Come si confrontano due prestazioni sullo stesso macchinario.
///
/// Conta quello che hai davvero caricato, non una stima: **prima il peso, poi le
/// ripetizioni**. Quindi 85 × 3 batte 80 × 8 (più carico), e a parità di carico
/// 80 × 8 batte 80 × 5. Il 1RM stimato resta solo una nota a margine e non
/// partecipa mai a questa decisione.
enum MaxRanking {

    /// Tolleranza per evitare che un arrotondamento faccia scattare un falso record.
    static let epsilon = 0.01

    /// `true` se `weight × reps` è una prestazione migliore di `other`.
    /// Senza un termine di paragone vince qualsiasi serie valida.
    static func beats(weight: Double, reps: Int, than other: (weight: Double, reps: Int)?) -> Bool {
        guard weight > 0, reps >= 1 else { return false }
        guard let other else { return true }
        if weight > other.weight + epsilon { return true }
        if weight < other.weight - epsilon { return false }
        return reps > other.reps
    }
}
