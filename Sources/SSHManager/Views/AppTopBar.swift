import SwiftUI

struct AppTopBar: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @Binding var selectedHostId: UUID?
    @Binding var editingHost: SSHHost?
    
    var body: some View {
        HStack(spacing: 16) {
            // Add Button
            Button {
                addNewHost()
            } label: {
                Label("添加主机", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                if isHovering { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
            }
            .help("添加新的 SSH 主机配置")
            
            // Edit Button
            Button {
                editSelectedHost()
            } label: {
                Label("编辑配置", systemImage: "pencil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedHostId != nil ? .primary : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedHostId != nil ? Color.accentColor.opacity(0.1) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedHostId != nil ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(selectedHostId == nil)
            .onHover { isHovering in
                if isHovering && selectedHostId != nil { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
            }
            .help("编辑当前选中的主机配置")

            Divider()
                .frame(height: 20)

            // Test Connection Button
            if let host = getSelectedHost() {
                Button {
                    testConnection(host)
                } label: {
                    HStack(spacing: 6) {
                        if host.isTesting {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 13, height: 13)
                        } else {
                            Image(systemName: "network")
                        }
                        Text(host.isTesting ? "测试中..." : "测试连接")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(host.isTesting)
                .onHover { isHovering in
                    if isHovering { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() }
                }
                .help("测试到当前主机的网络连通性")
            } else {
                // Disabled Test Button
                Label("测试连接", systemImage: "network")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                    .opacity(0.5)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            VisualEffectView(material: .titlebar)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private func getSelectedHost() -> SSHHost? {
        guard let id = selectedHostId else { return nil }
        return configManager.hosts.first(where: { $0.id == id })
    }
    
    private func addNewHost() {
        let newHost = SSHHost()
        configManager.addHost(newHost)
        selectedHostId = newHost.id
        editingHost = newHost
    }
    
    private func editSelectedHost() {
        if let host = getSelectedHost() {
            editingHost = host
        }
    }
    
    private func testConnection(_ host: SSHHost) {
        host.isTesting = true
        host.lastTestResult = nil
        
        Task {
            let connector = SSHConnector()
            let result = await connector.testConnection(host)
            
            await MainActor.run {
                host.lastTestResult = result
                host.isTesting = false
            }
        }
    }
}

// Helper view for visual effects
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.state = .active
        visualEffectView.isEmphasized = false
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

struct AppTopBar_Previews: PreviewProvider {
    static var previews: some View {
        AppTopBar(
            selectedHostId: .constant(nil),
            editingHost: .constant(nil)
        )
        .environmentObject(SSHConfigManager())
        .frame(width: 500, height: 60)
    }
}
