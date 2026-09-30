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
    /// Se c'è una foto, toccarla la apre intera.
    var zoomable: Bool = false

    @State private var showingPhoto = false

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
    }

    var body: some View {
        if zoomable, let image = photo {
            Button { showingPhoto = true } label: { thumbnail }
                .buttonStyle(.borderless)
                .accessibilityLabel("Mostra la foto di \(exercise.name)")
                .fullScreenCover(isPresented: $showingPhoto) {
                    PhotoViewer(image: image, title: exercise.name)
                }
        } else {
            thumbnail
        }
    }

    private var thumbnail: some View {
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

/// La foto intera, per riconoscere il macchinario. Si chiude toccando
/// o trascinando verso il basso.
private struct PhotoViewer: View {
    let image: UIImage
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var drag: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: drag)
                .gesture(
                    DragGesture()
                        .onChanged { drag = max(0, $0.translation.height) }
                        .onEnded { value in
                            if value.translation.height > 120 { dismiss() } else { withAnimation(.snappy) { drag = 0 } }
                        }
                )
                .onTapGesture { dismiss() }

            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Chiudi")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .opacity(1 - min(drag / 200, 1))
        }
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
