import SwiftUI

@main
struct SSHManagerApp: App {
    @StateObject private var configManager = SSHConfigManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
        }
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 SSH Manager") {
                    // 可以添加关于对话框
                }
            }
            CommandGroup(after: .appInfo) {
                Button("退出", action: NSApp.terminate)
                    .keyboardShortcut("q")
            }
        }
    }
}