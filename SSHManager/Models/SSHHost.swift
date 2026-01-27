import Foundation

// SSH主机配置模型
struct SSHHost: Identifiable, Codable {
    let id = UUID()
    var alias: String
    var hostname: String
    var user: String
    var port: Int
    var identityFile: String
    var options: [String: String] // 其他SSH选项

    init(
        alias: String = "",
        hostname: String = "",
        user: String = "",
        port: Int = 22,
        identityFile: String = "",
        options: [String: String] = [:]
    ) {
        self.alias = alias
        self.hostname = hostname
        self.user = user
        self.port = port
        self.identityFile = identityFile
        self.options = options
    }

    // 获取 user@host 格式的字符串
    func getUserAtHost() -> String {
        if user.isEmpty {
            return hostname
        }
        return "\(user)@\(hostname)"
    }
}

// SSH配置解析状态
class ConfigParserState {
    var hosts: [SSHHost] = []
    var currentHost: SSHHost?
    var inHostBlock = false

    init() {}
}