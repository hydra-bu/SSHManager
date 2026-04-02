// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SSHManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SSHManager", targets: ["SSHManager"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.9.0")
    ],
    targets: [
        .executableTarget(
            name: "SSHManager",
            dependencies: ["Sparkle"],
            path: "Sources/SSHManager"
        ),
        .testTarget(
            name: "SSHManagerTests",
            dependencies: ["SSHManager"],
            path: "Tests/SSHManagerTests"
        )
    ]
)