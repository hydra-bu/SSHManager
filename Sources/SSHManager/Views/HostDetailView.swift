import SwiftUI

struct HostDetailView: View {
    @ObservedObject var host: SSHHost
    var onEditHost: () -> Void
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var showCopyToast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Button(action: onEditHost) {
                        Label("编辑", systemImage: "pencil")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: testConnection) {
                        if host.isTesting {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                            Text("测试中...")
                        } else {
                            Label("测试连接", systemImage: "bolt.horizontal")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(host.isTesting)
                    
                    Spacer()
                }
                
                // 状态指示器
                if host.isTesting || host.lastTestResult != nil {
                    GroupBox(label: Label("连接状态", systemImage: "bolt.horizontal")) {
                        HStack {
                            if host.isTesting {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("正在测试连接...")
                                    .font(.subheadline)
                            } else if let result = host.lastTestResult {
                                switch result {
                                case .success(let latency):
                                    Label("在线 (\(String(format: "%.0f", latency * 1000))ms)", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                case .failure(let error):
                                    Label("离线: \(error.localizedDescription)", systemImage: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 基本信息
                GroupBox(label: Label("基本信息", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("别名:")
                                .font(.headline)
                            Spacer()
                            Text(host.alias)
                        }
                        HStack {
                            Text("主机:")
                                .font(.headline)
                            Spacer()
                            Text(host.hostname)
                        }
                        HStack {
                            Text("用户:")
                                .font(.headline)
                            Spacer()
                            Text(host.user.isEmpty ? "默认" : host.user)
                        }
                        HStack {
                            Text("端口:")
                                .font(.headline)
                            Spacer()
                            Text("\(host.port)")
                        }
                        if !host.identityFile.isEmpty {
                            HStack {
                                Text("密钥文件:")
                                    .font(.headline)
                                Spacer()
                                Text(host.identityFile)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }

                // 配置预览
                GroupBox(label: Label("SSH配置预览", systemImage: "doc.plaintext")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("~/.ssh/config 中的内容：")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal) {
                            Text(generateSSHConfig())
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(4)
                                .textSelection(.enabled)
                        }
                    }
                }

                // 终端命令预览
                GroupBox(label: Label("终端命令", systemImage: "terminal")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("在终端中执行的命令：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            if showCopyToast {
                                Text("已复制到剪贴板")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .transition(.opacity)
                            }
                            
                            Button(action: copyCommandToClipboard) {
                                Label("复制命令", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                        }

                        ScrollView(.horizontal) {
                            Text(generateTerminalCommand())
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(4)
                                .textSelection(.enabled)
                        }
                        
                        Text("复制命令后粘贴到终端即可连接")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .animation(.default, value: host.isTesting)
            .animation(.default, value: host.lastTestResult)
        }
        .navigationTitle(host.alias)
    }

    private func generateSSHConfig() -> String {
        var config = "Host \(host.alias)\n"
        config += "  HostName \(host.hostname)\n"

        if !host.user.isEmpty {
            config += "  User \(host.user)\n"
        }

        if host.port != 22 {
            config += "  Port \(host.port)\n"
        }

        if !host.identityFile.isEmpty {
            config += "  IdentityFile \(host.identityFile)\n"
        }

        for (key, value) in host.options.sorted(by: { $0.key < $1.key }) {
            config += "  \(key.capitalized) \(value)\n"
        }

        return config
    }

    private func generateTerminalCommand() -> String {
        var cmd = "ssh \(host.alias)"
        if host.port != 22 {
            cmd += " -p \(host.port)"
        }
        return cmd
    }
    
    private func copyCommandToClipboard() {
        let command = generateTerminalCommand()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(command, forType: .string)
        
        withAnimation {
            showCopyToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopyToast = false
            }
        }
    }
    
    private func testConnection() {
        host.isTesting = true
        host.lastTestResult = nil
        
        Task {
            let connector = SSHConnector()
            let result = await connector.testConnection(host)
            
            await MainActor.run {
                host.lastTestResult = result
                host.isTesting = false
            }
        }
    }
}

struct HostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HostDetailView(
                host: SSHHost(
                    alias: "My Server",
                    hostname: "192.168.1.100",
                    user: "admin",
                    port: 22,
                    identityFile: "~/.ssh/id_rsa"
                ),
                onEditHost: {}
            )
        }
    }
}
