import Foundation

class SSHConnector: ObservableObject {
    private let preferences = UserPreferences.shared

    func connect(to host: SSHHost) {
        switch preferences.preferredTerminal {
        case .iTerm2:
            connectWithiTerm2NewTab(host: host)
        case .terminal:
            connectWithTerminal(host: host)
        }
    }

    func connectWithiTerm2NewTab(host: SSHHost) {
        let sshCommand = generateSSHCommand(for: host)
        let escapedCommand = sshCommand.replacingOccurrences(of: "\"", with: "\\\"")

        let appleScript = """
        tell application "iTerm"
            activate
            if (count of windows) = 0 then
                create window with default profile
            end if
            tell current session of current tab of current window
                set newTab to (split horizontally with default profile)
                tell newTab
                    write text "\(escapedCommand)"
                end tell
            end tell
        end tell
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", appleScript]

        do {
            try task.run()
        } catch {
            print("启动iTerm2新标签页失败: \(error)")
            connectWithiTerm2Window(host: host)
        }
    }

    func testConnection(_ host: SSHHost) async -> ConnectionTestResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = buildTestArguments(for: host)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            try process.run()
            process.waitUntilExit()
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            if process.terminationStatus == 0 {
                return .success(latency: timeElapsed)
            } else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let error = SSHErrorParser.parseSystemError(output)
                return .failure(error)
            }
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    private func connectWithTerminal(host: SSHHost) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [
            "-e", "tell app \"Terminal\" to do script \"\(generateSSHCommand(for: host))\""
        ]

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("启动Terminal失败: \(error)")
            connectDirectly(host: host)
        }
    }

    private func connectWithiTerm2Window(host: SSHHost) {
        let sshCommand = generateSSHCommand(for: host)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [
            "-e", "tell app \"iTerm\" to create window with default profile command \"\(sshCommand)\""
        ]

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("启动iTerm2失败: \(error)")
            connectDirectly(host: host)
        }
    }

    private func connectDirectly(host: SSHHost) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = [host.alias]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("SSH连接失败: \(error)")
        }
    }

    private func generateSSHCommand(for host: SSHHost) -> String {
        var components = ["ssh"]

        if host.port != 22 {
            components.append(contentsOf: ["-p", "\(host.port)"])
        }

        if !host.identityFile.isEmpty {
            components.append(contentsOf: ["-i", host.identityFile])
        }

        if !host.jumpHosts.isEmpty {
            let jumpString = host.jumpHosts.map { $0.toProxyJumpString() }.joined(separator: ",")
            components.append(contentsOf: ["-J", jumpString])
        }

        for forward in host.portForwards where forward.isActive {
            components.append(forward.toSSHArgument())
        }

        components.append(host.getUserAtHost())
        return components.joined(separator: " ")
    }

    private func buildTestArguments(for host: SSHHost) -> [String] {
        let timeout = preferences.testTimeout
        var args = [
            "-o", "ConnectTimeout=\(timeout)",
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "PreferredAuthentications=publickey",
            "-o", "ServerAliveInterval=5",
            "-o", "ServerAliveCountMax=1",
            "-p", "\(host.port)"
        ]

        if !host.jumpHosts.isEmpty {
            let jumpString = host.jumpHosts.map { $0.toProxyJumpString() }.joined(separator: ",")
            args.append(contentsOf: ["-J", jumpString])
        }

        args.append(host.getUserAtHost())
        return args
    }
}

class SSHErrorParser {
    static func parseSystemError(_ output: String) -> SSHConnectionError {
        if output.contains("Connection refused") || output.contains("kex_exchange_identification") {
            return .connectionRefused
        } else if output.contains("Permission denied") || output.contains("publickey") {
            return .permissionDenied
        } else if output.contains("Connection timed out") || output.contains("Operation timed out") {
            return .connectionTimeout
        } else if output.contains("Name or service not known") || output.contains("nodename nor servname provided") || output.contains("Could not resolve hostname") {
            return .unknownHost
        } else if output.contains("No route to host") {
            return .noRouteToHost
        } else if output.contains("Network is unreachable") {
            return .networkUnreachable
        } else if output.contains("No such file") || output.contains("not found") {
            return .keyFileNotFound("unknown_path")
        } else if output.contains("Bad permissions") || output.contains("Permission denied (publickey)") {
            return .keyFileWrongPermissions("unknown_path")
        } else if output.contains("Host key verification failed") {
            return .hostKeyVerificationFailed
        } else {
            return .unknown(output)
        }
    }
}
