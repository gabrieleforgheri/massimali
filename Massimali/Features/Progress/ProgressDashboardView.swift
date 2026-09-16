import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query(sort: \Exercise.sortIndex) private var exercises: [Exercise]
    @Query(sort: \MaxRecord.date, order: .reverse) private var records: [MaxRecord]

    private var finished: [Workout] { workouts.filter { !$0.isActive } }

    private var weekly: [Stats.WeeklyVolume] {
        Stats.weeklyVolume(workouts: finished, weeks: 12)
    }

    /// Solo alcune settimane vengono datate sotto le barre, altrimenti si accavallano.
    private var weekLabels: [String] {
        Stats.tickIndices(count: weekly.count).map { Fmt.shortDate(weekly[$0].weekStart) }
    }

    private var byGroup: [Stats.GroupVolume] {
        Stats.volumeByGroup(workouts: finished, days: 30)
    }

    private var movers: [Stats.Mover] {
        Stats.topMovers(exercises: exercises, days: 90)
    }

    private var volume30: Double {
        let cutoff = Date().addingTimeInterval(-30 * 86_400)
        return finished.filter { $0.date >= cutoff }.reduce(0) { $0 + $1.totalVolume }
    }

    private var records30: Int {
        let cutoff = Date().addingTimeInterval(-30 * 86_400)
        return records.filter { $0.date >= cutoff }.count
    }

    @Query private var weights: [BodyWeightEntry]

    private var hasTrainingData: Bool { !finished.isEmpty || !records.isEmpty }

    var body: some View {
        NavigationStack {
            content
                .screenBackground(settings.accentColor)
                .navigationTitle("Progressi")
        }
    }

    /// Il peso corporeo si registra anche senza aver mai fatto un allenamento,
    /// quindi la sua card resta sempre a schermo: nasconderla dietro lo stato
    /// vuoto lascerebbe senza via d'accesso chi parte da zero.
    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                if hasTrainingData { tiles }

                BodyWeightCard()

                if !weekly.isEmpty { volumeCard }
                if !byGroup.isEmpty { groupCard }
                if !movers.isEmpty { moversCard }
                if !records.isEmpty { recentRecordsCard }

                if !hasTrainingData { emptyHint }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private var emptyHint: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Label("Ancora nessun allenamento", systemImage: "chart.line.uptrend.xyaxis")
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Registra un massimale o completa una sessione: qui compariranno volumi, record e andamento.")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var tiles: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatTile(
                    symbol: "flame.fill",
                    title: "Sessioni 30gg",
                    value: "\(Stats.sessionCount(workouts: finished, days: 30))",
                    tint: settings.accentColor
                )
                StatTile(
                    symbol: "calendar",
                    title: "Settimane di fila",
                    value: "\(Stats.weeklyStreak(workouts: finished))",
                    tint: settings.accentColor
                )
            }
            HStack(spacing: 10) {
                StatTile(
                    symbol: "scalemass",
                    title: "Volume 30gg",
                    value: Fmt.volume(volume30, unit: settings.unit),
                    tint: settings.accentColor
                )
                StatTile(
                    symbol: "trophy.fill",
                    title: "Record 30gg",
                    value: "\(records30)",
                    tint: Theme.positive
                )
            }
        }
    }

    private var volumeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Volume settimanale", trailing: "settimane allenate")

                Chart(weekly) { week in
                    BarMark(
                        // Asse a bande, non temporale: una barra per settimana allenata,
                        // tutte della stessa larghezza e senza buchi da riempire.
                        x: .value("Settimana", Fmt.shortDate(week.weekStart)),
                        y: .value("Volume", settings.unit.fromKilograms(week.volume))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [settings.accentColor, settings.accentColor.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(5)
                }
                .chartXScale(range: .plotDimension(padding: 8))
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Theme.stroke)
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(compact(number))
                                    .font(Theme.rounded(10, .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: weekLabels) { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(Theme.rounded(10, .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 170)
            }
        }
    }

    private var groupCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Dove va il lavoro", trailing: "ultimi 30 giorni")

                Chart(byGroup) { item in
                    BarMark(
                        x: .value("Volume", settings.unit.fromKilograms(item.volume)),
                        y: .value("Gruppo", item.group.title)
                    )
                    .foregroundStyle(item.group.tint)
                    .cornerRadius(5)
                }
                .chartXScale(range: .plotDimension(padding: 8))
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Theme.stroke)
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(compact(number))
                                    .font(Theme.rounded(10, .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let title = value.as(String.self) {
                                Text(title)
                                    .font(Theme.rounded(11, .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(byGroup.count) * 34 + 30)
            }
        }
    }

    private var moversCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Cresciuti di più", trailing: "ultimi 90 giorni")

                ForEach(movers) { mover in
                    HStack(spacing: 12) {
                        ExerciseThumbnail(exercise: mover.exercise, size: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(mover.exercise.name)
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Text(mover.previous > 0
                                 ? "\(Fmt.weight(mover.previous, unit: settings.unit)) → \(Fmt.weight(mover.current, unit: settings.unit))"
                                 : "primo massimale: \(Fmt.weight(mover.current, unit: settings.unit))")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }

                        Spacer()

                        if mover.previous > 0 {
                            DeltaBadge(percent: mover.deltaPercent)
                        } else {
                            PRBadge(text: "NUOVO")
                        }
                    }
                }
            }
        }
    }

    private var recentRecordsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Ultimi record")

                ForEach(records.prefix(8)) { record in
                    HStack(spacing: 12) {
                        Text(Fmt.shortDate(record.date))
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: 52, alignment: .leading)

                        Text(record.exercise?.name ?? "Esercizio rimosso")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(Fmt.setLine(weight: record.weight, reps: record.reps, unit: settings.unit))
                            .font(Theme.rounded(14, .bold))
                            .foregroundStyle(record.isEstimated ? Theme.textSecondary : Theme.textPrimary)
                    }
                }
            }
        }
    }

    /// Numeri compatti sugli assi: 12.400 → "12,4k".
    private func compact(_ value: Double) -> String {
        if value >= 1000 {
            return (value / 1000).formatted(.number.precision(.fractionLength(0...1))) + "k"
        }
        return value.formatted(.number.precision(.fractionLength(0)))
    }
}
