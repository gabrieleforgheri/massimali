import HealthKit
import SwiftUI
import WatchKit

@main
struct MassimaliWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(delegate.model)
                .task { delegate.model.activate() }
        }
    }
}

/// Riceve l'avvio dall'iPhone ("Avvia sul Watch" usa HealthKit per aprire l'app):
/// la sessione di allenamento parte subito, la serie quando arriva l'esercizio.
final class AppDelegate: NSObject, WKApplicationDelegate {
    let model = WatchModel()

    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        model.activate()
        model.startWorkout()
    }
}
