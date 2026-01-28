import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var selectedHostId: UUID?
    @State private var isEditing = false
    @State private var editingHostIndex: Int?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedHostId) {
                ForEach(Array(configManager.hosts.enumerated()), id: \.element.id) { index, host in
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedHostId = host.id
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteHost(at: index)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        Button {
                            editingHostIndex = index
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button {
                        addNewHost()
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)

                    if let selectedHostId = selectedHostId,
                       let selectedHost = configManager.hosts.first(where: { $0.id == selectedHostId }) {
                        Button {
                            connect(to: selectedHost)
                        } label: {
                            Label("连接", systemImage: "terminal")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.thickMaterial)
            }
        } detail: {
            if let selectedHostId = selectedHostId {
                if let host = configManager.hosts.first(where: { $0.id == selectedHostId }) {
                    HostDetailView(host: host)
                } else {
                    EmptyDetailView()
                }
            } else {
                EmptyDetailView()
            }
        }
        .sheet(isPresented: $isEditing) {
            if let index = editingHostIndex {
                NavigationStack {
                    HostEditorView(host: Binding(
                        get: { configManager.hosts[index] },
                        set: { newHost in
                            configManager.hosts[index] = newHost
                            configManager.saveConfig()
                        }
                    )) { updatedHost in
                        configManager.hosts[index] = updatedHost
                        configManager.saveConfig()
                        isEditing = false
                    }
                }
            }
        }
    }

    private func addNewHost() {
        let newHost = SSHHost()
        configManager.addHost(newHost)
        if let lastIndex = configManager.hosts.indices.last {
            selectedHostId = configManager.hosts[lastIndex].id
            editingHostIndex = lastIndex
            isEditing = true
        }
    }

    private func deleteHost(at index: Int) {
        let host = configManager.hosts[index]
        configManager.removeHost(host)
        if selectedHostId == host.id {
            selectedHostId = nil
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