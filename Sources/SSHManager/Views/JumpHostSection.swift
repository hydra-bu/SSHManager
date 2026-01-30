import SwiftUI

struct JumpHostSection: View {
    @ObservedObject var host: SSHHost
    @EnvironmentObject var configManager: SSHConfigManager
    @State private var showingWizard = false
    @State private var showingAdvanced = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            
            if host.jumpHosts.isEmpty {
                emptyState
            } else {
                jumpChainView
                jumpHostsList
            }
            
            actionButtons
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .sheet(isPresented: $showingWizard) {
            JumpHostWizard(
                isPresented: $showingWizard,
                host: host,
                onComplete: { jump in
                    host.jumpHosts.append(jump)
                }
            )
            .environmentObject(configManager)
        }
    }

    private var header: some View {
        HStack {
            Label("跳板机链", systemImage: "network")
                .font(.headline)
            Spacer()
            if !host.jumpHosts.isEmpty {
                Text("\(host.jumpHosts.count) 级跳板")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "network.badge.shield.half.filled")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("直接连接目标服务器")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("添加跳板机可以通过中间服务器安全访问内网")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var jumpChainView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chainNode(icon: "desktopcomputer", label: "本地", color: .secondary)
                
                ForEach(Array(host.jumpHosts.enumerated()), id: \.offset) { index, jump in
                    chainArrow
                    chainNode(
                        icon: "server.rack",
                        label: "\(index + 1). \(jump.displayName)",
                        color: .blue
                    )
                }
                
                chainArrow
                chainNode(icon: "server.rack.fill", label: host.alias, color: .green)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
    
    private var chainArrow: some View {
        Image(systemName: "arrow.right")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private func chainNode(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
        .frame(minWidth: 60)
    }
    
    private var jumpHostsList: some View {
        VStack(spacing: 4) {
            ForEach($host.jumpHosts) { $jump in
                JumpHostRow(jump: $jump, onDelete: {
                    deleteJump(jump)
                })
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showingWizard = true }) {
                Label("添加跳板机", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func deleteJump(_ jump: JumpHost) {
        host.jumpHosts.removeAll { $0.id == jump.id }
    }
}

struct JumpHostRow: View {
    @Binding var jump: JumpHost
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: jump.type == .reference ? "link" : "keyboard")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(jump.displayName)
                    .font(.subheadline)
                if jump.type == .manual {
                    Text("\(jump.user)@\(jump.hostname):\(jump.port)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
