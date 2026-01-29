import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var selectedHostId: UUID?
    @State private var editingHost: SSHHost?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedHostId) {
                ForEach(configManager.hosts) { host in
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
                    .tag(host.id)
                    .contextMenu {
                        Button("编辑") {
                            editingHost = host
                        }
                        Button("删除", role: .destructive) {
                            configManager.removeHost(host)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            configManager.removeHost(host)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        Button {
                            editingHost = host
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("主机列表")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addNewHost()
                    } label: {
                        Label("添加主机", systemImage: "plus")
                    }
                    .help("添加新主机")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if let selectedHostId = selectedHostId,
                           let selectedHost = configManager.hosts.first(where: { $0.id == selectedHostId }) {
                            editingHost = selectedHost
                        }
                    } label: {
                        Label("编辑主机", systemImage: "pencil")
                    }
                    .disabled(selectedHostId == nil)
                    .help("编辑选中的主机")
                }
            }
        } detail: {
            if let selectedHostId = selectedHostId,
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

    private func addNewHost() {
        let newHost = SSHHost()
        configManager.addHost(newHost)
        selectedHostId = newHost.id
        editingHost = newHost
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
            Text("选择一个主机进行编辑")
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