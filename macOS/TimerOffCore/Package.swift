// swift-tools-version: 6.0
import PackageDescription

// The timer logic, kept apart from the app so it can be tested with `swift test` alone.
let package = Package(
    name: "TimerOffCore",
    platforms: [.macOS(.v15)],
    products: [.library(name: "TimerOffCore", targets: ["TimerOffCore"])],
    targets: [
        .target(name: "TimerOffCore"),
        .testTarget(name: "TimerOffCoreTests", dependencies: ["TimerOffCore"]),
    ]
)
