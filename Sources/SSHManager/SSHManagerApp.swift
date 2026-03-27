import SwiftUI
import Sparkle

// MARK: - Check for Updates ViewModel
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

// MARK: - Check for Updates View
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Button("检查更新…") {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

@main
struct SSHManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var configManager = SSHConfigManager()
    @State private var showingPortForwardWizard = false
    @State private var showingJumpHostWizard = false
    
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
                .sheet(isPresented: $showingPortForwardWizard) {
                    if let selectedHostId = configManager.selectedHostId,
                       let host = configManager.hosts.first(where: { $0.id == selectedHostId }) {
                        PortForwardWizard(
                            isPresented: $showingPortForwardWizard,
                            host: host,
                            onComplete: { forward in
                                host.portForwards.append(forward)
                            }
                        )
                    }
                }
                .sheet(isPresented: $showingJumpHostWizard) {
                    if let selectedHostId = configManager.selectedHostId,
                       let host = configManager.hosts.first(where: { $0.id == selectedHostId }) {
                        JumpHostWizard(
                            isPresented: $showingJumpHostWizard,
                            host: host,
                            onComplete: { jump in
                                host.jumpHosts.append(jump)
                            }
                        )
                        .environmentObject(configManager)
                    }
                }
        }
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 SSH Manager") {
                    // 关于对话框
                }
            }
            
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            
            CommandMenu("主机") {
                Button("添加新主机") {
                    NotificationCenter.default.post(name: .addNewHost, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Divider()
                
                Button("配置端口转发") {
                    showingPortForwardWizard = true
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(configManager.selectedHostId == nil)
                
                Button("配置跳板机") {
                    showingJumpHostWizard = true
                }
                .keyboardShortcut("j", modifiers: [.command, .shift])
                .disabled(configManager.selectedHostId == nil)
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}

extension Notification.Name {
    static let addNewHost = Notification.Name("addNewHost")
}
