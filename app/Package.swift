// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacSweep",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "MacSweep", path: "Sources/MacSweep"),
        .testTarget(name: "MacSweepTests", dependencies: ["MacSweep"], path: "Tests/MacSweepTests"),
    ]
)
