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
        
        // 触发连接测试。由于 HostDetailView 已经有这个逻辑，
        // 这里我们可以简单的通过 NotificationCenter 或者更直接的方式触发。
        // 但最简单的是在 SSHConnector 中提供一个通用的方法。
        Task {
            let connector = SSHConnector()
            _ = await connector.testConnection(host)
            // 测试结果会在 HostDetailView 中显示（如果它正在观察这个 host 的话）
            // 注意：目前的 ConnectionTestResult 是 HostDetailView 的私有状态。
            // 之后可以考虑将其移入 SSHHost 模型以实现多处同步。
        }
    }
}