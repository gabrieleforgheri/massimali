import SwiftUI
import SwiftData
import Charts

/// Peso corporeo: ultima pesata, andamento e inserimento rapido.
/// Sta nei Progressi perché è lì che si guarda l'andamento di tutto il resto.
struct BodyWeightCard: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var entries: [BodyWeightEntry]

    @State private var showingEditor = false
    @State private var importing = false
    @State private var importMessage: String?

    private var latest: BodyWeightEntry? { entries.first }

    /// Variazione rispetto alla pesata di circa un mese prima.
    private var monthDelta: Double? {
        guard let latest else { return nil }
        let cutoff = latest.date.addingTimeInterval(-30 * 86_400)
        guard let previous = entries.first(where: { $0.date <= cutoff }) else { return nil }
        return latest.weight - previous.weight
    }

    /// Solo le pesate vere, una per passo: i giorni in cui non ti sei pesato non
    /// devono occupare spazio sull'asse.
    private var points: [(index: Int, entry: BodyWeightEntry)] {
        entries
            .filter { $0.date >= Date().addingTimeInterval(-180 * 86_400) }
            .reversed()
            .enumerated()
            .map { ($0.offset, $0.element) }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Peso corporeo", trailing: latest.map { Fmt.relativeDay($0.date) })

                if let latest {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(Fmt.weightValue(latest.weight, unit: settings.unit))
                            .font(Theme.display(38))
                            .foregroundStyle(Theme.textPrimary)
                        Text(settings.unit.symbol)
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.textSecondary)

                        if let monthDelta, abs(monthDelta) >= 0.05 {
                            let sign = monthDelta > 0 ? "+" : "−"
                            Text("\(sign)\(Fmt.weight(abs(monthDelta), unit: settings.unit)) in 30 gg")
                                .font(Theme.rounded(11, .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                } else {
                    Text("Nessuna pesata registrata")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.textTertiary)
                }

                if points.count >= 2 {
                    Chart(points, id: \.entry.persistentModelID) { point in
                        LineMark(
                            x: .value("Pesata", Double(point.index)),
                            y: .value("Peso", settings.unit.fromKilograms(point.entry.weight))
                        )
                        .foregroundStyle(settings.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.monotone)

                        PointMark(
                            x: .value("Pesata", Double(point.index)),
                            y: .value("Peso", settings.unit.fromKilograms(point.entry.weight))
                        )
                        .foregroundStyle(point.entry.fromHealth ? settings.accentColor.opacity(0.5) : settings.accentColor)
                        .symbolSize(30)
                    }
                    .chartXScale(domain: -0.5...(Double(Swift.max(points.count - 1, 1)) + 0.5))
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
                        AxisMarks(values: Stats.tickIndices(count: points.count, max: 3).map(Double.init)) { value in
                            AxisValueLabel {
                                if let index = value.as(Double.self).map({ Int($0.rounded()) }), points.indices.contains(index) {
                                    Text(Fmt.shortDate(points[index].entry.date))
                                        .font(Theme.rounded(10, .medium))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                            }
                        }
                    }
                    .frame(height: 120)
                }

                HStack(spacing: 8) {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Aggiungi pesata", systemImage: "plus")
                            .font(Theme.rounded(13, .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(settings.accentColor.opacity(0.20), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .foregroundStyle(settings.accentColor)
                    }
                    .buttonStyle(.plain)

                    if settings.healthSyncEnabled {
                        Button {
                            Task { await importFromHealth() }
                        } label: {
                            Label(importing ? "Importo…" : "Da Salute", systemImage: "heart.fill")
                                .font(Theme.rounded(13, .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Theme.card, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(importing)
                    }
                }

                if let importMessage {
                    Text(importMessage)
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            BodyWeightSheet(lastWeight: latest?.weight)
        }
    }

    /// Prende l'ultima pesata da Salute, saltandola se è la stessa già registrata.
    private func importFromHealth() async {
        importing = true
        defer { importing = false }

        do {
            guard let sample = try await HealthService.latestBodyWeight() else {
                importMessage = "Salute non ha ancora nessuna pesata."
                return
            }
            if let latest, abs(latest.date.timeIntervalSince(sample.date)) < 60 {
                importMessage = "Già aggiornato."
                return
            }
            let entry = BodyWeightEntry(weight: sample.weight, date: sample.date, fromHealth: true)
            context.insert(entry)
            try context.save()
            importMessage = "Importata la pesata del \(Fmt.date(sample.date))."
            Haptics.success()
        } catch {
            importMessage = error.localizedDescription
        }
    }
}

/// Inserimento di una pesata.
struct BodyWeightSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let lastWeight: Double?

    @State private var weight: Double = 75
    @State private var date = Date()
    @State private var didPrefill = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    GlassCard(padding: 18, tint: settings.accentColor) {
                        VStack(spacing: 18) {
                            SectionHeader(title: "Peso")
                            WeightStepper(
                                kilograms: $weight,
                                step: settings.unit == .kg ? 0.1 : 0.2,
                                unit: settings.unit,
                                tint: settings.accentColor
                            )
                        }
                    }

                    GlassCard {
                        DatePicker("Data", selection: $date, in: ...Date(), displayedComponents: .date)
                            .font(Theme.rounded(14, .medium))
                    }

                    if settings.healthSyncEnabled {
                        Text("La pesata verrà scritta anche in Salute.")
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .screenBackground(settings.accentColor)
            .navigationTitle("Pesata")
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
            .onAppear {
                guard !didPrefill else { return }
                didPrefill = true
                if let lastWeight { weight = lastWeight }
            }
        }
    }

    private func save() {
        let entry = BodyWeightEntry(weight: weight, date: date)
        context.insert(entry)
        try? context.save()

        if settings.healthSyncEnabled {
            let kilograms = weight
            let when = date
            Task { try? await HealthService.saveBodyWeight(kilograms, date: when) }
        }

        Haptics.commit()
        dismiss()
    }
}
