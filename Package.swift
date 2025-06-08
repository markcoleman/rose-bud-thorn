// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "RoseBudThorn",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "RoseBudThorn",
            targets: ["RoseBudThorn"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftGen/SwiftGen", from: "6.6.0"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX", from: "0.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.10.0"),
    ],
    targets: [
        .target(
            name: "RoseBudThorn",
            dependencies: [
                "SwiftUIX",
            ],
            path: "src/Shared"
        ),
        .testTarget(
            name: "RoseBudThornTests",
            dependencies: [
                "RoseBudThorn",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "src/Tests"
        ),
    ]
)