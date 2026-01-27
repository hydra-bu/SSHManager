import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var selectedHost: SSHHost?
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var editingHost: SSHHost?

    var body: some View {
        NavigationSplitView {
            // 左侧：主机列表
            List(selection: $selectedHost) {
                ForEach(configManager.hosts) { host in
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
                    .tag(host as SSHHost?)
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button("添加") {
                        editingHost = SSHHost()
                        showingEditSheet = true
                    }
                    .buttonStyle(.borderedProminent)

                    if let selectedHost = selectedHost {
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
            if let host = selectedHost {
                HostDetailView(host: host)
            } else {
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
        .sheet(isPresented: $showingEditSheet, content: {
            if var editHost = editingHost {
                NavigationStack {
                    HostEditorView(host: editHost) { updatedHost in
                        if updatedHost.id == editingHost?.id {
                            // 更新现有主机
                            configManager.updateHost(updatedHost)
                        } else {
                            // 添加新主机
                            configManager.addHost(updatedHost)
                        }
                        selectedHost = updatedHost
                    }
                    .onDisappear {
                        editingHost = nil
                    }
                }
            }
        })
    }

    private func connect(to host: SSHHost) {
        let connector = SSHConnector()
        connector.connect(to: host)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SSHConfigManager())
    }
}