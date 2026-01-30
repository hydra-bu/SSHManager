import SwiftUI

struct OptionItem: Identifiable {
    var id = UUID()
    var key: String
    var value: String
}

struct HostEditorView: View {
    @ObservedObject var host: SSHHost
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var options: [OptionItem] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                connectionSection
                authSection
                advancedSection
                portForwardingSection
                jumpHostSection
            }
            .padding()
        }
        .onAppear {
            options = host.options.map { OptionItem(key: $0.key, value: $0.value) }
        }
        .onDisappear {
            syncOptionsToHost()
        }
    }
    
    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("连接信息")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                HStack {
                    Text("别名")
                        .frame(width: 80, alignment: .trailing)
                    TextField("例如：生产服务器 (必填)", text: $host.alias)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("地址")
                        .frame(width: 80, alignment: .trailing)
                    TextField("主机名或IP (必填)", text: $host.hostname)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("用户")
                        .frame(width: 80, alignment: .trailing)
                    TextField("用户名", text: $host.user)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("端口")
                    TextField("", value: $host.port, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var authSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("认证")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("私钥路径")
                    .frame(width: 80, alignment: .trailing)
                TextField("~/.ssh/id_rsa", text: $host.identityFile)
                    .textFieldStyle(.roundedBorder)
                Button("浏览") {
                    browseKeyFile()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("高级 SSH 选项")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    let newKey = "option\(options.count + 1)"
                    options.append(OptionItem(key: newKey, value: ""))
                }) {
                    Label("添加选项", systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
            }
            
            if !options.isEmpty {
                VStack(spacing: 8) {
                    ForEach($options) { $opt in
                        HStack {
                            TextField("键", text: $opt.key)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                            TextField("值", text: $opt.value)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                if let idx = options.firstIndex(where: { $0.id == opt.id }) {
                                    options.remove(at: idx)
                                }
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var portForwardingSection: some View {
        PortForwardingSection(host: host)
            .environmentObject(configManager)
    }
    
    private var jumpHostSection: some View {
        JumpHostSection(host: host)
            .environmentObject(configManager)
    }
    
    private func browseKeyFile() {
        let panel = NSOpenPanel()
        panel.title = "选择SSH密钥文件"
        panel.allowedContentTypes = [.data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        
        if panel.runModal() == .OK {
            host.identityFile = panel.url?.path ?? ""
        }
    }
    
    private func syncOptionsToHost() {
        var newDict: [String: String] = [:]
        for opt in options {
            if !opt.key.trimmingCharacters(in: .whitespaces).isEmpty {
                newDict[opt.key] = opt.value
            }
        }
        host.options = newDict
    }
}

struct HostEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let host = SSHHost(alias: "test", hostname: "192.168.1.100", user: "admin")
        return HostEditorView(host: host)
            .environmentObject(SSHConfigManager())
    }
}
