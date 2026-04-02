import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    var onEditHost: (SSHHost) -> Void
    var onAddHost: () -> Void
    @State private var showingGroupManager = false
    @State private var refreshID = UUID()
    @State private var showingImportDialog = false
    @State private var importResult: ImportResult?
    @State private var showingImportResult = false
    @State private var isSelectionMode = false
    @State private var selectedHostIds = Set<UUID>()
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            hostList
            toolbar
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textSecondary)
            TextField("搜索主机...", text: $configManager.searchText)
                .textFieldStyle(.plain)
            if !configManager.searchText.isEmpty {
                Button(action: { configManager.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var hostList: some View {
        List(selection: $configManager.selectedHostId) {
            if !configManager.favoriteHosts.isEmpty {
                favoritesSection
            }
            
            ForEach(configManager.groups.sorted(by: { $0.sortOrder < $1.sortOrder })) { group in
                GroupSection(
                    group: group,
                    onEditHost: onEditHost,
                    refreshID: refreshID,
                    onGroupChanged: {
                        refreshID = UUID()
                    }
                )
            }
            
            let ungrouped = configManager.hosts(forGroup: nil)
            if !ungrouped.isEmpty {
                ungroupedSection(hosts: ungrouped)
            }
        }
        .listStyle(.sidebar)
        .id(refreshID)
    }
    
    private var favoritesSection: some View {
        Section("常用") {
            ForEach(configManager.favoriteHosts) { host in
                HostRow(host: host, onEditHost: onEditHost)
                    .tag(host.id)
            }
        }
    }
    
    private func ungroupedSection(hosts: [SSHHost]) -> some View {
        Section("未分组") {
            ForEach(hosts) { host in
                HostRow(host: host, onEditHost: onEditHost)
                    .tag(host.id)
            }
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 8) {
            if isSelectionMode {
                batchToolbar
            } else {
                normalToolbar
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .alert("导入完成", isPresented: $showingImportResult) {
            Button("好的", role: .cancel) { }
        } message: {
            Text(importResult?.description ?? "")
        }
        .alert("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteSelected()
            }
        } message: {
            Text("确定要删除选中的 \(selectedHostIds.count) 个主机吗？")
        }
    }

    private var normalToolbar: some View {
        HStack(spacing: 8) {
            Button(action: { importFromDefault() }) {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.borderless)
            .help("从 ~/.ssh/config 导入")

            Button(action: { importFromFile() }) {
                Image(systemName: "doc.badge.plus")
            }
            .buttonStyle(.borderless)
            .help("从文件导入配置")

            Button(action: { toggleSelectionMode() }) {
                Image(systemName: "checklist")
            }
            .buttonStyle(.borderless)
            .help("选择模式")

            Spacer()

            Button(action: { showingGroupManager = true }) {
                Image(systemName: "folder.badge.plus")
            }
            .buttonStyle(.borderless)
            .help("管理分组")
        }
    }

    private var batchToolbar: some View {
        HStack(spacing: 8) {
            Text("\(selectedHostIds.count) 已选")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: { selectAll() }) {
                Image(systemName: "checkmark.rectangle.stack")
            }
            .buttonStyle(.borderless)
            .help("全选")

            Menu {
                Button("收藏选中") { favoriteSelected(true) }
                Button("取消收藏") { favoriteSelected(false) }
                Divider()
                ForEach(configManager.groups) { group in
                    Button(group.name) { moveSelectedToGroup(group.id) }
                }
                Button("移出分组") { moveSelectedToGroup(nil) }
            } label: {
                Image(systemName: "folder.badge.gearshape")
            }
            .menuStyle(.borderlessButton)
            .help("批量操作")

            Button(action: { showingDeleteConfirmation = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .disabled(selectedHostIds.isEmpty)
            .help("删除选中")

            Spacer()

            Button(action: { toggleSelectionMode() }) {
                Text("完成")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedHostIds.removeAll()
        }
    }

    private func selectAll() {
        if selectedHostIds.count == configManager.hosts.count {
            selectedHostIds.removeAll()
        } else {
            selectedHostIds = Set(configManager.hosts.map { $0.id })
        }
    }

    private func deleteSelected() {
        configManager.removeHosts(selectedHostIds)
        selectedHostIds.removeAll()
        refreshID = UUID()
    }

    private func favoriteSelected(_ favorite: Bool) {
        configManager.setFavorite(favorite, for: selectedHostIds)
        refreshID = UUID()
    }

    private func moveSelectedToGroup(_ groupId: UUID?) {
        configManager.moveHostsToGroup(selectedHostIds, groupId: groupId)
        refreshID = UUID()
    }

    private func importFromDefault() {
        if let result = configManager.importFromDefaultLocation() {
            importResult = result
            showingImportResult = true
            refreshID = UUID()
        }
    }

    private func importFromFile() {
        let panel = NSOpenPanel()
        panel.title = "选择SSH配置文件"
        panel.allowedContentTypes = [.data, .text, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            let result = configManager.importFrom(path: url.path)
            importResult = result
            showingImportResult = true
            refreshID = UUID()
        }
    }
}

struct GroupSection: View {
    let group: HostGroup
    @EnvironmentObject var configManager: SSHConfigManager
    var onEditHost: (SSHHost) -> Void
    let refreshID: UUID
    var onGroupChanged: () -> Void
    
    var body: some View {
        Section {
            ForEach(configManager.hosts(forGroup: group.id)) { host in
                HostRow(host: host, onEditHost: onEditHost)
                    .tag(host.id)
            }
        } header: {
            GroupHeader(group: group)
        }
    }
}

struct GroupHeader: View {
    @ObservedObject var group: HostGroup
    @EnvironmentObject var configManager: SSHConfigManager
    
    var body: some View {
        HStack {
            Image(systemName: group.isExpanded ? "folder.fill" : "folder")
                .foregroundColor(group.swiftUIColor)
            Text(group.name)
                .font(.headline)
            Spacer()
            Text("\(hostCount)")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                group.isExpanded.toggle()
            }
        }
    }
    
    private var hostCount: Int {
        configManager.hosts.filter { $0.groupId == group.id }.count
    }
}

struct HostRow: View {
    @ObservedObject var host: SSHHost
    var onEditHost: (SSHHost) -> Void
    @EnvironmentObject var configManager: SSHConfigManager
    
    var body: some View {
        HStack {
            Image(systemName: hostIcon)
                .foregroundColor(Theme.info)
            VStack(alignment: .leading) {
                Text(host.alias.isEmpty ? "未命名" : host.alias)
                    .font(.headline)
                Text(host.getUserAtHost())
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
            if host.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(Theme.warning)
                    .font(.caption)
            }
        }
        .contextMenu {
            HostContextMenu(host: host, onEditHost: onEditHost)
        }
    }
    
    private var hostIcon: String {
        if host.jumpHosts.isEmpty && host.portForwards.isEmpty {
            return "server.rack"
        } else if !host.jumpHosts.isEmpty {
            return "network.badge.shield.half.filled"
        } else {
            return "server.rack.badge.checkmark"
        }
    }
}

struct HostContextMenu: View {
    @ObservedObject var host: SSHHost
    var onEditHost: (SSHHost) -> Void
    @EnvironmentObject var configManager: SSHConfigManager
    
    var body: some View {
        Button("连接") {
            SSHConnector().connect(to: host)
        }
        Button("测试连接") {
            testConnection()
        }
        Divider()
        Button(host.isFavorite ? "取消收藏" : "收藏") {
            host.isFavorite.toggle()
            configManager.saveConfig()
        }
        Menu("移动到分组") {
            ForEach(configManager.groups) { group in
                Button(group.name) {
                    withAnimation {
                        host.groupId = group.id
                        configManager.saveConfig()
                        configManager.objectWillChange.send()
                    }
                }
            }
            Button("移除分组") {
                withAnimation {
                    host.groupId = nil
                    configManager.saveConfig()
                    configManager.objectWillChange.send()
                }
            }
        }
        Divider()
        Button("编辑") {
            onEditHost(host)
        }
        Button("复制SSH命令") {
            copySSHCommand()
        }
        Divider()
        Button("删除", role: .destructive) {
            configManager.removeHost(host)
        }
    }
    
    private func testConnection() {
        host.isTesting = true
        Task {
            let result = await SSHConnector().testConnection(host)
            await MainActor.run {
                host.lastTestResult = result
                host.isTesting = false
            }
        }
    }
    
    private func copySSHCommand() {
        var cmd = "ssh"
        if host.port != 22 {
            cmd += " -p \(host.port)"
        }
        cmd += " \(host.alias)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
    }
}
