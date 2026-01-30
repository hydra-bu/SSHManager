import SwiftUI

struct PortForwardingSection: View {
    @ObservedObject var host: SSHHost
    @State private var showingWizard = false
    @State private var showingAdvanced = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            
            if host.portForwards.isEmpty {
                emptyState
            } else {
                forwardsList
            }
            
            actionButtons
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var header: some View {
        HStack {
            Label("端口转发", systemImage: "arrow.left.arrow.right")
                .font(.headline)
            Spacer()
            Text("\(host.portForwards.count) 条规则")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("暂无端口转发规则")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("通过端口转发可以安全地访问远程服务")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var forwardsList: some View {
        VStack(spacing: 8) {
            ForEach($host.portForwards) { $forward in
                PortForwardRow(forward: $forward, onDelete: {
                    deleteForward(forward)
                })
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showingWizard = true }) {
                Label("配置向导", systemImage: "wand.and.stars")
            }
            .buttonStyle(.bordered)
            
            Button(action: { showingAdvanced = true }) {
                Label("高级", systemImage: "gearshape.2")
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func deleteForward(_ forward: PortForward) {
        host.portForwards.removeAll { $0.id == forward.id }
    }
}

struct PortForwardRow: View {
    @Binding var forward: PortForward
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(forward.displayDescription)
                    .font(.subheadline)
                if let desc = forward.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $forward.isActive)
                .toggleStyle(.switch)
                .scaleEffect(0.8)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private var iconName: String {
        switch forward.type {
        case .local: return "arrow.forward.circle.fill"
        case .remote: return "arrow.backward.circle.fill"
        case .dynamic: return "network.badge.shield.half.filled"
        }
    }
    
    private var color: Color {
        switch forward.type {
        case .local: return .green
        case .remote: return .blue
        case .dynamic: return .purple
        }
    }
}
