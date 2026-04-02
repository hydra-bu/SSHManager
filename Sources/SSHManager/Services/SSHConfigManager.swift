import Foundation

// SSH配置管理器
class SSHConfigManager: ObservableObject {
    @Published var hosts: [SSHHost] = []
    @Published var groups: [HostGroup] = []
    @Published var selectedHostId: UUID?
    @Published var selectedGroupId: UUID?
    @Published var searchText: String = ""
    
    private let groupsFileName = "groups.json"

    private let configPath: String

    init(configPath: String = "~/.ssh/config") {
        self.configPath = configPath.expandingTildeInPath
        loadConfig()
        loadGroups()
        ensureDefaultGroups()
    }
    
    var filteredHosts: [SSHHost] {
        if searchText.isEmpty { return hosts }
        return hosts.filter { host in
            host.alias.localizedCaseInsensitiveContains(searchText) ||
            host.hostname.localizedCaseInsensitiveContains(searchText) ||
            host.user.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var favoriteHosts: [SSHHost] {
        hosts.filter { $0.isFavorite }
    }
    
    func hosts(forGroup groupId: UUID?) -> [SSHHost] {
        if let id = groupId {
            return filteredHosts.filter { $0.groupId == id }
        } else {
            return filteredHosts.filter { $0.groupId == nil }
        }
    }
    
    func loadGroups() {
        let configDir = (configPath as NSString).deletingLastPathComponent
        let groupsPath = (configDir as NSString).appendingPathComponent(groupsFileName)
        guard FileManager.default.fileExists(atPath: groupsPath) else {
            ensureDefaultGroups()
            return
        }
        do {
            let url = URL(fileURLWithPath: groupsPath)
            let data = try Data(contentsOf: url)
            self.groups = try JSONDecoder().decode([HostGroup].self, from: data)
        } catch {
            ensureDefaultGroups()
        }
    }
    
    func saveGroups() {
        let configDir = (configPath as NSString).deletingLastPathComponent
        let groupsPath = (configDir as NSString).appendingPathComponent(groupsFileName)
        do {
            let data = try JSONEncoder().encode(groups)
            let url = URL(fileURLWithPath: groupsPath)
            try data.write(to: url)
        } catch {
            print("Failed to save groups: \(error)")
        }
    }
    
    private func ensureDefaultGroups() {
        if groups.isEmpty {
            groups = HostGroup.defaultGroups
            saveGroups()
        }
    }

    // 加载SSH配置文件
    func loadConfig() {
        self.hosts = SSHConfigParser.load(from: configPath)
        print("成功加载 \(hosts.count) 个SSH主机配置")
    }

    // 保存SSH配置文件 (异步)
    func saveConfig() {
        let currentHosts = self.hosts
        let path = self.configPath
        
        Task.detached(priority: .utility) {
            do {
                try SSHConfigParser.save(currentHosts, to: path)
                print("✅ 配置已保存到: \(path)")
            } catch {
                print("❌ 保存SSH配置失败: \(error)")
            }
        }
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