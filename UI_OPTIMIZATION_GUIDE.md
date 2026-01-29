# SSH Manager UI/UX 优化指南

## 概述

本文档提供了SSH Manager应用的完整UI/UX优化方案，包括视觉设计、交互改进和功能修复。按照优先级分为三个阶段实施。

---

## 当前问题诊断

### 视觉问题
- ❌ 色彩单调，全灰色调缺乏层次感
- ❌ 间距不当，元素过于拥挤
- ❌ 字体层级不明显，视觉权重未区分
- ❌ 图标单一，所有主机使用相同图标
- ❌ 右侧面板设计过于朴素

### 功能问题
- ❌ **严重：无法编辑已有配置**
- ❌ **严重：新增按钮点击无响应**
- ❌ 缺少交互反馈
- ❌ 缺少错误处理

---

## Phase 1: 核心功能修复（最高优先级）

### 1.1 修复编辑功能

**问题：** 选中主机后无法修改配置

**解决方案：**

#### 数据绑定修复

在 `HostEditorView.swift` 中：

```swift
struct HostEditorView: View {
    @ObservedObject var host: SSHHost  // 确保使用 @ObservedObject
    @EnvironmentObject var hostManager: SSHHostManager
    @State private var hasUnsavedChanges = false
    
    var body: some View {
        Form {
            Section("基本信息") {
                // 使用双向绑定
                TextField("主机名称", text: $host.name)
                    .onChange(of: host.name) { _ in 
                        hasUnsavedChanges = true 
                    }
                
                TextField("主机地址", text: $host.hostname)
                    .onChange(of: host.hostname) { _ in 
                        hasUnsavedChanges = true 
                    }
                
                TextField("端口", value: $host.port, format: .number)
                    .onChange(of: host.port) { _ in 
                        hasUnsavedChanges = true 
                    }
                
                TextField("用户名", text: $host.user)
                    .onChange(of: host.user) { _ in 
                        hasUnsavedChanges = true 
                    }
            }
            
            Section("操作") {
                HStack {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(!hasUnsavedChanges)
                    .buttonStyle(.borderedProminent)
                    
                    if hasUnsavedChanges {
                        Text("有未保存的更改")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        do {
            try hostManager.saveConfig()
            hasUnsavedChanges = false
            // 显示成功提示
            showSuccessAlert()
        } catch {
            // 显示错误提示
            showErrorAlert(error)
        }
    }
}
```

#### 确保SSHHost类正确声明

在 `Models/SSHHost.swift` 中：

```swift
class SSHHost: ObservableObject, Identifiable, Codable {
    let id: UUID
    
    // 所有需要编辑的属性都要用 @Published
    @Published var name: String
    @Published var hostname: String
    @Published var port: Int
    @Published var user: String
    @Published var identityFile: String?
    @Published var group: String?
    
    // Codable 支持
    enum CodingKeys: String, CodingKey {
        case id, name, hostname, port, user, identityFile, group
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        hostname = try container.decode(String.self, forKey: .hostname)
        port = try container.decode(Int.self, forKey: .port)
        user = try container.decode(String.self, forKey: .user)
        identityFile = try container.decodeIfPresent(String.self, forKey: .identityFile)
        group = try container.decodeIfPresent(String.self, forKey: .group)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(hostname, forKey: .hostname)
        try container.encode(port, forKey: .port)
        try container.encode(user, forKey: .user)
        try container.encodeIfPresent(identityFile, forKey: .identityFile)
        try container.encodeIfPresent(group, forKey: .group)
    }
}
```

#### 主视图数据流

在 `ContentView.swift` 中：

```swift
struct ContentView: View {
    @StateObject private var hostManager = SSHHostManager()
    @State private var selectedHost: SSHHost?
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            HostListView(
                hosts: hostManager.hosts,
                searchText: $searchText,
                selection: $selectedHost
            )
            .environmentObject(hostManager)
        } detail: {
            if let host = selectedHost {
                // 传递 ObservableObject，确保双向绑定
                HostEditorView(host: host)
                    .environmentObject(hostManager)
                    .id(host.id) // 强制刷新
            } else {
                EmptyStateView()
            }
        }
    }
}
```

---

### 1.2 修复新增按钮

**问题：** 点击添加按钮无响应

**解决方案：**

#### 在工具栏添加新增按钮

在 `ContentView.swift` 中：

