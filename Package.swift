// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SSHManager",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "SSHManager", targets: ["SSHManager"])
    ],
    dependencies: [
        // 依赖项（如果需要的话）
    ],
    targets: [
        .executableTarget(
            name: "SSHManager",
            dependencies: [],
            path: "Sources/SSHManager"
        )
    ]
)