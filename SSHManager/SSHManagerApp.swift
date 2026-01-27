import SwiftUI

@main
struct SSHManagerApp: App {
    @StateObject private var configManager = SSHConfigManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
        }
        .windowStyle(.document)
        .windowToolbarStyle(.unifiedCompact)
    }
}