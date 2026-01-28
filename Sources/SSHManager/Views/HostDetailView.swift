import SwiftUI

struct HostDetailView: View {
    let host: SSHHost
    @State private var testResult: ConnectionTestResult?
    @State private var isTesting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 基本信息
                GroupBox(label: Label("基本信息", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 8) {
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("在终端中执行的命令：")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal) {
                            Text(generateTerminalCommand())
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(4)
                                .textSelection(.enabled)
                        }
                    }
                }

                // 测试连接
                GroupBox(label: Label("连接测试", systemImage: "link")) {
                    HStack {
                        Button(action: testConnection) {
                            HStack {
                                if isTesting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text(isTesting ? "测试中..." : "测试连接")
                            }
                        }
                        .disabled(isTesting)

                        Spacer()

                        if let result = testResult {
                            switch result {
                            case .success(let latency):
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("在线 (\(String(format: "%.0f", latency * 1000))ms)")
                                        .font(.caption)
                                }
                            case .failure(let error):
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text("离线")
                                        .font(.caption)
                                }
                                .popoverTip(error.localizedDescription, arrowEdge: .top) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
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

    private func testConnection() {
        isTesting = true
        Task {
            let connector = SSHConnector()
            let result = await connector.testConnection(host)

            await MainActor.run {
                testResult = result
                isTesting = false
            }
        }
    }
}

extension View {
    func popoverTip(_ text: String, arrowEdge: Edge = .bottom, @ViewBuilder accessory: () -> some View) -> some View {
        self
            .contextMenu {
                Text(text)
                    .font(.caption)
                    .frame(maxWidth: 300)
            } preview: {
                HStack {
                    accessory()
                    Text(text)
                }
                .padding()
                .frame(width: 300)
            }
    }
}

struct HostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HostDetailView(host: SSHHost(
                alias: "My Server",
                hostname: "192.168.1.100",
                user: "admin",
                port: 22,
                identityFile: "~/.ssh/id_rsa"
            ))
        }
    }
}