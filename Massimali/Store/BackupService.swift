import Foundation
import SwiftData

enum RestoreMode {
    /// Cancella tutto e riparte dal file.
    case replace
    /// Aggiunge solo ciò che non è già presente (confronto per uuid).
    case merge
}

enum BackupError: LocalizedError {
    case invalidFile
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "Il file non è un backup di Massimali valido."
        case .unsupportedVersion(let version):
            return "Backup in versione \(version): serve una versione più recente dell'app."
        }
    }
}

/// Export, import e backup automatico dei dati.
///
/// Con la firma gratuita l'app va rilanciata da Xcode ogni 7 giorni: i dati sopravvivono
/// finché l'app non viene disinstallata. Il backup automatico in `Documents` (visibile
/// nell'app File grazie a `UIFileSharingEnabled`) è la rete di sicurezza.
enum BackupService {

    static let autoBackupFilename = "backup-latest.json"

    // MARK: - Codifica

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Snapshot

    static func snapshot(context: ModelContext) throws -> BackupFile {
        let exercises = try context.fetch(
            FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.sortIndex)])
        )
        let workouts = try context.fetch(
            FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date)])
        )
        let weights = try context.fetch(
            FetchDescriptor<BodyWeightEntry>(sortBy: [SortDescriptor(\.date)])
        )

        return BackupFile(
            version: BackupFile.currentVersion,
            exportedAt: Date(),
            exercises: exercises.map { exercise in
                ExerciseDTO(
                    uuid: exercise.uuid,
                    name: exercise.name,
                    muscleGroup: exercise.muscleGroupRaw,
                    notes: exercise.notes,
                    incrementStep: exercise.incrementStep,
                    sortIndex: exercise.sortIndex,
                    isArchived: exercise.isArchived,
                    createdAt: exercise.createdAt,
                    glyph: exercise.glyphRaw.isEmpty ? nil : exercise.glyphRaw,
                    photo: exercise.photo?.base64EncodedString(),
                    photoOffset: exercise.photoOffset == 0 ? nil : exercise.photoOffset,
                    records: exercise.recordList.map { record in
                        MaxRecordDTO(
                            uuid: record.uuid,
                            date: record.date,
                            weight: record.weight,
                            reps: record.reps,
                            isEstimated: record.isEstimated,
                            note: record.note
                        )
                    }
                )
            },
            workouts: workouts.map { workout in
                WorkoutDTO(
                    uuid: workout.uuid,
                    date: workout.date,
                    endedAt: workout.endedAt,
                    note: workout.note,
                    sets: workout.orderedSets.map { set in
                        WorkoutSetDTO(
                            uuid: set.uuid,
                            exerciseUUID: set.exercise?.uuid,
                            weight: set.weight,
                            reps: set.reps,
                            rpe: set.rpe,
                            isWarmup: set.isWarmup,
                            order: set.order,
                            createdAt: set.createdAt,
                            isPersonalRecord: set.isPersonalRecord
                        )
                    }
                )
            },
            bodyWeights: weights.map { entry in
                BodyWeightDTO(
                    uuid: entry.uuid,
                    date: entry.date,
                    weight: entry.weight,
                    fromHealth: entry.fromHealth
                )
            }
        )
    }

    static func data(context: ModelContext) throws -> Data {
        try encoder().encode(snapshot(context: context))
    }

    // MARK: - File su disco

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var autoBackupURL: URL {
        documentsURL.appendingPathComponent(autoBackupFilename)
    }

    /// Scrive/aggiorna il backup automatico. Restituisce la data di scrittura.
    @discardableResult
    static func writeAutoBackup(context: ModelContext) throws -> Date {
        let payload = try data(context: context)
        try payload.write(to: autoBackupURL, options: .atomic)
        return Date()
    }

    /// Prepara un file con nome parlante da passare al foglio di condivisione.
    static func makeShareFile(context: ModelContext) throws -> URL {
        let payload = try data(context: context)
        let stamp = Date().formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Massimali-\(stamp).json")
        try payload.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Ripristino

    @discardableResult
    static func restore(from data: Data, context: ModelContext, mode: RestoreMode) throws -> BackupFile {
        let file: BackupFile
        do {
            file = try decoder().decode(BackupFile.self, from: data)
        } catch {
            throw BackupError.invalidFile
        }
        guard file.version <= BackupFile.currentVersion else {
            throw BackupError.unsupportedVersion(file.version)
        }

        if mode == .replace {
            try context.delete(model: WorkoutSet.self)
            try context.delete(model: Workout.self)
            try context.delete(model: MaxRecord.self)
            try context.delete(model: Exercise.self)
            try context.delete(model: BodyWeightEntry.self)
            try context.save()
        }

        // Esercizi già presenti, indicizzati per uuid: serve sia al merge sia a
        // ricollegare le serie degli allenamenti.
        var exercisesByUUID: [UUID: Exercise] = [:]
        for exercise in try context.fetch(FetchDescriptor<Exercise>()) {
            exercisesByUUID[exercise.uuid] = exercise
        }

        for dto in file.exercises {
            // In merge un esercizio già presente non viene sovrascritto: si aggiungono
            // solo i record che mancano. In replace la mappa è vuota, quindi si ricrea tutto.
            if let existing = exercisesByUUID[dto.uuid] {
                addMissingRecords(from: dto, to: existing, context: context)
                continue
            }

            let exercise = Exercise(
                name: dto.name,
                muscleGroup: MuscleGroup(rawValue: dto.muscleGroup) ?? .petto,
                incrementStep: dto.incrementStep,
                notes: dto.notes,
                sortIndex: dto.sortIndex
            )
            exercise.uuid = dto.uuid
            exercise.createdAt = dto.createdAt
            exercise.isArchived = dto.isArchived
            exercise.glyphRaw = dto.glyph ?? ""
            exercise.photo = dto.photo.flatMap { Data(base64Encoded: $0) }
            exercise.photoOffset = dto.photoOffset ?? 0
            context.insert(exercise)
            exercisesByUUID[dto.uuid] = exercise
            addMissingRecords(from: dto, to: exercise, context: context)
        }

        var existingWorkoutUUIDs = Set<UUID>()
        for workout in try context.fetch(FetchDescriptor<Workout>()) {
            existingWorkoutUUIDs.insert(workout.uuid)
        }

        for dto in file.workouts where !existingWorkoutUUIDs.contains(dto.uuid) {
            let workout = Workout(date: dto.date, note: dto.note)
            workout.uuid = dto.uuid
            workout.endedAt = dto.endedAt
            context.insert(workout)

            for setDTO in dto.sets {
                let set = WorkoutSet(
                    weight: setDTO.weight,
                    reps: setDTO.reps,
                    rpe: setDTO.rpe,
                    isWarmup: setDTO.isWarmup,
                    order: setDTO.order
                )
                set.uuid = setDTO.uuid
                set.createdAt = setDTO.createdAt
                set.isPersonalRecord = setDTO.isPersonalRecord
                context.insert(set)
                set.exercise = setDTO.exerciseUUID.flatMap { exercisesByUUID[$0] }
                set.workout = workout
            }
        }

        var existingWeightUUIDs = Set<UUID>()
        for entry in try context.fetch(FetchDescriptor<BodyWeightEntry>()) {
            existingWeightUUIDs.insert(entry.uuid)
        }

        for dto in file.bodyWeights ?? [] where !existingWeightUUIDs.contains(dto.uuid) {
            let entry = BodyWeightEntry(weight: dto.weight, date: dto.date, fromHealth: dto.fromHealth)
            entry.uuid = dto.uuid
            context.insert(entry)
        }

        try context.save()
        return file
    }

    private static func addMissingRecords(from dto: ExerciseDTO, to exercise: Exercise, context: ModelContext) {
        let existing = Set(exercise.recordList.map(\.uuid))
        for recordDTO in dto.records where !existing.contains(recordDTO.uuid) {
            let record = MaxRecord(
                weight: recordDTO.weight,
                reps: recordDTO.reps,
                date: recordDTO.date,
                isEstimated: recordDTO.isEstimated,
                note: recordDTO.note
            )
            record.uuid = recordDTO.uuid
            context.insert(record)
            record.exercise = exercise
        }
    }
}