```swift
var body: some View {
    NavigationSplitView {
        HostListView(...)
    } detail: {
        ...
    }
    .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: addNewHost) {
                Label("添加主机", systemImage: "plus")
            }
            .help("创建新的SSH连接")
        }
    }
}

private func addNewHost() {
    // 创建新主机
    let newHost = SSHHost(
        name: "新主机 \(hostManager.hosts.count + 1)",
        hostname: "",
        user: NSUserName() // 使用当前用户名作为默认值
    )
    
    // 添加到列表
    hostManager.hosts.append(newHost)
    
    // 自动选中新主机
    selectedHost = newHost
    
    // 可选：显示提示
    print("✅ 已创建新主机: \(newHost.name)")
}
```

#### 或使用菜单按钮（更专业的方案）

```swift
.toolbar {
    ToolbarItemGroup(placement: .primaryAction) {
        Menu {
            Button("空白主机", action: addBlankHost)
            Button("从模板创建...", action: showTemplateSelector)
            Button("粘贴SSH命令", action: showCommandPaster)
            Divider()
            Button("导入配置文件...", action: importConfig)
        } label: {
            Label("添加", systemImage: "plus")
        }
    }
}

private func addBlankHost() {
    let newHost = SSHHost(
        name: "新主机",
        hostname: "",
        user: NSUserName()
    )
    hostManager.hosts.append(newHost)
    selectedHost = newHost
}

private func showTemplateSelector() {
    // 显示模板选择器 Sheet
    showingTemplateSheet = true
}

private func showCommandPaster() {
    // 显示命令粘贴器 Sheet
    showingCommandSheet = true
}

private func importConfig() {
    // 显示文件选择器
    showingFileImporter = true
}
```

---

### 1.3 保存功能增强

**确保保存操作正确写入配置文件**

在 `SSHConfigManager.swift` 中：

```swift
class SSHConfigManager: ObservableObject {
    @Published var hosts: [SSHHost] = []
    private let configPath = NSString("~/.ssh/config").expandingTildeInPath
    
    func saveConfig() throws {
        // 1. 备份原文件
        let backupPath = configPath + ".backup"
        if FileManager.default.fileExists(atPath: configPath) {
            try? FileManager.default.removeItem(atPath: backupPath)
            try? FileManager.default.copyItem(atPath: configPath, toPath: backupPath)
        }
        
        // 2. 生成配置内容
        var configContent = "# SSH Manager - 自动生成的配置\n"
        configContent += "# 最后更新: \(Date())\n\n"
        
        for host in hosts {
            configContent += host.toConfigString()
            configContent += "\n\n"
        }
        
        // 3. 写入文件
        try configContent.write(
            toFile: configPath, 
            atomically: true, 
            encoding: .utf8
        )
        
        // 4. 设置正确的文件权限
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: configPath
        )
        
        print("✅ 配置已保存到: \(configPath)")
    }
    
    func loadConfig() throws {
        guard FileManager.default.fileExists(atPath: configPath) else {
            // 首次使用，创建空配置
            try "".write(toFile: configPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: configPath
            )
            return
        }
        
        let content = try String(contentsOfFile: configPath, encoding: .utf8)
        hosts = parseSSHConfig(content)
        print("✅ 已加载 \(hosts.count) 个主机配置")
    }
}
```

#### 添加自动保存（可选）

```swift
class SSHConfigManager: ObservableObject {
    @Published var hosts: [SSHHost] = [] {
        didSet {
            // 每次修改后自动保存
            autoSave()
        }
    }
    
    private var autoSaveTimer: Timer?
    
    private func autoSave() {
        // 防抖：延迟1秒后保存
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            do {
                try self.saveConfig()
                print("💾 自动保存完成")
            } catch {
                print("❌ 自动保存失败: \(error)")
            }
        }
    }
}
```

---

### 1.4 错误处理

**添加友好的错误提示**

#### 创建错误提示组件

创建文件 `Views/ErrorAlert.swift`：

