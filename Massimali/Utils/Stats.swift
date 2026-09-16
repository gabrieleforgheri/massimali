import Foundation

/// Calcoli aggregati per la scheda Progressi. Tutto in memoria: i volumi di dati
/// di un singolo utente sono minuscoli e così restano fuori dai predicati SwiftData.
enum Stats {

    struct WeeklyVolume: Identifiable {
        let id = UUID()
        let weekStart: Date
        let volume: Double
    }

    struct GroupVolume: Identifiable {
        let id = UUID()
        let group: MuscleGroup
        let volume: Double
    }

    struct Mover: Identifiable {
        let id = UUID()
        let exercise: Exercise
        let previous: Double
        let current: Double

        var deltaPercent: Double {
            guard previous > 0 else { return 100 }
            return (current - previous) / previous * 100
        }
    }

    /// Volume per settimana (lunedì → domenica) nelle ultime `weeks` settimane,
    /// **solo quelle in cui ti sei allenato**: le settimane vuote non devono occupare
    /// spazio nel grafico fingendo di essere dati.
    static func weeklyVolume(
        workouts: [Workout],
        weeks: Int = 12,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [WeeklyVolume] {
        var cal = calendar
        cal.firstWeekday = 2 // lunedì

        guard let thisWeek = cal.dateInterval(of: .weekOfYear, for: now)?.start,
              let oldest = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisWeek) else { return [] }

        var buckets: [Date: Double] = [:]
        for workout in workouts {
            guard let start = cal.dateInterval(of: .weekOfYear, for: workout.date)?.start,
                  start >= oldest, start <= thisWeek else { continue }
            buckets[start, default: 0] += workout.totalVolume
        }

        return buckets
            .map { WeeklyVolume(weekStart: $0.key, volume: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    /// Ripartizione del volume per gruppo muscolare in un intervallo di giorni.
    static func volumeByGroup(
        workouts: [Workout],
        days: Int = 30,
        now: Date = Date()
    ) -> [GroupVolume] {
        let cutoff = now.addingTimeInterval(-Double(days) * 86_400)
        var totals: [MuscleGroup: Double] = [:]

        for workout in workouts where workout.date >= cutoff {
            for set in workout.setList where !set.isWarmup {
                guard let group = set.exercise?.muscleGroup else { continue }
                totals[group, default: 0] += set.volume
            }
        }

        return MuscleGroup.allCases
            .compactMap { group in
                guard let volume = totals[group], volume > 0 else { return nil }
                return GroupVolume(group: group, volume: volume)
            }
            .sorted { $0.volume > $1.volume }
    }

    /// Esercizi cresciuti di più: miglior carico negli ultimi `days` giorni
    /// confrontato con il miglior carico precedente.
    static func topMovers(
        exercises: [Exercise],
        days: Int = 90,
        limit: Int = 5,
        now: Date = Date()
    ) -> [Mover] {
        let cutoff = now.addingTimeInterval(-Double(days) * 86_400)

        return exercises.compactMap { exercise -> Mover? in
            let recent = exercise.recordList
                .filter { $0.date >= cutoff }
                .map(\.weight)
                .max()
            guard let recent else { return nil }

            let previous = exercise.recordList
                .filter { $0.date < cutoff }
                .map(\.weight)
                .max() ?? 0

            guard recent > previous else { return nil }
            return Mover(exercise: exercise, previous: previous, current: recent)
        }
        .sorted { $0.deltaPercent > $1.deltaPercent }
        .prefix(limit)
        .map { $0 }
    }

    /// Fino a `max` indici equidistanti fra 0 e `count - 1`, primo e ultimo sempre
    /// inclusi. Serve a datare i grafici a passo fisso senza stamparci sotto tutte
    /// le date.
    static func tickIndices(count: Int, max: Int = 4) -> [Int] {
        guard count > 0, max > 0 else { return [] }
        guard count > max else { return Array(0..<count) }
        let step = Double(count - 1) / Double(max - 1)
        return (0..<max).map { Int((Double($0) * step).rounded()) }
    }

    /// Numero di sessioni nell'intervallo indicato.
    static func sessionCount(workouts: [Workout], days: Int, now: Date = Date()) -> Int {
        let cutoff = now.addingTimeInterval(-Double(days) * 86_400)
        return workouts.filter { $0.date >= cutoff }.count
    }

    /// Serie di settimane consecutive con almeno un allenamento, fino a oggi.
    static func weeklyStreak(workouts: [Workout], calendar: Calendar = .current, now: Date = Date()) -> Int {
        var cal = calendar
        cal.firstWeekday = 2
        guard let thisWeek = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }

        let trainedWeeks = Set(workouts.compactMap {
            cal.dateInterval(of: .weekOfYear, for: $0.date)?.start
        })

        var streak = 0
        var cursor = thisWeek
        while trainedWeeks.contains(cursor) {
            streak += 1
            guard let previous = cal.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
