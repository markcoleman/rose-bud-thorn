// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RoseBudThorn",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "CoreModels", targets: ["CoreModels"]),
        .library(name: "CoreDate", targets: ["CoreDate"]),
        .library(name: "DocumentStore", targets: ["DocumentStore"]),
        .library(name: "SearchIndex", targets: ["SearchIndex"]),
        .library(name: "Summaries", targets: ["Summaries"]),
        .library(name: "AppFeatures", targets: ["AppFeatures"]),
        .executable(name: "RoseBudThornApp", targets: ["RoseBudThornApp"])
    ],
    targets: [
        .target(
            name: "CoreModels"
        ),
        .target(
            name: "CoreDate",
            dependencies: ["CoreModels"]
        ),
        .target(
            name: "DocumentStore",
            dependencies: ["CoreModels", "CoreDate"]
        ),
        .target(
            name: "SearchIndex",
            dependencies: ["CoreModels", "CoreDate", "DocumentStore"],
            exclude: ["IndexSchema.sql"]
        ),
        .target(
            name: "Summaries",
            dependencies: ["CoreModels", "CoreDate", "DocumentStore"]
        ),
        .target(
            name: "AppFeatures",
            dependencies: ["CoreModels", "CoreDate", "DocumentStore", "SearchIndex", "Summaries"]
        ),
        .executableTarget(
            name: "RoseBudThornApp",
            dependencies: ["AppFeatures"]
        ),
        .testTarget(
            name: "CoreModelsTests",
            dependencies: ["CoreModels"]
        ),
        .testTarget(
            name: "CoreDateTests",
            dependencies: ["CoreDate", "CoreModels"]
        ),
        .testTarget(
            name: "DocumentStoreTests",
            dependencies: ["DocumentStore", "CoreModels", "CoreDate"]
        ),
        .testTarget(
            name: "SearchIndexTests",
            dependencies: ["SearchIndex", "DocumentStore", "CoreModels", "CoreDate"]
        ),
        .testTarget(
            name: "SummariesTests",
            dependencies: ["Summaries", "DocumentStore", "CoreModels", "CoreDate"]
        ),
        .testTarget(
            name: "AppFeaturesTests",
            dependencies: ["AppFeatures", "DocumentStore", "SearchIndex", "Summaries", "CoreModels", "CoreDate"]
        )
    ]
)
