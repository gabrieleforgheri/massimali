import SwiftUI
import SwiftData

struct WorkoutsListView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    @State private var path: [Workout] = []

    private var activeWorkout: Workout? { workouts.first(where: \.isActive) }
    private var finishedWorkouts: [Workout] { workouts.filter { !$0.isActive } }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    startCard
                        .plainListRow()
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 10, trailing: 16))
                }

                if finishedWorkouts.isEmpty {
                    Section {
                        Text("Gli allenamenti conclusi finiscono qui, con volume e record della giornata.")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                            .plainListRow()
                    }
                } else {
                    Section {
                        ForEach(finishedWorkouts) { workout in
                            ZStack {
                                NavigationLink(value: workout) { EmptyView() }.opacity(0)
                                WorkoutRow(workout: workout)
                            }
                            .plainListRow()
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(workout)
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        SectionHeader(title: "Storico", trailing: "\(finishedWorkouts.count)")
                            .textCase(nil)
                            .padding(.horizontal, 2)
                    }
                }
            }
            .listStyle(.plain)
            .screenBackground(settings.accentColor)
            .navigationTitle("Allenamenti")
            .navigationDestination(for: Workout.self) { workout in
                WorkoutSessionView(workout: workout)
            }
        }
    }

    private var startCard: some View {
        GlassCard(padding: 18, tint: activeWorkout != nil ? settings.accentColor : nil) {
            VStack(alignment: .leading, spacing: 14) {
                if let activeWorkout {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(settings.accentColor)
                            .frame(width: 8, height: 8)
                        Text("SESSIONE IN CORSO")
                            .font(Theme.rounded(11, .bold))
                            .tracking(0.8)
                            .foregroundStyle(settings.accentColor)
                        Spacer()
                        Text(Fmt.dateTime(activeWorkout.date))
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    HStack(spacing: 18) {
                        MiniStat(value: "\(activeWorkout.workingSetCount)", label: "serie")
                        MiniStat(value: Fmt.volume(activeWorkout.totalVolume, unit: settings.unit), label: "volume")
                        MiniStat(value: "\(activeWorkout.exercisesInOrder.count)", label: "esercizi")
                    }

                    Button {
                        path.append(activeWorkout)
                    } label: {
                        Label("Riprendi allenamento", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: settings.accentColor))
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pronto ad allenarti?")
                            .font(Theme.rounded(19, .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Registra le serie mentre ti alleni: i nuovi massimali scattano da soli.")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Button {
                        startWorkout()
                    } label: {
                        Label("Inizia allenamento", systemImage: "bolt.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: settings.accentColor))
                }
            }
        }
    }

    private func startWorkout() {
        let workout = Workout()
        context.insert(workout)
        try? context.save()
        Haptics.commit()
        path.append(workout)
    }

    private func delete(_ workout: Workout) {
        withAnimation {
            context.delete(workout)
            try? context.save()
        }
        Haptics.warning()
    }
}

// MARK: - Riga

private struct WorkoutRow: View {
    @Environment(AppSettings.self) private var settings
    let workout: Workout

    private var prCount: Int { workout.setList.filter(\.isPersonalRecord).count }

    private var groups: [MuscleGroup] {
        var seen: [MuscleGroup] = []
        for exercise in workout.exercisesInOrder where !seen.contains(exercise.muscleGroup) {
            seen.append(exercise.muscleGroup)
        }
        return seen
    }

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(Fmt.relativeDay(workout.date))
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if prCount > 0 {
                        PRBadge(text: prCount == 1 ? "1 PR" : "\(prCount) PR")
                    }
                    Spacer()
                    if let duration = workout.duration {
                        Text(Fmt.duration(duration))
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                if !workout.note.isEmpty {
                    Text(workout.note)
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    MiniStat(value: "\(workout.workingSetCount)", label: "serie")
                    MiniStat(value: Fmt.volume(workout.totalVolume, unit: settings.unit), label: "volume")
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach(groups.prefix(4), id: \.self) { group in
                            Image(systemName: group.symbol)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(group.tint)
                        }
                    }
                }
            }
        }
    }
}

struct MiniStat: View {
    let value: String
    let label: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}
