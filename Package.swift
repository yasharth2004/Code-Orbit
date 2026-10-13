// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "CodeOrbit",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CodeOrbit", targets: ["CodeOrbit"])
    ],
    targets: [
        .executableTarget(
            name: "CodeOrbit",
            exclude: ["Info.plist", "CodeOrbit.entitlements"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "CodeOrbitTests",
            dependencies: ["CodeOrbit"]
        )
    ],
    swiftLanguageModes: [.v6]
)
