import Foundation

// SSH配置管理器
class SSHConfigManager: ObservableObject {
    @Published var hosts: [SSHHost] = []

    private let configPath: String

    init(configPath: String = "~/.ssh/config") {
        self.configPath = configPath.expandingTildeInPath
        loadConfig()
    }

    // 加载SSH配置文件
    func loadConfig() {
        // 检查文件是否存在
        if !FileManager.default.fileExists(atPath: configPath) {
            print("SSH配置文件不存在: \(configPath)，创建空配置")
            self.hosts = []
            return
        }

        do {
            let content = try String(contentsOfFile: configPath, encoding: .utf8)
            self.hosts = parseSSHConfig(content)
            print("成功加载 \(hosts.count) 个SSH主机配置")
        } catch {
            print("加载SSH配置失败: \(error)")
            // 如果配置文件存在但读取失败，创建空的hosts数组
            self.hosts = []
        }
    }

    // 保存SSH配置文件
    func saveConfig() {
        do {
            let content = formatSSHConfig(hosts)
            try content.write(toFile: configPath, atomically: true, encoding: .utf8)
        } catch {
            print("保存SSH配置失败: \(error)")
        }
    }

    // 解析SSH配置内容
    private func parseSSHConfig(_ content: String) -> [SSHHost] {
        let lines = content.components(separatedBy: .newlines)
        var state = ConfigParserState()

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // 跳过注释和空行
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }

            let components = trimmedLine.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            if components.count < 2 { continue }

            let key = String(components[0]).lowercased()
            let value = String(components[1]).trimmingCharacters(in: .whitespaces)

            if key == "host" {
                // 新的Host块开始
                if let currentHost = state.currentHost {
                    state.hosts.append(currentHost)
                }

                state.currentHost = SSHHost(alias: value)
                state.inHostBlock = true
            } else if state.inHostBlock, let currentHost = state.currentHost {
                // 在Host块内，设置主机属性
                var updatedHost = currentHost

                switch key {
                case "hostname":
                    updatedHost.hostname = value
                case "user":
                    updatedHost.user = value
                case "port":
                    updatedHost.port = Int(value) ?? 22
                case "identityfile":
                    updatedHost.identityFile = value
                default:
                    // 其他选项保存到options字典
                    updatedHost.options[key] = value
                }

                state.currentHost = updatedHost
            } else if !state.inHostBlock {
                // 全局选项（不在Host块内）可以在这里处理
            }
        }

        // 添加最后一个主机
        if let currentHost = state.currentHost {
            state.hosts.append(currentHost)
        }

        return state.hosts
    }

    // 格式化SSH配置内容
    private func formatSSHConfig(_ hosts: [SSHHost]) -> String {
        var content = ""

        for host in hosts {
            content += "Host \(host.alias)\n"
            content += "  HostName \(host.hostname)\n"

            if !host.user.isEmpty {
                content += "  User \(host.user)\n"
            }

            if host.port != 22 {
                content += "  Port \(host.port)\n"
            }

            if !host.identityFile.isEmpty {
                content += "  IdentityFile \(host.identityFile)\n"
            }

            // 写入其他选项
            for (key, value) in host.options.sorted(by: { $0.key < $1.key }) {
                content += "  \(key.capitalized) \(value)\n"
            }

            content += "\n"
        }

        return content
    }

    // 添加主机
    func addHost(_ host: SSHHost) {
        hosts.append(host)
        saveConfig()
    }

    // 更新主机
    func updateHost(_ host: SSHHost) {
        if let index = hosts.firstIndex(where: { $0.id == host.id }) {
            hosts[index] = host
            saveConfig()
        }
    }

    // 删除主机
    func removeHost(_ host: SSHHost) {
        hosts.removeAll { $0.id == host.id }
        saveConfig()
    }
}

// 扩展String以支持波浪号路径展开
extension String {
    var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }
}