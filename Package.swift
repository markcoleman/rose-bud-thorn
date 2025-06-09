// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "RoseBudThorn",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "RoseBudThornApp",
            targets: ["RoseBudThornApp"]
        ),
        .library(
            name: "RoseBudThornCore",
            targets: ["RoseBudThornCore"]
        ),
        .library(
            name: "RoseBudThornUI",
            targets: ["RoseBudThornUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftGen/SwiftGen", from: "6.6.0"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX", from: "0.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.10.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "RoseBudThornCore",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS", condition: .when(platforms: [.iOS, .macCatalyst])),
            ],
            path: "Sources/RoseBudThornCore"
        ),
        .target(
            name: "RoseBudThornUI",
            dependencies: [
                "RoseBudThornCore",
                "SwiftUIX",
            ],
            path: "Sources/RoseBudThornUI",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "RoseBudThornApp",
            dependencies: [
                "RoseBudThornCore",
                "RoseBudThornUI",
            ],
            path: "Sources/RoseBudThornApp"
        ),
        .testTarget(
            name: "RoseBudThornTests",
            dependencies: [
                "RoseBudThornCore",
                "RoseBudThornUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "src/Tests"
        ),
    ]
)