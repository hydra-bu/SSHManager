import Foundation

// SSH配置解析器 - 统一解析和格式化逻辑
class SSHConfigParser {

    // MARK: - Parse

    static func parse(_ content: String) -> [SSHHost] {
        let lines = content.components(separatedBy: .newlines)
        let state = ConfigParserState()

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }

            let components = trimmedLine.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            if components.count < 2 { continue }

            let key = String(components[0]).lowercased()
            let value = String(components[1]).trimmingCharacters(in: .whitespaces)

            if key == "host" {
                if let currentHost = state.currentHost {
                    state.hosts.append(currentHost)
                }
                state.currentHost = SSHHost(alias: value)
                state.inHostBlock = true
            } else if state.inHostBlock, let currentHost = state.currentHost {
                applyOption(key: key, value: value, to: currentHost)
            }
        }

        if let currentHost = state.currentHost {
            state.hosts.append(currentHost)
        }

        return state.hosts
    }

    // MARK: - Format

    static func format(_ hosts: [SSHHost]) -> String {
        var content = ""

        for host in hosts {
            content += formatSingle(host)
        }

        return content
    }

    static func formatSingle(_ host: SSHHost) -> String {
        var content = ""
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

        // 跳板机配置
        if !host.jumpHosts.isEmpty {
            let jumpString = host.jumpHosts.map { $0.toProxyJumpString() }.joined(separator: ",")
            content += "  ProxyJump \(jumpString)\n"
        }

        // 端口转发配置
        for forward in host.portForwards where forward.isActive {
            content += "  \(forward.toConfigString())\n"
        }

        // 其他自定义选项
        for (key, value) in host.options.sorted(by: { $0.key < $1.key }) {
            content += "  \(key.capitalized) \(value)\n"
        }

        content += "\n"
        return content
    }

    // MARK: - Helpers

    private static func applyOption(key: String, value: String, to host: SSHHost) {
        switch key {
        case "hostname":
            host.hostname = value
        case "user":
            host.user = value
        case "port":
            host.port = Int(value) ?? 22
        case "identityfile":
            host.identityFile = value
        case "proxyjump":
            host.jumpHosts = JumpHost.parse(from: value)
        case "localforward", "remoteforward", "dynamicforward":
            if let forward = PortForward.parse(from: "\(key) \(value)") {
                host.portForwards.append(forward)
            }
        default:
            host.options[key] = value
        }
    }

    // 从文件路径加载
    static func load(from path: String) -> [SSHHost] {
        let expandedPath = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return []
        }
        do {
            let content = try String(contentsOfFile: expandedPath, encoding: .utf8)
            return parse(content)
        } catch {
            print("加载SSH配置失败: \(error)")
            return []
        }
    }

    // 保存到文件路径
    static func save(_ hosts: [SSHHost], to path: String) throws {
        let expandedPath = (path as NSString).expandingTildeInPath
        let content = format(hosts)

        // 备份原文件
        let backupPath = expandedPath + ".backup"
        if FileManager.default.fileExists(atPath: expandedPath) {
            try? FileManager.default.removeItem(atPath: backupPath)
            try? FileManager.default.copyItem(atPath: expandedPath, toPath: backupPath)
        }

        // 写入文件
        try content.write(toFile: expandedPath, atomically: true, encoding: .utf8)

        // 设置权限 600
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: expandedPath
        )
    }
}