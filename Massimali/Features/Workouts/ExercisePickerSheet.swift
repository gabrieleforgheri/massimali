import SwiftUI
import SwiftData

/// Selettore di macchinari, usato per aggiungere un esercizio alla sessione.
struct ExercisePickerSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.sortIndex) private var allExercises: [Exercise]
    /// Le ultime serie svolte, per proporre in cima quello che usi davvero.
    /// Con 98 macchinari a catalogo, scorrere ogni volta è il vero attrito.
    @Query private var recentSets: [WorkoutSet]

    /// I gruppi di oggi. Vuoto = tutti.
    let focus: Set<MuscleGroup>
    let onSelect: (Exercise) -> Void

    init(focus: Set<MuscleGroup> = [], onSelect: @escaping (Exercise) -> Void) {
        self.focus = focus
        self.onSelect = onSelect
        var descriptor = FetchDescriptor<WorkoutSet>(
            sortBy: [SortDescriptor(\WorkoutSet.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 80
        _recentSets = Query(descriptor)
    }

    /// Esercizi usati di recente, senza ripetizioni, dal più recente.
    private var recentExercises: [Exercise] {
        guard search.isEmpty else { return [] }
        var seen = Set<PersistentIdentifier>()
        var result: [Exercise] = []
        for set in recentSets {
            guard let exercise = set.exercise, !exercise.isArchived, isVisible(exercise) else { continue }
            if seen.insert(exercise.persistentModelID).inserted {
                result.append(exercise)
            }
            if result.count == 6 { break }
        }
        return result
    }

    @State private var search = ""
    @State private var showingNewExercise = false
    /// Scappatoia per l'esercizio fuori programma: vale solo per questo foglio.
    @State private var showAll = false

    private var isFiltering: Bool { !focus.isEmpty && !showAll }

    private func isVisible(_ exercise: Exercise) -> Bool {
        !isFiltering || focus.contains(exercise.muscleGroup)
    }

    private var grouped: [(group: MuscleGroup, items: [Exercise])] {
        let filtered = allExercises.filter { exercise in
            guard !exercise.isArchived, isVisible(exercise) else { return false }
            guard !search.isEmpty else { return true }
            return exercise.name.localizedCaseInsensitiveContains(search)
        }
        return MuscleGroup.allCases.compactMap { group in
            let items = filtered.filter { $0.muscleGroup == group }
            return items.isEmpty ? nil : (group, items)
        }
    }

    @ViewBuilder
    private func exerciseRow(_ exercise: Exercise) -> some View {
        // La miniatura sta fuori dal bottone: toccarla apre la foto, non sceglie.
        HStack(spacing: 12) {
            ExerciseThumbnail(exercise: exercise, size: 32, zoomable: true)

            Button {
                onSelect(exercise)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Text(exercise.name)
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    if let max = exercise.currentMax {
                        Text(Fmt.weight(max, unit: settings.unit))
                            .font(Theme.rounded(12, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .glassSurface(radius: Theme.radiusSmall)
        .plainListRow()
    }

    var body: some View {
        NavigationStack {
            List {
                if !recentExercises.isEmpty {
                    Section {
                        ForEach(recentExercises) { exercise in
                            exerciseRow(exercise)
                        }
                    } header: {
                        SectionHeader(title: "Usati di recente")
                            .textCase(nil)
                            .padding(.horizontal, 2)
                    }
                }

                ForEach(grouped, id: \.group) { section in
                    Section {
                        ForEach(section.items) { exercise in
                            exerciseRow(exercise)
                        }
                    } header: {
                        MuscleGroupChip(group: section.group)
                            .textCase(nil)
                            .padding(.horizontal, 2)
                    }
                }

                if isFiltering {
                    Button("Mostra tutti i macchinari") {
                        withAnimation { showAll = true }
                    }
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(settings.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .buttonStyle(.plain)
                    .plainListRow()
                }
            }
            .listStyle(.plain)
            .screenBackground(settings.accentColor)
            .navigationTitle("Scegli macchinario")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Cerca")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Nuovo macchinario")
                }
            }
            .sheet(isPresented: $showingNewExercise) {
                ExerciseEditorView(exercise: nil)
            }
        }
    }
}
