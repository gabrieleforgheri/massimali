import SwiftUI

/// Un tratto del disegno, in coordinate normalizzate 0…1 (y verso il basso).
/// Tenere le forme come dati invece che come `Path` scritti a mano rende i
/// pittogrammi compatti da definire e uniformi da disegnare.
enum GlyphShape {
    /// Linea sottile: telai, cavi, basamenti.
    case line(CGFloat, CGFloat, CGFloat, CGFloat)
    /// Linea spessa: bilancieri, pedane, schienali inclinati.
    case bar(CGFloat, CGFloat, CGFloat, CGFloat)
    /// Rettangolo pieno con angoli morbidi: sedute, pacchi pesi, imbottiture.
    case solidRect(CGFloat, CGFloat, CGFloat, CGFloat)
    /// Cerchio pieno: impugnature, rulli, teste.
    case dot(CGFloat, CGFloat, CGFloat)
    /// Cerchio vuoto: dischi, pulegge.
    case ring(CGFloat, CGFloat, CGFloat)
}

/// Pittogrammi degli attrezzi. Non sono 98 disegni diversi — a 40 pixel non
/// avrebbe senso — ma una ventina di archetipi che si distinguono davvero a
/// colpo d'occhio: cosa spingi, da che parte, e con che tipo di carico.
enum MachineGlyph: String, Codable, CaseIterable, Identifiable {
    case seatedPush
    case pecDeck
    case latPulldown
    case seatedRow
    case cableStation
    case cableCross
    case benchFlat
    case benchIncline
    case barbell
    case dumbbell
    case plateLoaded
    case pullUpBar
    case legPress
    case legLever
    case squatRack
    case smithMachine
    case hyperBench
    case calfPlatform
    case abBench
    case romanChair
    case bodyweight
    case machine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .seatedPush: return "Spinta da seduto"
        case .pecDeck: return "Butterfly"
        case .latPulldown: return "Lat machine"
        case .seatedRow: return "Rematore / pulley"
        case .cableStation: return "Cavi"
        case .cableCross: return "Croci ai cavi"
        case .benchFlat: return "Panca piana"
        case .benchIncline: return "Panca inclinata"
        case .barbell: return "Bilanciere"
        case .dumbbell: return "Manubri"
        case .plateLoaded: return "Plate loaded"
        case .pullUpBar: return "Sbarra / parallele"
        case .legPress: return "Pressa"
        case .legLever: return "Leva per gambe"
        case .squatRack: return "Rack"
        case .smithMachine: return "Multipower"
        case .hyperBench: return "Panca iperestensioni"
        case .calfPlatform: return "Pedana calf"
        case .abBench: return "Panca addominali"
        case .romanChair: return "Sedia romana"
        case .bodyweight: return "Corpo libero"
        case .machine: return "Macchina generica"
        }
    }

    // MARK: - Mattoncini riusati da più pittogrammi

    /// Pacco pesi: rettangolo pieno con le fessure fra una piastra e l'altra.
    private static func stack(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> [GlyphShape] {
        var shapes: [GlyphShape] = [.solidRect(x, y, w, h)]
        for i in 1...3 {
            let ly = y + h * CGFloat(i) / 4
            shapes.append(.line(x, ly, x + w, ly))
        }
        return shapes
    }

    private static let base: GlyphShape = .line(0.08, 0.88, 0.92, 0.88)

    /// Bilanciere con i dischi alle estremità.
    private static func loadedBar(_ y: CGFloat, radius: CGFloat = 0.085) -> [GlyphShape] {
        [.bar(0.12, y, 0.88, y), .dot(0.17, y, radius), .dot(0.83, y, radius)]
    }

    var shapes: [GlyphShape] {
        switch self {

        case .seatedPush:
            return Self.stack(0.06, 0.26, 0.14, 0.54) + [
                .line(0.28, 0.14, 0.28, 0.88),
                .solidRect(0.37, 0.30, 0.075, 0.32),   // schienale
                .solidRect(0.37, 0.62, 0.26, 0.07),    // seduta
                .line(0.46, 0.30, 0.76, 0.30),         // due bracci di spinta
                .line(0.46, 0.44, 0.76, 0.44),
                .dot(0.80, 0.30, 0.055),
                .dot(0.80, 0.44, 0.055),
                Self.base
            ]

        case .pecDeck:
            return Self.stack(0.06, 0.30, 0.13, 0.50) + [
                .line(0.30, 0.16, 0.30, 0.88),
                .solidRect(0.38, 0.60, 0.24, 0.07),
                .line(0.44, 0.24, 0.74, 0.34),         // braccia che si chiudono
                .line(0.44, 0.52, 0.74, 0.42),
                .dot(0.78, 0.34, 0.05),
                .dot(0.78, 0.42, 0.05),
                Self.base
            ]

        case .latPulldown:
            return Self.stack(0.06, 0.32, 0.12, 0.48) + [
                .line(0.24, 0.12, 0.24, 0.88),
                .line(0.24, 0.13, 0.68, 0.13),         // trave alta
                .ring(0.64, 0.19, 0.05),               // puleggia
                .line(0.64, 0.24, 0.64, 0.44),         // cavo lungo: si tira dall'alto
                .bar(0.38, 0.46, 0.92, 0.46),          // barra larga
                .solidRect(0.46, 0.70, 0.26, 0.07),    // seduta
                Self.base
            ]

        case .seatedRow:
            return Self.stack(0.06, 0.30, 0.12, 0.50) + [
                .line(0.24, 0.16, 0.24, 0.88),
                .line(0.24, 0.52, 0.64, 0.52),         // cavo orizzontale: si tira in piano
                .dot(0.68, 0.52, 0.055),
                .solidRect(0.36, 0.64, 0.26, 0.07),    // seduta
                .bar(0.84, 0.52, 0.84, 0.80),          // pedana per i piedi
                Self.base
            ]

        case .cableStation:
            return [
                .solidRect(0.14, 0.12, 0.10, 0.76),    // colonna
                .ring(0.19, 0.22, 0.045),              // puleggia alta
                .line(0.19, 0.265, 0.19, 0.38),
                .line(0.19, 0.38, 0.62, 0.46),         // cavo
                .dot(0.66, 0.47, 0.055),               // impugnatura
                Self.base
            ]

        case .cableCross:
            return [
                .solidRect(0.07, 0.14, 0.09, 0.74),
                .solidRect(0.84, 0.14, 0.09, 0.74),
                .ring(0.115, 0.24, 0.04),
                .ring(0.885, 0.24, 0.04),
                .line(0.115, 0.28, 0.50, 0.54),
                .line(0.885, 0.28, 0.50, 0.54),
                .dot(0.50, 0.57, 0.055),
                Self.base
            ]

        case .benchFlat:
            return Self.loadedBar(0.32) + [
                .solidRect(0.24, 0.54, 0.52, 0.09),    // panca
                .line(0.32, 0.63, 0.32, 0.86),
                .line(0.68, 0.63, 0.68, 0.86)
            ]

        case .benchIncline:
            return Self.loadedBar(0.26, radius: 0.075) + [
                .bar(0.26, 0.74, 0.66, 0.46),          // schienale inclinato
                .line(0.30, 0.74, 0.30, 0.87),
                .line(0.63, 0.50, 0.63, 0.87),
                .solidRect(0.20, 0.72, 0.16, 0.07)     // seduta
            ]

        case .barbell:
            return [
                .bar(0.08, 0.50, 0.92, 0.50),
                .dot(0.20, 0.50, 0.145),
                .dot(0.80, 0.50, 0.145),
                .dot(0.34, 0.50, 0.085),
                .dot(0.66, 0.50, 0.085)
            ]

        case .dumbbell:
            return [
                .bar(0.33, 0.50, 0.67, 0.50),
                .solidRect(0.14, 0.33, 0.14, 0.34),
                .solidRect(0.72, 0.33, 0.14, 0.34)
            ]

        case .plateLoaded:
            return [
                .line(0.22, 0.14, 0.22, 0.88),
                .solidRect(0.28, 0.58, 0.24, 0.07),    // seduta
                .solidRect(0.28, 0.30, 0.07, 0.28),    // schienale
                .line(0.38, 0.40, 0.64, 0.40),         // braccio
                .ring(0.76, 0.50, 0.155),              // disco
                .ring(0.76, 0.50, 0.05),
                Self.base
            ]

        case .pullUpBar:
            return [
                .line(0.14, 0.18, 0.86, 0.18),         // sbarra
                .line(0.16, 0.18, 0.16, 0.88),
                .line(0.84, 0.18, 0.84, 0.88),
                .dot(0.38, 0.18, 0.05),
                .dot(0.62, 0.18, 0.05),
                .line(0.38, 0.22, 0.50, 0.40),         // braccia
                .line(0.62, 0.22, 0.50, 0.40),
                .dot(0.50, 0.46, 0.075),               // testa
                .line(0.50, 0.53, 0.50, 0.74)
            ]

        case .legPress:
            return [
                .bar(0.20, 0.78, 0.72, 0.34),          // slitta inclinata
                .bar(0.64, 0.20, 0.86, 0.44),          // pedana
                .solidRect(0.10, 0.62, 0.22, 0.08),    // seduta
                .ring(0.48, 0.58, 0.09),               // disco
                Self.base
            ]

        case .legLever:
            return [
                .solidRect(0.20, 0.50, 0.30, 0.08),    // seduta
                .solidRect(0.16, 0.24, 0.08, 0.26),    // schienale
                .line(0.50, 0.58, 0.78, 0.42),         // leva
                .dot(0.83, 0.39, 0.075),               // rullo
                .line(0.34, 0.58, 0.34, 0.88),
                Self.base
            ]

        case .squatRack:
            return Self.loadedBar(0.30, radius: 0.09) + [
                .line(0.22, 0.14, 0.22, 0.88),
                .line(0.78, 0.14, 0.78, 0.88),
                .line(0.22, 0.38, 0.30, 0.33),         // ganci
                .line(0.78, 0.38, 0.70, 0.33),
                Self.base
            ]

        case .smithMachine:
            return [
                .line(0.26, 0.10, 0.26, 0.88),         // binari
                .line(0.74, 0.10, 0.74, 0.88),
                .solidRect(0.22, 0.40, 0.08, 0.09),    // carrelli
                .solidRect(0.70, 0.40, 0.08, 0.09),
                .bar(0.10, 0.445, 0.90, 0.445),
                .dot(0.15, 0.445, 0.08),
                .dot(0.85, 0.445, 0.08),
                Self.base
            ]

        case .hyperBench:
            return [
                .bar(0.24, 0.68, 0.62, 0.32),          // appoggio a 45°
                .line(0.44, 0.52, 0.44, 0.86),
                .dot(0.72, 0.68, 0.06),                // rulli caviglie
                .dot(0.82, 0.68, 0.06),
                .line(0.66, 0.68, 0.66, 0.86),
                Self.base
            ]

        case .calfPlatform:
            return Self.stack(0.74, 0.36, 0.12, 0.34) + [
                .solidRect(0.18, 0.68, 0.50, 0.09),    // pedana
                .line(0.28, 0.18, 0.28, 0.68),
                .solidRect(0.22, 0.22, 0.30, 0.08),    // spalliere
                Self.base
            ]

        case .abBench:
            return [
                .bar(0.20, 0.72, 0.68, 0.42),          // piano inclinato
                .line(0.28, 0.70, 0.28, 0.86),
                .line(0.62, 0.46, 0.62, 0.86),
                .dot(0.76, 0.38, 0.06),                // rulli piedi
                .dot(0.76, 0.52, 0.06),
                Self.base
            ]

        case .romanChair:
            return [
                .line(0.28, 0.12, 0.28, 0.88),
                .solidRect(0.28, 0.24, 0.07, 0.26),    // schienale
                .solidRect(0.34, 0.34, 0.26, 0.07),    // braccioli
                .dot(0.50, 0.20, 0.075),               // testa
                .line(0.50, 0.44, 0.50, 0.62),
                .line(0.50, 0.62, 0.68, 0.60),         // ginocchia sollevate
                Self.base
            ]

        case .bodyweight:
            return [
                .dot(0.50, 0.22, 0.095),
                .line(0.50, 0.32, 0.50, 0.58),
                .line(0.28, 0.42, 0.72, 0.42),
                .line(0.50, 0.58, 0.34, 0.80),
                .line(0.50, 0.58, 0.66, 0.80)
            ]

        case .machine:
            return Self.stack(0.10, 0.26, 0.16, 0.56) + [
                .line(0.34, 0.14, 0.34, 0.88),
                .solidRect(0.42, 0.56, 0.28, 0.08),
                .solidRect(0.42, 0.30, 0.07, 0.26),
                Self.base
            ]
        }
    }
}

