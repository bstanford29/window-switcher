// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WindowSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", exact: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "WindowSwitcher",
            dependencies: ["HotKey"],
            path: "Sources/WindowSwitcher",
            resources: [
                .process("../../Resources")
            ]
        )
    ]
)
