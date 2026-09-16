import CoreGraphics

/// Inquadratura della foto dentro il riquadro quadrato delle miniature.
///
/// Una foto non è quadrata: riempiendo il riquadro, una delle due dimensioni
/// sborda. `offset` è quanto la si è spostata lungo quell'asse, da −1 (tutta
/// verso l'alto o verso sinistra) a +1, con 0 al centro.
enum PhotoFraming {

    /// Di quanto sborda l'immagine, in punti, riempiendo un quadrato di lato `side`.
    static func overflow(imageAspect: CGFloat, side: CGFloat) -> CGFloat {
        guard imageAspect > 0, side > 0 else { return 0 }
        if imageAspect > 1 {
            // più larga che alta: sborda in orizzontale
            return side * (imageAspect - 1)
        } else {
            // più alta che larga: sborda in verticale
            return side * (1 / imageAspect - 1)
        }
    }

    /// Lo spostamento da applicare, in punti, sull'asse che sborda.
    /// Fuori da −1…1 non ha senso: si vedrebbe il bordo vuoto.
    static func offsetPoints(normalized: CGFloat, imageAspect: CGFloat, side: CGFloat) -> CGFloat {
        let clamped = min(max(normalized, -1), 1)
        return clamped * overflow(imageAspect: imageAspect, side: side) / 2
    }

    /// `true` se lo spostamento agisce in verticale (immagine più alta che larga).
    static func isVertical(imageAspect: CGFloat) -> Bool {
        imageAspect <= 1
    }

    /// Converte una trascinata in punti nella variazione dell'offset normalizzato.
    static func normalizedDelta(dragPoints: CGFloat, imageAspect: CGFloat, side: CGFloat) -> CGFloat {
        let total = overflow(imageAspect: imageAspect, side: side) / 2
        guard total > 0 else { return 0 }
        return dragPoints / total
    }
}
