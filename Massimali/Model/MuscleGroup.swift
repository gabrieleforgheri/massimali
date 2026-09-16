import SwiftUI

/// I gruppi muscolari usati per organizzare i macchinari.
/// Il `rawValue` viene salvato su disco: non va mai cambiato senza una migrazione.
enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case petto
    case schiena
    case gambe
    case spalle
    case braccia
    case core

    var id: String { rawValue }

    var title: String {
        switch self {
        case .petto: return "Petto"
        case .schiena: return "Schiena"
        case .gambe: return "Gambe"
        case .spalle: return "Spalle"
        case .braccia: return "Braccia"
        case .core: return "Core"
        }
    }

    var symbol: String {
        switch self {
        case .petto: return "figure.strengthtraining.traditional"
        case .schiena: return "figure.rower"
        case .gambe: return "figure.strengthtraining.functional"
        case .spalle: return "figure.arms.open"
        case .braccia: return "dumbbell.fill"
        case .core: return "figure.core.training"
        }
    }

    /// Tinta usata per chip, icone e grafici.
    var tint: Color {
        switch self {
        case .petto: return Color(red: 0.98, green: 0.42, blue: 0.36)
        case .schiena: return Color(red: 0.36, green: 0.72, blue: 0.98)
        case .gambe: return Color(red: 0.55, green: 0.85, blue: 0.42)
        case .spalle: return Color(red: 0.99, green: 0.75, blue: 0.31)
        case .braccia: return Color(red: 0.78, green: 0.54, blue: 0.98)
        case .core: return Color(red: 0.40, green: 0.87, blue: 0.80)
        }
    }

    /// Ordine di visualizzazione nelle liste.
    var order: Int { MuscleGroup.allCases.firstIndex(of: self) ?? 0 }
}
