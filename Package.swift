// swift-tools-version: 6.0
// MacPhoto Utility (Documentation/SPECIFICATION.md): the engine as a
// library, its tests, a developer's harness (mpu) that runs the engine
// without the window, and the SwiftUI app.
import PackageDescription

let package = Package(
    name: "MacPhotoUtility",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "MacPhotoKit", targets: ["MacPhotoKit"]),
        .executable(name: "mpu", targets: ["mpu"]),
        .executable(name: "MacPhotoUtility", targets: ["MacPhotoUtility"]),
    ],
    targets: [
        .target(name: "MacPhotoKit"),
        .executableTarget(name: "mpu", dependencies: ["MacPhotoKit"]),
        // The window (Phase 3); nothing the engine needs.
        .executableTarget(name: "MacPhotoUtility", dependencies: ["MacPhotoKit"]),
        .testTarget(name: "MacPhotoKitTests", dependencies: ["MacPhotoKit"]),
    ]
)
