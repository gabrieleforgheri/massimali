import Foundation

/// Quali dischi mettere per lato per arrivare a un carico.
enum Plates {

    /// Tutti i dischi selezionabili nelle impostazioni, dal più pesante.
    static let catalog: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25, 0.5]

    struct Load: Equatable {
        /// Dischi su un lato, dal più pesante (il primo infilato) al più leggero.
        let perSide: [Double]
        /// Peso per lato che con i dischi disponibili non si riesce a caricare.
        let leftover: Double
    }

    /// Avido dal disco più pesante: con i tagli standard è anche la soluzione con meno dischi.
    /// `bar` è il peso già presente senza dischi (bilanciere, 0 per le plate loaded).
    static func load(total: Double, bar: Double, plates: [Double]) -> Load {
        var remaining = max(0, (total - bar) / 2)
        var perSide: [Double] = []
        for plate in plates.sorted(by: >) where plate > 0 {
            while remaining + 0.0001 >= plate {
                perSide.append(plate)
                remaining -= plate
            }
        }
        return Load(perSide: perSide, leftover: remaining < 0.0001 ? 0 : (remaining * 100).rounded() / 100)
    }
}
