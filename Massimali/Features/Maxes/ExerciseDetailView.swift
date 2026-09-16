import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise

    @State private var showingNewRecord = false
    @State private var showingEditor = false
    @State private var range: ChartRange = .all

    enum ChartRange: String, CaseIterable, Identifiable {
        case threeMonths, year, all
        var id: String { rawValue }
        var title: String {
            switch self {
            case .threeMonths: return "3 mesi"
            case .year: return "1 anno"
            case .all: return "Tutto"
            }
        }
        var days: Double? {
            switch self {
            case .threeMonths: return 90
            case .year: return 365
            case .all: return nil
            }
        }
    }

    private var formula: OneRepMaxFormula { settings.formula }
    private var tint: Color { exercise.muscleGroup.tint }

    private var records: [MaxRecord] { exercise.recordsByDateDesc }

    private var chartPoints: [ChartPoint] {
        let cutoff = range.days.map { Date().addingTimeInterval(-$0 * 86_400) }
        return records
            .filter { cutoff == nil || $0.date >= cutoff! }
            .sorted { $0.date < $1.date }
            .enumerated()
            .map { index, record in
                ChartPoint(
                    index: index,
                    date: record.date,
                    value: settings.unit.fromKilograms(record.weight),
                    isEstimated: record.isEstimated
                )
            }
    }

    private var warmupPlan: [Warmup.Step] { exercise.warmupPlan }

    /// Ultime serie eseguite in allenamento su questo macchinario.
    private var recentSets: [WorkoutSet] {
        exercise.setList
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                heroCard
                if !warmupPlan.isEmpty { warmupCard }
                if chartPoints.count >= 2 { chartCard }
                if !records.isEmpty { recordsCard }
                if !recentSets.isEmpty { setsCard }
                if !exercise.notes.isEmpty { notesCard }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .screenBackground(settings.accentColor)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Modifica macchinario")
            }
        }
        .sheet(isPresented: $showingNewRecord) {
            EditMaxSheet(exercise: exercise)
        }
        .sheet(isPresented: $showingEditor) {
            ExerciseEditorView(exercise: exercise) { dismiss() }
        }
    }

    // MARK: - Testata

    private var heroCard: some View {
        GlassCard(padding: 20, tint: tint) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    ExerciseThumbnail(exercise: exercise, size: 52)
                    MuscleGroupChip(group: exercise.muscleGroup)
                    Spacer()
                    if let best = exercise.bestRecord, best.isEstimated {
                        Text("da allenamento")
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                if let best = exercise.bestRecord {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(Fmt.weightValue(best.weight, unit: settings.unit))
                                .font(Theme.display(52))
                                .foregroundStyle(Theme.textPrimary)
                            Text(settings.unit.symbol)
                                .font(Theme.rounded(18, .semibold))
                                .foregroundStyle(Theme.textSecondary)
                            Text("× \(best.reps)")
                                .font(Theme.rounded(18, .semibold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        HStack(spacing: 8) {
                            Text("Massimale attuale · \(Fmt.date(best.date))")
                                .font(Theme.rounded(12, .medium))
                                .foregroundStyle(Theme.textTertiary)
                            if let previous = exercise.bestWeight(before: best.date), previous > 0 {
                                DeltaBadge(percent: (best.weight - previous) / previous * 100)
                            }
                        }
                        if best.reps > 1 {
                            Text("≈ \(Fmt.weight(best.estimatedOneRepMax(using: formula), unit: settings.unit)) di 1RM stimato")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("—")
                            .font(Theme.display(52))
                            .foregroundStyle(Theme.textTertiary)
                        Text("Nessun massimale registrato")
                            .font(Theme.rounded(12, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Button {
                    showingNewRecord = true
                } label: {
                    Label("Aggiorna massimale", systemImage: "arrow.up.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: tint))
            }
        }
    }

    // MARK: - Riscaldamento

    private var warmupCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Riscaldamento consigliato", trailing: "sul massimale reale")

                HStack(spacing: 8) {
                    ForEach(warmupPlan) { step in
                        VStack(spacing: 4) {
                            Text(step.percentLabel)
                                .font(Theme.rounded(10, .bold))
                                .foregroundStyle(tint)
                            Text(Fmt.weightValue(step.weight, unit: settings.unit))
                                .font(Theme.display(22))
                                .foregroundStyle(Theme.textPrimary)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                            Text("\(settings.unit.symbol) × \(step.reps)")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(tint.opacity(0.22), lineWidth: 1)
                        )
                    }
                }

                Text("Pesi arrotondati al passo del macchinario (\(Fmt.weight(exercise.incrementStep, unit: settings.unit))).")
                    .font(Theme.rounded(11, .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    // MARK: - Grafico

    private var chartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: "Andamento")
                    Spacer()
                }

                Picker("Intervallo", selection: $range) {
                    ForEach(ChartRange.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                Chart(chartPoints) { point in
                    AreaMark(
                        x: .value("Misurazione", Double(point.index)),
                        y: .value("Carico", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tint.opacity(0.35), tint.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)

                    LineMark(
                        x: .value("Misurazione", Double(point.index)),
                        y: .value("Carico", point.value)
                    )
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value("Misurazione", Double(point.index)),
                        y: .value("Carico", point.value)
                    )
                    .foregroundStyle(point.isEstimated ? tint.opacity(0.55) : tint)
                    .symbolSize(point.isEstimated ? 28 : 55)
                }
                .chartXScale(domain: xDomain)
                .chartYScale(domain: yDomain)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Theme.stroke)
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(number.formatted(.number.precision(.fractionLength(0))))
                                    .font(Theme.rounded(10, .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: Stats.tickIndices(count: chartPoints.count).map(Double.init)) { value in
                        AxisValueLabel {
                            if let index = value.as(Double.self).map({ Int($0.rounded()) }), chartPoints.indices.contains(index) {
                                Text(Fmt.shortDate(chartPoints[index].date))
                                    .font(Theme.rounded(10, .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 190)

                HStack(spacing: 14) {
                    LegendDot(color: tint, label: "Registrato")
                    LegendDot(color: tint.opacity(0.55), label: "Da allenamento")
                }
            }
        }
    }

    /// Un quarto di passo di respiro ai lati: senza, l'etichetta dell'ultima
    /// misurazione finisce mezza fuori dal riquadro.
    private var xDomain: ClosedRange<Double> {
        -0.5...(Double(Swift.max(chartPoints.count - 1, 1)) + 0.5)
    }

    private var yDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.value)
        guard let min = values.min(), let max = values.max() else { return 0...100 }
        if min == max { return (min * 0.9)...(max * 1.1 + 1) }
        let padding = (max - min) * 0.18
        return Swift.max(0, min - padding)...(max + padding)
    }

    // MARK: - Storico record

    private var recordsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Storico massimali", trailing: "\(records.count)")

                ForEach(records.prefix(12)) { record in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(record.isEstimated ? tint.opacity(0.45) : tint)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(Fmt.setLine(weight: record.weight, reps: record.reps, unit: settings.unit))
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(Fmt.date(record.date) + (record.isEstimated ? " · da allenamento" : ""))
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }

                        Spacer()

                        if record.reps > 1 {
                            Text("≈ \(Fmt.weight(record.estimatedOneRepMax(using: formula), unit: settings.unit))")
                                .font(Theme.rounded(12, .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }

                        Button {
                            delete(record)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)

                    if record.persistentModelID != records.prefix(12).last?.persistentModelID {
                        Divider().overlay(Theme.stroke)
                    }
                }
            }
        }
    }

    // MARK: - Serie recenti

    private var setsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Ultime serie in allenamento")

                ForEach(recentSets) { set in
                    HStack(spacing: 10) {
                        Text(Fmt.setLine(weight: set.weight, reps: set.reps, unit: settings.unit))
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if set.isPersonalRecord { PRBadge() }
                        if set.isWarmup {
                            Text("riscaldamento")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                        Text(Fmt.relativeDay(set.createdAt))
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Note")
                Text(exercise.notes)
                    .font(Theme.rounded(14, .regular))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func delete(_ record: MaxRecord) {
        withAnimation {
            context.delete(record)
            try? context.save()
        }
        Haptics.warning()
    }
}

// MARK: - Supporto

struct ChartPoint: Identifiable {
    let id = UUID()
    /// Posizione sull'asse: una misurazione, un passo. I giorni senza allenamento
    /// non esistono nel grafico, altrimenti disegnerebbero solo righe piatte.
    let index: Int
    let date: Date
    let value: Double
    var isEstimated: Bool = false
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(Theme.rounded(10, .medium))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}
