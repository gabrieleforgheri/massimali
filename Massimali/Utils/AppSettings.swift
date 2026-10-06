import Foundation
import Observation
import SwiftUI

/// Unità di misura mostrata a schermo. Sul disco i pesi sono **sempre** in kg.
enum WeightUnit: String, CaseIterable, Identifiable, Codable {
    case kg
    case lb

    var id: String { rawValue }
    var symbol: String { rawValue }
    var title: String { self == .kg ? "Chilogrammi (kg)" : "Libbre (lb)" }

    private static let poundsPerKilogram = 2.204622621848776

    /// Da kg (storage) al valore mostrato.
    func fromKilograms(_ kg: Double) -> Double {
        self == .kg ? kg : kg * Self.poundsPerKilogram
    }

    /// Dal valore inserito dall'utente ai kg da salvare.
    func toKilograms(_ value: Double) -> Double {
        self == .kg ? value : value / Self.poundsPerKilogram
    }

    /// Passo di default degli stepper quando l'esercizio non ne ha uno suo.
    var defaultStep: Double { self == .kg ? 2.5 : 5 }
}

/// Tinte selezionabili per l'accento dell'app.
enum AccentPalette: String, CaseIterable, Identifiable, Codable {
    case lime
    case ember
    case ice
    case violet
    case coral

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lime: return "Lime"
        case .ember: return "Brace"
        case .ice: return "Ghiaccio"
        case .violet: return "Viola"
        case .coral: return "Corallo"
        }
    }

    var color: Color {
        switch self {
        case .lime: return Color(red: 0.72, green: 0.94, blue: 0.30)
        case .ember: return Color(red: 1.00, green: 0.58, blue: 0.24)
        case .ice: return Color(red: 0.45, green: 0.80, blue: 1.00)
        case .violet: return Color(red: 0.68, green: 0.55, blue: 1.00)
        case .coral: return Color(red: 1.00, green: 0.45, blue: 0.45)
        }
    }
}

/// Preferenze dell'utente, persistite su `UserDefaults`.
@Observable
final class AppSettings {

    private enum Key {
        static let unit = "settings.unit"
        static let formula = "settings.formula"
        static let accent = "settings.accent"
        static let didSeed = "settings.didSeedCatalog"
        static let lastBackup = "settings.lastBackupDate"
        static let lastExport = "settings.lastExportDate"
        static let didCurate = "settings.didCurateCatalog"
        static let health = "settings.healthSyncEnabled"
        static let restEnabled = "settings.restTimerEnabled"
        static let restSeconds = "settings.restSeconds"
        static let progression = "settings.progressionEnabled"
        static let repMin = "settings.repRangeMin"
        static let repMax = "settings.repRangeMax"
        static let plates = "settings.plateCalculatorEnabled"
        static let barWeight = "settings.barWeight"
        static let availablePlates = "settings.availablePlates"
        static let watch = "settings.watchEnabled"
        static let watchMode = "settings.watchMode"
        static let watchAutoEnd = "settings.watchAutoEndSeconds"
        static let watchSensitivity = "settings.watchSensitivity"
    }

    private let defaults: UserDefaults

    var unit: WeightUnit {
        didSet { defaults.set(unit.rawValue, forKey: Key.unit) }
    }

    var formula: OneRepMaxFormula {
        didSet { defaults.set(formula.rawValue, forKey: Key.formula) }
    }

    var accent: AccentPalette {
        didSet { defaults.set(accent.rawValue, forKey: Key.accent) }
    }

    var didSeedCatalog: Bool {
        didSet { defaults.set(didSeedCatalog, forKey: Key.didSeed) }
    }

    /// `true` una volta che hai scelto quali macchinari ha la tua palestra,
    /// così l'invito a sfoltire il catalogo non torna a ogni avvio.
    var didCurateCatalog: Bool {
        didSet { defaults.set(didCurateCatalog, forKey: Key.didCurate) }
    }

    /// Sincronizzazione con l'app Salute: peso in entrata, allenamenti in uscita.
    var healthSyncEnabled: Bool {
        didSet { defaults.set(healthSyncEnabled, forKey: Key.health) }
    }

    /// Timer di recupero dopo ogni serie.
    var restTimerEnabled: Bool {
        didSet { defaults.set(restTimerEnabled, forKey: Key.restEnabled) }
    }

    /// Recupero predefinito in secondi; ogni macchinario può avere il suo.
    var restSeconds: Int {
        didSet { defaults.set(restSeconds, forKey: Key.restSeconds) }
    }

    /// Suggerimento del prossimo carico (doppia progressione).
    var progressionEnabled: Bool {
        didSet { defaults.set(progressionEnabled, forKey: Key.progression) }
    }

