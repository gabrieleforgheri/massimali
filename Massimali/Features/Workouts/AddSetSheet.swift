import SwiftUI

/// Inserimento **o modifica** di una serie. In aggiunta parte dai valori
/// dell'ultima serie fatta su quel macchinario, in modifica da quelli della serie stessa.
struct AddSetSheet: View {
    enum Mode {
        /// Nuova serie, precompilata con l'ultima fatta su questo esercizio.
        case add(lastSet: WorkoutSet?)
        /// Correzione di una serie già registrata.
        case edit(WorkoutSet)
    }

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise
    let mode: Mode
    let onSave: (Double, Int, Bool) -> Void

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    @State private var weight: Double = 0
    @State private var reps: Int = 8
    @State private var isWarmup = false
    @State private var didPrefill = false

    private var tint: Color { exercise.muscleGroup.tint }

    private var estimated: Double {
        settings.formula.oneRepMax(weight: weight, reps: reps)
    }

    private var warmupPlan: [Warmup.Step] { exercise.warmupPlan }

    /// Il carico da battere, oppure — se lo stai già battendo — quello che stai facendo.
    private var reference: String {
        if isRecord { return Fmt.setLine(weight: weight, reps: reps, unit: settings.unit) }
        guard let best = exercise.bestRecord else { return "—" }
        return Fmt.setLine(weight: best.weight, reps: best.reps, unit: settings.unit)
    }

    private var isRecord: Bool {
        guard !isWarmup, !isEditing else { return false }
        return MaxRanking.beats(
            weight: weight,
            reps: reps,
            than: exercise.bestRecord.map { (weight: $0.weight, reps: $0.reps) }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    GlassCard(padding: 18, tint: tint) {
                        VStack(spacing: 18) {
                            SectionHeader(title: "Carico")
                            WeightStepper(kilograms: $weight, step: exercise.incrementStep, unit: settings.unit, tint: tint)
                        }
                    }

                    GlassCard(padding: 18) {
                        VStack(spacing: 16) {
                            SectionHeader(title: "Ripetizioni")
                            RepsStepper(reps: $reps, tint: tint)
                        }
                    }

                    GlassCard(padding: 16) {
                        Toggle(isOn: $isWarmup) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Serie di riscaldamento")
                                    .font(Theme.rounded(15, .semibold))
                                Text("Esclusa dal volume e dai record.")
                                    .font(Theme.rounded(11, .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                        .tint(tint)
                    }

                    if isWarmup, !warmupPlan.isEmpty {
                        GlassCard(padding: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeader(title: "Riscaldamento consigliato")
                                HStack(spacing: 8) {
                                    ForEach(warmupPlan) { step in
                                        Button {
                                            weight = step.weight
                                            reps = step.reps
                                            Haptics.tap()
                                        } label: {
                                            VStack(spacing: 3) {
                                                Text(step.percentLabel)
                                                    .font(Theme.rounded(10, .bold))
                                                    .foregroundStyle(tint)
                                                Text(Fmt.setLine(weight: step.weight, reps: step.reps, unit: settings.unit))
                                                    .font(Theme.rounded(13, .bold))
                                                    .foregroundStyle(Theme.textPrimary)
                                                    .minimumScaleFactor(0.6)
                                                    .lineLimit(1)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                                    .strokeBorder(tint.opacity(0.25), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                Text("Tocca per compilare peso e ripetizioni.")
                                    .font(Theme.rounded(11, .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }

                    if !isWarmup {
                        GlassCard(padding: 16, tint: isRecord ? Theme.positive : nil) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(isRecord ? "QUESTA SERIE" : "MASSIMALE DA BATTERE")
                                        .font(Theme.rounded(10, .bold))
                                        .tracking(0.7)
                                        .foregroundStyle(Theme.textTertiary)
                                    Text(reference)
                                        .font(Theme.display(24))
                                        .foregroundStyle(isRecord ? Theme.positive : Theme.textPrimary)
                                        .contentTransition(.numericText())
                                        .animation(.snappy, value: reference)
                                    if reps > 1 {
                                        Text("questa serie ≈ \(Fmt.weight(estimated, unit: settings.unit)) di 1RM")
                                            .font(Theme.rounded(11, .medium))
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                }
                                Spacer()
                                if isRecord { PRBadge(text: "NUOVO RECORD") }
                            }
                        }
                    }

                    Button {
                        onSave(weight, reps, isWarmup)
                        dismiss()
                    } label: {
                        Label(
                            isEditing ? "Salva modifica" : "Aggiungi serie",
                            systemImage: isEditing ? "checkmark.circle.fill" : "plus.circle.fill"
                        )
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: tint))
                    .disabled(weight <= 0 || reps < 1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .screenBackground(settings.accentColor)
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private func prefill() {
        guard !didPrefill else { return }
        didPrefill = true

        if case let .edit(set) = mode {
            weight = set.weight
            reps = set.reps
            isWarmup = set.isWarmup
            return
        }

        var lastSet: WorkoutSet?
        if case let .add(previous) = mode { lastSet = previous }

        if let lastSet {
            weight = lastSet.weight
            reps = lastSet.reps
            isWarmup = false
        } else if let best = exercise.recordsByDateDesc.first {
            weight = best.weight
            reps = max(best.reps, 5)
        } else {
            weight = exercise.incrementStep * 4
            reps = 8
        }
    }
}