```swift
import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    
    func body(content: Content) -> some View {
        content
            .alert("操作失败", isPresented: .constant(error != nil)) {
                Button("确定") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(errorMessage(for: error))
                }
            }
    }
    
    private func errorMessage(for error: Error) -> String {
        if let sshError = error as? SSHError {
            switch sshError {
            case .connectionFailed:
                return "无法连接到服务器。请检查IP地址和网络连接。"
            case .authenticationFailed:
                return "认证失败。请检查用户名和密钥。"
            case .keyFileNotFound:
                return "找不到密钥文件。请选择正确的密钥路径。"
            case .permissionDenied:
                return "权限不足。无法写入SSH配置文件。"
            }
        }
        return error.localizedDescription
    }
}

extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

enum SSHError: Error {
    case connectionFailed
    case authenticationFailed
    case keyFileNotFound
    case permissionDenied
}
```

#### 在视图中使用

```swift
struct HostEditorView: View {
    @State private var currentError: Error?
    
    var body: some View {
        Form {
            // ...
        }
        .errorAlert(error: $currentError)
    }
    
    private func saveChanges() {
        do {
            try hostManager.saveConfig()
        } catch {
            currentError = error
        }
    }
}
```

---

## Phase 2: 视觉优化（中优先级）

### 2.1 色彩系统

**创建统一的色彩系统**

创建文件 `Utilities/Theme.swift`：

```swift
import SwiftUI

struct Theme {
    // MARK: - 主色调
    static let primary = Color(hex: "0071E3")      // macOS 蓝
    static let success = Color(hex: "34C759")      // 成功绿
    static let warning = Color(hex: "FF9500")      // 警告橙
    static let danger = Color(hex: "FF3B30")       // 错误红
    
    // MARK: - 背景色（浅色模式）
    static let backgroundPrimary = Color(hex: "F5F5F7")
    static let backgroundSecondary = Color.white
    static let backgroundTertiary = Color(hex: "E5E5E7")
    
    // MARK: - 文字色
    static let textPrimary = Color(hex: "1D1D1F")
    static let textSecondary = Color(hex: "6E6E73")
    static let textTertiary = Color(hex: "86868B")
    
    // MARK: - 状态色
    static let selectedBackground = Color(hex: "E3F2FD")
    static let hoverBackground = Color(hex: "F0F0F2")
    
    // MARK: - 分隔线
    static let divider = Color(hex: "D1D1D6")
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
```

---

### 2.2 左侧列表优化

#### 主机行重设计

修改 `Views/HostListView.swift`：

```swift
struct HostRowView: View {
    @ObservedObject var host: SSHHost
    @State private var isHovered = false
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: hostIcon)
                .font(.system(size: 24))
                .foregroundColor(Theme.primary)
                .frame(width: 32, height: 32)
            
            // 主机信息
            VStack(alignment: .leading, spacing: 4) {
                Text(host.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("\(host.user)@\(host.hostname)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                
                // 标签（如果有）
                if let group = host.group {
                    Text(group)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.backgroundTertiary)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // 状态指示器
            if let status = host.connectionStatus {
                HStack(spacing: 4) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                    
                    if case .online(let latency) = status {
                        Text("\(latency)ms")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
            }
            
            // 悬停时显示的快捷按钮
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: connectAction) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("连接")
                    
                    Button(action: editAction) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("编辑")
                }
                .foregroundColor(Theme.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Theme.primary : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Theme.selectedBackground
        } else if isHovered {
            return Theme.hoverBackground
        } else {
            return Color.clear
        }
    }
    
    private var hostIcon: String {
        // 根据主机类型返回不同图标
        if host.hostname.contains("192.168") || host.hostname.contains("10.") {
            return "network"
        } else if host.hostname.contains("cloud") || host.hostname.contains("aws") {
            return "cloud.fill"
        } else {
            return "server.rack"
        }
    }
    
    private func connectAction() {
        // 连接操作
    }
    
    private func editAction() {
        // 编辑操作
    }
}

// 连接状态枚举
extension SSHHost {
    enum ConnectionStatus {
        case online(latency: Int)
        case offline
        case unknown
        
        var color: Color {
            switch self {
            case .online: return Theme.success
            case .offline: return Theme.textTertiary
            case .unknown: return Color.clear
            }
        }
    }
    
    var connectionStatus: ConnectionStatus? {
        // 这里可以实现真实的状态检测
        // 临时返回示例数据
        return .online(latency: 373)
    }
}
```

#### 添加搜索栏

