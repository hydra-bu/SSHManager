import Foundation

// SSH配置解析器
class SSHConfigParser {
    static func parse(_ content: String) -> [SSHHost] {
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
            }
        }

        // 添加最后一个主机
        if let currentHost = state.currentHost {
            state.hosts.append(currentHost)
        }

        return state.hosts
    }

    static func format(_ hosts: [SSHHost]) -> String {
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
}