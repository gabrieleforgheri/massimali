import SwiftUI

@main
struct MassimaliWatchApp: App {
    @State private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .task { model.activate() }
        }
    }
}
