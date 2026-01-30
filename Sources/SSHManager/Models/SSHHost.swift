import Foundation

// 连接测试结果
enum ConnectionTestResult: Equatable {
    case success(latency: Double)
    case failure(SSHConnectionError)
    
    static func == (lhs: ConnectionTestResult, rhs: ConnectionTestResult) -> Bool {
        switch (lhs, rhs) {
        case (.success(let l1), .success(let l2)): return l1 == l2
        case (.failure(let e1), .failure(let e2)): return e1.localizedDescription == e2.localizedDescription
        default: return false
        }
    }
}

// SSH连接错误类型
enum SSHConnectionError: Error, LocalizedError {
    case permissionDenied
    case connectionTimeout
    case unknownHost
    case keyFileNotFound(String)
    case keyFileWrongPermissions(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "服务器拒绝了你的连接，请检查密钥配置"
        case .connectionTimeout:
            return "连接超时，请检查主机地址和网络连接"
        case .unknownHost:
            return "无法解析主机地址"
        case .keyFileNotFound(let path):
            return "密钥文件不存在：\(path)"
        case .keyFileWrongPermissions(let path):
            return "密钥文件权限错误：\(path) (建议权限为600)"
        case .unknown(let message):
            return "连接失败：\(message)"
        }
    }
}

// SSH主机配置模型
class SSHHost: ObservableObject, Identifiable, Codable {
    private(set) var id: UUID
    @Published var alias: String
    @Published var hostname: String
    @Published var user: String
    @Published var port: Int
    @Published var identityFile: String
    @Published var options: [String: String]
    @Published var groupId: UUID?
    @Published var tags: [String]
    @Published var portForwards: [PortForward]
    @Published var jumpHosts: [JumpHost]
    @Published var isFavorite: Bool
    
    @Published var isTesting: Bool = false
    @Published var lastTestResult: ConnectionTestResult? = nil

    init(
        id: UUID = UUID(),
        alias: String = "",
        hostname: String = "",
        user: String = "",
        port: Int = 22,
        identityFile: String = "",
        options: [String: String] = [:],
        groupId: UUID? = nil,
        tags: [String] = [],
        portForwards: [PortForward] = [],
        jumpHosts: [JumpHost] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.alias = alias
        self.hostname = hostname
        self.user = user
        self.port = port
        self.identityFile = identityFile
        self.options = options
        self.groupId = groupId
        self.tags = tags
        self.portForwards = portForwards
        self.jumpHosts = jumpHosts
        self.isFavorite = isFavorite
    }
    
    // MARK: - Codable Conformance
    enum CodingKeys: String, CodingKey {
        case id, alias, hostname, user, port, identityFile, options
        case groupId, tags, portForwards, jumpHosts, isFavorite
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
        self.groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.portForwards = try container.decode([PortForward].self, forKey: .portForwards)
        self.jumpHosts = try container.decode([JumpHost].self, forKey: .jumpHosts)
        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
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
        try container.encodeIfPresent(groupId, forKey: .groupId)
        try container.encode(tags, forKey: .tags)
        try container.encode(portForwards, forKey: .portForwards)
        try container.encode(jumpHosts, forKey: .jumpHosts)
        try container.encode(isFavorite, forKey: .isFavorite)
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