    var repRangeMin: Int {
        didSet { defaults.set(repRangeMin, forKey: Key.repMin) }
    }

    var repRangeMax: Int {
        didSet { defaults.set(repRangeMax, forKey: Key.repMax) }
    }

    /// Mai vuoto: se gli estremi si incrociano vale il minimo.
    var repRange: ClosedRange<Int> { repRangeMin...max(repRangeMin, repRangeMax) }

    /// Calcolatore dischi per bilanciere e plate loaded.
    var plateCalculatorEnabled: Bool {
        didSet { defaults.set(plateCalculatorEnabled, forKey: Key.plates) }
    }

    /// Peso del bilanciere scarico, in kg.
    var barWeight: Double {
        didSet { defaults.set(barWeight, forKey: Key.barWeight) }
    }

    /// Dischi che la tua palestra ha davvero, in kg.
    var availablePlates: [Double] {
        didSet { defaults.set(availablePlates, forKey: Key.availablePlates) }
    }

    /// App del Watch: conteggio delle ripetizioni e serie registrate dall'orologio.
    var watchEnabled: Bool {
        didSet { defaults.set(watchEnabled, forKey: Key.watch) }
    }

    var watchMode: WatchCountMode {
        didSet { defaults.set(watchMode.rawValue, forKey: Key.watchMode) }
    }

    /// Secondi di fermo dopo l'ultima ripetizione prima di chiudere la serie.
    var watchAutoEndSeconds: Double {
        didSet { defaults.set(watchAutoEndSeconds, forKey: Key.watchAutoEnd) }
    }

    /// Calibrazione del contatore: 1 normale, più alto conta movimenti più piccoli.
    var watchSensitivity: Double {
        didSet { defaults.set(watchSensitivity, forKey: Key.watchSensitivity) }
    }

    var lastBackupDate: Date? {
        didSet { defaults.set(lastBackupDate, forKey: Key.lastBackup) }
    }

    /// Ultima volta che un backup è uscito davvero dall'app (condiviso o salvato).
    /// Diverso da `lastBackupDate`, che è la copia automatica interna: se disinstalli
    /// l'app quella se ne va con lei, questa no.
    var lastExportDate: Date? {
        didSet { defaults.set(lastExportDate, forKey: Key.lastExport) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.unit = WeightUnit(rawValue: defaults.string(forKey: Key.unit) ?? "") ?? .kg
        self.formula = OneRepMaxFormula(rawValue: defaults.string(forKey: Key.formula) ?? "") ?? .epley
        self.accent = AccentPalette(rawValue: defaults.string(forKey: Key.accent) ?? "") ?? .lime
        self.didSeedCatalog = defaults.bool(forKey: Key.didSeed)
        self.didCurateCatalog = defaults.bool(forKey: Key.didCurate)
        self.healthSyncEnabled = defaults.bool(forKey: Key.health)
        self.lastBackupDate = defaults.object(forKey: Key.lastBackup) as? Date
        self.restTimerEnabled = defaults.object(forKey: Key.restEnabled) as? Bool ?? true
        self.restSeconds = defaults.object(forKey: Key.restSeconds) as? Int ?? 120
        self.progressionEnabled = defaults.object(forKey: Key.progression) as? Bool ?? true
        self.repRangeMin = defaults.object(forKey: Key.repMin) as? Int ?? 8
        self.repRangeMax = defaults.object(forKey: Key.repMax) as? Int ?? 12
        self.plateCalculatorEnabled = defaults.object(forKey: Key.plates) as? Bool ?? true
        self.barWeight = defaults.object(forKey: Key.barWeight) as? Double ?? 20
        self.availablePlates = defaults.array(forKey: Key.availablePlates) as? [Double]
            ?? [25, 20, 15, 10, 5, 2.5, 1.25]
        self.watchEnabled = defaults.object(forKey: Key.watch) as? Bool ?? true
        self.watchMode = WatchCountMode(rawValue: defaults.string(forKey: Key.watchMode) ?? "") ?? .tapStartAutoEnd
        self.watchAutoEndSeconds = defaults.object(forKey: Key.watchAutoEnd) as? Double ?? 4
        self.watchSensitivity = defaults.object(forKey: Key.watchSensitivity) as? Double ?? 1
        self.lastExportDate = defaults.object(forKey: Key.lastExport) as? Date
    }

    var accentColor: Color { accent.color }

    /// Dopo due settimane senza esportare vale la pena ricordarlo.
    static let exportReminderDays = 14

    var daysSinceExport: Int? {
        guard let lastExportDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastExportDate, to: Date()).day
    }

    /// `true` se non hai mai esportato o se è passato troppo tempo.
    var needsExportReminder: Bool {
        guard let days = daysSinceExport else { return true }
        return days >= Self.exportReminderDays
    }
}
