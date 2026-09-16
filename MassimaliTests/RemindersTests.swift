import XCTest
import SwiftData
@testable import Massimali

@MainActor
final class RemindersTests: XCTestCase {

    private func makeSettings() -> AppSettings {
        let suite = "massimali.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return AppSettings(defaults: defaults)
    }

    // MARK: - Promemoria di backup

    /// Chi non ha mai esportato va avvisato subito: è la situazione più esposta.
    func testNeverExportedNeedsReminder() {
        let settings = makeSettings()
        XCTAssertNil(settings.lastExportDate)
        XCTAssertTrue(settings.needsExportReminder)
        XCTAssertNil(settings.daysSinceExport)
    }

    func testRecentExportDoesNotRemind() {
        let settings = makeSettings()
        settings.lastExportDate = Date().addingTimeInterval(-3 * 86_400)
        XCTAssertEqual(settings.daysSinceExport, 3)
        XCTAssertFalse(settings.needsExportReminder)
    }

    func testOldExportRemindsAgain() {
        let settings = makeSettings()
        settings.lastExportDate = Date().addingTimeInterval(-Double(AppSettings.exportReminderDays + 1) * 86_400)
        XCTAssertTrue(settings.needsExportReminder)
    }

    func testSettingsSurviveAcrossInstances() {
        let suite = "massimali.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!

        let first = AppSettings(defaults: defaults)
        first.healthSyncEnabled = true
        first.didCurateCatalog = true
        first.unit = .lb

        let second = AppSettings(defaults: defaults)
        XCTAssertTrue(second.healthSyncEnabled)
        XCTAssertTrue(second.didCurateCatalog)
        XCTAssertEqual(second.unit, .lb)
    }

    // MARK: - Scadenza della firma

    /// Nel bundle dei test non c'è nessun profilo: deve restituire nil senza
    /// esplodere, che è esattamente quello che succede anche sul simulatore.
    func testProvisioningIsSilentWithoutProfile() {
        XCTAssertNil(Provisioning.expirationDate)
        XCTAssertNil(Provisioning.daysRemaining())
        XCTAssertNil(Provisioning.statusText())
        XCTAssertFalse(Provisioning.isExpiringSoon())
    }

    // MARK: - Peso corporeo

    func testBodyWeightSurvivesBackupRoundTrip() throws {
        let container = try AppStore.makeContainer(inMemory: true)
        let source = ModelContext(container)

        let old = BodyWeightEntry(weight: 78.4, date: .now.addingTimeInterval(-30 * 86_400))
        let recent = BodyWeightEntry(weight: 77.1, date: .now, fromHealth: true)
        source.insert(old)
        source.insert(recent)
        try source.save()

        let data = try BackupService.data(context: source)
        let destination = ModelContext(try AppStore.makeContainer(inMemory: true))
        try BackupService.restore(from: data, context: destination, mode: .replace)

        let restored = try destination.fetch(
            FetchDescriptor<BodyWeightEntry>(sortBy: [SortDescriptor(\.date)])
        )
        XCTAssertEqual(restored.count, 2)
        XCTAssertEqual(restored[0].weight, 78.4, accuracy: 0.001)
        XCTAssertFalse(restored[0].fromHealth)
        XCTAssertTrue(restored[1].fromHealth)
    }

    /// Un backup vecchio, senza il campo del peso, deve restare importabile.
    func testBackupWithoutBodyWeightsStillImports() throws {
        let json = """
        {
          "version": 1,
          "exportedAt": "2026-01-15T10:00:00Z",
          "exercises": [],
          "workouts": []
        }
        """
        let context = ModelContext(try AppStore.makeContainer(inMemory: true))
        let file = try BackupService.restore(from: Data(json.utf8), context: context, mode: .replace)
        XCTAssertNil(file.bodyWeights)
        XCTAssertEqual(try context.fetch(FetchDescriptor<BodyWeightEntry>()).count, 0)
    }
}
