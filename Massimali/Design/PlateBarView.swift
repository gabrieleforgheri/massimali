import SwiftUI

/// Mezzo bilanciere visto di lato: i dischi di un lato entrano a molla dall'esterno
/// a ogni cambio di carico, così si vede subito cosa aggiungere o togliere.
struct PlateBarView: View {
    let load: Plates.Load
    let unit: WeightUnit
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 2) {
                // Bilanciere e fermo, poi il manicotto con i dischi.
                Capsule().fill(Theme.textTertiary).frame(width: 34, height: 6)
                RoundedRectangle(cornerRadius: 2).fill(Theme.textSecondary).frame(width: 8, height: 26)
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.textTertiary.opacity(0.7)).frame(height: 10)
                    HStack(spacing: 2) {
                        ForEach(slots) { slot in
                            plateShape(slot.plate)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity.combined(with: .scale(scale: 0.6))
                                ))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 92)
            .animation(.spring(response: 0.38, dampingFraction: 0.68), value: load)

            Text(summary)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.textSecondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: summary)

            if load.leftover > 0 {
                Text("Mancano \(Fmt.weight(load.leftover, unit: unit)) per lato con i dischi disponibili.")
                    .font(Theme.rounded(11, .medium))
                    .foregroundStyle(Theme.negative)
            }
        }
    }

    /// Identità per posizione **e** taglia: cambiando un disco il vecchio sparisce
    /// e il nuovo entra, invece di cambiare colore sul posto.
    private struct Slot: Identifiable {
        let id: String
        let plate: Double
    }

    private var slots: [Slot] {
        load.perSide.enumerated().map { Slot(id: "\($0.offset)-\($0.element)", plate: $0.element) }
    }

    private var summary: String {
        guard !load.perSide.isEmpty else { return "Nessun disco" }
        // Raggruppa per taglia mantenendo l'ordine: "2 × 20 + 5 per lato".
        var groups: [(plate: Double, count: Int)] = []
        for plate in load.perSide {
            if let last = groups.last, last.plate == plate {
                groups[groups.count - 1].count += 1
            } else {
                groups.append((plate, 1))
            }
        }
        let parts = groups.map { group in
            let weight = Fmt.weight(group.plate, unit: unit, includeSymbol: false)
            return group.count > 1 ? "\(group.count) × \(weight)" : weight
        }
        return parts.joined(separator: " + ") + " \(unit.symbol) per lato"
    }

    private func plateShape(_ plate: Double) -> some View {
        let height = 26 + 64 * min(plate, 25) / 25
        let width: CGFloat = plate >= 10 ? 14 : 10
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Self.color(for: plate).gradient)
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
            )
            .frame(width: width, height: height)
    }

    /// Colori dei dischi olimpici, così si riconoscono a colpo d'occhio.
    static func color(for plate: Double) -> Color {
        switch plate {
        case 25...: return Color(red: 0.86, green: 0.20, blue: 0.20)
        case 20..<25: return Color(red: 0.20, green: 0.42, blue: 0.90)
        case 15..<20: return Color(red: 0.95, green: 0.78, blue: 0.20)
        case 10..<15: return Color(red: 0.25, green: 0.70, blue: 0.35)
        case 5..<10: return Color(white: 0.92)
        case 2.5..<5: return Color(red: 0.86, green: 0.30, blue: 0.30)
        default: return Color(white: 0.65)
        }
    }
}

#Preview {
    PlateBarView(load: Plates.load(total: 102.5, bar: 20, plates: Plates.catalog), unit: .kg, tint: .green)
        .padding()
}
