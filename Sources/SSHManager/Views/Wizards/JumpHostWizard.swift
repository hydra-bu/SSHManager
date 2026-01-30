import SwiftUI

struct JumpHostWizard: View {
    @Binding var isPresented: Bool
    @ObservedObject var host: SSHHost
    @EnvironmentObject var configManager: SSHConfigManager
    var onComplete: (JumpHost) -> Void
    
    @State private var mode: JumpHostType = .reference
    @State private var selectedHostId: UUID?
    @State private var alias: String = ""
    @State private var hostname: String = ""
    @State private var user: String = ""
    @State private var port: Int = 22
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("配置方式", selection: $mode) {
                    ForEach(JumpHostType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 8)
                
                if mode == .reference {
                    referenceSection
                } else {
                    manualSection
                }
            }
            .navigationTitle("添加跳板机")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let jumpHost = createJumpHost()
                        onComplete(jumpHost)
                        isPresented = false
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 450, height: 300)
    }
    
    private var referenceSection: some View {
        Group {
            if configManager.hosts.isEmpty {
                Text("没有可用的主机配置")
                    .foregroundColor(.secondary)
            } else {
                Picker("选择主机", selection: $selectedHostId) {
                    Text("请选择").tag(nil as UUID?)
                    ForEach(configManager.hosts.filter({ $0.id != host.id })) { h in
                        Text(h.alias).tag(h.id as UUID?)
                    }
                }
            }
            
            HStack {
                Text("或输入别名")
                Spacer()
                TextField("主机别名", text: $alias)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
        }
    }
    
    private var manualSection: some View {
        Group {
            HStack {
                Text("主机地址")
                Spacer()
                TextField("hostname or IP", text: $hostname)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            
            HStack {
                Text("用户名")
                Spacer()
                TextField("username", text: $user)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            
            HStack {
                Text("端口")
                Spacer()
                TextField("22", value: $port, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            
            HStack {
                Text("别名(可选)")
                Spacer()
                TextField("显示名称", text: $alias)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
        }
    }
    
    private var isValid: Bool {
        switch mode {
        case .reference:
            return selectedHostId != nil || !alias.isEmpty
        case .manual:
            return !hostname.isEmpty
        }
    }
    
    private func createJumpHost() -> JumpHost {
        if mode == .reference, let hostId = selectedHostId,
           let refHost = configManager.hosts.first(where: { $0.id == hostId }) {
            return JumpHost(
                type: .reference,
                referencedHostId: hostId,
                alias: refHost.alias
            )
        } else {
            return JumpHost(
                type: mode,
                referencedHostId: selectedHostId,
                alias: alias,
                hostname: hostname,
                user: user,
                port: port
            )
        }
    }
}
