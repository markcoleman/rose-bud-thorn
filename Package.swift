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
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.10.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", exact: "6.2.4"),
        .package(url: "https://github.com/google/gtm-session-fetcher", from: "3.4.0"),
    ],
    targets: [
        .target(
            name: "RoseBudThornCore",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS", condition: .when(platforms: [.iOS, .macCatalyst])),
                .product(name: "GTMSessionFetcher", package: "gtm-session-fetcher", condition: .when(platforms: [.iOS, .macCatalyst])),
            ],
            path: "Sources/RoseBudThornCore"
        ),
        .target(
            name: "RoseBudThornUI",
            dependencies: [
                "RoseBudThornCore",
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