import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var editingHost: SSHHost?
    @State private var showingHostEditor = false
    @State private var isNewHost = false

    var body: some View {
        NavigationSplitView {
            SidebarView(
                onEditHost: { host in
                    editingHost = host
                    isNewHost = false
                    showingHostEditor = true
                },
                onAddHost: {
                    let newHost = SSHHost()
                    configManager.addHost(newHost)
                    configManager.selectedHostId = newHost.id
                    editingHost = newHost
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
                        editingHost = newHost
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
                        editingHost = selectedHost
                        isNewHost = false
                        showingHostEditor = true
                    }
                )
            } else {
                EmptyDetailView()
            }
        }
        .sheet(isPresented: $showingHostEditor) {
            if let host = editingHost {
                NavigationStack {
                    HostEditorView(host: host)
                        .environmentObject(configManager)
                        .navigationTitle(isNewHost ? "添加主机" : "编辑主机")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("取消") {
                                    if isNewHost && host.alias.isEmpty && host.hostname.isEmpty {
                                        configManager.removeHost(host)
                                    }
                                    showingHostEditor = false
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("保存") {
                                    configManager.saveConfig()
                                    showingHostEditor = false
                                }
                                .disabled(host.alias.trimmingCharacters(in: .whitespaces).isEmpty ||
                                         host.hostname.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                }
                .frame(minWidth: 600, minHeight: 500)
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
