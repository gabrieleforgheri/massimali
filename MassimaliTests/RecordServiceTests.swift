import XCTest
import SwiftData
@testable import Massimali

@MainActor
final class RecordServiceTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try AppStore.makeContainer(inMemory: true)
        return ModelContext(container)
    }

    func testFirstWorkingSetCreatesRecord() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Leg Press", muscleGroup: .gambe, incrementStep: 10)
        context.insert(exercise)

        let set = WorkoutSet(weight: 120, reps: 5, order: 0, exercise: exercise)
        context.insert(set)

        let isRecord = RecordService.evaluatePersonalRecord(for: set, context: context)
        try context.save()

        XCTAssertTrue(isRecord)
        XCTAssertTrue(set.isPersonalRecord)
        XCTAssertEqual(exercise.recordList.count, 1)
        XCTAssertEqual(exercise.currentMax ?? 0, 120, accuracy: 0.01, "il massimale è il carico vero, non la stima")
    }

    func testWeakerSetDoesNotCreateRecord() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Lat Machine", muscleGroup: .schiena)
        context.insert(exercise)
        context.insert(MaxRecord(weight: 90, reps: 1, exercise: exercise))

        let set = WorkoutSet(weight: 60, reps: 8, order: 0, exercise: exercise)
        context.insert(set)

        XCTAssertFalse(RecordService.evaluatePersonalRecord(for: set, context: context))
        XCTAssertFalse(set.isPersonalRecord)
        XCTAssertEqual(exercise.recordList.count, 1)
    }

    func testWarmupSetIsIgnored() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Panca Piana Bilanciere", muscleGroup: .petto)
        context.insert(exercise)

        let set = WorkoutSet(weight: 200, reps: 5, isWarmup: true, order: 0, exercise: exercise)
        context.insert(set)

        XCTAssertFalse(RecordService.evaluatePersonalRecord(for: set, context: context))
        XCTAssertTrue(exercise.recordList.isEmpty)
    }

    func testRemovingSetRemovesItsAutomaticRecord() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Shoulder Press", muscleGroup: .spalle)
        context.insert(exercise)

        let set = WorkoutSet(weight: 50, reps: 6, order: 0, exercise: exercise)
        context.insert(set)
        RecordService.evaluatePersonalRecord(for: set, context: context)
        try context.save()
        XCTAssertEqual(exercise.recordList.count, 1)

        RecordService.removeAutomaticRecord(for: set, context: context)
        try context.save()

        XCTAssertTrue(exercise.recordList.isEmpty)
        XCTAssertFalse(set.isPersonalRecord)
    }

    func testManualRecordIsNotRemovedBySetDeletion() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Curl Bilanciere", muscleGroup: .braccia)
        context.insert(exercise)
        let manual = MaxRecord(weight: 40, reps: 3, isEstimated: false, exercise: exercise)
        context.insert(manual)

        let set = WorkoutSet(weight: 40, reps: 3, order: 0, exercise: exercise)
        set.isPersonalRecord = true
        context.insert(set)

        RecordService.removeAutomaticRecord(for: set, context: context)
        try context.save()

        XCTAssertEqual(exercise.recordList.count, 1, "un record inserito a mano non va toccato")
    }
}
