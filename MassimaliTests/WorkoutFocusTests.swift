import XCTest
import SwiftData
@testable import Massimali

@MainActor
final class WorkoutFocusTests: XCTestCase {

    func testFocusRoundTripsThroughRawValue() {
        let workout = Workout()
        XCTAssertTrue(workout.focus.isEmpty)

        workout.focus = [.spalle, .petto]
        XCTAssertEqual(workout.focusRaw, "petto,spalle")
        XCTAssertEqual(workout.focus, [.petto, .spalle])

        workout.focus = []
        XCTAssertEqual(workout.focusRaw, "")
    }

    func testFocusSurvivesBackupAndOldBackupsHaveNone() throws {
        let source = ModelContext(try AppStore.makeContainer(inMemory: true))
        let workout = Workout()
        workout.focus = [.gambe]
        workout.name = "Gambe 1"
        source.insert(workout)
        try source.save()

        let destination = ModelContext(try AppStore.makeContainer(inMemory: true))
        try BackupService.restore(from: try BackupService.data(context: source), context: destination, mode: .replace)
        let restored = try destination.fetch(FetchDescriptor<Workout>()).first
        XCTAssertEqual(restored?.focus, [.gambe])
        XCTAssertEqual(restored?.name, "Gambe 1")

        let old = """
        {"version":1,"exportedAt":"2026-01-15T10:00:00Z","exercises":[],
         "workouts":[{"uuid":"\(UUID().uuidString)","date":"2026-01-15T10:00:00Z","note":"","sets":[]}]}
        """
        let context = ModelContext(try AppStore.makeContainer(inMemory: true))
        try BackupService.restore(from: Data(old.utf8), context: context, mode: .replace)
        let legacy = try context.fetch(FetchDescriptor<Workout>()).first
        XCTAssertEqual(legacy?.focus, [])
        XCTAssertEqual(legacy?.name, "")
    }
}
