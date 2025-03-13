// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SatelliteUtilities",
    platforms: [
        .macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v10), .visionOS(.v2)
    ],
    products: [
        .library(
            name: "SatelliteUtilities",
            targets: ["SatelliteUtilities"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gavineadie/SatelliteKit.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "SatelliteUtilities", dependencies: ["SatelliteKit"]),
        .testTarget(
            name: "SatelliteUtilitiesTests",
            dependencies: ["SatelliteUtilities"]
        ),
    ]
)
