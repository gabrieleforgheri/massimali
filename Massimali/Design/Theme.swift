import SwiftUI

extension Color {
    /// `Color(hex: 0x1A2B3C)` — comodo per tenere la palette leggibile.
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

/// Token visivi dell'app. L'interfaccia è solo scura (vedi `UIUserInterfaceStyle` in Info.plist),
/// quindi qui non servono varianti chiaro/scuro.
enum Theme {

    // Superfici
    static let bg = Color(hex: 0x0B0D14)
    static let bgRaised = Color(hex: 0x12151F)
    static let card = Color.white.opacity(0.055)
    static let cardStrong = Color.white.opacity(0.09)
    static let stroke = Color.white.opacity(0.10)
    static let strokeStrong = Color.white.opacity(0.18)

    // Testo
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.58)
    static let textTertiary = Color.white.opacity(0.35)

    // Semantica
    static let positive = Color(hex: 0x5FD98A)
    static let negative = Color(hex: 0xFF6B6B)

    // Geometria
    static let radius: CGFloat = 20
    static let radiusSmall: CGFloat = 14
    static let padding: CGFloat = 16

    /// Sfondo dell'app: nero bluastro con due aloni dell'accento in alto.
    static func background(accent: Color) -> some View {
        ZStack {
            bg
            RadialGradient(
                colors: [accent.opacity(0.22), .clear],
                center: .init(x: 0.15, y: -0.05),
                startRadius: 0,
                endRadius: 420
            )
            RadialGradient(
                colors: [Color(hex: 0x4A5BFF).opacity(0.16), .clear],
                center: .init(x: 0.95, y: 0.08),
                startRadius: 0,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }

    /// Font dei numeri grandi: tondo, largo, tabellare così le cifre non ballano.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
