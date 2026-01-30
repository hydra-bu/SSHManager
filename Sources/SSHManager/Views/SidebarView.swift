import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var showingAddHost = false
    @State private var showingGroupManager = false
    
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
                .foregroundColor(.secondary)
            TextField("搜索主机...", text: $configManager.searchText)
                .textFieldStyle(.plain)
            if !configManager.searchText.isEmpty {
                Button(action: { configManager.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
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
                GroupSection(group: group)
            }
            
            let ungrouped = configManager.hosts(forGroup: nil)
            if !ungrouped.isEmpty {
                ungroupedSection(hosts: ungrouped)
            }
        }
        .listStyle(.sidebar)
    }
    
    private var favoritesSection: some View {
        Section("常用") {
            ForEach(configManager.favoriteHosts) { host in
                HostRow(host: host)
                    .tag(host.id)
            }
        }
    }
    
    private func ungroupedSection(hosts: [SSHHost]) -> some View {
        Section("未分组") {
            ForEach(hosts) { host in
                HostRow(host: host)
                    .tag(host.id)
            }
        }
    }
    
    private var toolbar: some View {
        HStack {
            Button(action: { showingAddHost = true }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            
            Spacer()
            
            Button(action: { showingGroupManager = true }) {
                Image(systemName: "folder.badge.plus")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct GroupSection: View {
    let group: HostGroup
    @EnvironmentObject var configManager: SSHConfigManager
    
    var body: some View {
        Section {
            ForEach(configManager.hosts(forGroup: group.id)) { host in
                HostRow(host: host)
                    .tag(host.id)
            }
        } header: {
            GroupHeader(group: group)
        }
    }
}

struct GroupHeader: View {
    @ObservedObject var group: HostGroup
    
    var body: some View {
        HStack {
            Image(systemName: group.isExpanded ? "folder.fill" : "folder")
                .foregroundColor(group.swiftUIColor)
            Text(group.name)
                .font(.headline)
            Spacer()
            Text("\(groupHostCount)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                group.isExpanded.toggle()
            }
        }
    }
    
    private var groupHostCount: Int {
        return 0 // Will be calculated from configManager
    }
}

struct HostRow: View {
    @ObservedObject var host: SSHHost
    
    var body: some View {
        HStack {
            Image(systemName: hostIcon)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(host.alias.isEmpty ? "未命名" : host.alias)
                    .font(.headline)
                Text(host.getUserAtHost())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if host.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .contextMenu {
            HostContextMenu(host: host)
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
    let host: SSHHost
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
                    host.groupId = group.id
                    configManager.saveConfig()
                }
            }
            Button("移除分组") {
                host.groupId = nil
                configManager.saveConfig()
            }
        }
        Divider()
        Button("编辑") {
            // Will trigger edit sheet
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