```swift
struct HostListView: View {
    let hosts: [SSHHost]
    @Binding var searchText: String
    @Binding var selection: SSHHost?
    @State private var showingAddMenu = false
    
    var filteredHosts: [SSHHost] {
        if searchText.isEmpty {
            return hosts
        }
        return hosts.filter { host in
            host.name.localizedCaseInsensitiveContains(searchText) ||
            host.hostname.localizedCaseInsensitiveContains(searchText) ||
            host.user.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏和工具栏
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textTertiary)
                
                TextField("搜索主机...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                    .frame(height: 20)
                
                Menu {
                    Button("空白主机") { }
                    Button("从模板创建") { }
                    Button("粘贴SSH命令") { }
                    Divider()
                    Button("导入配置") { }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.primary)
                }
                .menuStyle(.borderlessButton)
                
                Button(action: { }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Theme.backgroundSecondary)
            
            Divider()
            
            // 主机列表
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredHosts) { host in
                        HostRowView(
                            host: host,
                            isSelected: selection?.id == host.id
                        )
                        .onTapGesture {
                            selection = host
                        }
                        .contextMenu {
                            Button("连接") { }
                            Button("在Finder中打开SFTP") { }
                            Divider()
                            Button("编辑") { }
                            Button("复制SSH命令") { }
                            Button("复制地址") { }
                            Divider()
                            Button("删除", role: .destructive) { }
                        }
                    }
                }
                .padding(8)
            }
            .background(Theme.backgroundPrimary)
        }
    }
}
```

---

### 2.3 右侧编辑区优化

#### 卡片式布局

修改 `Views/HostEditorView.swift`：

```swift
struct HostEditorView: View {
    @ObservedObject var host: SSHHost
    @EnvironmentObject var hostManager: SSHHostManager
    @State private var hasUnsavedChanges = false
    @State private var showAdvancedOptions = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题栏
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(host.name.isEmpty ? "新主机" : host.name)
                            .font(.system(size: 24, weight: .bold))
                        
                        if !host.hostname.isEmpty {
                            Text("\(host.user)@\(host.hostname):\(host.port)")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    if hasUnsavedChanges {
                        Button("保存") {
                            saveChanges()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                
                // 基本信息卡片
                SectionCard(title: "基本信息", icon: "info.circle.fill") {
                    VStack(spacing: 16) {
                        FormField(label: "名称", text: $host.name)
                            .onChange(of: host.name) { _ in hasUnsavedChanges = true }
                        
                        FormField(label: "主机地址", text: $host.hostname, placeholder: "192.168.1.100 或 example.com")
                            .onChange(of: host.hostname) { _ in hasUnsavedChanges = true }
                        
                        HStack(spacing: 12) {
                            FormField(label: "端口", value: $host.port)
                                .frame(width: 100)
                                .onChange(of: host.port) { _ in hasUnsavedChanges = true }
                            
                            FormField(label: "用户名", text: $host.user)
                                .onChange(of: host.user) { _ in hasUnsavedChanges = true }
                        }
                    }
                }
                
                // 认证方式卡片
                SectionCard(title: "认证方式", icon: "key.fill") {
                    VStack(spacing: 16) {
                        // 认证方式选择器
                        Picker("", selection: $host.authMethod) {
                            Text("SSH密钥").tag(AuthMethod.key)
                            Text("密码").tag(AuthMethod.password)
                            Text("交互式").tag(AuthMethod.interactive)
                        }
                        .pickerStyle(.segmented)
                        
                        // 根据选择显示不同的输入
                        switch host.authMethod {
                        case .key:
                            KeyFileSelector(path: $host.identityFile)
                        case .password:
                            SecureField("密码", text: $host.password)
                        case .interactive:
                            Text("连接时会提示输入认证信息")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                
                // 高级选项（可折叠）
                DisclosureGroup(
                    isExpanded: $showAdvancedOptions,
                    content: {
                        AdvancedOptionsCard(host: host)
                            .padding(.top, 8)
                    },
                    label: {
                        Label("高级选项", systemImage: "gearshape.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                )
                .padding()
                .background(Theme.backgroundSecondary)
                .cornerRadius(12)
                
                // 配置预览（Tab切换）
                Picker("", selection: $selectedTab) {
                    Text("配置预览").tag(0)
                    Text("SSH命令").tag(1)
                    Text("连接统计").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                TabView(selection: $selectedTab) {
                    ConfigPreviewView(host: host)
                        .tag(0)
                    
                    SSHCommandView(host: host)
                        .tag(1)
                    
                    StatisticsView(host: host)
                        .tag(2)
                }
                .frame(height: 200)
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button(action: testConnection) {
                        Label("测试连接", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: openInTerminal) {
                        Label("在终端打开", systemImage: "terminal.fill")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("删除主机", role: .destructive) {
                        deleteHost()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .padding()
        }
        .background(Theme.backgroundPrimary)
    }
    
    private func saveChanges() {
        // 保存逻辑
    }
    
    private func testConnection() {
        // 测试连接
    }
    
    private func openInTerminal() {
        // 在终端打开
    }
    
    private func deleteHost() {
        // 删除主机
    }
}

// MARK: - 辅助组件

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            
            content
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// 数字输入版本
extension FormField {
    init(label: String, value: Binding<Int>) {
        self.label = label
        self._text = Binding(
            get: { String(value.wrappedValue) },
            set: { value.wrappedValue = Int($0) ?? 22 }
        )
    }
}

struct KeyFileSelector: View {
    @Binding var path: String?
    @State private var isTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("密钥文件路径", text: Binding(
                    get: { path ?? "" },
                    set: { path = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                
                Button("浏览...") {
                    selectKeyFile()
                }
                .buttonStyle(.bordered)
            }
            
            // 拖拽区域
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Theme.primary : Theme.divider,
                    style: StrokeStyle(lineWidth: 2, dash: [5])
                )
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isTargeted ? Theme.primary.opacity(0.1) : Color.clear)
                )
                .frame(height: 60)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.textTertiary)
                        
                        Text("拖拽密钥文件到这里")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                )
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    handleDrop(providers)
                }
        }
    }
    
    private func selectKeyFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.data]
        panel.directoryURL = URL(fileURLWithPath: NSString("~/.ssh").expandingTildeInPath)
        
        if panel.runModal() == .OK {
            path = panel.url?.path
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, error in
            if let data = data as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    path = url.path
                }
            }
        }
        return true
    }
}
```

