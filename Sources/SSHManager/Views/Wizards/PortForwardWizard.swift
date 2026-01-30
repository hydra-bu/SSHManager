import SwiftUI

struct UseCaseButton: View {
    let useCase: PortForwardUseCase
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(useCase.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var iconName: String {
        switch useCase {
        case .accessRemoteWeb: return "globe"
        case .socksProxy: return "network.badge.shield.half.filled"
        case .reverseForward: return "arrow.backward"
        case .custom: return "gearshape.2"
        }
    }
    
    private var description: String {
        switch useCase {
        case .accessRemoteWeb: return "通过本地端口访问远程服务器上的Web服务"
        case .socksProxy: return "通过SSH隧道加密所有网络流量"
        case .reverseForward: return "让远程服务器访问你的本地服务"
        case .custom: return "手动配置端口转发参数"
        }
    }
}

enum PortForwardUseCase: String, CaseIterable {
    case accessRemoteWeb = "访问远程Web界面"
    case socksProxy = "SOCKS代理"
    case reverseForward = "反向转发"
    case custom = "自定义配置"
}

enum WizardMode {
    case simple, advanced
}

struct PortForwardWizard: View {
    @Binding var isPresented: Bool
    @ObservedObject var host: SSHHost
    var onComplete: (PortForward) -> Void
    
    @State private var mode: WizardMode = .simple
    @State private var currentStep = 1
    @State private var selectedUseCase: PortForwardUseCase = .accessRemoteWeb
    @State private var newForward = PortForward()
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 20) {
                    if mode == .simple {
                        simpleContent
                    } else {
                        advancedContent
                    }
                }
                .padding()
            }
            Divider()
            footer
        }
        .frame(width: 500, height: 500)
    }
    
    private var header: some View {
        HStack {
            Text("端口转发配置")
                .font(.title2)
            Spacer()
            Picker("", selection: $mode) {
                Text("向导").tag(WizardMode.simple)
                Text("高级").tag(WizardMode.advanced)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .padding()
    }
    
    private var simpleContent: some View {
        Group {
            if currentStep == 1 {
                step1UseCase
            } else if currentStep == 2 {
                step2Config
            } else {
                step3Review
            }
        }
    }
    
    private var step1UseCase: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("你想实现什么功能？")
                .font(.headline)
            ForEach(PortForwardUseCase.allCases, id: \.self) { useCase in
                UseCaseButton(
                    useCase: useCase,
                    isSelected: selectedUseCase == useCase,
                    action: { selectedUseCase = useCase }
                )
            }
        }
    }
    
    private var step2Config: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "globe")
                Text(selectedUseCase.rawValue)
                    .font(.headline)
            }
            
            switch selectedUseCase {
            case .accessRemoteWeb:
                webConfigFields
            case .socksProxy:
                socksConfigFields
            case .reverseForward:
                reverseConfigFields
            case .custom:
                EmptyView()
            }
        }
    }
    
    private var webConfigFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("远程地址")
                    .frame(width: 80, alignment: .trailing)
                TextField("localhost", text: $newForward.remoteHost)
                    .textFieldStyle(.roundedBorder)
            }
            Text("如果Web服务在远程服务器本地运行，使用localhost")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("远程端口")
                    .frame(width: 80, alignment: .trailing)
                TextField("", value: $newForward.remotePort, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
            }
            Text("常见: 80(HTTP), 443(HTTPS), 3000(Node.js), 8080(Tomcat)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("本地端口")
                    .frame(width: 80, alignment: .trailing)
                TextField("", value: $newForward.localPort, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
            }
            Text("配置后在浏览器访问 http://localhost:\(newForward.localPort)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var socksConfigFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SOCKS代理可以加密转发所有网络流量，保护隐私")
                .font(.subheadline)
            HStack {
                Text("代理端口")
                    .frame(width: 80, alignment: .trailing)
                TextField("", value: $newForward.localPort, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
            }
            Text("标准端口1080，在系统设置→网络→代理中配置")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var reverseConfigFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("让远程服务器访问你本地电脑的服务")
                .font(.subheadline)
            HStack {
                Text("本地端口")
                    .frame(width: 80, alignment: .trailing)
                TextField("", value: $newForward.localPort, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("远程端口")
                    .frame(width: 80, alignment: .trailing)
                TextField("", value: $newForward.remotePort, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private var step3Review: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("配置预览")
                .font(.headline)
            
            HStack(spacing: 8) {
                VStack {
                    Image(systemName: "desktopcomputer")
                    Text("本地")
                        .font(.caption)
                }
                Image(systemName: "arrow.right")
                VStack {
                    Image(systemName: "server.rack")
                    Text("远程")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("SSH参数: \(newForward.toSSHArgument())")
                .font(.caption.monospaced())
                .padding()
                .background(Color.black.opacity(0.05))
                .cornerRadius(4)
        }
    }
    
    private var advancedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("类型", selection: $newForward.type) {
                ForEach(PortForwardType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            
            HStack {
                Text("本地端口")
                Spacer()
                TextField("", value: $newForward.localPort, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            
            if newForward.type != .dynamic {
                HStack {
                    Text("远程主机")
                    Spacer()
                    TextField("", text: $newForward.remoteHost)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }
                
                HStack {
                    Text("远程端口")
                    Spacer()
                    TextField("", value: $newForward.remotePort, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
            }
        }
    }
    
    private var footer: some View {
        HStack {
            Button("取消") { isPresented = false }
            Spacer()
            if mode == .simple && currentStep > 1 {
                Button("上一步") { currentStep -= 1 }
            }
            if mode == .simple && currentStep < 3 {
                Button("下一步") { currentStep += 1 }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("完成") {
                    onComplete(newForward)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
