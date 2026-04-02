import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences = UserPreferences.shared
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            form
            Divider()
            footer
        }
        .frame(width: 400, height: 300)
    }

    private var header: some View {
        HStack {
            Text("偏好设置")
                .font(.title2)
            Spacer()
        }
        .padding()
    }

    private var form: some View {
        Form {
            Section("连接设置") {
                Picker("默认终端", selection: $preferences.preferredTerminal) {
                    ForEach(TerminalType.allCases, id: \.self) { terminal in
                        Text(terminal.displayName).tag(terminal)
                    }
                }

                HStack {
                    Text("连接超时")
                    Spacer()
                    TextField("", value: $preferences.testTimeout, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("秒")
                }
            }

            Section("主机默认值") {
                HStack {
                    Text("默认端口")
                    Spacer()
                    TextField("", value: $preferences.defaultPort, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }

                Toggle("默认启用压缩", isOn: $preferences.enableCompression)
            }
        }
        .formStyle(.grouped)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("完成") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
