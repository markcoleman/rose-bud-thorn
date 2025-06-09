// swift-tools-version:5.7
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
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "RoseBudThorn",
            dependencies: [
                "SwiftUIX",
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS", condition: .when(platforms: [.iOS, .macCatalyst])),
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