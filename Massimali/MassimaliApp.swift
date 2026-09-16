import SwiftUI
import SwiftData

@main
struct MassimaliApp: App {
    @State private var settings = AppSettings()
    private let container = AppStore.sharedContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .tint(settings.accentColor)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
