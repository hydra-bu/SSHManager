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

    // 从文件导入配置
    func importFrom(path: String, strategy: ImportStrategy = .skipDuplicates) -> ImportResult {
        let importedHosts = SSHConfigParser.load(from: path)

        var added = 0
        var skipped = 0
        var updated = 0

        for imported in importedHosts {
            if let existingIndex = hosts.firstIndex(where: { $0.alias == imported.alias }) {
                switch strategy {
                case .skipDuplicates:
                    skipped += 1
                case .overwriteDuplicates:
                    imported.groupId = hosts[existingIndex].groupId
                    imported.isFavorite = hosts[existingIndex].isFavorite
                    hosts[existingIndex] = imported
                    updated += 1
                case .renameDuplicates:
                    imported.alias = "\(imported.alias)_imported"
                    hosts.append(imported)
                    added += 1
                }
            } else {
                hosts.append(imported)
                added += 1
            }
        }

        saveConfig()

        return ImportResult(
            total: importedHosts.count,
            added: added,
            skipped: skipped,
            updated: updated
        )
    }

    // 从系统默认路径导入
    func importFromDefaultLocation() -> ImportResult? {
        let defaultPath = "~/.ssh/config"
        let expanded = (defaultPath as NSString).expandingTildeInPath

        guard FileManager.default.fileExists(atPath: expanded) else {
            return nil
        }

        return importFrom(path: expanded)
    }
}

enum ImportStrategy {
    case skipDuplicates
    case overwriteDuplicates
    case renameDuplicates
}

struct ImportResult {
    let total: Int
    let added: Int
    let skipped: Int
    let updated: Int

    var description: String {
        var parts: [String] = []
        if added > 0 { parts.append("新增 \(added) 个") }
        if updated > 0 { parts.append("更新 \(updated) 个") }
        if skipped > 0 { parts.append("跳过 \(skipped) 个重复") }
        return parts.isEmpty ? "无变更" : parts.joined(separator: "，")
    }
}

// 扩展String以支持波浪号路径展开
extension String {
    var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }
}