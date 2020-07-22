// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Hydra",
    products: [
        .library(name: "Hydra", targets: ["Hydra"])
    ],
    targets: [
        .target(name: "Hydra", dependencies: []),
        .testTarget(name: "HydraTests", dependencies: ["Hydra"])
    ]
)
