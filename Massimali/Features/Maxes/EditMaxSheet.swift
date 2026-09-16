import SwiftUI
import SwiftData

/// Registra un nuovo massimale: il carico vero × ripetizioni, con il 1RM stimato
/// come nota a margine.
struct EditMaxSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise

    @State private var weight: Double = 0
    @State private var reps: Int = 1
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var didPrefill = false

    private var tint: Color { exercise.muscleGroup.tint }

    private var estimated: Double {
        settings.formula.oneRepMax(weight: weight, reps: reps)
    }

    private var previousBest: MaxRecord? { exercise.bestRecord }

    private var isRecord: Bool {
        MaxRanking.beats(
            weight: weight,
            reps: reps,
            than: previousBest.map { (weight: $0.weight, reps: $0.reps) }
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

                    estimateCard

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Dettagli")
                            DatePicker("Data", selection: $date, in: ...Date(), displayedComponents: .date)
                                .font(Theme.rounded(14, .medium))
                            Divider().overlay(Theme.stroke)
                            TextField("Nota (facoltativa)", text: $note, axis: .vertical)
                                .font(Theme.rounded(14, .regular))
                                .lineLimit(1...3)
                        }
                    }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salva") { save() }
                        .font(Theme.rounded(16, .bold))
                        .disabled(weight <= 0)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private var estimateCard: some View {
        GlassCard(padding: 18, tint: isRecord ? Theme.positive : nil) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(title: "Massimale")
                    Spacer()
                    if isRecord { PRBadge(text: "NUOVO RECORD") }
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Fmt.weightValue(weight, unit: settings.unit))
                        .font(Theme.display(42))
                        .foregroundStyle(isRecord ? Theme.positive : Theme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: weight)
                    Text("\(settings.unit.symbol) × \(reps)")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }

                if reps > 1 {
                    Text("≈ \(Fmt.weight(estimated, unit: settings.unit)) di 1RM stimato · \(settings.formula.title)")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.textTertiary)
                }

                if let previousBest {
                    Text("Precedente: \(Fmt.setLine(weight: previousBest.weight, reps: previousBest.reps, unit: settings.unit))")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }

    /// Parte dall'ultimo record così di solito basta un tap sul "+".
    private func prefill() {
        guard !didPrefill else { return }
        didPrefill = true
        if let last = exercise.recordsByDateDesc.first {
            weight = last.weight
            reps = last.reps
        } else if let lastSet = exercise.setList.sorted(by: { $0.createdAt > $1.createdAt }).first {
            weight = lastSet.weight
            reps = lastSet.reps
        } else {
            weight = exercise.incrementStep * 4
            reps = 1
        }
    }

    private func save() {
        let record = MaxRecord(
            weight: weight,
            reps: reps,
            date: date,
            isEstimated: false,
            note: note
        )
        context.insert(record)
        record.exercise = exercise
        try? context.save()
        if isRecord { Haptics.personalRecord() } else { Haptics.commit() }
        dismiss()
    }
}
