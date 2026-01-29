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
            
            CommandMenu("连接") {
                Button("测试选中主机的连接") {
                    testSelectedHost()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(configManager.selectedHostId == nil)
            }
            
            CommandGroup(after: .appInfo) {
                Button("退出", action: { NSApp.terminate(nil) })
                    .keyboardShortcut("q")
            }
        }
    }
    
    private func testSelectedHost() {
        guard let id = configManager.selectedHostId,
              let host = configManager.hosts.first(where: { $0.id == id }) else { return }
        
        host.isTesting = true
        host.lastTestResult = nil
        
        Task {
            let connector = SSHConnector()
            let result = await connector.testConnection(host)
            
            await MainActor.run {
                host.lastTestResult = result
                host.isTesting = false
            }
        }
    }
}