---

### 2.4 配置预览组件

创建 `Views/ConfigPreviewView.swift`：

```swift
import SwiftUI

struct ConfigPreviewView: View {
    @ObservedObject var host: SSHHost
    @State private var validationResults: [ValidationResult] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("配置文件预览")
                .font(.system(size: 14, weight: .semibold))
            
            ScrollView {
                Text(host.toConfigString())
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
            }
            
            // 验证结果
            if !validationResults.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(validationResults) { result in
                        HStack(spacing: 8) {
                            Image(systemName: result.icon)
                                .foregroundColor(result.color)
                            
                            Text(result.message)
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .cornerRadius(8)
        .onAppear {
            validateConfiguration()
        }
        .onChange(of: host.hostname) { _ in
            validateConfiguration()
        }
    }
    
    private func validateConfiguration() {
        validationResults = []
        
        // 检查主机名
        if !host.hostname.isEmpty {
            if isValidHostname(host.hostname) {
                validationResults.append(ValidationResult(
                    message: "主机地址格式正确",
                    type: .success
                ))
            } else {
                validationResults.append(ValidationResult(
                    message: "主机地址格式可能不正确",
                    type: .warning
                ))
            }
        }
        
        // 检查端口
        if host.port < 1 || host.port > 65535 {
            validationResults.append(ValidationResult(
                message: "端口号应在 1-65535 之间",
                type: .error
            ))
        }
        
        // 检查密钥文件
        if let keyFile = host.identityFile {
            let expandedPath = NSString(string: keyFile).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                // 检查权限
                if let attrs = try? FileManager.default.attributesOfItem(atPath: expandedPath),
                   let permissions = attrs[.posixPermissions] as? Int {
                    if permissions & 0o077 == 0 {
                        validationResults.append(ValidationResult(
                            message: "密钥文件权限正确 (600)",
                            type: .success
                        ))
                    } else {
                        validationResults.append(ValidationResult(
                            message: "密钥文件权限不安全，建议设置为 600",
                            type: .warning
                        ))
                    }
                }
            } else {
                validationResults.append(ValidationResult(
                    message: "密钥文件不存在",
                    type: .error
                ))
            }
        }
    }
    
    private func isValidHostname(_ hostname: String) -> Bool {
        // 简单的主机名验证
        let ipPattern = "^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$"
        let domainPattern = "^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$"
        
        return hostname.range(of: ipPattern, options: .regularExpression) != nil ||
               hostname.range(of: domainPattern, options: .regularExpression) != nil
    }
}

struct ValidationResult: Identifiable {
    let id = UUID()
    let message: String
    let type: ResultType
    
    enum ResultType {
        case success, warning, error
    }
    
    var icon: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch type {
        case .success: return Theme.success
        case .warning: return Theme.warning
        case .error: return Theme.danger
        }
    }
}
```

