import Foundation

// SSH主机配置模型
class SSHHost: ObservableObject, Identifiable, Codable {
    private(set) var id: UUID
    @Published var alias: String
    @Published var hostname: String
    @Published var user: String
    @Published var port: Int
    @Published var identityFile: String
    @Published var options: [String: String] // 其他SSH选项

    init(
        id: UUID = UUID(),
        alias: String = "",
        hostname: String = "",
        user: String = "",
        port: Int = 22,
        identityFile: String = "",
        options: [String: String] = [:]
    ) {
        self.id = id
        self.alias = alias
        self.hostname = hostname
        self.user = user
        self.port = port
        self.identityFile = identityFile
        self.options = options
    }
    
    // MARK: - Codable Conformance
    enum CodingKeys: String, CodingKey {
        case id, alias, hostname, user, port, identityFile, options
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.alias = try container.decode(String.self, forKey: .alias)
        self.hostname = try container.decode(String.self, forKey: .hostname)
        self.user = try container.decode(String.self, forKey: .user)
        self.port = try container.decode(Int.self, forKey: .port)
        self.identityFile = try container.decode(String.self, forKey: .identityFile)
        self.options = try container.decode([String: String].self, forKey: .options)
    }
    

    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(alias, forKey: .alias)
        try container.encode(hostname, forKey: .hostname)
        try container.encode(user, forKey: .user)
        try container.encode(port, forKey: .port)
        try container.encode(identityFile, forKey: .identityFile)
        try container.encode(options, forKey: .options)
    }
    
    // MARK: - Hashable Conformance
    static func == (lhs: SSHHost, rhs: SSHHost) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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