import SwiftUI

struct HostEditorView: View {
    @State var host: SSHHost
    let onSave: (SSHHost) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("连接信息") {
                    TextField("别名", text: $host.alias)
                    TextField("主机名或IP", text: $host.hostname)
                    HStack {
                        TextField("用户名", text: $host.user)
                        Spacer()
                        TextField("端口", value: $host.port, formatter: NumberFormatter())
                            .frame(width: 80)
                    }
                }

                Section("认证") {
                    HStack {
                        TextField("密钥文件路径", text: $host.identityFile)
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

                            ForEach(Array(host.options.keys), id: \.self) { key in
                                HStack {
                                    TextField("选项名", text: Binding(
                                        get: { key },
                                        set: { newValue in
                                            let oldValue = key
                                            if !newValue.isEmpty {
                                                host.options[newValue] = host.options[oldValue]
                                                host.options.removeValue(forKey: oldValue)
                                            }
                                        }
                                    ))
                                    TextField("值", text: Binding(
                                        get: { host.options[key] ?? "" },
                                        set: { newValue in
                                            host.options[key] = newValue
                                        }
                                    ))
                                    Button("删除") {
                                        host.options.removeValue(forKey: key)
                                    }
                                    .foregroundColor(.red)
                                }
                            }

                            HStack {
                                Spacer()
                                Button("添加选项") {
                                    let newKey = "option\(host.options.count + 1)"
                                    host.options[newKey] = ""
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(host.id == UUID() ? "新建连接" : "编辑连接")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(host)
                        dismiss()
                    }
                    .disabled(host.alias.isEmpty || host.hostname.isEmpty)
                }
            }
        }
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
}

struct HostEditorView_Previews: PreviewProvider {
    static var previews: some View {
        HostEditorView(host: SSHHost(alias: "test", hostname: "192.168.1.100", user: "admin")) { _ in }
    }
}