---

### 2.5 SSH命令预览

创建 `Views/SSHCommandView.swift`：

```swift
import SwiftUI

struct SSHCommandView: View {
    @ObservedObject var host: SSHHost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("等效SSH命令")
                .font(.system(size: 14, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 8) {
                // 简化命令
                CommandBox(title: "使用别名") {
                    Text("ssh \(host.name)")
                }
                
                // 完整命令
                CommandBox(title: "完整命令") {
                    Text(generateFullCommand())
                }
            }
            
            HStack {
                Button(action: copyCommand) {
                    Label("复制命令", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                
                Button(action: copyAlias) {
                    Label("复制别名", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .cornerRadius(8)
    }
    
    private func generateFullCommand() -> String {
        var parts = ["ssh"]
        
        if let keyFile = host.identityFile {
            parts.append("-i \(keyFile)")
        }
        
        if host.port != 22 {
            parts.append("-p \(host.port)")
        }
        
        // 端口转发
        for forward in host.portForwards {
            switch forward.type {
            case .local:
                parts.append("-L \(forward.localPort):\(forward.remoteHost):\(forward.remotePort)")
            case .remote:
                parts.append("-R \(forward.localPort):\(forward.remoteHost):\(forward.remotePort)")
            case .dynamic:
                parts.append("-D \(forward.localPort)")
            }
        }
        
        // 跳板机
        if !host.jumpHosts.isEmpty {
            let jumps = host.jumpHosts.map { $0.toString() }.joined(separator: ",")
            parts.append("-J \(jumps)")
        }
        
        parts.append("\(host.user)@\(host.hostname)")
        
        return parts.joined(separator: " \\\n    ")
    }
    
    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generateFullCommand(), forType: .string)
    }
    
    private func copyAlias() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("ssh \(host.name)", forType: .string)
    }
}

struct CommandBox<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            
            content
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
        }
    }
}
```

---

### 2.6 空状态设计

创建 `Views/EmptyStateView.swift`：

```swift
import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 图标
            Image(systemName: "server.rack")
                .font(.system(size: 64))
                .foregroundColor(Theme.textTertiary)
            
            // 提示文字
            VStack(spacing: 8) {
                Text("SSH Manager")
                    .font(.system(size: 24, weight: .bold))
                
                Text("从左侧选择一个主机开始")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                
                Text("或者点击")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                + Text(" + ")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.primary)
                + Text("创建新连接")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Divider()
                .frame(width: 300)
                .padding(.vertical)
            
            // 快捷提示
            VStack(alignment: .leading, spacing: 12) {
                Text("💡 快捷键提示")
                    .font(.system(size: 14, weight: .semibold))
                
                ShortcutRow(key: "⌘N", description: "新建主机")
                ShortcutRow(key: "⌘S", description: "保存配置")
                ShortcutRow(key: "⌘T", description: "测试连接")
                ShortcutRow(key: "⌘F", description: "搜索主机")
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .cornerRadius(12)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundPrimary)
    }
}

struct ShortcutRow: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.backgroundTertiary)
                .cornerRadius(4)
            
            Text(description)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
    }
}
```

---

## Phase 3: 高级功能（低优先级）

### 3.1 分组功能

**允许用户创建分组来组织主机**

修改 `Models/HostGroup.swift`（新建文件）：

```swift
import SwiftUI

class HostGroup: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var isExpanded: Bool = true
    @Published var hosts: [SSHHost] = []
    
    init(name: String) {
        self.name = name
    }
}
```

修改 `SSHHostManager` 支持分组：

```swift
class SSHHostManager: ObservableObject {
    @Published var groups: [HostGroup] = []
    @Published var ungroupedHosts: [SSHHost] = []
    
    var allHosts: [SSHHost] {
        groups.flatMap { $0.hosts } + ungroupedHosts
    }
    
    func createGroup(named name: String) {
        let group = HostGroup(name: name)
        groups.append(group)
    }
    
    func moveHost(_ host: SSHHost, to group: HostGroup?) {
        // 从所有组中移除
        for g in groups {
            g.hosts.removeAll { $0.id == host.id }
        }
        ungroupedHosts.removeAll { $0.id == host.id }
        
        // 添加到目标组
        if let group = group {
            group.hosts.append(host)
        } else {
            ungroupedHosts.append(host)
        }
    }
}
```

