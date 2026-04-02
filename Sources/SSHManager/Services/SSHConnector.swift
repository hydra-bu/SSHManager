import Foundation

// SSH连接器
class SSHConnector: ObservableObject {
    // 连接到主机（在新的终端窗口中）
    func connect(to host: SSHHost) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = [host.alias]  // 使用配置别名，自动读取~/.ssh/config

        // 设置为在终端中运行
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [
            "-e", "tell app \"Terminal\" to do script \"ssh \(host.alias)\""
        ]

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("启动终端失败: \(error)")
            // 如果Terminal失败，尝试使用iTerm2
            connectWithiTerm2(host: host)
        }
    }

    // 使用iTerm2连接（如果安装了的话）
    private func connectWithiTerm2(host: SSHHost) {
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
            // 最后尝试直接执行ssh命令
            connectDirectly(host: host)
        }
    }

    // 使用iTerm2在新标签页连接
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
            // 如果失败，尝试创建新窗口
            connectWithiTerm2(host: host)
        }
    }

    // 生成SSH命令
    private func generateSSHCommand(for host: SSHHost) -> String {
        var cmd = "ssh"
        if host.port != 22 {
            cmd += " -p \(host.port)"
        }
        if !host.identityFile.isEmpty {
            cmd += " -i \(host.identityFile)"
        }
        cmd += " \(host.getUserAtHost())"
        return cmd
    }

    // 直接连接（用于测试）
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

    // 测试连接（异步）
    func testConnection(_ host: SSHHost) async -> ConnectionTestResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = [
            "-o", "ConnectTimeout=10",
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "PreferredAuthentications=publickey",
            "-o", "ServerAliveInterval=5",
            "-o", "ServerAliveCountMax=1",
            "-p", "\(host.port)",
            host.getUserAtHost()
        ]

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
}

// SSH错误解析器
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
            // 尝试找出是哪个文件不存在
            let lines = output.components(separatedBy: "\n")
            for line in lines {
                if line.contains("No such file") || line.contains("not found") {
                    // 简单提取路径（实际情况可能需要更复杂的解析）
                    return .keyFileNotFound("unknown_path")
                }
            }
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