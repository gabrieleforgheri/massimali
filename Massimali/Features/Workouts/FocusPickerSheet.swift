import SwiftUI

/// "Cosa alleni oggi?": i gruppi scelti qui filtrano il selettore degli esercizi.
/// Nessun gruppo scelto = nessun filtro.
struct FocusPickerSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let confirmTitle: String
    let onConfirm: (Set<MuscleGroup>) -> Void

    @State private var selection: Set<MuscleGroup>

    init(initial: Set<MuscleGroup> = [], confirmTitle: String, onConfirm: @escaping (Set<MuscleGroup>) -> Void) {
        self.confirmTitle = confirmTitle
        self.onConfirm = onConfirm
        _selection = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
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
                    onConfirm(selection)
                    dismiss()
                } label: {
                    Label(confirmTitle, systemImage: "bolt.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: settings.accentColor))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .screenBackground(settings.accentColor)
            .navigationTitle("Cosa alleni oggi?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
