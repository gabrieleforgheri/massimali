import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: Tab = .maxes

    enum Tab: Hashable {
        case maxes, workouts, progress, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            MaxesListView()
                .tabItem { Label("Massimali", systemImage: "trophy.fill") }
                .tag(Tab.maxes)

            WorkoutsListView()
                .tabItem { Label("Allenamenti", systemImage: "figure.strengthtraining.traditional") }
                .tag(Tab.workouts)

            ProgressDashboardView()
                .tabItem { Label("Progressi", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.progress)

            SettingsView()
                .tabItem { Label("Impostazioni", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(settings.accentColor)
        .task {
            AppStore.seedIfNeeded(context: context, settings: settings)
            runAutoBackup()
        }
        .onChange(of: scenePhase) { _, phase in
            // Alla chiusura dell'app il backup automatico resta allineato:
            // è la rete di sicurezza contro la disinstallazione.
            if phase == .background { runAutoBackup() }
        }
    }

    private func runAutoBackup() {
        if let date = try? BackupService.writeAutoBackup(context: context) {
            settings.lastBackupDate = date
        }
    }
}
