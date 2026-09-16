import Foundation
import SwiftData

/// Configurazione unica dello store SwiftData.
///
/// Con un Apple ID gratuito la capability iCloud non è attivabile, quindi il database
/// è puramente locale. Per accendere la sincronizzazione in futuro serve solo:
///   1. account sviluppatore a pagamento + capability iCloud/CloudKit nel target;
///   2. cambiare `cloudKitDatabase: .none` in `.automatic` qui sotto.
/// Il modello dati è già compatibile: ogni proprietà ha un default e tutte le
/// relazioni sono opzionali, che è ciò che CloudKit richiede.
enum AppStore {

    static let schema = Schema([
        Exercise.self,
        MaxRecord.self,
        Workout.self,
        WorkoutSet.self,
        BodyWeightEntry.self
    ])

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "Massimali",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Contenitore usato dall'app. Se lo store esistente non è apribile (schema cambiato
    /// durante lo sviluppo) si riparte in memoria invece di crashare all'avvio.
    static func sharedContainer() -> ModelContainer {
        do {
            return try makeContainer()
        } catch {
            assertionFailure("Store non apribile: \(error)")
            // Ultima spiaggia: sessione volatile, così l'app resta usabile e i dati
            // possono essere reimportati da un backup.
            return try! makeContainer(inMemory: true)
        }
    }

    /// Inserisce il catalogo iniziale solo la prima volta in assoluto.
    static func seedIfNeeded(context: ModelContext, settings: AppSettings) {
        guard !settings.didSeedCatalog else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        guard existing == 0 else {
            settings.didSeedCatalog = true
            return
        }
        SeedCatalog.insert(into: context)
        try? context.save()
        settings.didSeedCatalog = true
    }
}
