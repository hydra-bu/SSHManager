import SwiftUI

struct AppTopBar: View {
    @EnvironmentObject var configManager: SSHConfigManager
    @Binding var selectedHostId: UUID?
    @Binding var editingHost: SSHHost?
    
    var body: some View {
        HStack(spacing: 12) {
            // Add Button
            Button {
                addNewHost()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                    Text("添加")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
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
                if isHovering {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .help("添加新主机")
            
            // Edit Button
            Button {
                editSelectedHost()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                    Text("编辑")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(selectedHostId != nil ? .primary : .secondary)
                .padding(.horizontal, 12)
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
                if isHovering && selectedHostId != nil {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .help("编辑选中的主机")
            
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
    
    private func addNewHost() {
        let newHost = SSHHost()
        configManager.addHost(newHost)
        selectedHostId = newHost.id
        editingHost = newHost
    }
    
    private func editSelectedHost() {
        if let selectedHostId = selectedHostId,
           let selectedHost = configManager.hosts.first(where: { $0.id == selectedHostId }) {
            editingHost = selectedHost
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
        .frame(width: 400, height: 60)
    }
}