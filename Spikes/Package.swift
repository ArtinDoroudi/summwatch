// swift-tools-version: 6.0
// Throwaway M1 spikes. Not part of the Summwatch product; delete once findings are recorded in docs/adr/.
import PackageDescription

let package = Package(
    name: "SummwatchSpikes",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "overlay-spike", path: "Sources/OverlaySpike"),
        .executableTarget(name: "api-probe", path: "Sources/APIProbe"),
    ],
    swiftLanguageModes: [.v5]
)