// MARK: - Riconoscimento dal nome

extension MachineGlyph {

    /// Coppie (frammento di nome, pittogramma) valutate **in ordine**: le voci
    /// più specifiche stanno prima, così "Rematore Bilanciere" non finisce sul
    /// pittogramma generico del rematore.
    private static let keywords: [(String, MachineGlyph)] = [
        // Gambe
        ("leg press", .legPress), ("pressa", .legPress), ("hack squat", .legPress),
        ("leg extension", .legLever), ("leg curl", .legLever),
        ("calf", .calfPlatform),
        ("adductor", .machine), ("abductor", .machine), ("glute machine", .machine),
        ("multipower", .smithMachine),
        ("squat", .squatRack), ("hip thrust", .barbell), ("step up", .dumbbell),
        ("affondi", .dumbbell), ("bulgarian", .dumbbell),

        // Schiena
        ("lat machine", .latPulldown),
        ("pulley", .seatedRow),
        ("rematore bilanciere", .barbell), ("rematore con manubrio", .dumbbell),
        ("rematore ai cavi", .cableStation), ("rematore t-bar", .barbell),
        ("rematore", .seatedRow),
        ("trazioni", .pullUpBar), ("dip", .pullUpBar),
        ("stacco", .barbell), ("good morning", .barbell),
        ("iperestensioni", .hyperBench),
        ("pullover machine", .machine),

        // Petto e spalle
        ("plate loaded", .plateLoaded),
        ("pectoral", .pecDeck), ("butterfly", .pecDeck),
        ("croci ai cavi", .cableCross),
        ("panca piana", .benchFlat), ("panca stretta", .benchFlat),
        ("panca inclinata", .benchIncline), ("panca declinata", .benchIncline),
        ("panca scott", .benchIncline),
        ("panca addominali", .abBench),
        ("chest press", .seatedPush), ("shoulder press", .seatedPush),
        ("lento avanti", .barbell),

        // Core
        ("sedia romana", .romanChair), ("leg raise", .romanChair),
        ("crunch machine", .machine), ("rotary", .machine),
        ("plank", .bodyweight), ("piegamenti", .bodyweight),
        ("russian", .bodyweight), ("ab wheel", .bodyweight),
        ("crunch a terra", .bodyweight),

        // Generici, per ultimi
        ("cavi", .cableStation), ("cable", .cableStation),
        ("pushdown", .cableStation), ("face pull", .cableStation),
        ("kickback", .cableStation),
        ("machine", .machine),
        ("manubri", .dumbbell), ("manubrio", .dumbbell),
        ("bilanciere", .barbell), ("sbarra", .pullUpBar),
        ("alzate", .dumbbell), ("scrollate", .dumbbell), ("curl", .barbell),
        ("press", .seatedPush)
    ]

