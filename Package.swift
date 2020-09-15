// swift-tools-version:5.1
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