修改列表视图支持分组显示：

```swift
struct HostListView: View {
    @EnvironmentObject var hostManager: SSHHostManager
    
    var body: some View {
        List {
            ForEach(hostManager.groups) { group in
                Section(header: GroupHeader(group: group)) {
                    ForEach(group.hosts) { host in
                        HostRowView(host: host)
                    }
                }
            }
            
            Section(header: Text("未分组")) {
                ForEach(hostManager.ungroupedHosts) { host in
                    HostRowView(host: host)
                }
            }
        }
    }
}

struct GroupHeader: View {
    @ObservedObject var group: HostGroup
    
    var body: some View {
        HStack {
            Image(systemName: group.isExpanded ? "folder.fill" : "folder")
            Text(group.name)
            Spacer()
            Text("\(group.hosts.count)")
                .font(.caption)
                .foregroundColor(Theme.textTertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                group.isExpanded.toggle()
            }
        }
    }
}
```

---

### 3.2 连接统计

创建 `Views/StatisticsView.swift`：

```swift
import SwiftUI

struct StatisticsView: View {
    @ObservedObject var host: SSHHost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("连接统计")
                .font(.system(size: 14, weight: .semibold))
            
            HStack(spacing: 20) {
                StatCard(
                    icon: "arrow.up.arrow.down",
                    title: "总连接次数",
                    value: "\(host.connectionCount)"
                )
                
                StatCard(
                    icon: "clock.fill",
                    title: "最后连接",
                    value: host.lastConnected?.timeAgo() ?? "从未"
                )
                
                StatCard(
                    icon: "timer",
                    title: "平均延迟",
                    value: "\(host.averageLatency)ms"
                )
            }
            
            Divider()
            
            Text("最近连接")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            
            if host.connectionHistory.isEmpty {
                Text("暂无连接记录")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(host.connectionHistory.prefix(5)) { record in
                    ConnectionRecordRow(record: record)
                }
            }
        }
        .padding()
        .background(Theme.backgroundSecondary)
        .cornerRadius(8)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.primary)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.backgroundTertiary.opacity(0.5))
        .cornerRadius(8)
    }
}

struct ConnectionRecordRow: View {
    let record: ConnectionRecord
    
    var body: some View {
        HStack {
            Circle()
                .fill(record.isSuccess ? Theme.success : Theme.danger)
                .frame(width: 6, height: 6)
            
            Text(record.timestamp.formatted())
                .font(.caption)
            
            Spacer()
            
            if record.isSuccess {
                Text("\(record.duration)s")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
            } else {
                Text("失败")
                    .font(.caption)
                    .foregroundColor(Theme.danger)
            }
        }
    }
}

// 扩展 SSHHost 添加统计属性
extension SSHHost {
    var connectionCount: Int {
        // 从 UserDefaults 或数据库读取
        UserDefaults.standard.integer(forKey: "connection_count_\(id)")
    }
    
    var lastConnected: Date? {
        // 从 UserDefaults 读取
        UserDefaults.standard.object(forKey: "last_connected_\(id)") as? Date
    }
    
    var averageLatency: Int {
        // 计算平均延迟
        73 // 示例值
    }
    
    var connectionHistory: [ConnectionRecord] {
        // 从持久化存储读取
        []
    }
}

struct ConnectionRecord: Identifiable {
    let id = UUID()
    let timestamp: Date
    let isSuccess: Bool
    let duration: Int
}

extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
```

---

### 3.3 快捷键支持

在 `SSHManagerApp.swift` 中添加：

```swift
@main
struct SSHManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // 文件菜单
            CommandGroup(replacing: .newItem) {
                Button("新建主机") {
                    // 触发新建
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // 编辑菜单
            CommandGroup(after: .pasteboard) {
                Button("测试连接") {
                    // 触发测试
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Button("保存配置") {
                    // 触发保存
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
```

---

## 实施检查清单

### Phase 1 - 核心功能（必须完成）

