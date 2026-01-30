import SwiftUI

struct JumpHostWizard: View {
    @Binding var isPresented: Bool
    @ObservedObject var host: SSHHost
    @EnvironmentObject var configManager: SSHConfigManager
    var onComplete: (JumpHost) -> Void
    
    @State private var currentStep = 1
    @State private var selectedHostId: UUID?
    @State private var alias = ""
    @State private var hostname = ""
    @State private var user = ""
    @State private var port = 22
    @State private var mode: JumpHostType = .reference
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 20) {
                    if currentStep == 1 {
                        step1Content
                    } else if currentStep == 2 {
                        step2Content
                    } else {
                        step3Content
                    }
                }
                .padding()
            }
            Divider()
            footer
        }
        .frame(width: 500, height: 450)
    }
    
    private var header: some View {
        HStack {
            Text("跳板机配置")
                .font(.title2)
            Spacer()
            Text("第 \(currentStep)/3 步")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var step1Content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择配置方式")
                .font(.headline)
            
            ForEach(JumpHostType.allCases, id: \.self) { type in
                Button(action: { mode = type }) {
                    HStack {
                        Image(systemName: type == .reference ? "link" : "keyboard")
                            .font(.title2)
                            .foregroundColor(mode == type ? .white : .blue)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(type.displayName)
                                .font(.headline)
                                .foregroundColor(mode == type ? .white : .primary)
                        }
                        
                        Spacer()
                        
                        if mode == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(mode == type ? Color.blue : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var step2Content: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: mode == .reference ? "link" : "keyboard")
                Text(mode.displayName)
                    .font(.headline)
            }
            
            if mode == .reference {
                referenceConfig
            } else {
                manualConfig
            }
        }
    }
    
    private var referenceConfig: some View {
        Group {
            if configManager.hosts.filter({ $0.id != host.id }).isEmpty {
                Text("没有可用的主机配置")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Picker("选择主机", selection: $selectedHostId) {
                    Text("请选择").tag(nil as UUID?)
                    ForEach(configManager.hosts.filter({ $0.id != host.id })) { h in
                        Text(h.alias).tag(h.id as UUID?)
                    }
                }
                .labelsHidden()
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
    
    private var manualConfig: some View {
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
                Text("别名")
                Spacer()
                TextField("显示名称", text: $alias)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
        }
    }
    
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("配置预览")
                .font(.headline)
            
            VStack(spacing: 12) {
                connectionNode(icon: "desktopcomputer", label: "本地", color: .secondary)
                
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                connectionNode(icon: "server.rack", label: getJumpName(), color: .blue)
                
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                connectionNode(icon: "server.rack.fill", label: host.alias, color: .green)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var footer: some View {
        HStack {
            Button("取消") { isPresented = false }
            Spacer()
            if currentStep > 1 {
                Button("上一步") { currentStep -= 1 }
            }
            if currentStep < 3 {
                Button("下一步") { currentStep += 1 }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
            } else {
                Button("完成") {
                    onComplete(createJumpHost())
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private func connectionNode(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(label)
                .font(.caption)
        }
        .foregroundColor(color)
    }
    
    private func getJumpName() -> String {
        if mode == .reference, let hostId = selectedHostId,
           let refHost = configManager.hosts.first(where: { $0.id == hostId }) {
            return refHost.alias
        }
        return alias.isEmpty ? (hostname.isEmpty ? "未命名" : hostname) : alias
    }
    
    private var canProceed: Bool {
        if currentStep == 2 {
            if mode == .reference {
                return selectedHostId != nil || !alias.isEmpty
            } else {
                return !hostname.isEmpty
            }
        }
        return true
    }
    
    private func createJumpHost() -> JumpHost {
        if mode == .reference, let hostId = selectedHostId,
           let refHost = configManager.hosts.first(where: { $0.id == hostId }) {
            return JumpHost(type: .reference, referencedHostId: hostId, alias: refHost.alias)
        } else {
            return JumpHost(type: .manual, alias: alias, hostname: hostname, user: user, port: port)
        }
    }
}
