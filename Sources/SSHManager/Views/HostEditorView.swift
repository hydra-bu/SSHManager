import SwiftUI

struct OptionItem: Identifiable {
    var id = UUID()
    var key: String
    var value: String
}

struct HostEditorView: View {
    @ObservedObject var host: SSHHost
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var hasUnsavedChanges = false
    @State private var options: [OptionItem] = []
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义标题栏
            HStack {
                Text(host.alias.isEmpty && host.hostname.isEmpty ? "新增连接" : "编辑连接")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 连接信息组
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
                                    .onChange(of: host.alias) { _ in hasUnsavedChanges = true }
                            }
                            
                            HStack {
                                Text("地址")
                                    .frame(width: 80, alignment: .trailing)
                                TextField("主机名或IP (必填)", text: $host.hostname)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: host.hostname) { _ in hasUnsavedChanges = true }
                            }
                            
                            HStack {
                                Text("用户")
                                    .frame(width: 80, alignment: .trailing)
                                TextField("用户名", text: $host.user)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: host.user) { _ in hasUnsavedChanges = true }
                                
                                Text("端口")
                                TextField("", value: $host.port, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                    .onChange(of: host.port) { _ in hasUnsavedChanges = true }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    // 认证组
                    VStack(alignment: .leading, spacing: 12) {
                        Text("认证")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("私钥路径")
                                .frame(width: 80, alignment: .trailing)
                            TextField("~/.ssh/id_rsa", text: $host.identityFile)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: host.identityFile) { _ in hasUnsavedChanges = true }
                            Button("浏览") {
                                browseKeyFile()
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    // 高级选项组
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("高级 SSH 选项")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                let newKey = "option\(options.count + 1)"
                                options.append(OptionItem(key: newKey, value: ""))
                                hasUnsavedChanges = true
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
                                                hasUnsavedChanges = true
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
                .padding()
            }
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("取消") { 
                    cancelChanges()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("保存") {
                    saveChanges()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(host.alias.trimmingCharacters(in: .whitespaces).isEmpty || 
                          host.hostname.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 550, minHeight: 400, maxHeight: 700)
        .onAppear {
            // Initialize options array from host.options
            options = host.options.map { OptionItem(key: $0.key, value: $0.value) }
        }
    }
    
    private func cancelChanges() {
        if host.alias.isEmpty && host.hostname.isEmpty {
            // 如果是新建且未填内容，取消时从列表中移除
            configManager.removeHost(host)
        }
        dismiss()
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
            hasUnsavedChanges = true
        }
    }
    
    private func saveChanges() {
        // Sync edited options back to host
        var newDict: [String: String] = [:]
        for opt in options {
            if !opt.key.trimmingCharacters(in: .whitespaces).isEmpty {
                newDict[opt.key] = opt.value
            }
        }
        host.options = newDict
        
        configManager.saveConfig()
        hasUnsavedChanges = false
        print("✅ 配置已保存")
    }
}

struct HostEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let host = SSHHost(alias: "test", hostname: "192.168.1.100", user: "admin")
        return HostEditorView(host: host)
            .environmentObject(SSHConfigManager())
    }
}
