import SwiftUI
import SwiftData

/// La sessione di allenamento: si aggiungono esercizi e serie, i record scattano da soli.
struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @Bindable var workout: Workout

    /// Esercizi scelti ma ancora senza serie: esistono solo finché la vista è aperta.
    @State private var pendingExercises: [Exercise] = []
    @State private var showingPicker = false
    @State private var addSetTarget: Exercise?
    @State private var editingSet: WorkoutSet?
    @State private var showingSummary = false
    @State private var showingFinishConfirm = false
    @State private var healthMessage: String?
    @State private var sendingToHealth = false

    private var recordCount: Int {
        workout.setList.filter(\.isPersonalRecord).count
    }

    private var exercises: [Exercise] {
        var list = workout.exercisesInOrder
        for exercise in pendingExercises
        where !list.contains(where: { $0.persistentModelID == exercise.persistentModelID }) {
            list.append(exercise)
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header

                ForEach(exercises) { exercise in
                    ExerciseSessionCard(
                        exercise: exercise,
                        sets: workout.sets(for: exercise),
                        onAddSet: { addSetTarget = exercise },
                        onRepeatLast: { repeatLastSet(for: exercise) },
                        onEditSet: { editingSet = $0 },
                        onDeleteSet: { delete($0) }
                    )
                }

                Button {
                    showingPicker = true
                } label: {
                    Label("Aggiungi esercizio", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())

                noteCard

                if workout.isActive {
                    Button {
                        showingFinishConfirm = true
                    } label: {
                        Label("Termina allenamento", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: settings.accentColor))
                    .padding(.top, 4)
                } else if settings.healthSyncEnabled {
                    // Serve per le sessioni chiuse prima di attivare Salute,
                    // o quando il primo invio è fallito.
                    Button {
                        sendToHealth(announceSuccess: true)
                    } label: {
                        Label(
                            sendingToHealth ? "Invio…" : "Invia a Salute",
                            systemImage: "heart.fill"
                        )
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(sendingToHealth)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .screenBackground(settings.accentColor)
        .navigationTitle(Fmt.relativeDay(workout.date))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPicker) {
            ExercisePickerSheet { exercise in
                if !exercises.contains(where: { $0.persistentModelID == exercise.persistentModelID }) {
                    pendingExercises.append(exercise)
                }
                // Il foglio successivo deve aspettare che questo sia sparito,
                // altrimenti iOS ignora la seconda presentazione.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    addSetTarget = exercise
                }
            }
        }
        .sheet(item: $addSetTarget) { exercise in
            AddSetSheet(
                exercise: exercise,
                mode: .add(lastSet: lastSet(for: exercise))
            ) { weight, reps, isWarmup in
                addSet(to: exercise, weight: weight, reps: reps, isWarmup: isWarmup)
            }
        }
        .sheet(item: $editingSet) { set in
            if let exercise = set.exercise {
                AddSetSheet(exercise: exercise, mode: .edit(set)) { weight, reps, isWarmup in
                    update(set, weight: weight, reps: reps, isWarmup: isWarmup)
                }
            }
        }
        .sheet(isPresented: $showingSummary) {
            WorkoutSummaryView(workout: workout) { dismiss() }
        }
        .alert(
            "App Salute",
            isPresented: Binding(get: { healthMessage != nil }, set: { if !$0 { healthMessage = nil } })
        ) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(healthMessage ?? "")
        }
        .confirmationDialog(
            "Terminare l'allenamento?",
            isPresented: $showingFinishConfirm,
            titleVisibility: .visible
        ) {
            Button("Termina") { finish() }
            Button("Continua ad allenarti", role: .cancel) {}
        }
    }

    // MARK: - Testata

    private var header: some View {
        GlassCard(padding: 18, tint: workout.isActive ? settings.accentColor : nil) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    if workout.isActive {
                        HStack(spacing: 7) {
                            Circle().fill(settings.accentColor).frame(width: 7, height: 7)
                            Text("IN CORSO")
                                .font(Theme.rounded(11, .bold))
                                .tracking(0.8)
                                .foregroundStyle(settings.accentColor)
                        }
                    } else {
                        Text("CONCLUSO")
                            .font(Theme.rounded(11, .bold))
                            .tracking(0.8)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Text(Fmt.dateTime(workout.date))
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.textTertiary)
                }

                if workout.isActive {
                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        Text(Fmt.duration(timeline.date.timeIntervalSince(workout.date)))
                            .font(Theme.display(34))
                            .foregroundStyle(Theme.textPrimary)
                    }
                } else if let duration = workout.duration {
                    Text(Fmt.duration(duration))
                        .font(Theme.display(34))
                        .foregroundStyle(Theme.textPrimary)
                }

                HStack(spacing: 20) {
                    MiniStat(value: "\(workout.workingSetCount)", label: "serie")
                    MiniStat(value: Fmt.volume(workout.totalVolume, unit: settings.unit), label: "volume")
                    if recordCount > 0 {
                        MiniStat(value: "\(recordCount)", label: "record")
                    }
                }
            }
        }
    }

    /// Come è andata: un promemoria che al prossimo allenamento vale più dei numeri.
    private var noteCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Note")
                TextField(
                    "Come è andata? Sensazioni, dolori, regolazioni del sedile…",
                    text: $workout.note,
                    axis: .vertical
                )
                .font(Theme.rounded(14, .regular))
                .lineLimit(2...6)
                .onChange(of: workout.note) { _, _ in
                    try? context.save()
                }
            }
        }
    }

    // MARK: - Azioni

    private func lastSet(for exercise: Exercise) -> WorkoutSet? {
        workout.sets(for: exercise).last
            ?? exercise.setList.sorted { $0.createdAt > $1.createdAt }.first
    }

    private func addSet(to exercise: Exercise, weight: Double, reps: Int, isWarmup: Bool) {
        let order = (workout.setList.map(\.order).max() ?? -1) + 1
        let set = WorkoutSet(
            weight: weight,
            reps: reps,
            isWarmup: isWarmup,
            order: order
        )
        context.insert(set)
        set.exercise = exercise
        set.workout = workout

        let isRecord = RecordService.evaluatePersonalRecord(for: set, context: context)
        try? context.save()

        withAnimation(.snappy) {
            pendingExercises.removeAll { $0.persistentModelID == exercise.persistentModelID }
        }
        if isRecord { Haptics.personalRecord() } else { Haptics.commit() }
    }

    private func repeatLastSet(for exercise: Exercise) {
        guard let last = lastSet(for: exercise) else { return }
        addSet(to: exercise, weight: last.weight, reps: last.reps, isWarmup: last.isWarmup)
    }

    /// Applica la correzione e ricalcola il record: una serie corretta al ribasso
    /// non deve lasciarsi dietro il massimale che aveva fatto scattare.
    private func update(_ set: WorkoutSet, weight: Double, reps: Int, isWarmup: Bool) {
        RecordService.removeAutomaticRecord(for: set, context: context)
        set.weight = weight
        set.reps = reps
        set.isWarmup = isWarmup

        let isRecord = RecordService.evaluatePersonalRecord(for: set, context: context)
        try? context.save()
        if isRecord { Haptics.personalRecord() } else { Haptics.commit() }
    }

    /// Manda la sessione a Salute. Le date si leggono **qui**, sul main actor,
    /// e solo quelle attraversano il confine con HealthKit.
    private func sendToHealth(announceSuccess: Bool) {
        guard !workout.setList.isEmpty else {
            healthMessage = HealthService.HealthError.emptyWorkout.localizedDescription
            return
        }
        let start = workout.date
        let end = workout.endedAt ?? Date()

        sendingToHealth = true
        Task {
            do {
                try await HealthService.saveWorkout(start: start, end: end)
                sendingToHealth = false
                if announceSuccess {
                    healthMessage = "Allenamento registrato in Salute."
                    Haptics.success()
                }
            } catch {
                sendingToHealth = false
                healthMessage = error.localizedDescription
                Haptics.warning()
            }
        }
    }

    private func delete(_ set: WorkoutSet) {
        withAnimation {
            RecordService.removeAutomaticRecord(for: set, context: context)
            context.delete(set)
            try? context.save()
        }
        Haptics.warning()
    }

    private func finish() {
        workout.endedAt = Date()
        try? context.save()
        if let date = try? BackupService.writeAutoBackup(context: context) {
            settings.lastBackupDate = date
        }
        if settings.healthSyncEnabled {
            sendToHealth(announceSuccess: false)
        }

        Haptics.success()
        showingSummary = true
    }
}

