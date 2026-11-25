// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MeshCore",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "MeshCore", targets: ["MeshCore"]),
        .library(name: "MeshBLE", targets: ["MeshBLE"]),
    ],
    targets: [
        .target(name: "MeshCore"),
        .target(name: "MeshBLE", dependencies: ["MeshCore"]),
        .testTarget(
            name: "MeshCoreTests",
            dependencies: ["MeshCore"],
            resources: [.copy("Resources/vectors.json")]
        ),
    ]
)
