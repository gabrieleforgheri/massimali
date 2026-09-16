import SwiftUI
import SwiftData

/// Schermata principale: tutti i macchinari con il massimale attuale, divisi per gruppo.
struct MaxesListView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Exercise.sortIndex) private var allExercises: [Exercise]

    @State private var search = ""
    @State private var showingNewExercise = false
    @State private var selectedGroup: MuscleGroup?

    private var visibleExercises: [Exercise] {
        allExercises.filter { exercise in
            guard !exercise.isArchived else { return false }
            if let selectedGroup, exercise.muscleGroup != selectedGroup { return false }
            guard !search.isEmpty else { return true }
            return exercise.name.localizedCaseInsensitiveContains(search)
        }
    }

    private var grouped: [(group: MuscleGroup, items: [Exercise])] {
        MuscleGroup.allCases.compactMap { group in
            let items = visibleExercises.filter { $0.muscleGroup == group }
            return items.isEmpty ? nil : (group, items)
        }
    }

    /// L'invito compare finché non hai scelto e finché la lista è davvero lunga.
    private var showCurationInvite: Bool {
        !settings.didCurateCatalog && allExercises.filter { !$0.isArchived }.count > 50
    }

    private var withMaxCount: Int {
        allExercises.filter { !$0.isArchived && !$0.recordList.isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if allExercises.filter({ !$0.isArchived }).isEmpty {
                    emptyCatalog
                } else if grouped.isEmpty {
                    ContentUnavailableView.search(text: search)
                } else {
                    list
                }
            }
            .screenBackground(settings.accentColor)
            .navigationTitle("Massimali")
            .searchable(text: $search, prompt: "Cerca macchinario")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewExercise = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .accessibilityLabel("Nuovo macchinario")
                }
            }
            .sheet(isPresented: $showingNewExercise) {
                ExerciseEditorView(exercise: nil)
            }
        }
    }

    private var list: some View {
        List {
            if Provisioning.isExpiringSoon(), let status = Provisioning.statusText() {
                Section {
                    WarningBanner(
                        symbol: "clock.badge.exclamationmark",
                        title: "L'app sta per scadere",
                        message: "\(status). Ricollega l'iPhone al Mac e premi Run in Xcode per rinnovarla: i dati restano al loro posto."
                    )
                    .plainListRow()
                }
            }

            if showCurationInvite {
                Section {
                    NavigationLink {
                        CatalogCurationView()
                    } label: {
                        WarningBanner(
                            symbol: "checklist",
                            title: "Sfoltisci il catalogo",
                            message: "Ci sono \(allExercises.count) macchinari, molti dei quali la tua palestra non ha. Scegli i tuoi: gli altri si archiviano in blocco.",
                            tint: settings.accentColor
                        )
                    }
                    .buttonStyle(.plain)
                    .plainListRow()
                }
            }

            Section {
                filterRow
                    .plainListRow()
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
            }

            ForEach(grouped, id: \.group) { section in
                Section {
                    ForEach(section.items) { exercise in
                        ZStack {
                            // NavigationLink senza la freccia di sistema: la riga
                            // è già una card e la chevron la sporcherebbe.
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                EmptyView()
                            }
                            .opacity(0)

                            ExerciseRow(exercise: exercise)
                        }
                        .plainListRow()
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation { archive(exercise) }
                            } label: {
                                Label("Archivia", systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        MuscleGroupChip(group: section.group)
                        Spacer()
                        Text("\(section.items.count)")
                            .font(Theme.rounded(12, .bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.horizontal, 2)
                    .textCase(nil)
                }
            }

            Section {
                Text("\(withMaxCount) macchinari con massimale su \(allExercises.filter { !$0.isArchived }.count)")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    .plainListRow()
            }
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(title: "Tutti", isOn: selectedGroup == nil, tint: settings.accentColor) {
                    withAnimation(.snappy) { selectedGroup = nil }
                }
                ForEach(MuscleGroup.allCases) { group in
                    FilterPill(title: group.title, isOn: selectedGroup == group, tint: group.tint) {
                        withAnimation(.snappy) {
                            selectedGroup = selectedGroup == group ? nil : group
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollClipDisabled()
    }

    private var emptyCatalog: some View {
        ContentUnavailableView {
            Label("Nessun macchinario", systemImage: "dumbbell")
        } description: {
            Text("Aggiungi il primo macchinario oppure ripristina il catalogo iniziale dalle impostazioni.")
        } actions: {
            Button("Aggiungi macchinario") { showingNewExercise = true }
                .buttonStyle(PrimaryButtonStyle(tint: settings.accentColor, fullWidth: false))
        }
    }

    private func archive(_ exercise: Exercise) {
        exercise.isArchived = true
        try? context.save()
        Haptics.commit()
    }
}

// MARK: - Riga

private struct ExerciseRow: View {
    @Environment(AppSettings.self) private var settings
    let exercise: Exercise

    private var best: MaxRecord? { exercise.bestRecord }

    private var warmup: Warmup.Step? { exercise.warmupPlan.first }

    private var deltaPercent: Double? {
        guard let best else { return nil }
        guard let previous = exercise.bestWeight(before: best.date),
              previous > 0, best.weight > previous else { return nil }
        return (best.weight - previous) / previous * 100
    }

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 14) {
                ExerciseThumbnail(exercise: exercise, size: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if let best {
                            // In palestra la cosa più utile a colpo d'occhio è con
                            // quanto scaldarsi, non quando è stato aggiornato il record.
                            if let warmup {
                                Text("Risc. \(Fmt.weight(warmup.weight, unit: settings.unit))")
                                    .foregroundStyle(exercise.muscleGroup.tint.opacity(0.9))
                                Text("·")
                            }
                            Text(Fmt.relativeDay(best.date))
                        } else {
                            Text("Nessun massimale")
                        }
                    }
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.textTertiary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    if let best {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(Fmt.weightValue(best.weight, unit: settings.unit))
                                .font(Theme.display(21))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(settings.unit.symbol) × \(best.reps)")
                                .font(Theme.rounded(11, .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        if let deltaPercent {
                            DeltaBadge(percent: deltaPercent)
                        }
                    } else {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Filtro

private struct FilterPill: View {
    let title: String
    let isOn: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(isOn ? Theme.bg : Theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isOn ? tint : Theme.card, in: Capsule())
                .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
