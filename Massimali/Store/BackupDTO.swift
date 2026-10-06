import Foundation

/// Formato del file di backup. `version` serve a gestire eventuali cambi futuri.
struct BackupFile: Codable {
    var version: Int
    var exportedAt: Date
    var exercises: [ExerciseDTO]
    var workouts: [WorkoutDTO]
    /// Opzionale: i backup scritti prima del peso corporeo restano leggibili.
    var bodyWeights: [BodyWeightDTO]?

    static let currentVersion = 1
}

struct ExerciseDTO: Codable {
    var uuid: UUID
    var name: String
    var muscleGroup: String
    var notes: String
    var incrementStep: Double
    var sortIndex: Int
    var isArchived: Bool
    var createdAt: Date
    /// Opzionale: i backup scritti prima dei pittogrammi restano leggibili.
    var glyph: String?
    /// Foto in base64. Opzionale per lo stesso motivo.
    var photo: String?
    /// Inquadratura della foto. Opzionale: i backup più vecchi non ce l'hanno.
    var photoOffset: Double?
    /// Opzionale: i backup più vecchi non distinguono mono e bilaterale.
    var isUnilateral: Bool?
    /// Opzionale per lo stesso motivo; assente = recupero delle impostazioni.
    var restSeconds: Int?
    var records: [MaxRecordDTO]
}

struct MaxRecordDTO: Codable {
    var uuid: UUID
    var date: Date
    var weight: Double
    var reps: Int
    var isEstimated: Bool
    var note: String
}

struct WorkoutDTO: Codable {
    var uuid: UUID
    var date: Date
    var endedAt: Date?
    var note: String
    /// Opzionale: i backup scritti prima del focus restano leggibili.
    var focus: String?
    /// Opzionale: i backup scritti prima dei nomi restano leggibili.
    var name: String?
    var sets: [WorkoutSetDTO]
}

struct WorkoutSetDTO: Codable {
    var uuid: UUID
    /// Riferimento all'esercizio tramite uuid: resiste all'import su un database diverso.
    var exerciseUUID: UUID?
    var weight: Double
    var reps: Int
    var rpe: Double?
    var isWarmup: Bool
    var order: Int
    var createdAt: Date
    var isPersonalRecord: Bool
}

struct BodyWeightDTO: Codable {
    var uuid: UUID
    var date: Date
    var weight: Double
    var fromHealth: Bool
}
