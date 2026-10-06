import ActivityKit
import Foundation

/// La sessione in corso sulla schermata di blocco e nella Dynamic Island.
/// Una sola alla volta: se ne esiste già una, si aggiorna quella.
enum WorkoutActivity {

    private static var current: Activity<WorkoutActivityAttributes>? {
        Activity<WorkoutActivityAttributes>.activities.first
    }

    private static func state(for workout: Workout, unit: WeightUnit) -> WorkoutActivityAttributes.ContentState {
        .init(
            exercise: workout.orderedSets.last?.exercise?.name ?? "",
            sets: workout.workingSetCount,
            volume: Fmt.volume(workout.totalVolume, unit: unit),
            restEnd: RestTimer.shared.end
        )
    }

    /// Avvia l'attività se manca, altrimenti la aggiorna. Va bene anche alla
    /// riapertura di una sessione, dopo che iOS l'ha chiusa.
    static func start(for workout: Workout, unit: WeightUnit) {
        guard workout.isActive, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard current == nil else { return update(for: workout, unit: unit) }
        _ = try? Activity.request(
            attributes: WorkoutActivityAttributes(startDate: workout.date),
            content: .init(state: state(for: workout, unit: unit), staleDate: nil)
        )
    }

    static func update(for workout: Workout, unit: WeightUnit) {
        guard let activity = current else { return }
        let content = ActivityContent(state: state(for: workout, unit: unit), staleDate: nil)
        Task { await activity.update(content) }
    }

    static func end() {
        for activity in Activity<WorkoutActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
