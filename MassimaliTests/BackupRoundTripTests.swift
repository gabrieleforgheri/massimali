import XCTest
import SwiftData
@testable import Massimali

@MainActor
final class BackupRoundTripTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try AppStore.makeContainer(inMemory: true)
        return ModelContext(container)
    }

    /// Popola un database con dati realistici e restituisce il contesto.
    private func seedSampleData(in context: ModelContext) throws {
        let legPress = Exercise(name: "Leg Press", muscleGroup: .gambe, incrementStep: 10, sortIndex: 0)
        let lat = Exercise(name: "Lat Machine", muscleGroup: .schiena, incrementStep: 5, sortIndex: 1)
        context.insert(legPress)
        context.insert(lat)

        context.insert(MaxRecord(weight: 180, reps: 1, date: .now.addingTimeInterval(-86_400 * 20), exercise: legPress))
        context.insert(MaxRecord(weight: 200, reps: 3, date: .now.addingTimeInterval(-86_400 * 5), exercise: legPress))
        context.insert(MaxRecord(weight: 70, reps: 5, date: .now.addingTimeInterval(-86_400 * 2), exercise: lat))

        let workout = Workout(date: .now.addingTimeInterval(-86_400), note: "Gambe pesanti")
        workout.endedAt = .now.addingTimeInterval(-86_400 + 3600)
        context.insert(workout)
        context.insert(WorkoutSet(weight: 160, reps: 8, order: 0, exercise: legPress, workout: workout))
        context.insert(WorkoutSet(weight: 180, reps: 5, order: 1, exercise: legPress, workout: workout))
        context.insert(WorkoutSet(weight: 60, reps: 10, isWarmup: true, order: 2, exercise: lat, workout: workout))

        try context.save()
    }

    /// Pittogramma scelto a mano e foto devono sopravvivere all'export/import,
    /// altrimenti un ripristino cancellerebbe il lavoro fatto in palestra.
    func testGlyphAndPhotoSurviveRoundTrip() throws {
        let source = try makeContext()
        let exercise = Exercise(name: "Rematore Plate Loaded", muscleGroup: .schiena, incrementStep: 5)
        source.insert(exercise)
        exercise.glyph = .plateLoaded
        exercise.photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03])
        try source.save()

        let data = try BackupService.data(context: source)
        let destination = try makeContext()
        try BackupService.restore(from: data, context: destination, mode: .replace)

        let restored = try XCTUnwrap(try destination.fetch(FetchDescriptor<Exercise>()).first)
        XCTAssertEqual(restored.glyph, .plateLoaded)
        XCTAssertTrue(restored.hasCustomGlyph)
        XCTAssertEqual(restored.photo, Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03]))
    }

    /// Un esercizio senza scelte manuali non deve portarsi dietro campi vuoti,
    /// e al ritorno deve comunque avere un pittogramma dedotto dal nome.
    func testExerciseWithoutCustomGlyphStillResolvesOne() throws {
        let source = try makeContext()
        let exercise = Exercise(name: "Leg Press 45°", muscleGroup: .gambe, incrementStep: 10)
        source.insert(exercise)
        try source.save()

        let data = try BackupService.data(context: source)
        let destination = try makeContext()
        try BackupService.restore(from: data, context: destination, mode: .replace)

        let restored = try XCTUnwrap(try destination.fetch(FetchDescriptor<Exercise>()).first)
        XCTAssertFalse(restored.hasCustomGlyph)
        XCTAssertEqual(restored.glyph, .legPress)
        XCTAssertNil(restored.photo)
    }

    func testExportImportKeepsEverything() throws {
        let source = try makeContext()
        try seedSampleData(in: source)
        let data = try BackupService.data(context: source)

        let destination = try makeContext()
        let file = try BackupService.restore(from: data, context: destination, mode: .replace)

        XCTAssertEqual(file.version, BackupFile.currentVersion)

        let exercises = try destination.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.sortIndex)]))
        XCTAssertEqual(exercises.count, 2)
        XCTAssertEqual(exercises.map(\.name), ["Leg Press", "Lat Machine"])
        XCTAssertEqual(exercises[0].incrementStep, 10)
        XCTAssertEqual(exercises[0].recordList.count, 2)
        XCTAssertEqual(exercises[0].currentMax ?? 0, 200, accuracy: 0.01)

        let workouts = try destination.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(workouts.count, 1)
        XCTAssertEqual(workouts[0].note, "Gambe pesanti")
        XCTAssertEqual(workouts[0].setList.count, 3)
        XCTAssertEqual(workouts[0].workingSetCount, 2)
        XCTAssertEqual(workouts[0].totalVolume, 160 * 8 + 180 * 5, accuracy: 0.001)

        // Le serie devono restare agganciate all'esercizio giusto.
        let legPressSets = workouts[0].setList.filter { $0.exercise?.name == "Leg Press" }
        XCTAssertEqual(legPressSets.count, 2)
    }

    func testImportTwiceInMergeModeDoesNotDuplicate() throws {
        let source = try makeContext()
        try seedSampleData(in: source)
        let data = try BackupService.data(context: source)

        let destination = try makeContext()
        try BackupService.restore(from: data, context: destination, mode: .replace)
        try BackupService.restore(from: data, context: destination, mode: .merge)

        XCTAssertEqual(try destination.fetch(FetchDescriptor<Exercise>()).count, 2)
        XCTAssertEqual(try destination.fetch(FetchDescriptor<MaxRecord>()).count, 3)
        XCTAssertEqual(try destination.fetch(FetchDescriptor<Workout>()).count, 1)
        XCTAssertEqual(try destination.fetch(FetchDescriptor<WorkoutSet>()).count, 3)
    }

    func testReplaceModeWipesPreviousData() throws {
        let source = try makeContext()
        try seedSampleData(in: source)
        let data = try BackupService.data(context: source)

        let destination = try makeContext()
        let stray = Exercise(name: "Macchinario di prova", muscleGroup: .core)
        destination.insert(stray)
        try destination.save()

        try BackupService.restore(from: data, context: destination, mode: .replace)

        let names = try destination.fetch(FetchDescriptor<Exercise>()).map(\.name)
        XCTAssertFalse(names.contains("Macchinario di prova"))
        XCTAssertEqual(names.count, 2)
    }

    func testInvalidFileThrows() throws {
        let context = try makeContext()
        let garbage = Data("non sono un backup".utf8)
        XCTAssertThrowsError(try BackupService.restore(from: garbage, context: context, mode: .merge)) { error in
            XCTAssertTrue(error is BackupError)
        }
    }
}
