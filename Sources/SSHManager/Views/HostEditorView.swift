import SwiftUI

struct HostEditorView: View {
    @ObservedObject var host: SSHHost
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var mode: HostEditorMode = .simple
    
    @State private var enableCompression = false
    @State private var enableKeepAlive = false
    @State private var enableAgentForwarding = false
    @State private var enableX11Forwarding = false
    
    enum HostEditorMode {
        case simple, advanced
    }
    
    init(host: SSHHost) {
        self.host = host
        _enableCompression = State(initialValue: host.options["Compression"] == "yes")
        _enableKeepAlive = State(initialValue: host.options["ServerAliveInterval"] != nil)
        _enableAgentForwarding = State(initialValue: host.options["ForwardAgent"] == "yes")
        _enableX11Forwarding = State(initialValue: host.options["ForwardX11"] == "yes")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("模式", selection: $mode) {
                    Text("简单").tag(HostEditorMode.simple)
                    Text("高级").tag(HostEditorMode.advanced)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if mode == .simple {
                    simpleSection
                } else {
                    advancedSection
                }
            }
            .padding()
        }
        .onChange(of: enableCompression) { _ in syncOptions() }
        .onChange(of: enableKeepAlive) { _ in syncOptions() }
        .onChange(of: enableAgentForwarding) { _ in syncOptions() }
        .onChange(of: enableX11Forwarding) { _ in syncOptions() }
    }
    
    private var simpleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("基本信息") {
                VStack(spacing: 12) {
                    HStack {
                        Text("别名")
                            .frame(width: 60, alignment: .trailing)
                            .foregroundColor(.secondary)
                        TextField("例如：生产服务器", text: $host.alias)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("地址")
                            .frame(width: 60, alignment: .trailing)
                            .foregroundColor(.secondary)
                        TextField("主机名或IP地址", text: $host.hostname)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("用户")
                            .frame(width: 60, alignment: .trailing)
                            .foregroundColor(.secondary)
                        TextField("登录用户名", text: $host.user)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("端口")
                            .frame(width: 60, alignment: .trailing)
                            .foregroundColor(.secondary)
                        TextField("22", value: $host.port, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("默认: 22")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("私钥")
                            .frame(width: 60, alignment: .trailing)
                            .foregroundColor(.secondary)
                        TextField("~/.ssh/id_rsa", text: $host.identityFile)
                            .textFieldStyle(.roundedBorder)
                        Button("浏览") {
                            browseKeyFile()
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 8)
            }
            
            GroupBox("常用选项") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("启用压缩 (Compression)", isOn: $enableCompression)
                    Toggle("保持连接 (KeepAlive)", isOn: $enableKeepAlive)
                    Toggle("代理转发 (AgentForwarding)", isOn: $enableAgentForwarding)
                    Toggle("X11 转发", isOn: $enableX11Forwarding)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("连接信息") {
                VStack(spacing: 12) {
                    HStack {
                        Text("别名")
                            .frame(width: 80, alignment: .trailing)
                        TextField("必填", text: $host.alias)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("主机地址")
                            .frame(width: 80, alignment: .trailing)
                        TextField("主机名或IP", text: $host.hostname)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("用户名")
                            .frame(width: 80, alignment: .trailing)
                        TextField("可选", text: $host.user)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("端口")
                            .frame(width: 80, alignment: .trailing)
                        TextField("22", value: $host.port, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
                .padding(.vertical, 8)
            }
            
            GroupBox("认证") {
                VStack(spacing: 12) {
                    HStack {
                        Text("私钥路径")
                            .frame(width: 80, alignment: .trailing)
                        TextField("~/.ssh/id_rsa", text: $host.identityFile)
                            .textFieldStyle(.roundedBorder)
                        Button("浏览") {
                            browseKeyFile()
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 8)
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
    
    private func syncOptions() {
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
    }
}

struct HostEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let host = SSHHost(alias: "test", hostname: "192.168.1.100", user: "admin")
        return HostEditorView(host: host)
            .environmentObject(SSHConfigManager())
    }
}
