import SwiftUI

struct HostRowView: View {
    @ObservedObject var host: SSHHost
    
    var body: some View {
        HStack {
            Image(systemName: "server.rack")
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(host.alias.isEmpty ? "未命名" : host.alias)
                    .font(.headline)
                Text(host.getUserAtHost())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var editingHost: SSHHost?

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(configManager)
                .navigationTitle("SSH Manager")
                .frame(minWidth: 250)
        } detail: {
            if let selectedHostId = configManager.selectedHostId,
               let selectedHost = configManager.hosts.first(where: { $0.id == selectedHostId }) {
                HostDetailView(host: selectedHost)
                    .toolbar {
                        ToolbarItem {
                            Button {
                                connect(to: selectedHost)
                            } label: {
                                Label("连接", systemImage: "terminal")
                            }
                        }
                    }
            } else {
                EmptyDetailView()
            }
        }
        .sheet(item: $editingHost) { host in
            HostEditorView(host: host)
                .environmentObject(configManager)
        }
    }

    private func connect(to host: SSHHost) {
        let connector = SSHConnector()
        connector.connect(to: host)
    }
}

// 空状态视图
struct EmptyDetailView: View {
    var body: some View {
        VStack {
            Image(systemName: "server.rack")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("选择一个主机进行查看")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SSHConfigManager())
    }
}
