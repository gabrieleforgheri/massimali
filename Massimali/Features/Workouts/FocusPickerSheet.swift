import SwiftUI
import SwiftData

/// "Cosa alleni oggi?": nome della sessione e gruppi. I gruppi filtrano il
/// selettore degli esercizi; nessun gruppo scelto = nessun filtro.
struct FocusPickerSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    let confirmTitle: String
    let onConfirm: (String, Set<MuscleGroup>) -> Void

    @State private var name: String
    @State private var selection: Set<MuscleGroup>

    init(
        initialName: String = "",
        initial: Set<MuscleGroup> = [],
        confirmTitle: String,
        onConfirm: @escaping (String, Set<MuscleGroup>) -> Void
    ) {
        self.confirmTitle = confirmTitle
        self.onConfirm = onConfirm
        _name = State(initialValue: initialName)
        _selection = State(initialValue: initial)
    }

    /// Le sessioni con nome più recenti, una per nome: toccarne una ripropone
    /// nome e gruppi, così "Push 1" non va riscritto ogni settimana.
    private var recentNamed: [Workout] {
        var seen = Set<String>()
        return workouts.filter { !$0.name.isEmpty && seen.insert($0.name.lowercased()).inserted }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Nome")
                            TextField("Es. Push 1, Pull 2, Gambe", text: $name)
                                .font(Theme.rounded(17, .semibold))
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)

                            if !recentNamed.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(recentNamed) { workout in
                                            Button(workout.name) {
                                                name = workout.name
                                                selection = workout.focus
                                                Haptics.tap()
                                            }
                                            .font(Theme.rounded(13, .semibold))
                                            .foregroundStyle(Theme.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(Theme.card, in: Capsule())
                                            .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Gruppi muscolari")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                                ForEach(MuscleGroup.allCases) { group in
                                    let isOn = selection.contains(group)
                                    Button {
                                        if isOn { selection.remove(group) } else { selection.insert(group) }
                                        Haptics.tap()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: group.symbol)
                                                .font(.system(size: 11, weight: .semibold))
                                            Text(group.title)
                                                .font(Theme.rounded(13, .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            isOn ? group.tint.opacity(0.22) : Theme.card,
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(isOn ? group.tint.opacity(0.6) : Theme.stroke, lineWidth: 1)
                                        )
                                        .foregroundStyle(isOn ? group.tint : Theme.textSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            Text(selection.isEmpty
                                 ? "Nessun gruppo scelto: vedrai tutti i macchinari."
                                 : "Quando aggiungi un esercizio vedrai solo questi gruppi.")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }

                    Button {
                        onConfirm(name.trimmingCharacters(in: .whitespaces), selection)
                        dismiss()
                    } label: {
                        Label(confirmTitle, systemImage: "bolt.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: settings.accentColor))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .screenBackground(settings.accentColor)
            .navigationTitle("Cosa alleni oggi?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}
