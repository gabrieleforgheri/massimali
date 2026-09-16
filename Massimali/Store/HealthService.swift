import Foundation
import HealthKit

/// Ponte con l'app Salute, in due direzioni:
/// - **in entrata** il peso corporeo, così non lo devi riscrivere qui;
/// - **in uscita** gli allenamenti, così le tue sessioni finiscono nell'anello
///   attività e nello storico di Salute insieme a tutto il resto.
///
/// La capability HealthKit funziona anche con un Apple ID gratuito (verificato:
/// il profilo di provisioning personale include `com.apple.developer.healthkit`).
enum HealthService {

    enum HealthError: LocalizedError {
        case unavailable
        case workoutsNotAuthorized
        case emptyWorkout

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Salute non è disponibile su questo dispositivo."
            case .workoutsNotAuthorized:
                return "Salute non ha il permesso di registrare gli allenamenti. Apri Salute › Condivisione › App › Massimali e attiva Allenamenti."
            case .emptyWorkout:
                return "L'allenamento non ha serie da registrare."
            }
        }
    }

    static let store = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private static var bodyMass: HKQuantityType { HKQuantityType(.bodyMass) }

    private static var shareTypes: Set<HKSampleType> {
        [bodyMass, HKObjectType.workoutType()]
    }

    private static var readTypes: Set<HKObjectType> {
        [bodyMass]
    }

    /// Mostra il foglio di autorizzazione di sistema. Chiamarla più volte non fa
    /// danni: se il permesso c'è già, iOS non ripropone nulla.
    static func requestAuthorization() async throws {
        guard isAvailable else { throw HealthError.unavailable }
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    /// `true` se possiamo scrivere gli allenamenti. Per la **lettura** del peso iOS
    /// non consente di sapere se il permesso è stato dato: si scopre solo leggendo.
    static var canWriteWorkouts: Bool {
        guard isAvailable else { return false }
        return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    // MARK: - Peso in entrata

    /// L'ultima pesata registrata in Salute, in kg.
    static func latestBodyWeight() async throws -> (weight: Double, date: Date)? {
        guard isAvailable else { throw HealthError.unavailable }

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: bodyMass)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )

        guard let sample = try await descriptor.result(for: store).first else { return nil }
        return (sample.quantity.doubleValue(for: .gramUnit(with: .kilo)), sample.endDate)
    }

    // MARK: - Dati in uscita

    /// Scrive in Salute una pesata inserita a mano qui.
    static func saveBodyWeight(_ kilograms: Double, date: Date) async throws {
        guard isAvailable else { throw HealthError.unavailable }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kilograms)
        let sample = HKQuantitySample(type: bodyMass, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }

    /// Registra una sessione in Salute come allenamento di forza.
    ///
    /// Prende date già estratte, non il modello SwiftData: i modelli non sono
    /// sicuri da leggere fuori dal main actor, e qui si finisce su un altro
    /// esecutore appena si attende HealthKit.
    static func saveWorkout(start: Date, end: Date) async throws {
        guard isAvailable else { throw HealthError.unavailable }
        guard canWriteWorkouts else { throw HealthError.workoutsNotAuthorized }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        // Una sessione conclusa nello stesso istante in cui è iniziata verrebbe
        // rifiutata: si garantisce almeno un minuto di durata.
        let safeEnd = max(end, start.addingTimeInterval(60))

        try await builder.beginCollection(at: start)
        try await builder.endCollection(at: safeEnd)
        _ = try await builder.finishWorkout()
    }
}