// MARK: - Card di un esercizio nella sessione

private struct ExerciseSessionCard: View {
    @Environment(AppSettings.self) private var settings

    let exercise: Exercise
    let sets: [WorkoutSet]
    let onAddSet: () -> Void
    let onRepeatLast: () -> Void
    let onEditSet: (WorkoutSet) -> Void
    let onDeleteSet: (WorkoutSet) -> Void

    var body: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ExerciseThumbnail(exercise: exercise, size: 34)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(exercise.name)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if let best = exercise.bestRecord {
                            Text("max \(Fmt.setLine(weight: best.weight, reps: best.reps, unit: settings.unit))")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    Spacer()
                }

                if sets.isEmpty {
                    Text("Nessuna serie registrata")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.textTertiary)
                } else {
                    VStack(spacing: 6) {
                        ForEach(Array(sets.enumerated()), id: \.element.persistentModelID) { index, set in
                            HStack(spacing: 10) {
                                Text("\(index + 1)")
                                    .font(Theme.rounded(11, .bold))
                                    .foregroundStyle(Theme.textTertiary)
                                    .frame(width: 18)

                                Text(Fmt.setLine(weight: set.weight, reps: set.reps, unit: settings.unit))
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(set.isWarmup ? Theme.textSecondary : Theme.textPrimary)

                                if set.isPersonalRecord { PRBadge() }
                                if set.isWarmup {
                                    Text("risc.")
                                        .font(Theme.rounded(10, .semibold))
                                        .foregroundStyle(Theme.textTertiary)
                                }

                                Spacer()

                                if set.reps > 1 {
                                    Text("≈ \(Fmt.weight(set.estimatedOneRepMax(using: settings.formula), unit: settings.unit))")
                                        .font(Theme.rounded(11, .medium))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(
                                set.isPersonalRecord ? Theme.positive.opacity(0.10) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { onEditSet(set) }
                            .contextMenu {
                                Button {
                                    onEditSet(set)
                                } label: {
                                    Label("Modifica serie", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    onDeleteSet(set)
                                } label: {
                                    Label("Elimina serie", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    Button(action: onAddSet) {
                        Label("Serie", systemImage: "plus")
                            .font(Theme.rounded(13, .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(exercise.muscleGroup.tint.opacity(0.20), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .foregroundStyle(exercise.muscleGroup.tint)
                    }
                    .buttonStyle(.plain)

                    if let last = sets.last {
                        Button(action: onRepeatLast) {
                            Label(Fmt.setLine(weight: last.weight, reps: last.reps, unit: settings.unit), systemImage: "arrow.counterclockwise")
                                .font(Theme.rounded(13, .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Theme.card, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
