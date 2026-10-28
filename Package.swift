// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Summwatch",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SummwatchCore", targets: ["SummwatchCore"]),
        .executable(name: "Summwatch", targets: ["SummwatchApp"]),
        .executable(name: "summwatch-mock", targets: ["SummwatchMock"]),
    ],
    targets: [
        // UI-agnostic core: Live Client API, game state, cooldown math, Data Dragon.
        // Foundation only — must never import AppKit or SwiftUI.
        .target(name: "SummwatchCore"),

        // Menu bar app and in-game overlay.
        .executableTarget(
            name: "SummwatchApp",
            dependencies: ["SummwatchCore"]
        ),

        // Fixture replay server and recorder for developing without a running game.
        .executableTarget(
            name: "SummwatchMock",
            dependencies: ["SummwatchCore"]
        ),

        .testTarget(
            name: "SummwatchCoreTests",
            dependencies: ["SummwatchCore"]
        ),
    ]
)
