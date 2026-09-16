import XCTest
import SwiftData
@testable import Massimali

@MainActor
final class StatsTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try AppStore.makeContainer(inMemory: true)
        return ModelContext(container)
    }

    func testWeeklyVolumeSkipsEmptyWeeks() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Squat con Bilanciere", muscleGroup: .gambe)
        context.insert(exercise)

        let workout = Workout(date: .now)
        context.insert(workout)
        context.insert(WorkoutSet(weight: 100, reps: 5, order: 0, exercise: exercise, workout: workout))
        try context.save()

        let weekly = Stats.weeklyVolume(workouts: [workout], weeks: 8)
        XCTAssertEqual(weekly.count, 1, "le settimane senza allenamenti non devono occupare il grafico")
        XCTAssertEqual(weekly.last?.volume ?? 0, 500, accuracy: 0.001)
    }

    func testVolumeByGroupSkipsWarmup() throws {
        let context = try makeContext()
        let chest = Exercise(name: "Chest Press", muscleGroup: .petto)
        context.insert(chest)

        let workout = Workout(date: .now)
        context.insert(workout)
        context.insert(WorkoutSet(weight: 60, reps: 10, order: 0, exercise: chest, workout: workout))
        context.insert(WorkoutSet(weight: 20, reps: 20, isWarmup: true, order: 1, exercise: chest, workout: workout))
        try context.save()

        let groups = Stats.volumeByGroup(workouts: [workout], days: 30)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].group, .petto)
        XCTAssertEqual(groups[0].volume, 600, accuracy: 0.001)
    }

    func testTopMoversRanksByPercentGain() throws {
        let context = try makeContext()
        let a = Exercise(name: "Leg Extension", muscleGroup: .gambe, sortIndex: 0)
        let b = Exercise(name: "Pulley Basso", muscleGroup: .schiena, sortIndex: 1)
        context.insert(a)
        context.insert(b)

        let old = Date().addingTimeInterval(-120 * 86_400)
        let recent = Date().addingTimeInterval(-3 * 86_400)

        // +50%
        context.insert(MaxRecord(weight: 40, reps: 1, date: old, exercise: a))
        context.insert(MaxRecord(weight: 60, reps: 1, date: recent, exercise: a))
        // +10%
        context.insert(MaxRecord(weight: 50, reps: 1, date: old, exercise: b))
        context.insert(MaxRecord(weight: 55, reps: 1, date: recent, exercise: b))
        try context.save()

        let movers = Stats.topMovers(exercises: [a, b], days: 90)
        XCTAssertEqual(movers.count, 2)
        XCTAssertEqual(movers[0].exercise.name, "Leg Extension")
        XCTAssertEqual(movers[0].deltaPercent, 50, accuracy: 0.01)
        XCTAssertEqual(movers[1].deltaPercent, 10, accuracy: 0.01)
    }

    func testWeeklyStreakCountsConsecutiveWeeks() throws {
        let workouts = [
            Workout(date: .now),
            Workout(date: .now.addingTimeInterval(-7 * 86_400)),
            Workout(date: .now.addingTimeInterval(-14 * 86_400)),
            // salto la quarta settimana
            Workout(date: .now.addingTimeInterval(-28 * 86_400))
        ]
        XCTAssertEqual(Stats.weeklyStreak(workouts: workouts), 3)
    }
}
