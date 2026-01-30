import SwiftUI

struct HostEditorView: View {
    @ObservedObject var host: SSHHost
    @EnvironmentObject var configManager: SSHConfigManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var alias: String = ""
    @State private var hostname: String = ""
    @State private var user: String = ""
    @State private var port: String = "22"
    @State private var identityFile: String = ""
    @State private var enableCompression = false
    @State private var enableKeepAlive = false
    @State private var enableAgentForwarding = false
    @State private var enableX11Forwarding = false
    
    let isNewHost: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
            
            Form {
                Section("基本信息") {
                    TextField("别名", text: $alias)
                    TextField("主机地址", text: $hostname)
                    TextField("用户名", text: $user)
                    TextField("端口", text: $port)
                    HStack {
                        TextField("私钥路径", text: $identityFile)
                        Button("浏览") {
                            browseKeyFile()
                        }
                    }
                }
                
                Section("常用选项") {
                    Toggle("启用压缩", isOn: $enableCompression)
                    Toggle("保持连接", isOn: $enableKeepAlive)
                    Toggle("代理转发", isOn: $enableAgentForwarding)
                    Toggle("X11转发", isOn: $enableX11Forwarding)
                }
            }
            .formStyle(.grouped)
            
            Spacer()
            
            Divider()
            
            HStack {
                Button("取消") {
                    onCancel()
                    dismiss()
                }
                
                Spacer()
                
                Button("保存") {
                    saveHost()
                    onSave()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(alias.isEmpty || hostname.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .onAppear {
            alias = host.alias
            hostname = host.hostname
            user = host.user
            port = String(host.port)
            identityFile = host.identityFile
            enableCompression = host.options["Compression"] == "yes"
            enableKeepAlive = host.options["ServerAliveInterval"] != nil
            enableAgentForwarding = host.options["ForwardAgent"] == "yes"
            enableX11Forwarding = host.options["ForwardX11"] == "yes"
        }
    }
    
    private var header: some View {
        HStack {
            Text(isNewHost ? "添加主机" : "编辑主机")
                .font(.title2)
            Spacer()
        }
        .padding()
    }
    
    private func browseKeyFile() {
        let panel = NSOpenPanel()
        panel.title = "选择SSH密钥文件"
        panel.allowedContentTypes = [.data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            identityFile = panel.url?.path ?? ""
        }
    }
    
    private func saveHost() {
        host.alias = alias
        host.hostname = hostname
        host.user = user
        host.port = Int(port) ?? 22
        host.identityFile = identityFile
        
        if enableCompression {
            host.options["Compression"] = "yes"
        } else {
            host.options.removeValue(forKey: "Compression")
        }
        
        if enableKeepAlive {
            host.options["ServerAliveInterval"] = "60"
            host.options["ServerAliveCountMax"] = "3"
        } else {
            host.options.removeValue(forKey: "ServerAliveInterval")
            host.options.removeValue(forKey: "ServerAliveCountMax")
        }
        
        if enableAgentForwarding {
            host.options["ForwardAgent"] = "yes"
        } else {
            host.options.removeValue(forKey: "ForwardAgent")
        }
        
        if enableX11Forwarding {
            host.options["ForwardX11"] = "yes"
        } else {
            host.options.removeValue(forKey: "ForwardX11")
        }
        
        configManager.saveConfig()
    }
}
