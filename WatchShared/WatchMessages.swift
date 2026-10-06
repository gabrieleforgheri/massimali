import Foundation

/// Come il Watch apre e chiude una serie. Si sceglie nelle impostazioni dell'iPhone.
enum WatchCountMode: String, Codable, CaseIterable, Identifiable {
    /// Via dal telefono o dal Watch, fine dopo qualche secondo fermo.
    case tapStartAutoEnd
    /// Via e Fine a mano.
    case tapStartTapEnd
    /// Inizio e fine rilevati da soli mentre l'esercizio è aperto.
    case automatic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tapStartAutoEnd: return "Via a mano, fine automatica"
        case .tapStartTapEnd: return "Via e fine a mano"
        case .automatic: return "Tutto automatico"
        }
    }
}

/// L'esercizio aperto sull'iPhone, già pronto da mostrare: il Watch non conosce il modello.
struct WatchExercise: Codable, Equatable {
    var uuid: UUID
    var name: String
    /// Carico proposto, in kg.
    var weight: Double
    /// Passo del macchinario in kg, per la Digital Crown.
    var step: Double
    var isUnilateral: Bool
    /// Esercizio di gambe: il polso non si muove, niente conteggio automatico.
    var worksLegs: Bool
}

/// Stato che l'iPhone tiene aggiornato sul Watch (application context:
/// arriva anche se l'app del Watch era chiusa, alla prossima apertura).
struct WatchContext: Codable, Equatable {
    var exercise: WatchExercise?
    var mode: WatchCountMode
    /// Secondi di fermo dopo l'ultima ripetizione prima di chiudere la serie.
    var autoEndSeconds: Double
    /// Manopola di calibrazione del contatore: 1 normale, più alto = più sensibile.
    var sensitivity: Double
    /// Unità mostrata e fattore kg → unità.
    var unitSymbol: String
    var unitFactor: Double
    /// Valorizzato quando sull'iPhone si tocca "Avvia sul Watch": il Watch parte se è recente.
    var startRequestedAt: Date?

    static let key = "context"
}

/// Serie conclusa sul Watch, da registrare nella sessione dell'iPhone.
struct WatchSet: Codable, Equatable {
    var exerciseUUID: UUID
    var weight: Double
    var reps: Int

    static let key = "set"
}

extension Encodable {
    /// Le API di WatchConnectivity vogliono dizionari di plist: il JSON viaggia come `Data`.
    func watchPayload(key: String) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [key: data]
    }
}

extension Decodable {
    init?(watchPayload: [String: Any], key: String) {
        guard let data = watchPayload[key] as? Data,
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = value
    }
}
