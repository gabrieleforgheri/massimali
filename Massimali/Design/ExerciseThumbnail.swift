import SwiftUI

/// L'immagine di un macchinario: la tua foto se c'è, altrimenti il pittogramma.
/// Un unico punto in tutta l'app, così la lista, il selettore e la sessione
/// restano coerenti e basta cambiare qui per cambiarli tutti.
struct ExerciseThumbnail: View {
    let exercise: Exercise
    /// Lato del riquadro.
    var size: CGFloat = 42
    /// Quanto del riquadro occupa il pittogramma quando non c'è una foto.
    var glyphRatio: CGFloat = 0.64

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
    }

    var body: some View {
        ZStack {
            if let image = photo {
                FramedPhoto(image: image, offset: exercise.photoOffset, side: size)
            } else {
                exercise.muscleGroup.tint.opacity(0.14)
                MachineGlyphView(
                    glyph: exercise.glyph,
                    tint: exercise.muscleGroup.tint,
                    size: size * glyphRatio
                )
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Theme.stroke, lineWidth: photo == nil ? 0 : 1))
    }

    private var photo: UIImage? {
        guard let data = exercise.photo else { return nil }
        return UIImage(data: data)
    }
}


/// Foto che riempie un quadrato, spostata lungo l'asse che sborda.
struct FramedPhoto: View {
    let image: UIImage
    let offset: Double
    let side: CGFloat

    private var aspect: CGFloat {
        guard image.size.height > 0 else { return 1 }
        return image.size.width / image.size.height
    }

    var body: some View {
        let shift = PhotoFraming.offsetPoints(
            normalized: CGFloat(offset),
            imageAspect: aspect,
            side: side
        )
        let vertical = PhotoFraming.isVertical(imageAspect: aspect)

        Color.clear
            .overlay(
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .offset(x: vertical ? 0 : shift, y: vertical ? shift : 0)
            )
            .frame(width: side, height: side)
    }
}