- [ ] 修复编辑功能
  - [ ] 确认 `@Published` 和 `@ObservedObject` 正确使用
  - [ ] 实现双向数据绑定
  - [ ] 添加未保存更改提示
  - [ ] 测试编辑后保存

- [ ] 修复新增按钮
  - [ ] 实现添加按钮点击事件
  - [ ] 创建新主机的默认值
  - [ ] 自动选中新建主机
  - [ ] 添加成功反馈

- [ ] 完善保存功能
  - [ ] 实现配置文件写入
  - [ ] 添加备份机制
  - [ ] 设置正确的文件权限
  - [ ] 错误处理

- [ ] 添加错误处理
  - [ ] 创建错误提示组件
  - [ ] 友好的错误信息
  - [ ] 错误恢复建议

### Phase 2 - 视觉优化（重要）

- [ ] 应用色彩系统
  - [ ] 创建 Theme.swift
  - [ ] 定义主色调
  - [ ] 定义状态色
  - [ ] 深色模式适配

- [ ] 优化左侧列表
  - [ ] 重新设计主机卡片
  - [ ] 添加图标差异化
  - [ ] 实现悬停效果
  - [ ] 添加状态指示器

- [ ] 优化右侧编辑区
  - [ ] 实现卡片式布局
  - [ ] 优化表单设计
  - [ ] 添加配置预览
  - [ ] 实现Tab切换

- [ ] 添加空状态
  - [ ] 设计空状态界面
  - [ ] 添加快捷键提示

### Phase 3 - 高级功能（可选）

- [ ] 实现分组功能
- [ ] 添加连接统计
- [ ] 支持快捷键
- [ ] 添加搜索高亮

---

## 测试建议

### 功能测试

1. **编辑测试**
   - 修改主机名，保存，重启应用验证
   - 修改IP地址，测试连接
   - 修改端口号，验证配置文件

2. **新增测试**
   - 点击添加按钮，验证新主机创建
   - 检查默认值是否正确
   - 验证自动选中

3. **保存测试**
   - 修改后保存，检查配置文件
   - 验证备份文件创建
   - 检查文件权限（应为600）

### 视觉测试

1. **响应式测试**
   - 调整窗口大小
   - 测试深色/浅色模式
   - 检查不同分辨率

2. **交互测试**
   - 悬停效果
   - 点击反馈
   - 动画流畅度

---

## 常见问题排查

### 问题1：编辑无效

**症状：** 输入框可以输入，但数据不保存

**排查步骤：**
1. 检查 `@Published` 是否正确声明
2. 检查 `@ObservedObject` 是否使用
3. 打印日志验证数据变化
4. 检查 `saveConfig()` 是否被调用

### 问题2：新增按钮无响应

**症状：** 点击添加按钮没有任何反应

**排查步骤：**
1. 在 action 中添加 `print("添加按钮被点击")`
2. 检查是否有编译错误
3. 验证 `hostManager.hosts.append()` 是否执行
4. 检查 UI 是否刷新

### 问题3：配置保存失败

**症状：** 保存时报错或无法写入

**排查步骤：**
1. 检查文件路径是否正确
2. 验证文件权限
3. 检查是否有磁盘空间
4. 查看详细错误信息

---

## 性能优化建议

1. **懒加载**
   - 列表使用 `LazyVStack`
   - 配置预览延迟渲染

2. **防抖处理**
   - 搜索输入使用防抖
   - 自动保存延迟触发

3. **缓存**
   - 缓存解析结果
   - 缓存连接状态

---

## 参考资源

### SwiftUI文档
- [Apple SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)

### 设计参考
- [Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SF Symbols](https://developer.apple.com/sf-symbols/)

### SSH配置
- [OpenSSH Config Man Page](https://man.openbsd.org/ssh_config)

---

## 总结

**实施优先级：**

1. **立即修复（1-2天）**
   - 编辑功能
   - 新增按钮
   - 保存功能

2. **视觉优化（3-5天）**
   - 色彩系统
   - 列表重设计
   - 编辑区优化

3. **功能增强（可选）**
   - 分组功能
   - 连接统计
   - 高级选项

**成功标准：**
- ✅ 能够正常添加、编辑、保存主机配置
- ✅ 界面美观，符合macOS设计规范
- ✅ 交互流畅，有明确的状态反馈
- ✅ 错误处理友好，有清晰的提示

按照这个文档逐步实施，你的SSH Manager将会成为一个功能完善、体验优秀的macOS应用！🚀
