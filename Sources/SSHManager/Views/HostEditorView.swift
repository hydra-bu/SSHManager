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
            
            Form {
                Section("连接信息") {
                    TextField("别名 (必填)", text: $host.alias)
                        .onChange(of: host.alias) { _ in hasUnsavedChanges = true }
                    TextField("主机名或IP (必填)", text: $host.hostname)
                        .onChange(of: host.hostname) { _ in hasUnsavedChanges = true }
                    HStack {
                        TextField("用户名", text: $host.user)
                            .onChange(of: host.user) { _ in hasUnsavedChanges = true }
                        Spacer()
                        TextField("端口", value: $host.port, formatter: NumberFormatter())
                            .frame(width: 80)
                            .onChange(of: host.port) { _ in hasUnsavedChanges = true }
                    }
                }
                
                Section("认证") {
                    HStack {
                        TextField("密钥文件路径", text: $host.identityFile)
                            .onChange(of: host.identityFile) { _ in hasUnsavedChanges = true }
                        Button("浏览") {
                            browseKeyFile()
                        }
                    }
                }
                
                Section("高级选项") {
                    DisclosureGroup("更多SSH选项") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("其他SSH配置选项（每行一个）：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach($options) { $opt in
                                HStack {
                                    TextField("选项名", text: $opt.key)
                                    TextField("值", text: $opt.value)
                                    Button("删除") {
                                        if let idx = options.firstIndex(where: { $0.id == opt.id }) {
                                            options.remove(at: idx)
                                            hasUnsavedChanges = true
                                        }
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                            
                            HStack {
                                Spacer()
                                Button("添加选项") {
                                    let newKey = "option\(options.count + 1)"
                                    options.append(OptionItem(key: newKey, value: ""))
                                    hasUnsavedChanges = true
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            
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
        .frame(minWidth: 500, minHeight: 600)
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
