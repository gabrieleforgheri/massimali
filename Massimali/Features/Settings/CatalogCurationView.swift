import SwiftUI
import SwiftData

/// Selezione rapida di quello che la tua palestra ha davvero.
///
/// Il catalogo iniziale è volutamente abbondante, ma archiviare a mano sessanta
/// attrezzi uno swipe alla volta è una punizione: qui si spuntano in blocco.
/// Deselezionare **archivia**, non elimina: lo storico resta sempre al suo posto.
struct CatalogCurationView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.sortIndex) private var exercises: [Exercise]

    @State private var search = ""

    private var filtered: [Exercise] {
        guard !search.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private func items(in group: MuscleGroup) -> [Exercise] {
        filtered.filter { $0.muscleGroup == group }
    }

    private var activeCount: Int { exercises.filter { !$0.isArchived }.count }

    var body: some View {
        List {
            Section {
                GlassCard(padding: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(activeCount) su \(exercises.count) macchinari attivi")
                            .font(Theme.rounded(15, .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Togli la spunta a quelli che la tua palestra non ha: spariscono dalle liste ma restano archiviati, con tutto il loro storico.")
                            .font(Theme.rounded(12, .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .plainListRow()
            }

            ForEach(MuscleGroup.allCases) { group in
                let groupItems = items(in: group)
                if !groupItems.isEmpty {
                    Section {
                        ForEach(groupItems) { exercise in
                            row(for: exercise)
                        }
                    } header: {
                        HStack(spacing: 8) {
                            MuscleGroupChip(group: group)
                            Spacer()
                            Button("Tutti") { setAll(groupItems, archived: false) }
                                .font(Theme.rounded(12, .semibold))
                                .foregroundStyle(settings.accentColor)
                            Button("Nessuno") { setAll(groupItems, archived: true) }
                                .font(Theme.rounded(12, .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .textCase(nil)
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
        .listStyle(.plain)
        .screenBackground(settings.accentColor)
        .navigationTitle("La tua palestra")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Cerca macchinario")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fine") {
                    settings.didCurateCatalog = true
                    dismiss()
                }
                .font(Theme.rounded(16, .bold))
            }
        }
        .onDisappear { settings.didCurateCatalog = true }
    }

    private func row(for exercise: Exercise) -> some View {
        Button {
            toggle(exercise)
        } label: {
            HStack(spacing: 12) {
                ExerciseThumbnail(exercise: exercise, size: 34)

                Text(exercise.name)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(exercise.isArchived ? Theme.textTertiary : Theme.textPrimary)

                Spacer()

                Image(systemName: exercise.isArchived ? "circle" : "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(exercise.isArchived ? Theme.textTertiary : settings.accentColor)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 14)
            .glassSurface(radius: Theme.radiusSmall)
            .opacity(exercise.isArchived ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .plainListRow()
    }

    private func toggle(_ exercise: Exercise) {
        withAnimation(.snappy) { exercise.isArchived.toggle() }
        try? context.save()
        Haptics.tap()
    }

    private func setAll(_ items: [Exercise], archived: Bool) {
        withAnimation(.snappy) {
            for exercise in items { exercise.isArchived = archived }
        }
        try? context.save()
        Haptics.commit()
    }
}