    /// Pittogramma dedotto dal nome dell'esercizio; se non riconosce nulla
    /// ripiega su un default sensato per il gruppo muscolare.
    static func suggested(for name: String, group: MuscleGroup) -> MachineGlyph {
        let needle = name.lowercased()
        for (key, glyph) in keywords where needle.contains(key) {
            return glyph
        }
        switch group {
        case .petto, .spalle: return .seatedPush
        case .schiena: return .seatedRow
        case .gambe: return .legLever
        case .braccia: return .dumbbell
        case .core: return .bodyweight
        }
    }
}

// MARK: - Disegno

struct MachineGlyphView: View {
    let glyph: MachineGlyph
    var tint: Color = .white
    /// Lato del quadrato di disegno.
    var size: CGFloat = 26

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let thin = max(1, s * 0.055)
            let thick = max(1.4, s * 0.10)

            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * s, y: y * s)
            }

            for shape in glyph.shapes {
                switch shape {
                case let .line(x1, y1, x2, y2):
                    var path = Path()
                    path.move(to: point(x1, y1))
                    path.addLine(to: point(x2, y2))
                    context.stroke(path, with: .color(tint), style: StrokeStyle(lineWidth: thin, lineCap: .round))

                case let .bar(x1, y1, x2, y2):
                    var path = Path()
                    path.move(to: point(x1, y1))
                    path.addLine(to: point(x2, y2))
                    context.stroke(path, with: .color(tint), style: StrokeStyle(lineWidth: thick, lineCap: .round))

                case let .solidRect(x, y, w, h):
                    let rect = CGRect(x: x * s, y: y * s, width: w * s, height: h * s)
                    let radius = min(rect.width, rect.height) * 0.35
                    context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(tint))

                case let .dot(cx, cy, r):
                    let rect = CGRect(x: (cx - r) * s, y: (cy - r) * s, width: 2 * r * s, height: 2 * r * s)
                    context.fill(Path(ellipseIn: rect), with: .color(tint))

                case let .ring(cx, cy, r):
                    let rect = CGRect(x: (cx - r) * s, y: (cy - r) * s, width: 2 * r * s, height: 2 * r * s)
                    context.stroke(Path(ellipseIn: rect), with: .color(tint), lineWidth: thin)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
