import Foundation

// 端口转发类型
enum PortForwardType: String, Codable, CaseIterable {
    case local = "local"      // -L 本地转发
    case remote = "remote"    // -R 远程转发
    case dynamic = "dynamic"  // -D 动态转发(SOCKS)
    
    var displayName: String {
        switch self {
        case .local: return "本地转发"
        case .remote: return "远程转发"
        case .dynamic: return "动态转发(SOCKS)"
        }
    }
    
    var sshFlag: String {
        switch self {
        case .local: return "-L"
        case .remote: return "-R"
        case .dynamic: return "-D"
        }
    }
    
    var iconName: String {
        switch self {
        case .local: return "arrow.forward.circle"
        case .remote: return "arrow.backward.circle"
        case .dynamic: return "network.badge.shield.half.filled"
        }
    }
    
    var colorName: String {
        switch self {
        case .local: return "green"
        case .remote: return "blue"
        case .dynamic: return "purple"
        }
    }
}

// 端口转发配置
struct PortForward: Identifiable, Codable, Equatable {
    let id: UUID
    var type: PortForwardType
    var localPort: Int
    var remoteHost: String
    var remotePort: Int
    var description: String?
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        type: PortForwardType = .local,
        localPort: Int = 8080,
        remoteHost: String = "localhost",
        remotePort: Int = 80,
        description: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.localPort = localPort
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.description = description
        self.isActive = isActive
    }
    
    // 生成SSH命令参数
    func toSSHArgument() -> String {
        switch type {
        case .local:
            return "-L \(localPort):\(remoteHost):\(remotePort)"
        case .remote:
            return "-R \(localPort):\(remoteHost):\(remotePort)"
        case .dynamic:
            return "-D \(localPort)"
        }
    }
    
    // 生成配置字符串
    func toConfigString() -> String {
        switch type {
        case .local:
            return "LocalForward \(localPort) \(remoteHost):\(remotePort)"
        case .remote:
            return "RemoteForward \(localPort) \(remoteHost):\(remotePort)"
        case .dynamic:
            return "DynamicForward \(localPort)"
        }
    }
    
    // 验证配置是否有效
    var isValid: Bool {
        localPort > 0 && localPort <= 65535 &&
        (type == .dynamic || (remotePort > 0 && remotePort <= 65535))
    }
    
    // 显示用的描述
    var displayDescription: String {
        if let desc = description, !desc.isEmpty {
            return desc
        }
        
        switch type {
        case .local:
            return "本地:\(localPort) → \(remoteHost):\(remotePort)"
        case .remote:
            return "远程:\(localPort) ← \(remoteHost):\(remotePort)"
        case .dynamic:
            return "SOCKS代理 localhost:\(localPort)"
        }
    }
    
    static func == (lhs: PortForward, rhs: PortForward) -> Bool {
        lhs.id == rhs.id
    }
}

// 从SSH配置字符串解析端口转发
extension PortForward {
    static func parse(from configString: String) -> PortForward? {
        let components = configString.split(separator: " ", omittingEmptySubsequences: true)
        guard components.count >= 2 else { return nil }
        
        let key = String(components[0]).lowercased()
        
        if key == "localforward" || key == "lf" {
            // LocalForward localPort remoteHost:remotePort
            guard components.count >= 3 else { return nil }
            guard let localPort = Int(components[1]) else { return nil }
            
            let remoteParts = String(components[2]).split(separator: ":")
            guard remoteParts.count == 2,
                  let remotePort = Int(remoteParts[1]) else { return nil }
            
            return PortForward(
                type: .local,
                localPort: localPort,
                remoteHost: String(remoteParts[0]),
                remotePort: remotePort
            )
        } else if key == "remoteforward" || key == "rf" {
            // RemoteForward remotePort localHost:localPort
            guard components.count >= 3 else { return nil }
            guard let remotePort = Int(components[1]) else { return nil }
            
            let localParts = String(components[2]).split(separator: ":")
            guard localParts.count == 2,
                  let localPort = Int(localParts[1]) else { return nil }
            
            return PortForward(
                type: .remote,
                localPort: localPort,
                remoteHost: String(localParts[0]),
                remotePort: remotePort
            )
        } else if key == "dynamicforward" || key == "df" {
            // DynamicForward port
            guard components.count >= 2,
                  let port = Int(components[1]) else { return nil }
            
            return PortForward(
                type: .dynamic,
                localPort: port,
                remoteHost: "",
                remotePort: 0
            )
        }
        
        return nil
    }
}
