import Foundation

enum JumpHostType: String, Codable, CaseIterable {
    case reference = "reference"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .reference: return "引用已有主机"
        case .manual: return "手动配置"
        }
    }
}

struct JumpHost: Identifiable, Codable, Equatable {
    let id: UUID
    var type: JumpHostType
    var referencedHostId: UUID?
    var alias: String
    var hostname: String
    var user: String
    var port: Int
    var identityFile: String
    
    init(
        id: UUID = UUID(),
        type: JumpHostType = .reference,
        referencedHostId: UUID? = nil,
        alias: String = "",
        hostname: String = "",
        user: String = "",
        port: Int = 22,
        identityFile: String = ""
    ) {
        self.id = id
        self.type = type
        self.referencedHostId = referencedHostId
        self.alias = alias
        self.hostname = hostname
        self.user = user
        self.port = port
        self.identityFile = identityFile
    }
    
    func toProxyJumpString(configManager: SSHConfigManager? = nil) -> String {
        switch type {
        case .reference:
            if let hostId = referencedHostId,
               let host = configManager?.hosts.first(where: { $0.id == hostId }) {
                return host.alias
            }
            return alias
            
        case .manual:
            var components: [String] = []
            if !user.isEmpty {
                components.append(user)
                components.append("@")
            }
            components.append(hostname)
            if port != 22 {
                components.append(":")
                components.append(String(port))
            }
            return components.joined()
        }
    }
    
    func toConfigString(configManager: SSHConfigManager? = nil) -> String {
        if type == .reference, let hostId = referencedHostId,
           let host = configManager?.hosts.first(where: { $0.id == hostId }) {
            return "ProxyJump \(host.alias)"
        }
        return "ProxyJump \(toProxyJumpString(configManager: configManager))"
    }
    
    var displayName: String {
        switch type {
        case .reference:
            return alias
        case .manual:
            var name = alias
            if name.isEmpty {
                if !user.isEmpty && !hostname.isEmpty {
                    name = "\(user)@\(hostname)"
                } else if !hostname.isEmpty {
                    name = hostname
                } else {
                    name = "未命名跳板"
                }
            }
            return name
        }
    }
    
    var isValid: Bool {
        switch type {
        case .reference:
            return referencedHostId != nil || !alias.isEmpty
        case .manual:
            return !hostname.isEmpty
        }
    }
    
    static func == (lhs: JumpHost, rhs: JumpHost) -> Bool {
        lhs.id == rhs.id
    }
}

extension JumpHost {
    static func parse(from configValue: String, configManager: SSHConfigManager? = nil) -> [JumpHost] {
        let jumpStrings = configValue.split(separator: ",")
        var jumpHosts: [JumpHost] = []
        
        for jumpStr in jumpStrings {
            let trimmed = jumpStr.trimmingCharacters(in: .whitespaces)
            
            if let existingHost = configManager?.hosts.first(where: { $0.alias == trimmed }) {
                jumpHosts.append(JumpHost(
                    type: .reference,
                    referencedHostId: existingHost.id,
                    alias: existingHost.alias
                ))
            } else {
                var user: String = ""
                var host: String = trimmed
                var port: Int = 22
                
                if trimmed.contains("@") {
                    let parts = trimmed.split(separator: "@", maxSplits: 1)
                    if parts.count == 2 {
                        user = String(parts[0])
                        host = String(parts[1])
                    }
                }
                
                if host.contains(":") {
                    let parts = host.split(separator: ":", maxSplits: 1)
                    if parts.count == 2, let p = Int(parts[1]) {
                        host = String(parts[0])
                        port = p
                    }
                }
                
                jumpHosts.append(JumpHost(
                    type: .manual,
                    alias: trimmed,
                    hostname: host,
                    user: user,
                    port: port
                ))
            }
        }
        
        return jumpHosts
    }
}
