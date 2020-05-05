// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Hydra",
    products: [
        .library(name: "Hydra", targets: ["Hydra"])
    ],
    targets: [
        .target(name: "Hydra", dependencies: []),
        .testTarget(name: "HydraTests", dependencies: ["Hydra"])
    ],
    swiftLanguageVersions: [.v4, .v5]
)
