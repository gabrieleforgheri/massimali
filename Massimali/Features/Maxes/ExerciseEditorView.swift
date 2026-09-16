import SwiftUI
import SwiftData
import PhotosUI

/// Crea o modifica un macchinario. `exercise == nil` significa "nuovo".
struct ExerciseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise?
    /// Chiamata dopo l'eliminazione, per far tornare indietro la vista di dettaglio.
    var onDeleted: (() -> Void)? = nil

    @Query(sort: \Exercise.sortIndex) private var allExercises: [Exercise]

    @State private var name = ""
    @State private var group: MuscleGroup = .petto
    @State private var step: Double = 2.5
    @State private var notes = ""
    @State private var isArchived = false
    @State private var showingDeleteConfirm = false
    @State private var didLoad = false
    @State private var photoData: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var glyph: MachineGlyph = .machine
    @State private var photoOffset: Double = 0
    @State private var dragStart: Double = 0

    private let steps: [Double] = [1, 1.25, 2, 2.5, 5, 10]

    private var isNew: Bool { exercise == nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Nome")
                            TextField("Es. Chest Press", text: $name)
                                .font(Theme.rounded(17, .semibold))
                                .textInputAutocapitalization(.words)
                        }
                    }

                    imageCard

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Gruppo muscolare")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                                ForEach(MuscleGroup.allCases) { candidate in
                                    Button {
                                        group = candidate
                                        Haptics.tap()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: candidate.symbol)
                                                .font(.system(size: 11, weight: .semibold))
                                            Text(candidate.title)
                                                .font(Theme.rounded(13, .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            group == candidate ? candidate.tint.opacity(0.22) : Theme.card,
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(group == candidate ? candidate.tint.opacity(0.6) : Theme.stroke, lineWidth: 1)
                                        )
                                        .foregroundStyle(group == candidate ? candidate.tint : Theme.textSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Incremento del carico", trailing: "\(Fmt.weight(step, unit: .kg))")
                            HStack(spacing: 8) {
                                ForEach(steps, id: \.self) { candidate in
                                    Button {
                                        step = candidate
                                        Haptics.tap()
                                    } label: {
                                        Text(candidate.formatted(.number.precision(.fractionLength(0...2))))
                                            .font(Theme.rounded(13, .bold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 9)
                                            .background(
                                                step == candidate ? settings.accentColor.opacity(0.22) : Theme.card,
                                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            )
                                            .foregroundStyle(step == candidate ? settings.accentColor : Theme.textSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            Text("È il salto minimo tra un carico e l'altro su questo macchinario: definisce i pulsanti + e −.")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Note")
                            TextField("Es. sedile al foro 4, impugnatura larga", text: $notes, axis: .vertical)
                                .font(Theme.rounded(14, .regular))
                                .lineLimit(2...5)
                        }
                    }

                    if !isNew {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $isArchived) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Archivia")
                                            .font(Theme.rounded(15, .semibold))
                                        Text("Lo nasconde dalle liste senza perdere lo storico.")
                                            .font(Theme.rounded(11, .medium))
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                }
                                .tint(settings.accentColor)

                                Divider().overlay(Theme.stroke)

                                Button(role: .destructive) {
                                    showingDeleteConfirm = true
                                } label: {
                                    Label("Elimina macchinario", systemImage: "trash")
                                        .font(Theme.rounded(15, .semibold))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .screenBackground(settings.accentColor)
            .navigationTitle(isNew ? "Nuovo macchinario" : "Modifica")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salva") { save() }
                        .font(Theme.rounded(16, .bold))
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                "Eliminare il macchinario?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Elimina tutto lo storico", role: .destructive) { deleteExercise() }
                Button("Annulla", role: .cancel) {}
            } message: {
                Text("Verranno persi anche i massimali registrati. Le serie già svolte restano negli allenamenti.")
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - Foto e pittogramma

    private var imageCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Immagine")

                if photoData != nil {
                    largePreview
                }

                HStack(spacing: 14) {
                    if photoData == nil { preview }

                    VStack(alignment: .leading, spacing: 8) {
                        if CameraPicker.isAvailable {
                            Button {
                                showingCamera = true
                            } label: {
                                Label("Scatta foto", systemImage: "camera.fill")
                                    .font(Theme.rounded(14, .semibold))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(settings.accentColor)
                        }

                        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                            Label("Scegli dal rullino", systemImage: "photo.on.rectangle")
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(settings.accentColor)
                        }

                        if photoData != nil {
                            Button {
                                withAnimation { photoData = nil }
                                photoOffset = 0
                                dragStart = 0
                                Haptics.tap()
                            } label: {
                                Label("Rimuovi foto", systemImage: "trash")
                                    .font(Theme.rounded(14, .semibold))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Theme.negative)
                        }
                    }

                    Spacer()
                }

                Text(photoData == nil
                     ? "Senza foto viene usato il pittogramma qui sotto, scelto in automatico dal nome."
                     : "Trascina la foto per scegliere cosa si vede nel riquadro.")
                    .font(Theme.rounded(11, .medium))
                    .foregroundStyle(Theme.textTertiary)

                Divider().overlay(Theme.stroke)

                SectionHeader(title: "Pittogramma", trailing: glyph.title)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MachineGlyph.allCases) { candidate in
                            Button {
                                glyph = candidate
                                Haptics.tap()
                            } label: {
                                MachineGlyphView(
                                    glyph: candidate,
                                    tint: glyph == candidate ? group.tint : Theme.textTertiary,
                                    size: 26
                                )
                                .frame(width: 44, height: 44)
                                .background(
                                    glyph == candidate ? group.tint.opacity(0.18) : Theme.card,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(glyph == candidate ? group.tint.opacity(0.5) : .clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(candidate.title)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .scrollClipDisabled()
            }
        }
        // A tutto schermo, non in una sheet: la fotocamera di UIKit disegna i suoi
        // comandi partendo dall'altezza piena dello schermo, e dentro un foglio
        // (per giunta annidato in un altro foglio) il tasto di scatto finisce
        // fuori dall'area visibile.
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                photoData = ImageStore.prepare(image)
                photoOffset = 0
                dragStart = 0
                Haptics.commit()
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        photoData = ImageStore.prepare(image)
                        photoOffset = 0
                        dragStart = 0
                        Haptics.commit()
                    }
                }
            }
        }
    }

    /// Anteprima grande, trascinabile: è qui che si sceglie l'inquadratura,
    /// visto che il ritaglio di sistema della fotocamera è inservibile.
    @ViewBuilder
    private var largePreview: some View {
        if let photoData, let image = UIImage(data: photoData) {
            let side: CGFloat = 200
            let aspect = image.size.height > 0 ? image.size.width / image.size.height : 1
            let vertical = PhotoFraming.isVertical(imageAspect: aspect)
            let canMove = PhotoFraming.overflow(imageAspect: aspect, side: side) > 1

            VStack(spacing: 8) {
                FramedPhoto(image: image, offset: photoOffset, side: side)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Theme.stroke, lineWidth: 1)
                    )
                    // Ha la priorità sulla ScrollView: altrimenti un trascinamento
                    // verticale farebbe scorrere la pagina invece di spostare la foto.
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                guard canMove else { return }
                                let points = vertical ? value.translation.height : value.translation.width
                                let delta = PhotoFraming.normalizedDelta(
                                    dragPoints: points,
                                    imageAspect: aspect,
                                    side: side
                                )
                                photoOffset = min(max(dragStart + Double(delta), -1), 1)
                            }
                            .onEnded { _ in dragStart = photoOffset }
                    )

                HStack(spacing: 10) {
                    if canMove {
                        Label(
                            vertical ? "Trascina in alto o in basso" : "Trascina a destra o a sinistra",
                            systemImage: "hand.draw"
                        )
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.textTertiary)
                    } else {
                        Text("Foto già quadrata: si vede tutta.")
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer()

                    if photoOffset != 0 {
                        Button("Centra") {
                            withAnimation(.snappy) { photoOffset = 0 }
                            dragStart = 0
                            Haptics.tap()
                        }
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(settings.accentColor)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var preview: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        ZStack {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                group.tint.opacity(0.14)
                MachineGlyphView(glyph: glyph, tint: group.tint, size: 44)
            }
        }
        .frame(width: 78, height: 78)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Theme.stroke, lineWidth: 1))
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        guard let exercise else {
            glyph = MachineGlyph.suggested(for: "", group: group)
            return
        }
        name = exercise.name
        group = exercise.muscleGroup
        step = exercise.incrementStep
        notes = exercise.notes
        isArchived = exercise.isArchived
        photoData = exercise.photo
        photoOffset = exercise.photoOffset
        dragStart = exercise.photoOffset
        glyph = exercise.glyph
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let exercise {
            exercise.name = trimmed
            exercise.muscleGroup = group
            exercise.incrementStep = step
            exercise.notes = notes
            exercise.isArchived = isArchived
            exercise.photo = photoData
            exercise.photoOffset = photoOffset
            exercise.glyph = glyph
        } else {
            let nextIndex = (allExercises.map(\.sortIndex).max() ?? 0) + 1
            let new = Exercise(
                name: trimmed,
                muscleGroup: group,
                incrementStep: step,
                notes: notes,
                sortIndex: nextIndex
            )
            context.insert(new)
            new.photo = photoData
            new.photoOffset = photoOffset
            new.glyph = glyph
        }
        try? context.save()
        Haptics.commit()
        dismiss()
    }

    private func deleteExercise() {
        guard let exercise else { return }
        Haptics.warning()
        dismiss()
        onDeleted?()

        // La cancellazione vera avviene dopo che il foglio e il dettaglio sono spariti:
        // se l'oggetto venisse rimosso mentre una vista lo sta ancora leggendo,
        // SwiftUI si ritroverebbe con un modello svuotato tra le mani.
        let context = self.context
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            context.delete(exercise)
            try? context.save()
        }
    }
}
