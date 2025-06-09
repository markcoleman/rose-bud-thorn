// swift-tools-version:5.7
import PackageDescription

#if os(iOS) || os(macOS) || os(macCatalyst) || os(tvOS) || os(watchOS) || os(visionOS)
let uiProducts: [Product] = [
    .executable(
        name: "RoseBudThornApp",
        targets: ["RoseBudThornApp"]
    ),
    .library(
        name: "RoseBudThornUI",
        targets: ["RoseBudThornUI"]
    ),
]
let uiTargets: [Target] = [
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
]
#else
let uiProducts: [Product] = []
let uiTargets: [Target] = []
#endif

let package = Package(
    name: "RoseBudThorn",
    platforms: [
        .iOS("16.1"),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "RoseBudThornCore",
            targets: ["RoseBudThornCore"]
        ),
    ] + uiProducts,
    dependencies: [
        .package(url: "https://github.com/SwiftGen/SwiftGen", from: "6.6.0"),
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
        .testTarget(
            name: "RoseBudThornTests",
            dependencies: [
                "RoseBudThornCore",
            ] + (uiTargets.isEmpty ? [] : ["RoseBudThornUI"]) + [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "src/Tests"
        ),
    ] + uiTargets
)