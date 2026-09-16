import SwiftUI

/// Il contenitore base dell'app: vetro smerigliato, bordo sottile, angoli morbidi.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = Theme.padding
    var radius: CGFloat = Theme.radius
    var tint: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassSurface(radius: radius, tint: tint)
    }
}

private struct GlassSurface: ViewModifier {
    let radius: CGFloat
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(tint?.opacity(0.12) ?? Theme.card)
                    }
            }
            .overlay {
                // Bordo con un accenno di luce in alto, come il vetro di iOS.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Theme.strokeStrong, Theme.stroke.opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func glassSurface(radius: CGFloat = Theme.radius, tint: Color? = nil) -> some View {
        modifier(GlassSurface(radius: radius, tint: tint))
    }

    /// Rende le righe di `List` trasparenti così si vede lo sfondo dell'app.
    func plainListRow() -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
    }
}

extension View {
    /// Sfondo standard delle schermate: gradiente scuro + liste trasparenti.
    func screenBackground(_ accent: Color) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.background(accent: accent))
    }
}
