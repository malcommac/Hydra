// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Hydra",
    platforms: [
        .macOS(.v10_10), .iOS(.v9), .watchOS(.v2), .tvOS(.v9)
    ],
    products: [
        .library(name: "Hydra", targets: ["Hydra"])
    ],
    targets: [
        .target(name: "Hydra", dependencies: []),
        .testTarget(name: "HydraTests", dependencies: ["Hydra"])
    ]
)
