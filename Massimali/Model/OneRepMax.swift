import Foundation

/// Formule per stimare il 1RM partendo da peso × ripetizioni.
///
/// È solo una **nota a margine**: il massimale dell'app è il carico vero sollevato
/// sul macchinario (vedi `MaxRanking`), questa stima serve a confrontare serie con
/// ripetizioni diverse e non decide mai niente.
enum OneRepMaxFormula: String, Codable, CaseIterable, Identifiable {
    case epley
    case brzycki

    var id: String { rawValue }

    var title: String {
        switch self {
        case .epley: return "Epley"
        case .brzycki: return "Brzycki"
        }
    }

    var subtitle: String {
        switch self {
        case .epley: return "peso × (1 + rip / 30)"
        case .brzycki: return "peso × 36 / (37 − rip)"
        }
    }

    /// Massimale stimato in kg.
    /// Con 1 ripetizione restituisce il peso grezzo; sopra le 12 ripetizioni
    /// ogni formula perde attendibilità, quindi il valore va letto come indicativo.
    func oneRepMax(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps >= 1 else { return 0 }
        if reps == 1 { return weight }

        switch self {
        case .epley:
            return weight * (1 + Double(reps) / 30)
        case .brzycki:
            // Brzycki diverge avvicinandosi a 37 ripetizioni. Oltre le 10 si ripiega
            // su Epley: il raccordo è esatto, perché a 10 ripetizioni le due formule
            // danno lo stesso identico valore (36/27 = 1 + 10/30), quindi la stima
            // resta continua e crescente invece di fare un salto.
            guard reps <= 10 else { return weight * (1 + Double(reps) / 30) }
            return weight * 36 / (37 - Double(reps))
        }
    }
}
