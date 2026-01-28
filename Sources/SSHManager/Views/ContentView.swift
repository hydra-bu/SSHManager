import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var selectedHostId: UUID?
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var editingHost: SSHHost?

    var body: some View {
        NavigationSplitView {
            // 左侧：主机列表
            List($configManager.hosts, selection: $selectedHostId) { $host in
                HStack {
                    Image(systemName: "server.rack")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text(host.alias)
                            .font(.headline)
                        Text(host.getUserAtHost())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .tag(host.id)
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button("添加") {
                        print("点击添加按钮")
                        editingHost = SSHHost()
                        showingEditSheet = true
                        print("显示编辑界面: \(showingEditSheet)")
                    }
                    .buttonStyle(.borderedProminent)

                    if let selectedHostId = selectedHostId,
                       let selectedHost = configManager.hosts.first(where: { $0.id == selectedHostId }) {
                        Button("连接") {
                            connect(to: selectedHost)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.thickMaterial)
            }
        } detail: {
            // 右侧：详细信息或编辑
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
        .sheet(item: $editingHost, onDismiss: {
            editingHost = nil
        }, content: { editHost in
            NavigationStack {
                // 创建临时副本进行编辑
                HostEditorView(host: editHost) { updatedHost in
                    // 保存回调
                    if updatedHost.id == editHost.id {
                        configManager.updateHost(updatedHost)
                    } else {
                        configManager.addHost(updatedHost)
                    }
                    selectedHostId = updatedHost.id
                }
            }
        })
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