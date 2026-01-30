import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var editingHostId: UUID?
    @State private var showingHostEditor = false
    @State private var isNewHost = false

    var body: some View {
        NavigationSplitView {
            SidebarView(
                onEditHost: { host in
                    editingHostId = host.id
                    isNewHost = false
                    showingHostEditor = true
                },
                onAddHost: {
                    let newHost = SSHHost()
                    configManager.addHost(newHost)
                    configManager.selectedHostId = newHost.id
                    editingHostId = newHost.id
                    isNewHost = true
                    showingHostEditor = true
                }
            )
            .environmentObject(configManager)
            .navigationTitle("SSH Manager")
            .frame(minWidth: 250)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let newHost = SSHHost()
                        configManager.addHost(newHost)
                        configManager.selectedHostId = newHost.id
                        editingHostId = newHost.id
                        isNewHost = true
                        showingHostEditor = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("添加主机")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
        } detail: {
            if let selectedHostId = configManager.selectedHostId,
               let selectedHost = configManager.hosts.first(where: { $0.id == selectedHostId }) {
                HostDetailView(
                    host: selectedHost,
                    onEditHost: {
                        editingHostId = selectedHostId
                        isNewHost = false
                        showingHostEditor = true
                    }
                )
            } else {
                EmptyDetailView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addNewHost)) { _ in
            let newHost = SSHHost()
            configManager.addHost(newHost)
            configManager.selectedHostId = newHost.id
            editingHostId = newHost.id
            isNewHost = true
            showingHostEditor = true
        }
        .sheet(isPresented: $showingHostEditor) {
            if let hostId = editingHostId,
               let host = configManager.hosts.first(where: { $0.id == hostId }) {
                HostEditorView(
                    host: host,
                    isNewHost: isNewHost,
                    onSave: {
                        showingHostEditor = false
                        editingHostId = nil
                    },
                    onCancel: {
                        if isNewHost && host.alias.isEmpty && host.hostname.isEmpty {
                            configManager.removeHost(host)
                        }
                        showingHostEditor = false
                        editingHostId = nil
                    }
                )
                .environmentObject(configManager)
            }
        }
    }

    private func connect(to host: SSHHost) {
        let connector = SSHConnector()
        connector.connect(to: host)
    }
}

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
