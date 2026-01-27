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
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [
            "-e", "tell app \"iTerm\" to create window with default profile command \"ssh \(host.alias)\""
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
            "-o", "ConnectTimeout=5",
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=no",
            "-T",
            host.alias
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

// 连接测试结果
enum ConnectionTestResult {
    case success(latency: Double)
    case failure(SSHConnectionError)
}

// SSH连接错误类型
enum SSHConnectionError: Error, LocalizedError {
    case permissionDenied
    case connectionTimeout
    case unknownHost
    case keyFileNotFound(String)
    case keyFileWrongPermissions(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "服务器拒绝了你的连接，请检查密钥配置"
        case .connectionTimeout:
            return "连接超时，请检查主机地址和网络连接"
        case .unknownHost:
            return "无法解析主机地址"
        case .keyFileNotFound(let path):
            return "密钥文件不存在：\(path)"
        case .keyFileWrongPermissions(let path):
            return "密钥文件权限错误：\(path) (建议权限为600)"
        case .unknown(let message):
            return "连接失败：\(message)"
        }
    }
}

// SSH错误解析器
class SSHErrorParser {
    static func parseSystemError(_ output: String) -> SSHConnectionError {
        if output.contains("Permission denied") || output.contains("publickey") {
            return .permissionDenied
        } else if output.contains("Connection timed out") || output.contains("Operation timed out") {
            return .connectionTimeout
        } else if output.contains("Name or service not known") || output.contains("nodename nor servname provided") {
            return .unknownHost
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
        } else if output.contains("Bad permissions") {
            return .keyFileWrongPermissions("unknown_path")
        } else {
            return .unknown(output)
        }
    }
}